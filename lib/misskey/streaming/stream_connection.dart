import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../../core/logger.dart';
import '../http/host.dart';
import '../models/parsers.dart';
import 'reconnect_policy.dart';
import 'stream_messages.dart';
import 'stream_subscription_spec.dart';

/// One websocket session per `{host, account}` pair.
///
/// Owns:
/// - the websocket lifecycle
/// - the active subscription set (so it can resubscribe after reconnect)
/// - a heartbeat timer (Misskey idles connections after ~60s of silence)
/// - the reconnect loop with exponential backoff
///
/// Outbound API is the [events] stream. Subscribers don't see raw
/// websocket frames — only normalized [MisskeyStreamEvent]s.
class StreamConnection {
  final MisskeyHost host;
  final String token;
  final String accountId;

  /// Heartbeat interval. Misskey doesn't require client pings, but if we
  /// stay silent, NATs in the middle can drop the connection. Sending
  /// `ping` (an `unsubNote` for a known-bogus id is the canonical noop)
  /// keeps the path alive.
  final Duration _heartbeat;

  final _log = const Log('StreamConnection');
  final _events = StreamController<MisskeyStreamEvent>.broadcast();
  final _subscriptions = <String, StreamSubscriptionSpec>{};
  final _capturedNotes = <String>{};
  final ReconnectPolicy _backoff;

  /// How long a socket must stay open before the backoff schedule is
  /// rewound. Resetting on open alone let a server that accepts the
  /// upgrade and then rejects the token (closing immediately) drive a
  /// tight reconnect loop at the first slot's 500ms forever.
  final Duration _stableAfter;

  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  Timer? _stableTimer;
  bool _stopped = false;

  /// True while [_connect] is between the connect call and the socket
  /// being ready. Overlapping reconnects (an error and a close arriving
  /// for the same socket, or a stale timer) would otherwise open a
  /// second socket alongside the first.
  bool _connecting = false;
  ConnectionPhase _phase = ConnectionPhase.disconnected;

  StreamConnection({
    required this.host,
    required this.token,
    required this.accountId,
    Duration heartbeat = const Duration(seconds: 30),
    Duration stableAfter = const Duration(seconds: 5),
    ReconnectPolicy? backoff,
    @visibleForTesting String scheme = 'wss',
  })  : _heartbeat = heartbeat,
        _stableAfter = stableAfter,
        _scheme = scheme,
        _backoff = backoff ?? ReconnectPolicy();

  /// `wss` in production; tests point at a plaintext local server.
  final String _scheme;

  Stream<MisskeyStreamEvent> get events => _events.stream;
  ConnectionPhase get phase => _phase;

  /// Open the connection. Idempotent; call again after [stop] to restart.
  Future<void> start() async {
    if (_ws != null || _stopped) return;
    await _connect();
  }

  /// Close cleanly. After this, [start] won't reopen — discard the
  /// instance and create a new one (cheap; matches the supervisor's
  /// per-account ownership model).
  Future<void> stop() async {
    _stopped = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _stableTimer?.cancel();
    await _wsSub?.cancel();
    await _ws?.sink.close(ws_status.normalClosure);
    _ws = null;
    _emitState(ConnectionPhase.disconnected);
    await _events.close();
  }

  /// Subscribe to a channel. If the connection is up, the connect frame
  /// is sent immediately; otherwise it's queued and replayed after the
  /// next successful reconnect.
  void subscribe(StreamSubscriptionSpec spec) {
    _subscriptions[spec.localId] = spec;
    if (_phase == ConnectionPhase.connected) {
      _send(spec.toConnectFrame());
    }
  }

  void unsubscribe(String localId) {
    final spec = _subscriptions.remove(localId);
    if (spec != null && _phase == ConnectionPhase.connected) {
      _send(spec.toDisconnectFrame());
    }
  }

  /// Subscribe to per-note updates (reactions, edits, deletes) for a
  /// specific note. Used by [NoteCaptureManager] for viewport-visible
  /// notes; call [uncaptureNote] when the note leaves the viewport
  /// (debounced).
  void captureNote(String noteId) {
    _capturedNotes.add(noteId);
    if (_phase == ConnectionPhase.connected) {
      _send({'type': 'subNote', 'body': {'id': noteId}});
    }
  }

  void uncaptureNote(String noteId) {
    if (!_capturedNotes.remove(noteId)) return;
    if (_phase == ConnectionPhase.connected) {
      _send({'type': 'unsubNote', 'body': {'id': noteId}});
    }
  }

  Set<String> get capturedNotes => Set.unmodifiable(_capturedNotes);

  Future<void> _connect() async {
    if (_connecting || _stopped || _ws != null) return;
    _connecting = true;
    _emitState(ConnectionPhase.connecting);
    // MisskeyHost may carry an explicit port; Uri(host:) rejects a
    // colon, so split it out.
    final hostPort = host.value.split(':');
    final uri = Uri(
      scheme: _scheme,
      host: hostPort.first,
      port: hostPort.length > 1 ? int.tryParse(hostPort[1]) : null,
      path: '/streaming',
      queryParameters: {'i': token},
    );
    final WebSocketChannel ws;
    try {
      ws = WebSocketChannel.connect(uri);
      await ws.ready;
    } catch (e) {
      _connecting = false;
      _log.warn('connect failed for ${host.value}: $e');
      return _scheduleReconnect();
    }
    if (_stopped) {
      // stop() raced the handshake; don't adopt the socket.
      _connecting = false;
      unawaited(ws.sink.close(ws_status.normalClosure));
      return;
    }
    _ws = ws;
    _connecting = false;
    _emitState(ConnectionPhase.connected);
    _log.info('connected to ${host.value} as $accountId');

    // Only treat the connection as healthy — and rewind the backoff —
    // once it has stayed up for a while.
    _stableTimer?.cancel();
    _stableTimer = Timer(_stableAfter, () {
      if (_phase == ConnectionPhase.connected) _backoff.reset();
    });

    // An error is followed by a close for the same socket; both route
    // through _scheduleReconnect, which is idempotent while a
    // reconnect is already pending.
    _wsSub = ws.stream.listen(
      _onFrame,
      onError: (e, st) {
        _log.warn('socket error on ${host.value}: $e');
        _scheduleReconnect();
      },
      onDone: () {
        _log.warn('socket closed on ${host.value}');
        _scheduleReconnect();
      },
      cancelOnError: true,
    );

    // Replay subscriptions from before the disconnect.
    for (final s in _subscriptions.values) {
      _send(s.toConnectFrame());
    }
    // And replay note captures (NoteCaptureManager).
    for (final id in _capturedNotes) {
      _send({'type': 'subNote', 'body': {'id': id}});
    }

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeat, (_) => _ping());
  }

  void _ping() {
    if (_phase != ConnectionPhase.connected) return;
    // Misskey accepts an `unsubNote` for an unknown id silently; using it
    // as a no-op keeps NAT mappings alive without inventing a new frame.
    _send({
      'type': 'unsubNote',
      'body': {'id': '_heartbeat'},
    });
  }

  void _send(Map<String, dynamic> frame) {
    final ws = _ws;
    if (ws == null) return;
    try {
      ws.sink.add(jsonEncode(frame));
    } catch (e) {
      _log.warn('send failed: $e');
    }
  }

  void _onFrame(dynamic raw) {
    if (raw is! String) return;
    Map<String, dynamic> frame;
    try {
      frame = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _log.warn('non-json frame ignored');
      return;
    }
    final type = frame['type'] as String?;
    final body = frame['body'];
    switch (type) {
      case 'channel':
        _handleChannel(body as Map<String, dynamic>);
      case 'noteUpdated':
        _handleNoteUpdated(body as Map<String, dynamic>);
      default:
        _log.trace('unhandled frame type=$type');
    }
  }

  void _handleChannel(Map<String, dynamic> body) {
    final channelLocalId = body['id'] as String?;
    final innerType = body['type'] as String?;
    final innerBody = body['body'];
    if (channelLocalId == null || innerType == null) return;
    final spec = _subscriptions[channelLocalId];
    if (spec == null) return;

    switch (innerType) {
      case 'note':
        if (innerBody is Map<String, dynamic>) {
          final note = MisskeyParsers.noteFromJson(
            innerBody,
            sourceHost: host.value,
          );
          _events.add(NoteAdded(channelId: channelLocalId, note: note));
        }
      case 'mention':
      case 'reply':
      case 'renote':
      case 'followed':
      case 'unfollowed':
      case 'meUpdated':
      case 'reaction':
      case 'pollVoted':
      case 'notification':
        if (innerBody is Map<String, dynamic>) {
          _events.add(NotificationReceived(type: innerType, body: innerBody));
        }
      default:
        _log.trace('unhandled channel inner type=$innerType');
    }
  }

  void _handleNoteUpdated(Map<String, dynamic> body) {
    final id = body['id'] as String?;
    final type = body['type'] as String?;
    if (id == null) return;
    if (type == 'deleted') {
      _events.add(NoteDeleted(noteId: id, sourceHost: host.value));
    } else {
      _events.add(NoteUpdated(
        noteId: id,
        sourceHost: host.value,
        patch: body,
      ));
    }
  }

  void _scheduleReconnect() {
    if (_stopped) return;
    // Already counting down (e.g. onError then onDone for the same
    // socket): don't consume another backoff slot or replace the timer.
    if (_reconnectTimer?.isActive ?? false) return;
    _heartbeatTimer?.cancel();
    _stableTimer?.cancel();
    _wsSub?.cancel();
    _wsSub = null;
    _ws = null;
    _emitState(ConnectionPhase.reconnecting);
    final delay = _backoff.nextDelay();
    _log.info('reconnecting in ${delay.inMilliseconds}ms');
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      _connect();
    });
  }

  void _emitState(ConnectionPhase next, {Object? error}) {
    if (_phase == next) return;
    _phase = next;
    _events.add(ConnectionStateChanged(next, error: error));
  }
}
