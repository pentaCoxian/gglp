import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/logger.dart';
import '../http/host.dart';
import '../models/account.dart';
import 'stream_connection.dart';
import 'stream_messages.dart';

/// Owns one [StreamConnection] per logged-in account for the entire app
/// lifetime.
///
/// Reacts to changes in [accountsProvider]:
///   - new account in the list → open a connection
///   - account removed → close + drop its connection
///
/// Exposes the per-account map plus a merged event stream so the
/// unified timeline (next step) can listen once instead of fanning out
/// listens itself.
class StreamSupervisor {
  final Ref _ref;
  final _log = const Log('StreamSupervisor');
  final _connections = <String, StreamConnection>{};
  final _merged = StreamController<MisskeyStreamEvent>.broadcast();
  final _streamSubs = <String, StreamSubscription<MisskeyStreamEvent>>{};

  /// Bumped on every reconcile that adds or removes a connection.
  /// Riverpod consumers can watch [connectionsRevisionProvider] to
  /// re-run when the map changes — useful when a brand-new account
  /// finishes opening its websocket and timeline controllers need
  /// to subscribe their per-kind channel.
  final _revision = StreamController<int>.broadcast();
  int _revisionTick = 0;
  Stream<int> get revision => _revision.stream;
  int get currentRevision => _revisionTick;

  StreamSupervisor(this._ref);

  Map<String, StreamConnection> get connections =>
      Map.unmodifiable(_connections);

  StreamConnection? connectionFor(Account account) =>
      _connections[account.id];

  /// Cross-account event stream. Each event carries enough info
  /// (channelId / sourceHost / noteId) for the merge engine to
  /// attribute it to the right account.
  Stream<MisskeyStreamEvent> get events => _merged.stream;

  Future<void> reconcile(List<Account> accounts) async {
    final wantedIds = accounts.map((a) => a.id).toSet();
    var dirty = false;

    // Drop accounts that are no longer logged in.
    final stale = _connections.keys
        .where((id) => !wantedIds.contains(id))
        .toList(growable: false);
    for (final id in stale) {
      _log.info('closing stream for $id');
      await _streamSubs.remove(id)?.cancel();
      await _connections.remove(id)?.stop();
      dirty = true;
    }

    // Open new connections for new accounts.
    for (final account in accounts) {
      if (_connections.containsKey(account.id)) continue;
      try {
        final token = await _ref
            .read(secureTokenStoreProvider)
            .read(accountId: account.id);
        if (token == null) {
          _log.warn('skipping ${account.id}: no token (re-auth needed)');
          continue;
        }
        final conn = StreamConnection(
          host: MisskeyHost.parse(account.host),
          token: token,
          accountId: account.id,
        );
        _connections[account.id] = conn;
        _streamSubs[account.id] = conn.events.listen(_merged.add);
        // Bump revision the moment the entry exists — consumers can
        // bind subscriptions even before the first frame is flushed.
        // start() returns once the websocket transitions out of
        // CONNECTING, so bumping again afterwards isn't necessary.
        _revisionTick++;
        _revision.add(_revisionTick);
        dirty = true;
        await conn.start();
        _log.info('opened stream for ${account.id}');
      } catch (e, st) {
        _log.warn('failed to open ${account.id}: $e', stack: st);
      }
    }

    // Bump once more on overall completion so consumers that missed
    // the per-account bump (e.g. providers built mid-reconcile) still
    // see something.
    if (dirty) {
      _revisionTick++;
      _revision.add(_revisionTick);
    }
  }

  Future<void> shutdown() async {
    for (final s in _streamSubs.values) {
      await s.cancel();
    }
    _streamSubs.clear();
    for (final c in _connections.values) {
      await c.stop();
    }
    _connections.clear();
    await _merged.close();
    await _revision.close();
  }
}

/// App-lifetime supervisor. Reacts to the accounts list and keeps the
/// underlying [StreamConnection]s in sync.
final streamSupervisorProvider = Provider<StreamSupervisor>((ref) {
  final supervisor = StreamSupervisor(ref);

  // React to the accounts stream from Drift. fireImmediately: not
  // needed; the StreamProvider replays its current value when listened.
  ref.listen<AsyncValue<List<Account>>>(
    accountsProvider,
    (_, next) {
      final accounts = next.valueOrNull;
      if (accounts == null) return;
      // Fire and forget; reconcile is internally idempotent.
      supervisor.reconcile(accounts);
    },
    fireImmediately: true,
  );

  ref.onDispose(supervisor.shutdown);
  return supervisor;
});
