/// MFM (Misskey Flavored Markdown) abstract syntax tree.
///
/// All node types are sealed so the renderer's switch is exhaustive.
/// Inline vs. block is intentionally NOT modeled at the type level —
/// MFM mixes inline-style nodes inside block contexts everywhere, so
/// keeping a flat sealed hierarchy is simpler.
sealed class MfmNode {
  const MfmNode();
}

/// Plain text.
class MfmText extends MfmNode {
  final String text;
  const MfmText(this.text);
}

/// Hard line break.
class MfmBreak extends MfmNode {
  const MfmBreak();
}

/// Bold `**...**`.
class MfmBold extends MfmNode {
  final List<MfmNode> children;
  const MfmBold(this.children);
}

/// Italic `*...*`.
class MfmItalic extends MfmNode {
  final List<MfmNode> children;
  const MfmItalic(this.children);
}

/// Strikethrough `~~...~~`.
class MfmStrike extends MfmNode {
  final List<MfmNode> children;
  const MfmStrike(this.children);
}

/// Small text `<small>...</small>`.
class MfmSmall extends MfmNode {
  final List<MfmNode> children;
  const MfmSmall(this.children);
}

/// Block-level center `<center>...</center>`.
class MfmCenter extends MfmNode {
  final List<MfmNode> children;
  const MfmCenter(this.children);
}

/// Block quote (`> ...` lines).
class MfmQuote extends MfmNode {
  final List<MfmNode> children;
  const MfmQuote(this.children);
}

/// Inline `code`.
class MfmInlineCode extends MfmNode {
  final String code;
  const MfmInlineCode(this.code);
}

/// Block ```code```.
class MfmCodeBlock extends MfmNode {
  final String? language;
  final String code;
  const MfmCodeBlock({this.language, required this.code});
}

/// Bare URL.
class MfmUrl extends MfmNode {
  final String url;
  const MfmUrl(this.url);
}

/// `[label](url)` link.
class MfmLink extends MfmNode {
  final String url;
  final List<MfmNode> label;
  const MfmLink({required this.url, required this.label});
}

/// `@user@host` (host optional).
class MfmMention extends MfmNode {
  final String username;
  final String? host;
  const MfmMention({required this.username, this.host});
}

/// `#hashtag`.
class MfmHashtag extends MfmNode {
  final String tag;
  const MfmHashtag(this.tag);
}

/// `:emoji_name:` (per-host scoped — resolution happens at render time).
class MfmEmoji extends MfmNode {
  final String name;
  const MfmEmoji(this.name);
}

/// Tier 2/3 effect function: `$[name.arg1=v,arg2 content]`.
///
/// Examples:
///   - `$[x2 hello]`        → name=x2, args={}, children=[Text("hello")]
///   - `$[shake.speed=2s …]` → name=shake, args={speed:"2s"}
///   - `$[fg.color=ff0000 …]` → name=fg, args={color:"ff0000"}
///
/// The renderer dispatches on `name`; unknown names render as plain
/// children so a future Misskey adds a new fn doesn't crash us.
class MfmFn extends MfmNode {
  final String name;
  final Map<String, String> args;
  final List<MfmNode> children;
  const MfmFn({
    required this.name,
    this.args = const {},
    required this.children,
  });
}
