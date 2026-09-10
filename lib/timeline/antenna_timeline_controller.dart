import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/logger.dart';
import '../misskey/emoji/emoji_providers.dart';
import '../misskey/emoji/emoji_repository.dart';
import '../misskey/http/endpoint_registry.dart';
import '../misskey/models/account.dart';
import '../misskey/models/note.dart';
import '../misskey/models/parsers.dart';
import '../misskey/streaming/stream_connection.dart';
import '../misskey/streaming/stream_messages.dart';
import '../misskey/streaming/stream_providers.dart';
import '../misskey/streaming/stream_subscription_spec.dart';
import 'note_keys.dart';
import 'note_list_ops.dart';
import 'stream_event_batcher.dart';

/// Family key for [antennaTimelineControllerProvider].
class AntennaTimelineArgs {
  final Account account;
  final String antennaId;
  const AntennaTimelineArgs({
    required this.account,
    required this.antennaId,
  });

  @override
  bool operator ==(Object other) =>
      other is AntennaTimelineArgs &&
      other.account.id == account.id &&
      other.antennaId == antennaId;

  @override
  int get hashCode => Object.hash(account.id, antennaId);
}

/// Snapshot of a single-antenna timeline.
class AntennaTimelineState {
  final List<Note> notes;

  /// `globalId -> Note` index over [notes]; see [TimelineState.byId].
  final Map<String, Note> byId;
  final List<Note> pending;
  final bool holdPending;
  final bool isPaginating;
  final bool reachedEnd;
  final ConnectionPhase connectionPhase;
  final Object? error;

  const AntennaTimelineState({
    this.notes = const [],
    this.byId = const {},
    this.pending = const [],
    this.holdPending = false,
    this.isPaginating = false,
    this.reachedEnd = false,
    this.connectionPhase = ConnectionPhase.disconnected,
    this.error,
  });

  AntennaTimelineState copyWith({
    List<Note>? notes,
    Map<String, Note>? byId,
    List<Note>? pending,
    bool? holdPending,
    bool? isPaginating,
    bool? reachedEnd,
    ConnectionPhase? connectionPhase,
    Object? error,
    bool clearError = false,
  }) =>
      AntennaTimelineState(
        notes: notes ?? this.notes,
        byId: byId ?? (notes == null ? this.byId : indexNotes(notes)),
        pending: pending ?? this.pending,
        holdPending: holdPending ?? this.holdPending,
        isPaginating: isPaginating ?? this.isPaginating,
        reachedEnd: reachedEnd ?? this.reachedEnd,
        connectionPhase: connectionPhase ?? this.connectionPhase,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Controller for a stand-alone antenna view. Mirrors
/// `ChannelTimelineController` exactly — same hold-pending, gap-fill,
/// streaming, and reaction-patch machinery. Two controllers instead of
/// one generalized variant because the per-row Riverpod `select` paths
/// in the screen are simpler when each timeline kind has its own
/// distinct provider family.
class AntennaTimelineController
    extends FamilyAsyncNotifier<AntennaTimelineState, AntennaTimelineArgs> {
  static const _pageSize = 30;
  static const _liveCap = 500;

  final _log = const Log('AntennaTimeline');

  late MisskeyEndpoints _endpoints;
  late EmojiRepository _emojiRepo;
  late AntennaTimelineArgs _args;
  late String _channelLocalId;
  ConnectionPhase _previousPhase = ConnectionPhase.disconnected;
  static const _ops = NoteListOps(cap: _liveCap);

  /// See [TimelineController._events].
  late final _events =
      StreamEventBatcher<MisskeyStreamEvent>(onFlush: _applyBatch);

  /// See [TimelineController._gapFilling].
  bool _gapFilling = false;

  @override
  Future<AntennaTimelineState> build(AntennaTimelineArgs args) async {
    _args = args;
    _events.clear();
    ref.onDispose(_events.clear);
    final endpoints =
        await ref.watch(misskeyEndpointsProvider(args.account).future);
    if (endpoints == null) {
      throw StateError('No HTTP client for ${args.account.id}');
    }
    _endpoints = endpoints;
    _emojiRepo = ref.watch(emojiRepositoryProvider);
    _channelLocalId = 'antenna:${args.account.id}:${args.antennaId}';
    _attachStream();

    final initial = await _endpoints.antennasNotes(
      antennaId: args.antennaId,
      limit: _pageSize,
    );
    _ingestEmoji(initial);
    return AntennaTimelineState(
      notes: initial,
      byId: indexNotes(initial),
      reachedEnd: initial.length < _pageSize,
      connectionPhase: _previousPhase,
    );
  }

  void _ingestEmoji(Iterable<Note> notes) {
    for (final n in notes) {
      MisskeyParsers.ingestEmojis(n, _emojiRepo);
    }
  }

  void _attachStream() {
    void bind(StreamConnection? conn) {
      if (conn == null) return;
      conn.subscribe(StreamSubscriptionSpec(
        localId: _channelLocalId,
        channel: MisskeyChannels.antenna,
        params: {'antennaId': _args.antennaId},
      ));
      _previousPhase = conn.phase;
    }

    final initial = ref.read(streamConnectionProvider(_args.account));
    bind(initial);
    if (initial != null) {
      ref.onDispose(() => initial.unsubscribe(_channelLocalId));
    }
    ref.listen<StreamConnection?>(
      streamConnectionProvider(_args.account),
      (prev, next) {
        if (prev == null && next != null) {
          bind(next);
          ref.onDispose(() => next.unsubscribe(_channelLocalId));
        }
      },
    );
    ref.listen<AsyncValue<MisskeyStreamEvent>>(
      streamEventsProvider(_args.account),
      (_, next) {
        final event = next.valueOrNull;
        if (event != null) _onEvent(event);
      },
    );
  }

  void _onEvent(MisskeyStreamEvent event) {
    switch (event) {
      case NoteAdded(:final channelId):
        if (channelId != _channelLocalId) return;
        _events.add(event);
      case NoteDeleted():
        _events.add(event);
      case NoteUpdated(:final patch):
        if (patch != null) _events.add(event);
      case ConnectionStateChanged(:final phase):
        _onConnectionPhase(phase);
      case NotificationReceived():
        break;
    }
  }

  /// See [TimelineController._applyBatch].
  void _applyBatch(List<MisskeyStreamEvent> batch) {
    final s = state.valueOrNull;
    if (s == null) return;
    final r = _ops.applyEvents(
      notes: s.notes,
      byId: s.byId,
      pending: s.pending,
      holdPending: s.holdPending,
      viewerUserId: _args.account.userId,
      batch: batch,
      accepts: (e) => e.channelId == _channelLocalId,
    );
    if (r == null) return;
    _ingestEmoji(r.added);
    state = AsyncData(s.copyWith(
      notes: r.notes,
      byId: r.byId,
      pending: r.pending,
    ));
  }

  Future<void> _onConnectionPhase(ConnectionPhase phase) async {
    final s = state.valueOrNull;
    if (s == null) {
      _previousPhase = phase;
      return;
    }
    state = AsyncData(s.copyWith(connectionPhase: phase));
    final wasDown = _previousPhase != ConnectionPhase.connected;
    _previousPhase = phase;
    if (phase == ConnectionPhase.connected && wasDown && s.notes.isNotEmpty) {
      await _gapFill(sinceId: s.notes.first.id);
    }
  }

  /// See [TimelineController._gapFill].
  Future<void> _gapFill({required String sinceId}) async {
    if (_gapFilling) return;
    _gapFilling = true;
    try {
      final fresh = await _endpoints.antennasNotes(
        antennaId: _args.antennaId,
        sinceId: sinceId,
        limit: _pageSize,
      );
      if (fresh.isEmpty) return;
      final s = state.valueOrNull;
      if (s == null) return;
      final dedup =
          fresh.where((n) => !s.byId.containsKey(noteKey(n))).toList();
      if (dedup.isEmpty) return;
      _ingestEmoji(dedup);
      final result = _ops.prependVisible(dedup, s.notes, s.byId);
      state = AsyncData(s.copyWith(notes: result.notes, byId: result.byId));
    } catch (e, st) {
      _log.warn('gap-fill failed: $e', stack: st);
    } finally {
      _gapFilling = false;
    }
  }

  void setHoldPending(bool hold) {
    final s = state.valueOrNull;
    if (s == null) return;
    if (s.holdPending == hold) return;
    if (!hold && s.pending.isNotEmpty) {
      releasePending();
      return;
    }
    state = AsyncData(s.copyWith(holdPending: hold));
  }

  void releasePending() {
    final s = state.valueOrNull;
    if (s == null) return;
    if (s.pending.isEmpty) {
      state = AsyncData(s.copyWith(holdPending: false));
      return;
    }
    final result = _ops.prependVisible(s.pending, s.notes, s.byId);
    state = AsyncData(s.copyWith(
      notes: result.notes,
      byId: result.byId,
      pending: const [],
      holdPending: false,
    ));
  }

  Future<void> loadMore() async {
    final s = state.valueOrNull;
    if (s == null || s.isPaginating || s.reachedEnd || s.notes.isEmpty) return;
    state = AsyncData(s.copyWith(isPaginating: true, clearError: true));
    try {
      final older = await _endpoints.antennasNotes(
        antennaId: _args.antennaId,
        untilId: s.notes.last.id,
        limit: _pageSize,
      );
      _ingestEmoji(older);
      // Append to the *current* list — streamed notes may have been
      // prepended while the page was in flight.
      final cur = state.valueOrNull ?? s;
      final additions =
          older.where((n) => !cur.byId.containsKey(noteKey(n))).toList();
      state = AsyncData(cur.copyWith(
        notes: [...cur.notes, ...additions],
        byId: Map.of(cur.byId)..addAll(indexNotes(additions)),
        isPaginating: false,
        reachedEnd: older.length < _pageSize,
      ));
    } catch (e, st) {
      _log.warn('loadMore failed: $e', stack: st);
      final cur = state.valueOrNull ?? s;
      state = AsyncData(cur.copyWith(isPaginating: false, error: e));
    }
  }

  Future<void> refresh() async {
    _events.clear();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(_args));
  }
}

final antennaTimelineControllerProvider = AsyncNotifierProvider.family<
    AntennaTimelineController,
    AntennaTimelineState,
    AntennaTimelineArgs>(AntennaTimelineController.new);
