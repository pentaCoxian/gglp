import '../models/emoji.dart';

/// Parses an MFM `:name:` token and a viewer host into the `(host, name)`
/// pair that the emoji repository keys on.
///
/// Misskey conventions:
///   - `:name:`        → local custom emoji on the viewer's server
///   - `:name@.:`      → local emoji marker (Misskey writes this for
///                       its own emoji to make the suffix explicit
///                       when notes are federated). Equivalent to the
///                       no-suffix form for resolution purposes.
///   - `:name@host:`   → custom emoji from a remote host
///
/// `viewerHost` is the receiving server's hostname (== Note.sourceHost).
class EmojiRef {
  final String name;
  final String host;

  const EmojiRef({required this.name, required this.host});

  /// Parse a token of the form `name`, `name@.`, or `name@host`. The
  /// surrounding `:` markers should already be stripped by the caller
  /// (the MFM parser does that — it emits `MfmEmoji.name = "name@host"`).
  factory EmojiRef.parse(String raw, {required String viewerHost}) {
    final at = raw.indexOf('@');
    if (at < 0) {
      return EmojiRef(name: raw, host: viewerHost);
    }
    final name = raw.substring(0, at);
    final suffix = raw.substring(at + 1);
    if (suffix.isEmpty || suffix == '.') {
      return EmojiRef(name: name, host: viewerHost);
    }
    return EmojiRef(name: name, host: suffix);
  }

  /// Render a [CustomEmoji] as the MFM token form Misskey accepts in
  /// note text and reaction keys:
  ///
  ///   - `:name:`         when the emoji's host matches [viewerHost]
  ///                      (i.e. local to the active server).
  ///   - `:name@host:`    when the emoji is federated.
  ///
  /// The qualified-local form `:name@<viewerHost>:` does NOT match
  /// Misskey's `isCustomEmojiRegexp` and would fall back to ❤️ on the
  /// server side, so we never emit it. This single helper is the
  /// source of truth for both the reaction picker (which posts to
  /// `notes/reactions/create`) and the compose-time autocomplete
  /// (which inserts into the note body).
  static String tokenFor(CustomEmoji emoji, String viewerHost) {
    return emoji.host == viewerHost
        ? ':${emoji.name}:'
        : ':${emoji.name}@${emoji.host}:';
  }
}
