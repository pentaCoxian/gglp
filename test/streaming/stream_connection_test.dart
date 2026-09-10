import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/misskey/http/host.dart';
import 'package:misskey_gglp/misskey/streaming/reconnect_policy.dart';
import 'package:misskey_gglp/misskey/streaming/stream_connection.dart';
import 'package:misskey_gglp/misskey/streaming/stream_messages.dart';

/// Backoff policy that hands out tiny delays and counts calls, so the
/// tests can assert "one backoff slot per socket loss" and "no reset
/// until the socket has been stable".
class _CountingPolicy extends ReconnectPolicy {
  int delays = 0;
  int resets = 0;

  @override
  Duration nextDelay() {
    delays++;
    return const Duration(milliseconds: 20);
  }

  @override
  void reset() {
    resets++;
  }
}

/// Loopback websocket server. In `reject` mode it completes the upgrade
/// and closes immediately — what a Misskey server does with a bad
/// token — otherwise it holds the socket open.
class _FakeServer {
  _FakeServer._(this._server, {required this.reject}) {
    _server.listen(_handle);
  }

  static Future<_FakeServer> start({required bool reject}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _FakeServer._(server, reject: reject);
  }

  final HttpServer _server;
  final bool reject;
  final _sockets = <WebSocket>[];
  int accepted = 0;
  int concurrent = 0;
  int maxConcurrent = 0;

  MisskeyHost get host => MisskeyHost.parse('127.0.0.1:${_server.port}');

  Future<void> _handle(HttpRequest req) async {
    if (!WebSocketTransformer.isUpgradeRequest(req)) {
      req.response.statusCode = HttpStatus.badRequest;
      await req.response.close();
      return;
    }
    final ws = await WebSocketTransformer.upgrade(req);
    accepted++;
    concurrent++;
    maxConcurrent = math.max(maxConcurrent, concurrent);
    _sockets.add(ws);
    unawaited(ws.done.then((_) => concurrent--));
    if (reject) {
      await ws.close();
    } else {
      // Drain frames so the client's sends don't back up.
      ws.listen((_) {});
    }
  }

  Future<void> close() async {
    for (final ws in _sockets) {
      await ws.close();
    }
    await _server.close(force: true);
  }
}

void main() {
  test('a server that closes right after upgrade backs off, never resets, '
      'and never has two sockets open', () async {
    final server = await _FakeServer.start(reject: true);
    addTearDown(server.close);
    final policy = _CountingPolicy();
    final conn = StreamConnection(
      host: server.host,
      token: 'bad',
      accountId: 'acct',
      backoff: policy,
      stableAfter: const Duration(seconds: 30),
      scheme: 'ws',
    );
    final phases = <ConnectionPhase>[];
    final sub = conn.events.listen((e) {
      if (e is ConnectionStateChanged) phases.add(e.phase);
    });
    addTearDown(sub.cancel);

    await conn.start();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await conn.stop();

    expect(server.accepted, greaterThanOrEqualTo(3),
        reason: 'kept reconnecting');
    expect(server.maxConcurrent, 1, reason: 'no overlapping sockets');
    // Exactly one backoff slot per lost socket (an error + close pair
    // used to consume two).
    expect(policy.delays, inInclusiveRange(server.accepted - 1, server.accepted));
    expect(policy.resets, 0, reason: 'never stayed up long enough');
    expect(phases, contains(ConnectionPhase.reconnecting));
  });

  test('backoff resets only after the socket has stayed up', () async {
    final server = await _FakeServer.start(reject: false);
    addTearDown(server.close);
    final policy = _CountingPolicy();
    final conn = StreamConnection(
      host: server.host,
      token: 'ok',
      accountId: 'acct',
      backoff: policy,
      stableAfter: const Duration(milliseconds: 100),
      scheme: 'ws',
    );
    await conn.start();
    expect(conn.phase, ConnectionPhase.connected);
    expect(policy.resets, 0, reason: 'not yet stable');
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(policy.resets, 1);
    expect(policy.delays, 0);
    expect(server.accepted, 1);
    await conn.stop();
    expect(conn.phase, ConnectionPhase.disconnected);
  });

  test('start is idempotent while connecting or connected', () async {
    final server = await _FakeServer.start(reject: false);
    addTearDown(server.close);
    final conn = StreamConnection(
      host: server.host,
      token: 'ok',
      accountId: 'acct',
      backoff: _CountingPolicy(),
      scheme: 'ws',
    );
    await Future.wait([conn.start(), conn.start(), conn.start()]);
    await conn.start();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(server.accepted, 1);
    expect(server.maxConcurrent, 1);
    await conn.stop();
  });
}
