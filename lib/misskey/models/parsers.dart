import '../emoji/emoji_repository.dart';
import 'note.dart';
import 'note_channel.dart';
import 'note_file.dart';
import 'notification.dart';
import 'poll.dart';
import 'reaction.dart';
import 'user.dart';

/// JSON -> domain converters shared by the HTTP endpoint registry and
/// the streaming layer. Keeping them here means a Misskey schema tweak
/// is a one-file change.
class MisskeyParsers {
  static User userFromJson(
    Map<String, dynamic> j, {
    required String viewerHost,
  }) {
    return User(
      id: j['id'] as String,
      username: j['username'] as String,
      host: j['host'] as String?,
      name: j['name'] as String?,
      avatarUrl: j['avatarUrl'] as String?,
      avatarBlurhash: j['avatarBlurhash'] as String?,
      isBot: j['isBot'] == true,
      isCat: j['isCat'] == true,
    );
  }

  static Note noteFromJson(
    Map<String, dynamic> j, {
    required String sourceHost,
  }) {
    final user = userFromJson(
      j['user'] as Map<String, dynamic>,
      viewerHost: sourceHost,
    );
    final reactions = <Reaction>[];
    final raw = j['reactions'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final key = k.toString();
        reactions.add(Reaction(
          key: key,
          count: (v as num).toInt(),
          isCustom: key.startsWith(':') && key.endsWith(':'),
        ));
      });
    }
    final renoteJson = j['renote'];
    final Note? renote = renoteJson is Map<String, dynamic>
        ? noteFromJson(renoteJson, sourceHost: sourceHost)
        : null;
    final files = _filesFromJson(j['files']);
    final channelJson = j['channel'];
    final NoteChannel? channel =
        channelJson is Map<String, dynamic> ? _channelFromJson(channelJson) : null;
    final pollJson = j['poll'];
    final Poll? poll =
        pollJson is Map<String, dynamic> ? _pollFromJson(pollJson) : null;
    return Note(
      id: j['id'] as String,
      sourceHost: sourceHost,
      user: user,
      createdAt: DateTime.parse(j['createdAt'] as String),
      updatedAt: j['updatedAt'] != null
          ? DateTime.parse(j['updatedAt'] as String)
          : null,
      text: j['text'] as String?,
      cw: j['cw'] as String?,
      visibility: _visibility(j['visibility'] as String?),
      replyId: j['replyId'] as String?,
      renoteId: j['renoteId'] as String?,
      renote: renote,
      files: files,
      channel: channel,
      poll: poll,
      localOnly: j['localOnly'] == true,
      myReaction: j['myReaction'] as String?,
      reactions: reactions,
      repliesCount: (j['repliesCount'] as num?)?.toInt() ?? 0,
      renoteCount: (j['renoteCount'] as num?)?.toInt() ?? 0,
      // ActivityPub URI is populated for federated notes. The same
      // federated note observed by multiple of our accounts has the
      // same `uri` even though local `id`s differ.
      uri: j['uri'] as String?,
      rawExtras: _extrasFromJson(j),
    );
  }

  /// The subset of the wire payload a [Note] keeps after parsing.
  ///
  /// Every reader of [Note.rawExtras] today wants exactly one thing:
  /// the inline emoji blocks ([ingestEmojis]). Retaining the whole
  /// decoded map held the full user object, files, poll and reaction
  /// JSON alive for every note in an 800-row timeline — several times
  /// the size of the parsed model. So we flatten all the emoji blocks
  /// (note, reactions, author, nested renote / reply) into one
  /// `name@host -> url` map and drop the rest. Null when the note
  /// carries no custom emoji at all.
  ///
  /// Anything else a future feature needs from the payload should be
  /// parsed into a typed field here rather than read back from extras.
  static Map<String, dynamic>? _extrasFromJson(Map<String, dynamic> j) {
    final emojis = <String, dynamic>{};
    _collectEmojis(j, emojis);
    if (emojis.isEmpty) return null;
    return {_extrasEmojiKey: emojis};
  }

  static const _extrasEmojiKey = 'emojis';

  static void _collectEmojis(Map<String, dynamic> j, Map<String, dynamic> out) {
    void take(Object? m) {
      if (m is! Map) return;
      m.forEach((k, v) {
        if (k is String && v is String) out[k] = v;
      });
    }

    take(j['emojis']);
    take(j['reactionEmojis']);
    final user = j['user'];
    if (user is Map) take(user['emojis']);
    // Nested notes are parsed with the same sourceHost, so their bare
    // `name` keys resolve against the same viewer host.
    final renote = j['renote'];
    if (renote is Map) _collectEmojis(renote.cast<String, dynamic>(), out);
    final reply = j['reply'];
    if (reply is Map) _collectEmojis(reply.cast<String, dynamic>(), out);
  }

  static Poll _pollFromJson(Map<String, dynamic> j) {
    final rawChoices = j['choices'];
    final choices = <PollChoice>[];
    if (rawChoices is List) {
      for (final c in rawChoices) {
        if (c is! Map) continue;
        final m = c.cast<String, dynamic>();
        final text = m['text'];
        if (text is! String) continue;
        choices.add(PollChoice(
          text: text,
          votes: (m['votes'] as num?)?.toInt() ?? 0,
          isVoted: m['isVoted'] == true,
        ));
      }
    }
    final expires = j['expiresAt'];
    return Poll(
      expiresAt: expires is String ? DateTime.tryParse(expires) : null,
      multiple: j['multiple'] == true,
      choices: choices,
    );
  }

  static NoteChannel _channelFromJson(Map<String, dynamic> j) {
    return NoteChannel(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      color: j['color'] as String?,
      isSensitive: j['isSensitive'] == true,
    );
  }

  static List<NoteFile> _filesFromJson(Object? raw) {
    if (raw is! List) return const [];
    final out = <NoteFile>[];
    for (final f in raw) {
      if (f is! Map) continue;
      final m = f.cast<String, dynamic>();
      final url = m['url'];
      final type = m['type'];
      final id = m['id'];
      if (url is! String || type is! String || id is! String) continue;
      final props = m['properties'];
      int? width;
      int? height;
      if (props is Map) {
        width = (props['width'] as num?)?.toInt();
        height = (props['height'] as num?)?.toInt();
      }
      out.add(NoteFile(
        id: id,
        type: type,
        url: url,
        thumbnailUrl: m['thumbnailUrl'] as String?,
        name: m['name'] as String?,
        comment: m['comment'] as String?,
        blurhash: m['blurhash'] as String?,
        isSensitive: m['isSensitive'] == true,
        width: width,
        height: height,
      ));
    }
    return out;
  }

  /// Feed the emoji map a parsed note retained (see [_extrasFromJson];
  /// it already covers the nested renote/reply and author blocks) to
  /// [repo]. Misskey embeds the URL for every `:name@host:` referenced
  /// anywhere in the payload, so this covers federated emoji even on
  /// hosts the user has no account on — no additional fetch is needed
  /// for the rendering path.
  ///
  /// `repo.ingestInline` is idempotent and cheap; safe to call on every
  /// arriving note.
  static void ingestEmojis(Note note, EmojiRepository repo) {
    final extras = note.rawExtras;
    if (extras == null) return;
    final emojis = extras[_extrasEmojiKey];
    if (emojis is! Map) return;
    repo.ingestInline(
      viewerHost: note.sourceHost,
      embedded: emojis.cast<String, dynamic>(),
    );
  }

  /// Same as [ingestEmojis] but for a freshly-parsed user JSON (e.g.
  /// `users/show`) so display-name emoji resolve immediately.
  static void ingestUserEmojis(
    Map<String, dynamic> userJson, {
    required String viewerHost,
    required EmojiRepository repo,
  }) {
    final em = userJson['emojis'];
    if (em is Map) {
      repo.ingestInline(
        viewerHost: viewerHost,
        embedded: em.cast<String, dynamic>(),
      );
    }
  }

  static NoteVisibility _visibility(String? raw) {
    switch (raw) {
      case 'home':
        return NoteVisibility.home;
      case 'followers':
        return NoteVisibility.followers;
      case 'specified':
        return NoteVisibility.specified;
      case 'public':
      default:
        return NoteVisibility.public;
    }
  }

  /// Decode an `i/notifications` row. Misskey wires every notification
  /// type through the same envelope; we map the `type` string to a
  /// [NotificationKind] and pull whichever sub-fields the type
  /// actually carries.
  static MisskeyNotification notificationFromJson(
    Map<String, dynamic> j, {
    required String viewerHost,
  }) {
    final rawType = j['type'] as String? ?? 'unknown';
    final kind = _notificationKind(rawType);
    final userJson = j['user'];
    final user = userJson is Map<String, dynamic>
        ? userFromJson(userJson, viewerHost: viewerHost)
        : null;
    final noteJson = j['note'];
    final note = noteJson is Map<String, dynamic>
        ? noteFromJson(noteJson, sourceHost: viewerHost)
        : null;
    return MisskeyNotification(
      id: j['id'] as String,
      kind: kind,
      rawType: rawType,
      createdAt: DateTime.parse(j['createdAt'] as String),
      user: user,
      note: note,
      reaction: j['reaction'] as String?,
      isRead: j['isRead'] == true,
    );
  }

  static NotificationKind _notificationKind(String t) {
    switch (t) {
      case 'follow':
        return NotificationKind.follow;
      case 'unfollow':
        return NotificationKind.unfollow;
      case 'receiveFollowRequest':
        return NotificationKind.followRequest;
      case 'followRequestAccepted':
        return NotificationKind.followRequestAccepted;
      case 'mention':
        return NotificationKind.mention;
      case 'reply':
        return NotificationKind.reply;
      case 'renote':
        return NotificationKind.renote;
      case 'quote':
        return NotificationKind.quote;
      case 'reaction':
        return NotificationKind.reaction;
      case 'reaction:grouped':
        return NotificationKind.reactionGrouped;
      case 'renote:grouped':
        return NotificationKind.renoteGrouped;
      case 'achievementEarned':
        return NotificationKind.achievementEarned;
      case 'pollEnded':
        return NotificationKind.pollEnded;
      default:
        return NotificationKind.other;
    }
  }
}
