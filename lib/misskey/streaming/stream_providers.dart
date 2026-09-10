import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../timeline/note_capture_manager.dart';
import '../models/account.dart';
import 'stream_connection.dart';
import 'stream_messages.dart';
import 'stream_supervisor.dart';

/// Ticks every time the supervisor opens or closes a connection. Bind
/// to this in any provider that needs to re-fire when a fresh account's
/// websocket is added — e.g. [streamConnectionProvider] needs to
/// re-evaluate so a controller built right after add-account picks up
/// the connection the supervisor was still spinning up.
final connectionsRevisionProvider = StreamProvider<int>((ref) async* {
  final supervisor = ref.watch(streamSupervisorProvider);
  yield supervisor.currentRevision;
  yield* supervisor.revision;
});

/// Per-account [StreamConnection], looked up from the supervisor.
///
/// The supervisor opens these eagerly (one per logged-in account) and
/// keeps them alive for the app lifetime. This provider depends on
/// [connectionsRevisionProvider] so any add/remove triggers a rebuild
/// for consumers — without it, a controller created in the brief
/// window between `addAccount` returning and `reconcile` finishing
/// would cache a null connection forever.
final streamConnectionProvider =
    Provider.family<StreamConnection?, Account>((ref, account) {
  // Watch the revision so this provider re-runs on every supervisor
  // mutation. Reading via `valueOrNull` keeps the first-frame case
  // (no value yet) from blocking us.
  ref.watch(connectionsRevisionProvider);
  final supervisor = ref.watch(streamSupervisorProvider);
  return supervisor.connectionFor(account);
});

/// Per-account event stream filtered out of the supervisor's merged
/// stream. Only events tagged for this account flow through.
///
/// `NoteAdded`, `NoteUpdated`, `NoteDeleted` carry a `sourceHost`; we
/// match by host. `ConnectionStateChanged` and `NotificationReceived`
/// arrive without an account tag, so we infer membership via the
/// connection identity at subscribe time. (Each connection scopes its
/// own broadcast stream pre-merge.)
final streamEventsProvider =
    StreamProvider.family<MisskeyStreamEvent, Account>((ref, account) async* {
  final conn =
      ref.watch(streamSupervisorProvider).connectionFor(account);
  if (conn == null) return;
  yield* conn.events;
});

/// Merged stream of every account's events. Used by the unified
/// timeline + the in-app notification surface .
final mergedStreamEventsProvider =
    StreamProvider<MisskeyStreamEvent>((ref) async* {
  final supervisor = ref.watch(streamSupervisorProvider);
  yield* supervisor.events;
});

/// One [NoteCaptureManager] per account. Disposed automatically when
/// the account is removed (the connection-for-account lookup goes
/// null and the family entry can be invalidated).
final noteCaptureManagerProvider =
    Provider.family<NoteCaptureManager?, Account>((ref, account) {
  final conn = ref.watch(streamSupervisorProvider).connectionFor(account);
  if (conn == null) return null;
  final manager = NoteCaptureManager(conn);
  ref.onDispose(manager.dispose);
  return manager;
});

/// Live connection phase for an account. Combines the connection's
/// initial phase with subsequent ConnectionStateChanged events. Used by
/// the account drawer and per-timeline status badges.
final connectionPhaseProvider =
    StreamProvider.family<ConnectionPhase, Account>((ref, account) async* {
  final conn = ref.watch(streamSupervisorProvider).connectionFor(account);
  if (conn == null) {
    yield ConnectionPhase.disconnected;
    return;
  }
  yield conn.phase;
  await for (final ev in conn.events) {
    if (ev is ConnectionStateChanged) yield ev.phase;
  }
});
