import '../models/note.dart';

/// Normalized cross-channel events the rest of the app consumes.
///
/// Raw socket JSON never escapes the streaming layer — UI/repositories
/// only see `MisskeyStreamEvent`. This makes it cheap to swap protocols
/// (e.g. add Sharkey/Firefish-specific channels later) and cheap to test
/// without a live socket.
sealed class MisskeyStreamEvent {
  const MisskeyStreamEvent();
}

class NoteAdded extends MisskeyStreamEvent {
  /// Channel id this note arrived on (e.g. our internal subscription id),
  /// not the Misskey channel name.
  final String channelId;
  final Note note;
  const NoteAdded({required this.channelId, required this.note});
}

/// A note we previously [NoteAdded] (or captured) was edited or had its
/// reaction counts change.
class NoteUpdated extends MisskeyStreamEvent {
  final String noteId;
  final String sourceHost;

  /// Either the full updated note (preferred — emitted by `note` channel
  /// events) or a partial reaction patch (emitted by capture).
  final Note? full;
  final Map<String, dynamic>? patch;

  const NoteUpdated({
    required this.noteId,
    required this.sourceHost,
    this.full,
    this.patch,
  });
}

class NoteDeleted extends MisskeyStreamEvent {
  final String noteId;
  final String sourceHost;
  const NoteDeleted({required this.noteId, required this.sourceHost});
}

/// Anything from the `main` channel that isn't a note (mention, follow,
/// renote, reaction, DM hint, etc.). We pass the raw payload through so
/// the notifications screen  can render it without us hard-coding
/// every notification kind today.
class NotificationReceived extends MisskeyStreamEvent {
  final String type;
  final Map<String, dynamic> body;
  const NotificationReceived({required this.type, required this.body});
}

enum ConnectionPhase { connecting, connected, reconnecting, disconnected, failed }

class ConnectionStateChanged extends MisskeyStreamEvent {
  final ConnectionPhase phase;
  final Object? error;
  const ConnectionStateChanged(this.phase, {this.error});
}
