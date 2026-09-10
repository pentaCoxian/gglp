/// Curated unicode emoji set for the reaction picker.
///
/// Misskey accepts any unicode codepoint sequence as a reaction
/// (subject to per-instance rules), but a comprehensive picker would
/// need the full ~3700-entry Unicode emoji table. For MVP we ship the
/// most-used ~100 reactions; the remaining long tail is reachable via
/// the recents list once a user has used a less common one once
/// (typed via OS keyboard into the compose text-field reaction flow
/// later in ).
class UnicodeEmojiSet {
  const UnicodeEmojiSet._();

  /// Loose categories that drive the picker's section headers.
  static const Map<String, List<String>> categories = {
    'Smileys': [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃',
      '😉', '😊', '😇', '😍', '🥰', '😘', '😗', '😙', '😚', '😋',
      '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🫡',
      '😐', '😑', '😶', '🙄', '😏', '😣', '😥', '😮', '🤐', '😯',
      '😪', '😫', '🥱', '😴', '😌', '😛', '🤤', '😒', '😓', '😔',
    ],
    'Reactions': [
      '👍', '👎', '👏', '🙌', '👐', '🤲', '🙏', '✊', '👊', '🤛',
      '🤜', '🤞', '✌️', '🤟', '🤘', '👌', '🤌', '🤏', '👈', '👉',
      '👆', '👇', '☝️', '✋', '🤚', '🖐', '🖖', '👋', '🫶', '💪',
    ],
    'Hearts': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
      '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝',
    ],
    'Symbols': [
      '✨', '🔥', '⭐️', '🌟', '💫', '💯', '✅', '❌', '⚠️', '❗️',
      '❓', '💢', '💥', '💦', '💨', '🆗', '🆖', '🎉', '🎊', '🎂',
    ],
  };

  /// Flat list of all keys in declaration order (used for fallback
  /// search-all view).
  static List<String> get all =>
      categories.values.expand((e) => e).toList(growable: false);
}
