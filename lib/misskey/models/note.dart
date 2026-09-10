import 'package:freezed_annotation/freezed_annotation.dart';

import 'note_channel.dart';
import 'note_file.dart';
import 'poll.dart';
import 'reaction.dart';
import 'user.dart';

part 'note.freezed.dart';
part 'note.g.dart';

enum NoteVisibility { public, home, followers, specified }

/// A Misskey note.
///
/// Design-doc rule: every note preserves its `sourceHost`. The same `id` on
/// different hosts is a different note (federated copies are NOT assumed
/// canonical-equal).
@freezed
class Note with _$Note {
  const Note._();

  const factory Note({
    required String id,
    required String sourceHost,
    required User user,
    required DateTime createdAt,
    DateTime? updatedAt,
    String? text,
    String? cw,
    @Default(NoteVisibility.public) NoteVisibility visibility,
    String? replyId,
    String? renoteId,

    /// The full renoted note when one is embedded. Misskey ships the
    /// renoted note alongside the renote envelope so we can render a
    /// quote / boost without an extra fetch. Null on plain notes.
    Note? renote,

    /// Drive files attached to the note. Empty for text-only notes.
    @Default(<NoteFile>[]) List<NoteFile> files,

    /// Channel this note belongs to, if any. Misskey channels are
    /// server-side topic groups — when present we render a chip in
    /// the header so the user can see which channel the note came
    /// from.
    NoteChannel? channel,

    /// Poll attached to the note, if any. Choice vote counts and the
    /// viewer's `isVoted` flags come straight from the note JSON.
    Poll? poll,

    /// True when the author posted with the "local-only" flag set.
    /// Misskey calls these "non-federated" notes. We surface this as
    /// a small badge in the metadata row alongside the visibility
    /// icon, since federated viewers should never see them.
    @Default(false) bool localOnly,

    /// The viewer's own reaction key, if any. Misskey ships this as
    /// `myReaction` in the note JSON when there's an authenticated
    /// caller. The reaction chip uses it to toggle: tapping a chip
    /// whose key matches `myReaction` un-reacts; tapping any other
    /// chip is a no-op for now (re-reacting requires removing the
    /// previous reaction first, which is friction we surface via the
    /// "+ React" button instead).
    String? myReaction,
    @Default(<Reaction>[]) List<Reaction> reactions,
    @Default(0) int repliesCount,
    @Default(0) int renoteCount,

    /// ActivityPub URI for federated notes. Populated by Misskey only
    /// when the note's author is on a different server from `sourceHost`.
    /// Stable across all receiving servers — this is the ONLY identity
    /// that lets us dedup the same federated note across our accounts.
    String? uri,

    /// Compact per-note extras retained from the wire payload. Today
    /// this holds only the flattened inline emoji map under `emojis`
    /// (see `MisskeyParsers._extrasFromJson`); the full decoded JSON
    /// is deliberately NOT kept — it was several times the size of the
    /// parsed model for every note in memory. Model new fields
    /// explicitly rather than reading them back from here.
    Map<String, dynamic>? rawExtras,
  }) = _Note;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);

  /// Per-receiver identity. Two accounts each receiving the same
  /// federated note will produce DIFFERENT `globalId`s (because their
  /// `sourceHost` and local `id` differ). Used for cache keys and
  /// per-account timeline state where you want one row per receiving
  /// server.
  String get globalId => '$sourceHost:$id';

  /// Monotonically-increasing revision number derived from observable
  /// fields that affect the rendered layout (text/cw/files/updatedAt).
  /// Used as the cache-busting component of the height-cache key.
  ///
  /// We don't track `reactions` here because the reaction bar's height
  /// is constant (`InlinePlaceholderMetrics.reactionRowHeight`) — only
  /// edits that change the body / cw / media count change the layout.
  int get revision {
    final updated = updatedAt?.millisecondsSinceEpoch ?? 0;
    final fileCount = files.length;
    return updated ^ (fileCount * 0x9e3779b1);
  }

  /// True for a "quote renote" — a renote that adds its own text or
  /// attaches files. A renote without text/cw/files is a plain boost
  /// and should render with just a "renoted" header above the inner
  /// note's content.
  bool get isQuoteRenote {
    if (renote == null) return false;
    final hasText = (text != null && text!.isNotEmpty) ||
        (cw != null && cw!.isNotEmpty);
    return hasText || files.isNotEmpty;
  }

  /// True for a plain boost with no commentary.
  bool get isPureRenote => renote != null && !isQuoteRenote;

  /// Federation-aware identity for cross-account dedup.
  ///
  /// Misskey assigns its own local `id` to every note, so federated
  /// copies of the same note have different `id`s on different
  /// receiving servers. The `uri` field is populated by Misskey ONLY
  /// for federated notes — when the note is local to `sourceHost`,
  /// `uri` is null and we have to synthesize the canonical AP URI
  /// ourselves (the home server's `id` IS the path component the
  /// federated copies' `uri` would reference).
  ///
  /// For *truly* local notes (author is also local to sourceHost),
  /// the canonical id is `https://<sourceHost>/notes/<id>`. For
  /// federated notes, the server-supplied `uri` is canonical and
  /// always wins.
  String get originId => uri ?? 'https://$sourceHost/notes/$id';
}
