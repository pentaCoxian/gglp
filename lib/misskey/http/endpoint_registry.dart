import 'package:dio/dio.dart';

import '../models/note.dart';
import '../models/note_file.dart';
import '../models/notification.dart';
import '../models/parsers.dart';
import '../models/server.dart';
import '../models/user.dart';
import 'misskey_http_client.dart';

/// Typed wrappers around the Misskey REST endpoints we use.
///
/// Each method shapes params and decodes the response into a domain model.
/// We don't use a generated client because Misskey's schema is large and
/// not all forks publish OpenAPI docs.
class MisskeyEndpoints {
  final MisskeyHttpClient http;
  MisskeyEndpoints(this.http);

  String get host => http.host.value;

  /// Server metadata. Required during account add to capture server
  /// software/name and confirm reachability.
  Future<Server> meta() async {
    final raw = await http.call('meta', params: {'detail': false}) as Map<String, dynamic>;
    return Server(
      host: host,
      name: raw['name'] as String?,
      description: raw['description'] as String?,
      softwareName: (raw['softwareName'] ?? raw['software']?['name']) as String?,
      softwareVersion:
          (raw['softwareVersion'] ?? raw['software']?['version']) as String?,
      iconUrl: (raw['iconUrl'] ?? raw['icon']) as String?,
      bannerUrl: raw['bannerUrl'] as String?,
      metaFetchedAt: DateTime.now(),
    );
  }

  /// Logged-in user — used right after token issuance to populate the
  /// `Account` row with display name, avatar, etc.
  Future<Map<String, dynamic>> i() async {
    return (await http.call('i', requireToken: true)) as Map<String, dynamic>;
  }

  /// Resolve a user by id from the viewer's host perspective.
  Future<User> usersShow(String userId) async {
    final raw = await http.call(
      'users/show',
      params: {'userId': userId},
    ) as Map<String, dynamic>;
    return MisskeyParsers.userFromJson(raw, viewerHost: host);
  }

  /// Resolve a user by `username + host` (host null = local).
  ///
  /// This is the cross-server identity bridge for follow: the user the
  /// active account sees in a federated note has an id that's local to
  /// the *delivering* server, but the active account's `following/create`
  /// expects an id local to its OWN server. So we lookup again on the
  /// active server using the (username, home host) tuple, which Misskey
  /// resolves via WebFinger.
  ///
  /// Also returns the full raw map so callers (e.g. follow flow) can
  /// inspect `isFollowing`/`hasPendingFollowRequestFromYou`.
  Future<Map<String, dynamic>> usersShowByHandle({
    required String username,
    String? userHost,
  }) async {
    final raw = await http.call(
      'users/show',
      params: {
        'username': username,
        if (userHost != null) 'host': userHost,
      },
    ) as Map<String, dynamic>;
    return raw;
  }

  /// Per-account home timeline.
  ///
  /// Pagination uses Misskey's cursor convention: `untilId` for older,
  /// `sinceId` for newer. we always paginate per-account
  /// and merge in the timeline_merge_engine.
  Future<List<Note>> homeTimeline({
    int limit = 30,
    String? sinceId,
    String? untilId,
    DateTime? sinceDate,
    DateTime? untilDate,
  }) =>
      _timeline('notes/timeline',
          limit: limit,
          sinceId: sinceId,
          untilId: untilId,
          sinceDate: sinceDate,
          untilDate: untilDate);

  Future<List<Note>> localTimeline({
    int limit = 30,
    String? sinceId,
    String? untilId,
    DateTime? sinceDate,
    DateTime? untilDate,
  }) =>
      _timeline('notes/local-timeline',
          limit: limit,
          sinceId: sinceId,
          untilId: untilId,
          sinceDate: sinceDate,
          untilDate: untilDate);

  Future<List<Note>> hybridTimeline({
    int limit = 30,
    String? sinceId,
    String? untilId,
    DateTime? sinceDate,
    DateTime? untilDate,
  }) =>
      _timeline('notes/hybrid-timeline',
          limit: limit,
          sinceId: sinceId,
          untilId: untilId,
          sinceDate: sinceDate,
          untilDate: untilDate);

  /// Notes posted into a specific Misskey channel.
  Future<List<Note>> channelTimeline({
    required String channelId,
    int limit = 30,
    String? sinceId,
    String? untilId,
    DateTime? sinceDate,
    DateTime? untilDate,
  }) async {
    final raw = await http.call(
      'channels/timeline',
      requireToken: true,
      params: {
        'channelId': channelId,
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
        if (sinceDate != null) 'sinceDate': sinceDate.millisecondsSinceEpoch,
        if (untilDate != null) 'untilDate': untilDate.millisecondsSinceEpoch,
      },
    );
    final list = (raw as List).cast<Map<String, dynamic>>();
    return list
        .map((j) => MisskeyParsers.noteFromJson(j, sourceHost: host))
        .toList();
  }

  /// Channels the active account follows. Returns the raw JSON list so
  /// the picker can pull `name` / `color` / `bannerUrl` without us
  /// having to model the full Channel entity yet.
  Future<List<Map<String, dynamic>>> channelsFollowed({
    int limit = 100,
  }) async {
    final raw = await http.call(
      'channels/followed',
      requireToken: true,
      params: {'limit': limit},
    );
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Resolve a single channel by id.
  Future<Map<String, dynamic>> channelsShow(String channelId) async {
    return (await http.call(
      'channels/show',
      requireToken: true,
      params: {'channelId': channelId},
    )) as Map<String, dynamic>;
  }

  /// Featured (recently-active) channels on this server. Doesn't
  /// require any scope — useful as a fallback list when the active
  /// account doesn't follow any channels yet.
  Future<List<Map<String, dynamic>>> channelsFeatured() async {
    final raw = await http.call('channels/featured');
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Free-text search over channels on this server. Useful for
  /// discovering channels the user hasn't joined yet.
  Future<List<Map<String, dynamic>>> channelsSearch({
    required String query,
    int limit = 30,
    String type = 'nameAndDescription',
  }) async {
    final raw = await http.call('channels/search', params: {
      'query': query,
      'type': type,
      'limit': limit,
    });
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Channels the active account created. Additive to [channelsFollowed]
  /// for the compose-time channel picker: you can post into your own
  /// channel without following it.
  Future<List<Map<String, dynamic>>> channelsOwned({int limit = 100}) async {
    final raw = await http.call(
      'channels/owned',
      requireToken: true,
      params: {'limit': limit},
    );
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Channels the active account starred ("favorites"). Misskey's web
  /// composer lists these first in its channel selector, so we do too.
  Future<List<Map<String, dynamic>>> channelsMyFavorites() async {
    final raw = await http.call('channels/my-favorites', requireToken: true);
    return (raw as List).cast<Map<String, dynamic>>();
  }

  Future<List<Note>> globalTimeline({
    int limit = 30,
    String? sinceId,
    String? untilId,
    DateTime? sinceDate,
    DateTime? untilDate,
  }) =>
      _timeline('notes/global-timeline',
          limit: limit,
          sinceId: sinceId,
          untilId: untilId,
          sinceDate: sinceDate,
          untilDate: untilDate);

  Future<Note> notesShow(String noteId) async {
    final raw = await http.call(
      'notes/show',
      params: {'noteId': noteId},
    ) as Map<String, dynamic>;
    return MisskeyParsers.noteFromJson(raw, sourceHost: host);
  }

  /// Direct replies (and quote-renotes) to a note. One level deep;
  /// callers recurse on demand for deeper threads.
  Future<List<Note>> notesChildren({
    required String noteId,
    int limit = 30,
    String? untilId,
  }) async {
    final raw = await http.call(
      'notes/children',
      params: {
        'noteId': noteId,
        'limit': limit,
        if (untilId != null) 'untilId': untilId,
      },
    );
    return (raw as List)
        .cast<Map<String, dynamic>>()
        .map((j) => MisskeyParsers.noteFromJson(j, sourceHost: host))
        .toList();
  }

  /// Ancestor chain of a reply — the notes this note was replying to,
  /// nearest first. Used by the thread screen to show context above
  /// the focal note.
  Future<List<Note>> notesConversation({
    required String noteId,
    int limit = 30,
  }) async {
    final raw = await http.call(
      'notes/conversation',
      params: {'noteId': noteId, 'limit': limit},
    );
    return (raw as List)
        .cast<Map<String, dynamic>>()
        .map((j) => MisskeyParsers.noteFromJson(j, sourceHost: host))
        .toList();
  }

  /// Cast a vote. [choice] is the zero-based index into
  /// `note.poll.choices`.
  Future<void> pollsVote({required String noteId, required int choice}) async {
    await http.call(
      'notes/polls/vote',
      requireToken: true,
      params: {'noteId': noteId, 'choice': choice},
    );
  }

  /// Full-text note search. Scope-free on most servers, but some
  /// disable it (`notes/search` 400s) — callers surface the error.
  Future<List<Note>> notesSearch({
    required String query,
    int limit = 30,
    String? untilId,
    String? userId,
  }) async {
    final raw = await http.call(
      'notes/search',
      requireToken: true,
      params: {
        'query': query,
        'limit': limit,
        if (untilId != null) 'untilId': untilId,
        if (userId != null) 'userId': userId,
      },
    );
    return (raw as List)
        .cast<Map<String, dynamic>>()
        .map((j) => MisskeyParsers.noteFromJson(j, sourceHost: host))
        .toList();
  }

  /// Notes carrying a hashtag. Powers hashtag tap-through.
  Future<List<Note>> notesSearchByTag({
    required String tag,
    int limit = 30,
    String? untilId,
  }) async {
    final raw = await http.call(
      'notes/search-by-tag',
      requireToken: true,
      params: {
        'tag': tag,
        'limit': limit,
        if (untilId != null) 'untilId': untilId,
      },
    );
    return (raw as List)
        .cast<Map<String, dynamic>>()
        .map((j) => MisskeyParsers.noteFromJson(j, sourceHost: host))
        .toList();
  }

  /// User search (name / username / bio, server decides). Returns raw
  /// user JSON so callers can read follow-state fields.
  Future<List<Map<String, dynamic>>> usersSearch({
    required String query,
    int limit = 30,
    int offset = 0,
  }) async {
    final raw = await http.call(
      'users/search',
      requireToken: true,
      params: {'query': query, 'limit': limit, 'offset': offset},
    );
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Bookmark ("favorite") a note. Misskey rejects double-bookmarks
  /// with `ALREADY_FAVORITED`.
  Future<void> notesFavoritesCreate(String noteId) async {
    await http.call(
      'notes/favorites/create',
      requireToken: true,
      params: {'noteId': noteId},
    );
  }

  Future<void> notesFavoritesDelete(String noteId) async {
    await http.call(
      'notes/favorites/delete',
      requireToken: true,
      params: {'noteId': noteId},
    );
  }

  /// The account's bookmarks, newest first. Rows are
  /// `{id, createdAt, note}` — the wrapper id is the pagination
  /// cursor, NOT the note id.
  Future<List<Map<String, dynamic>>> iFavorites({
    int limit = 30,
    String? untilId,
  }) async {
    final raw = await http.call(
      'i/favorites',
      requireToken: true,
      params: {
        'limit': limit,
        if (untilId != null) 'untilId': untilId,
      },
    );
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Who reacted to a note. Rows are `{id, createdAt, user, type}`
  /// where `type` is the reaction key.
  Future<List<Map<String, dynamic>>> notesReactionsList({
    required String noteId,
    String? type,
    int limit = 30,
    int offset = 0,
  }) async {
    final raw = await http.call(
      'notes/reactions',
      params: {
        'noteId': noteId,
        if (type != null) 'type': type,
        'limit': limit,
        'offset': offset,
      },
    );
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Who renoted a note (renote envelopes; `.user` is the renoter).
  Future<List<Note>> notesRenotes({
    required String noteId,
    int limit = 30,
    String? untilId,
  }) async {
    final raw = await http.call(
      'notes/renotes',
      params: {
        'noteId': noteId,
        'limit': limit,
        if (untilId != null) 'untilId': untilId,
      },
    );
    return (raw as List)
        .cast<Map<String, dynamic>>()
        .map((j) => MisskeyParsers.noteFromJson(j, sourceHost: host))
        .toList();
  }

  /// Resolve an ActivityPub URI on the active server. Used to
  /// re-anchor a federated note onto a different account's server
  /// so reply / quote ids are valid for the poster.
  ///
  /// Returns null if Misskey can't resolve (`noSuchObject`,
  /// `federationNotAllowed`, etc.) — caller decides whether to
  /// surface the error.
  Future<Note?> apShowNote(String uri) async {
    final raw = await http.call(
      'ap/show',
      requireToken: true,
      params: {'uri': uri},
    ) as Map<String, dynamic>;
    if (raw['type'] != 'Note') return null;
    final obj = raw['object'];
    if (obj is! Map<String, dynamic>) return null;
    return MisskeyParsers.noteFromJson(obj, sourceHost: host);
  }

  /// Server-wide custom emoji catalog. Vanilla Misskey returns
  /// `{ "emojis": [...] }`. Forks may differ — keep raw entries available.
  Future<List<Map<String, dynamic>>> emojis() async {
    final raw = await http.call('emojis') as Map<String, dynamic>;
    final list = raw['emojis'];
    return list is List ? list.cast<Map<String, dynamic>>() : const [];
  }

  /// Create (post) a note. `fileIds` are drive file ids returned by
  /// [driveFilesCreate]. `replyId` / `renoteId` produce reply / renote /
  /// quote (renote + non-empty text/cw/files = quote on Misskey).
  Future<Note> notesCreate({
    String? text,
    String? cw,
    String visibility = 'public',
    bool localOnly = false,
    String? replyId,
    String? renoteId,
    String? channelId,
    List<String>? fileIds,

    /// Poll payload: `{choices: [...], multiple?, expiresAt?,
    /// expiredAfter?}` per Misskey's `notes/create` schema.
    Map<String, dynamic>? poll,
  }) async {
    final raw = await http.call(
      'notes/create',
      requireToken: true,
      params: {
        if (text != null && text.isNotEmpty) 'text': text,
        if (cw != null && cw.isNotEmpty) 'cw': cw,
        'visibility': visibility,
        if (localOnly) 'localOnly': true,
        if (replyId != null) 'replyId': replyId,
        if (renoteId != null) 'renoteId': renoteId,
        if (channelId != null) 'channelId': channelId,
        if (fileIds != null && fileIds.isNotEmpty) 'fileIds': fileIds,
        if (poll != null) 'poll': poll,
      },
    ) as Map<String, dynamic>;
    final created = raw['createdNote'] as Map<String, dynamic>;
    return MisskeyParsers.noteFromJson(created, sourceHost: host);
  }

  /// Delete a note authored by the active account.
  Future<void> notesDelete(String noteId) async {
    await http.call(
      'notes/delete',
      requireToken: true,
      params: {'noteId': noteId},
    );
  }

  /// Add a reaction. `reaction` is a unicode codepoint sequence (e.g.
  /// `👍`) or a custom-emoji `:name@host:` (or `:name:` for local).
  Future<void> notesReactionsCreate({
    required String noteId,
    required String reaction,
  }) async {
    await http.call(
      'notes/reactions/create',
      requireToken: true,
      params: {'noteId': noteId, 'reaction': reaction},
    );
  }

  /// Remove a reaction.
  Future<void> notesReactionsDelete({required String noteId}) async {
    await http.call(
      'notes/reactions/delete',
      requireToken: true,
      params: {'noteId': noteId},
    );
  }

  /// Follow a user.
  Future<Map<String, dynamic>> followingCreate(String userId) async {
    return (await http.call(
      'following/create',
      requireToken: true,
      params: {'userId': userId},
    )) as Map<String, dynamic>;
  }

  /// Unfollow a user.
  Future<Map<String, dynamic>> followingDelete(String userId) async {
    return (await http.call(
      'following/delete',
      requireToken: true,
      params: {'userId': userId},
    )) as Map<String, dynamic>;
  }

  /// Mute a user (their notes disappear from timelines server-side).
  Future<void> muteCreate(String userId) async {
    await http.call('mute/create',
        requireToken: true, params: {'userId': userId});
  }

  Future<void> muteDelete(String userId) async {
    await http.call('mute/delete',
        requireToken: true, params: {'userId': userId});
  }

  /// Block a user.
  Future<void> blockingCreate(String userId) async {
    await http.call('blocking/create',
        requireToken: true, params: {'userId': userId});
  }

  Future<void> blockingDelete(String userId) async {
    await http.call('blocking/delete',
        requireToken: true, params: {'userId': userId});
  }

  /// File an abuse report against a user with free-text [comment].
  Future<void> usersReportAbuse({
    required String userId,
    required String comment,
  }) async {
    await http.call(
      'users/report-abuse',
      requireToken: true,
      params: {'userId': userId, 'comment': comment},
    );
  }

  /// A user's followers. Rows are `{id, createdAt, follower: <user>}`;
  /// the wrapper `id` is the pagination cursor.
  Future<List<Map<String, dynamic>>> usersFollowers({
    required String userId,
    int limit = 30,
    String? untilId,
  }) async {
    final raw = await http.call(
      'users/followers',
      params: {
        'userId': userId,
        'limit': limit,
        if (untilId != null) 'untilId': untilId,
      },
    );
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Users someone follows. Rows are `{id, createdAt, followee: <user>}`.
  Future<List<Map<String, dynamic>>> usersFollowing({
    required String userId,
    int limit = 30,
    String? untilId,
  }) async {
    final raw = await http.call(
      'users/following',
      params: {
        'userId': userId,
        'limit': limit,
        if (untilId != null) 'untilId': untilId,
      },
    );
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Pending follow requests TO the active account (for locked
  /// accounts). Rows are `{id, follower: <user>, followee: <user>}`.
  Future<List<Map<String, dynamic>>> followingRequestsList({
    int limit = 30,
    String? untilId,
  }) async {
    final raw = await http.call(
      'following/requests/list',
      requireToken: true,
      params: {
        'limit': limit,
        if (untilId != null) 'untilId': untilId,
      },
    );
    return (raw as List).cast<Map<String, dynamic>>();
  }

  Future<void> followingRequestsAccept(String userId) async {
    await http.call('following/requests/accept',
        requireToken: true, params: {'userId': userId});
  }

  Future<void> followingRequestsReject(String userId) async {
    await http.call('following/requests/reject',
        requireToken: true, params: {'userId': userId});
  }

  /// Link-preview metadata via the server's summaly proxy. This is a
  /// plain GET on `/url` (NOT under `/api/`); returns
  /// `{title, description, thumbnail, icon, sitename, player, ...}`
  /// or null when the server can't summarize the page.
  Future<Map<String, dynamic>?> urlPreview(String url) async {
    final raw = await http.getPath('url', query: {'url': url});
    return raw is Map<String, dynamic> ? raw : null;
  }

  /// Upload a file to drive. Misskey's `drive/files/create` is
  /// multipart-only.
  Future<NoteFile> driveFilesCreate({
    required List<int> bytes,
    required String filename,
    String? contentType,
    bool isSensitive = false,
    String? folderId,
    String? comment,
  }) async {
    final raw = await http.upload(
      path: 'drive/files/create',
      file: MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: contentType != null
            ? DioMediaType.parse(contentType)
            : null,
      ),
      extraFields: {
        if (folderId != null) 'folderId': folderId,
        if (isSensitive) 'isSensitive': 'true',
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        'name': filename,
      },
    );
    return _driveFileFromJson(raw);
  }

  /// Resolve a single drive file by id. Used by the page viewer to turn
  /// a `PageBlockImage.fileId` into a usable URL — `pages/show` only
  /// returns the id, not the file object. Requires `read:drive`.
  Future<NoteFile> driveFilesShow(String fileId) async {
    final raw = await http.call(
      'drive/files/show',
      requireToken: true,
      params: {'fileId': fileId},
    ) as Map<String, dynamic>;
    return _driveFileFromJson(raw);
  }

  static NoteFile _driveFileFromJson(Map<String, dynamic> j) {
    final props = j['properties'];
    int? width;
    int? height;
    if (props is Map) {
      width = (props['width'] as num?)?.toInt();
      height = (props['height'] as num?)?.toInt();
    }
    return NoteFile(
      id: j['id'] as String,
      type: j['type'] as String? ?? 'application/octet-stream',
      url: j['url'] as String,
      thumbnailUrl: j['thumbnailUrl'] as String?,
      name: j['name'] as String?,
      comment: j['comment'] as String?,
      blurhash: j['blurhash'] as String?,
      isSensitive: j['isSensitive'] == true,
      width: width,
      height: height,
    );
  }

  Future<List<Map<String, dynamic>>> notifications({
    int limit = 30,
    String? sinceId,
    String? untilId,
  }) async {
    final raw = await http.call(
      'i/notifications',
      requireToken: true,
      params: {
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
      },
    );
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Same as [notifications] but returns parsed [MisskeyNotification]s.
  Future<List<MisskeyNotification>> notificationsParsed({
    int limit = 30,
    String? sinceId,
    String? untilId,
  }) async {
    final raw = await notifications(
      limit: limit,
      sinceId: sinceId,
      untilId: untilId,
    );
    return raw
        .map((j) =>
            MisskeyParsers.notificationFromJson(j, viewerHost: host))
        .toList(growable: false);
  }

  /// Notes posted by a single user. Used by the profile screen's
  /// timeline. Pagination via the standard `untilId` cursor.
  Future<List<Note>> usersNotes({
    required String userId,
    int limit = 30,
    String? sinceId,
    String? untilId,
    bool withReplies = true,
    bool withRenotes = true,
    bool withFiles = false,
  }) async {
    final raw = await http.call(
      'users/notes',
      requireToken: true,
      params: {
        'userId': userId,
        'limit': limit,
        'withReplies': withReplies,
        'withRenotes': withRenotes,
        if (withFiles) 'withFiles': true,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
      },
    );
    final list = (raw as List).cast<Map<String, dynamic>>();
    return list
        .map((j) => MisskeyParsers.noteFromJson(j, sourceHost: host))
        .toList(growable: false);
  }

  /// Mark every unread notification as read. Calling this clears the
  /// unread dot on the drawer entry. We don't send anything else with
  /// the request — Misskey rolls "all read" into one endpoint.
  Future<void> notificationsMarkAllAsRead() async {
    await http.call('notifications/mark-all-as-read', requireToken: true);
  }

  /// Antennas the active account has saved. `read:account` scope.
  Future<List<Map<String, dynamic>>> antennasList() async {
    final raw =
        await http.call('antennas/list', requireToken: true) as List;
    return raw.cast<Map<String, dynamic>>();
  }

  /// Notes matching an antenna. Same paging shape as the timelines.
  Future<List<Note>> antennasNotes({
    required String antennaId,
    int limit = 30,
    String? sinceId,
    String? untilId,
    DateTime? sinceDate,
    DateTime? untilDate,
  }) async {
    final raw = await http.call(
      'antennas/notes',
      requireToken: true,
      params: {
        'antennaId': antennaId,
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
        if (sinceDate != null) 'sinceDate': sinceDate.millisecondsSinceEpoch,
        if (untilDate != null) 'untilDate': untilDate.millisecondsSinceEpoch,
      },
    );
    final list = (raw as List).cast<Map<String, dynamic>>();
    return list
        .map((j) => MisskeyParsers.noteFromJson(j, sourceHost: host))
        .toList();
  }

  /// Resolve a single antenna's metadata.
  Future<Map<String, dynamic>> antennasShow(String antennaId) async {
    return (await http.call(
      'antennas/show',
      requireToken: true,
      params: {'antennaId': antennaId},
    )) as Map<String, dynamic>;
  }

  /// Page metadata + content blocks. Anonymous endpoint, no scope.
  ///
  /// Misskey accepts either `pageId` or `name + username`. We expose
  /// both shapes for flexibility.
  Future<Map<String, dynamic>> pagesShow({
    String? pageId,
    String? username,
    String? name,
  }) async {
    return (await http.call('pages/show', params: {
      if (pageId != null) 'pageId': pageId,
      if (username != null) 'username': username,
      if (name != null) 'name': name,
    })) as Map<String, dynamic>;
  }

  /// Featured pages. Anonymous endpoint.
  Future<List<Map<String, dynamic>>> pagesFeatured() async {
    final raw = await http.call('pages/featured');
    return (raw as List).cast<Map<String, dynamic>>();
  }

  /// Create a new page. Requires `write:pages`.
  ///
  /// `content` is the block tree — see `lib/misskey/models/page_block.dart`
  /// for the in-memory shape. We accept it as raw JSON-able list to keep
  /// this signature flexible while the editor evolves.
  Future<Map<String, dynamic>> pagesCreate({
    required String title,
    required String name,
    String? summary,
    required List<Map<String, dynamic>> content,
    List<Map<String, dynamic>> variables = const [],
    String script = '',
    String font = 'sans-serif',
    bool alignCenter = false,
    bool hideTitleWhenPinned = false,
    String? eyeCatchingImageId,
  }) async {
    return (await http.call('pages/create', requireToken: true, params: {
      'title': title,
      'name': name,
      if (summary != null) 'summary': summary,
      'content': content,
      'variables': variables,
      'script': script,
      'font': font,
      'alignCenter': alignCenter,
      'hideTitleWhenPinned': hideTitleWhenPinned,
      if (eyeCatchingImageId != null)
        'eyeCatchingImageId': eyeCatchingImageId,
    })) as Map<String, dynamic>;
  }

  /// Update an existing page. Requires `write:pages`.
  Future<void> pagesUpdate({
    required String pageId,
    required String title,
    required String name,
    String? summary,
    required List<Map<String, dynamic>> content,
    List<Map<String, dynamic>> variables = const [],
    String script = '',
    String font = 'sans-serif',
    bool alignCenter = false,
    bool hideTitleWhenPinned = false,
    String? eyeCatchingImageId,
  }) async {
    await http.call('pages/update', requireToken: true, params: {
      'pageId': pageId,
      'title': title,
      'name': name,
      if (summary != null) 'summary': summary,
      'content': content,
      'variables': variables,
      'script': script,
      'font': font,
      'alignCenter': alignCenter,
      'hideTitleWhenPinned': hideTitleWhenPinned,
      if (eyeCatchingImageId != null)
        'eyeCatchingImageId': eyeCatchingImageId,
    });
  }

  Future<void> pagesDelete(String pageId) async {
    await http.call('pages/delete',
        requireToken: true, params: {'pageId': pageId});
  }

  /// Pages the active account has authored.
  Future<List<Map<String, dynamic>>> iPages({
    int limit = 50,
    String? sinceId,
    String? untilId,
  }) async {
    final raw = await http.call('i/pages', requireToken: true, params: {
      'limit': limit,
      if (sinceId != null) 'sinceId': sinceId,
      if (untilId != null) 'untilId': untilId,
    });
    return (raw as List).cast<Map<String, dynamic>>();
  }

  Future<List<Note>> _timeline(
    String path, {
    required int limit,
    String? sinceId,
    String? untilId,
    DateTime? sinceDate,
    DateTime? untilDate,
  }) async {
    final raw = await http.call(
      path,
      requireToken: true,
      params: {
        'limit': limit,
        if (sinceId != null) 'sinceId': sinceId,
        if (untilId != null) 'untilId': untilId,
        if (sinceDate != null) 'sinceDate': sinceDate.millisecondsSinceEpoch,
        if (untilDate != null) 'untilDate': untilDate.millisecondsSinceEpoch,
      },
    );
    final list = (raw as List).cast<Map<String, dynamic>>();
    return list
        .map((j) => MisskeyParsers.noteFromJson(j, sourceHost: host))
        .toList();
  }
}
