import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/logger.dart';
import '../misskey/http/endpoint_registry.dart';
import '../misskey/models/account.dart';
import '../misskey/models/note.dart';
import '../misskey/models/note_file.dart';

/// Account-scoped facade over the write endpoints.
///
/// Returns parsed domain objects on success and throws Misskey errors
/// on failure so callers can surface a SnackBar. Optimistic local
/// updates (visible reaction count etc.) are intentionally NOT applied
/// here — Misskey echoes the same change back through the websocket
/// `noteUpdated` channel and the timeline already routes those into
/// `ReactionPatch.apply`. Doing the optimistic update twice would
/// either double-count the change or require a reconciliation pass.
class NoteActionsService {
  final _log = const Log('NoteActions');
  final MisskeyEndpoints _endpoints;
  final Account account;

  NoteActionsService({
    required this.account,
    required MisskeyEndpoints endpoints,
  }) : _endpoints = endpoints;

  /// Post a new note. `text` may be null for a pure renote.
  Future<Note> create({
    String? text,
    String? cw,
    String visibility = 'public',
    bool localOnly = false,
    String? replyId,
    String? renoteId,
    String? channelId,
    List<String>? fileIds,
    Map<String, dynamic>? poll,
  }) {
    return _endpoints.notesCreate(
      text: text,
      cw: cw,
      visibility: visibility,
      localOnly: localOnly,
      replyId: replyId,
      renoteId: renoteId,
      channelId: channelId,
      fileIds: fileIds,
      poll: poll,
    );
  }

  /// Pure renote (boost) — no commentary.
  Future<Note> renote(Note source) => create(
        renoteId: source.id,
        visibility: source.visibility.name,
      );

  /// Quote renote — embeds [source] as `renote` while keeping our own
  /// commentary text.
  Future<Note> quote({
    required Note source,
    required String text,
    String? cw,
    String? visibility,
    List<String>? fileIds,
  }) =>
      create(
        text: text,
        cw: cw,
        renoteId: source.id,
        visibility: visibility ?? source.visibility.name,
        fileIds: fileIds,
      );

  Future<void> delete(Note note) => _endpoints.notesDelete(note.id);

  Future<void> react({
    required Note note,
    required String reaction,
  }) =>
      _endpoints.notesReactionsCreate(noteId: note.id, reaction: reaction);

  Future<void> unreact(Note note) =>
      _endpoints.notesReactionsDelete(noteId: note.id);

  /// Vote on a poll choice (zero-based index).
  Future<void> vote({required Note note, required int choice}) =>
      _endpoints.pollsVote(noteId: note.id, choice: choice);

  /// Bookmark ("favorite") a note. Swallows Misskey's
  /// ALREADY_FAVORITED double-tap error — the end state is what the
  /// user asked for either way.
  Future<void> favorite(Note note) async {
    try {
      await _endpoints.notesFavoritesCreate(note.id);
    } catch (e, st) {
      if ('$e'.toUpperCase().contains('ALREADY')) return;
      _log.warn('favorite ${note.id} failed: $e', stack: st);
      rethrow;
    }
  }

  Future<void> unfavorite(Note note) =>
      _endpoints.notesFavoritesDelete(note.id);

  Future<void> muteUser(String userId) =>
      _endpoints.muteCreate(userId);

  Future<void> unmuteUser(String userId) =>
      _endpoints.muteDelete(userId);

  Future<void> blockUser(String userId) =>
      _endpoints.blockingCreate(userId);

  Future<void> unblockUser(String userId) =>
      _endpoints.blockingDelete(userId);

  Future<void> reportUser({
    required String userId,
    required String comment,
  }) =>
      _endpoints.usersReportAbuse(userId: userId, comment: comment);

  /// Resolve a note author's handle to an id on this account's server,
  /// then run [action] on it. Mirrors the follow-by-handle pattern —
  /// federated author ids are local to the delivering server and can't
  /// be used directly.
  Future<void> _byHandle(
    String username,
    String? userHost,
    Future<void> Function(String userId) action,
  ) async {
    final resolved = await resolveUserByHandle(
      username: username,
      userHost: userHost,
    );
    final id = resolved['id'] as String?;
    if (id == null) {
      throw StateError('users/show did not return an id');
    }
    await action(id);
  }

  Future<void> muteByHandle({
    required String username,
    String? userHost,
  }) =>
      _byHandle(username, userHost, muteUser);

  Future<void> blockByHandle({
    required String username,
    String? userHost,
  }) =>
      _byHandle(username, userHost, blockUser);

  Future<void> reportByHandle({
    required String username,
    String? userHost,
    required String comment,
  }) =>
      _byHandle(
        username,
        userHost,
        (id) => reportUser(userId: id, comment: comment),
      );

  Future<void> follow(String userId) async {
    try {
      await _endpoints.followingCreate(userId);
    } catch (e, st) {
      _log.warn('follow $userId failed: $e', stack: st);
      rethrow;
    }
  }

  Future<void> unfollow(String userId) async {
    try {
      await _endpoints.followingDelete(userId);
    } catch (e, st) {
      _log.warn('unfollow $userId failed: $e', stack: st);
      rethrow;
    }
  }

  /// Look up a user on the active account's server by (`username`,
  /// `userHost`). `userHost` is the user's home host — null when the
  /// target is local to [account.host]. Returns the raw user JSON;
  /// callers may pull `id`, `isFollowing`, etc.
  Future<Map<String, dynamic>> resolveUserByHandle({
    required String username,
    String? userHost,
  }) {
    // A user local to our own server is sent with host == null in
    // Misskey's federation conventions; normalize here so callers
    // don't have to.
    final effective = (userHost == null || userHost == account.host)
        ? null
        : userHost;
    return _endpoints.usersShowByHandle(
      username: username,
      userHost: effective,
    );
  }

  /// Convenience: resolve [username]+[userHost] to an id on the
  /// active account's server, then follow them. Handles the
  /// federated-author case where the id we have was issued by a
  /// foreign delivering server.
  Future<void> followByHandle({
    required String username,
    String? userHost,
  }) async {
    final resolved = await resolveUserByHandle(
      username: username,
      userHost: userHost,
    );
    final id = resolved['id'] as String?;
    if (id == null) {
      throw StateError('users/show did not return an id');
    }
    await follow(id);
  }

  Future<void> unfollowByHandle({
    required String username,
    String? userHost,
  }) async {
    final resolved = await resolveUserByHandle(
      username: username,
      userHost: userHost,
    );
    final id = resolved['id'] as String?;
    if (id == null) {
      throw StateError('users/show did not return an id');
    }
    await unfollow(id);
  }

  /// Re-anchor a [source] note onto this account's server.
  ///
  /// `notes/reactions/create`, `notes/create` (with replyId/renoteId),
  /// etc. all expect the **local** note id on the account's server.
  /// When the active account differs from the note's `sourceHost`,
  /// the local id we have isn't valid; we call `ap/show` to fetch
  /// the canonical id on this server (Misskey will pull the note over
  /// federation if it hasn't seen it yet).
  ///
  /// If [source] is already local to this account's server we short-
  /// circuit and return [source] unchanged.
  ///
  /// Returns null when the active server can't or won't resolve the
  /// URI (federation blocked, instance offline, dropped from cache,
  /// etc.) — callers should surface that to the user.
  Future<Note?> resolveOnThisAccount(Note source) async {
    if (source.sourceHost == account.host) return source;
    return resolveByUri(source.originId);
  }

  /// Look up a note by its canonical AP URI on this account's server.
  /// Returns null on `noSuchObject` / federation-blocked. Used by
  /// draft-resume to re-anchor a stored URI without needing the full
  /// source-note object in memory.
  Future<Note?> resolveByUri(String uri) async {
    try {
      return await _endpoints.apShowNote(uri);
    } catch (e, st) {
      _log.warn('ap/show $uri on ${account.host} failed: $e', stack: st);
      rethrow;
    }
  }

  /// Look up a note by its id local to this account. Used to restore
  /// a draft's reply/quote source when resuming.
  Future<Note?> notesShow(String noteId) async {
    try {
      return await _endpoints.notesShow(noteId);
    } catch (e, st) {
      _log.warn('notes/show $noteId failed: $e', stack: st);
      return null;
    }
  }

  Future<NoteFile> uploadFile({
    required List<int> bytes,
    required String filename,
    String? contentType,
    bool isSensitive = false,
  }) =>
      _endpoints.driveFilesCreate(
        bytes: bytes,
        filename: filename,
        contentType: contentType,
        isSensitive: isSensitive,
      );
}

/// Per-account write facade. Watches the auth-scoped endpoints provider
/// so an account row removal disposes the service.
final noteActionsProvider =
    FutureProvider.family<NoteActionsService?, Account>((ref, account) async {
  final endpoints = await ref.watch(misskeyEndpointsProvider(account).future);
  if (endpoints == null) return null;
  return NoteActionsService(account: account, endpoints: endpoints);
});
