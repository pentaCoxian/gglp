import 'note.dart';
import 'reaction.dart';

/// Applies a Misskey `noteUpdated` patch to a [Note] in-place
/// (functionally — returns a new Note).
///
/// Only the patch types we currently render are handled; everything
/// else returns the input note unchanged. Adding more is one switch
/// arm here, no controller change required.
class ReactionPatch {
  /// `viewerUserId` is the active account's user id on the note's
  /// source host. When the patch is caused by *that* user, we mirror
  /// the change into `note.myReaction` so the chip's tap-to-toggle
  /// state flips immediately, rather than waiting for the next HTTP
  /// refresh.
  static Note apply(
    Note note,
    Map<String, dynamic> patch, {
    String? viewerUserId,
  }) {
    final type = patch['type'] as String?;
    final body = patch['body'] as Map<String, dynamic>?;
    switch (type) {
      case 'reacted':
        if (body == null) return note;
        final key = body['reaction']?.toString();
        final actor = body['userId']?.toString();
        final isViewer = viewerUserId != null && actor == viewerUserId;
        var next = _bumpReaction(note, key, 1);
        if (isViewer && key != null && key.isNotEmpty) {
          next = next.copyWith(myReaction: key);
        }
        return next;
      case 'unreacted':
        if (body == null) return note;
        final key = body['reaction']?.toString();
        final actor = body['userId']?.toString();
        final isViewer = viewerUserId != null && actor == viewerUserId;
        var next = _bumpReaction(note, key, -1);
        if (isViewer) {
          // copyWith on a freezed class can't set a nullable to null
          // without a sentinel; build a fresh object instead.
          next = Note(
            id: next.id,
            sourceHost: next.sourceHost,
            user: next.user,
            createdAt: next.createdAt,
            updatedAt: next.updatedAt,
            text: next.text,
            cw: next.cw,
            visibility: next.visibility,
            replyId: next.replyId,
            renoteId: next.renoteId,
            renote: next.renote,
            files: next.files,
            channel: next.channel,
            localOnly: next.localOnly,
            myReaction: null,
            reactions: next.reactions,
            repliesCount: next.repliesCount,
            renoteCount: next.renoteCount,
            uri: next.uri,
            rawExtras: next.rawExtras,
          );
        }
        return next;
      default:
        return note;
    }
  }

  static Note _bumpReaction(Note note, String? key, int delta) {
    if (key == null || key.isEmpty) return note;
    final reactions = [...note.reactions];
    final i = reactions.indexWhere((r) => r.key == key);
    if (i >= 0) {
      final next = reactions[i].count + delta;
      if (next <= 0) {
        reactions.removeAt(i);
      } else {
        reactions[i] = reactions[i].copyWith(count: next);
      }
    } else if (delta > 0) {
      reactions.add(Reaction(
        key: key,
        count: delta,
        isCustom: key.startsWith(':') && key.endsWith(':'),
      ));
    }
    return note.copyWith(reactions: reactions);
  }
}
