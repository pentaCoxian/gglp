import 'ast.dart';

/// Hard safety caps .
class MfmLimits {
  /// Max characters of input. Notes longer than this fall back to
  /// sanitized text rendering.
  static const int maxInputLength = 10000;

  /// Max nesting depth of inline/block constructs.
  static const int maxNestingDepth = 32;

  /// Max total node count produced by the parser. Above this, fall
  /// back to sanitized text.
  static const int maxNodeCount = 5000;
}

class MfmParseException implements Exception {
  final String message;
  const MfmParseException(this.message);
  @override
  String toString() => 'MfmParseException: $message';
}

/// Parse MFM source into an AST. Returns a single-node fallback list
/// `[MfmText(input)]` if parsing fails or limits are exceeded.
///
/// Top-level dispatch: blocks first (`<center>`, `> ...`, code fences),
/// then inline. Inline parsers can recurse; depth and node count are
/// tracked centrally.
List<MfmNode> parseMfm(String input) {
  // Normalize line endings up front: many Misskey/AP payloads (and
  // anything paste-from-Windows) include `\r\n` or bare `\r`. Block
  // detection keys on `\n` only, so non-LF newlines would silently
  // hide quotes and code fences. Misskey itself does the same
  // normalization in mfm.js.
  final src = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  if (src.length > MfmLimits.maxInputLength) {
    return [MfmText(src.substring(0, MfmLimits.maxInputLength))];
  }
  try {
    final p = _Parser(src);
    final nodes = p.parseBlock();
    if (p._nodeCount > MfmLimits.maxNodeCount) {
      return [MfmText(input)];
    }
    return nodes;
  } catch (_) {
    return [MfmText(input)];
  }
}

class _Parser {
  final String src;
  int pos = 0;
  int _depth = 0;
  int _nodeCount = 0;

  _Parser(this.src);

  bool get atEnd => pos >= src.length;

  /// Parse a block context — used at top level and inside `<center>`,
  /// `> ` lines, etc.
  List<MfmNode> parseBlock() {
    final out = <MfmNode>[];
    while (!atEnd) {
      // Block-level constructs (only when at start of a line).
      if (_atLineStart()) {
        final fence = _tryParseCodeFence();
        if (fence != null) {
          _record();
          out.add(fence);
          continue;
        }
        final quote = _tryParseQuote();
        if (quote != null) {
          _record();
          out.add(quote);
          continue;
        }
      }
      final center = _tryParseTag('center', _wrapCenter);
      if (center != null) {
        _record();
        out.add(center);
        continue;
      }
      // Inline. Stop whenever we cross a newline AND the next line
      // starts with a block construct, so the outer block loop gets
      // another chance to dispatch quotes / code fences / center.
      final inline = _parseInlineRun(stop: _topLevelStop);
      out.addAll(inline);
    }
    return _coalesceText(out);
  }

  /// Inline run: collect inline nodes until `stop` returns true.
  ///
  /// At the top level, the run also yields back to the block loop
  /// whenever the next character begins a new line that starts with
  /// a block construct (`> `, ```, `<center>`). Without that, a
  /// blockquote that follows free text on the same parse pass would
  /// be eaten as inline text and never see _tryParseQuote.
  List<MfmNode> _parseInlineRun({required bool Function() stop}) {
    final out = <MfmNode>[];
    final buf = StringBuffer();
    void flushBuf() {
      if (buf.isEmpty) return;
      _record();
      out.add(MfmText(buf.toString()));
      buf.clear();
    }

    while (!atEnd && !stop()) {
      // Yield to the block loop when we're at the start of a line and
      // a block construct begins here.
      if (_atLineStart() && _atBlockStart()) {
        break;
      }
      final node = _tryInlineConstruct();
      if (node != null) {
        flushBuf();
        _record();
        out.add(node);
        continue;
      }
      // No inline construct matched; consume one char.
      buf.write(src[pos]);
      pos++;
    }
    flushBuf();
    return out;
  }

  bool _atBlockStart() {
    if (atEnd) return false;
    if (_peek('```')) return true;
    if (src[pos] == '>') return true;
    if (_peek('<center>')) return true;
    return false;
  }

  /// Try to match an inline construct at the current position.
  /// Returns null if nothing matches; consumes input on success.
  MfmNode? _tryInlineConstruct() {
    if (atEnd) return null;
    final c = src[pos];
    final c2 = pos + 1 < src.length ? src[pos + 1] : '';

    // Newline
    if (c == '\n') {
      pos++;
      return const MfmBreak();
    }

    // Inline code
    if (c == '`' && (c2 != '`' || _peekNot('``'))) {
      final code = _readBalanced('`', '`');
      if (code != null) return MfmInlineCode(code);
    }

    // **bold**
    if (c == '*' && c2 == '*') {
      final inner = _readDelimited('**', '**');
      if (inner != null) return MfmBold(_subParse(inner));
    }
    // ~~strike~~
    if (c == '~' && c2 == '~') {
      final inner = _readDelimited('~~', '~~');
      if (inner != null) return MfmStrike(_subParse(inner));
    }
    // *italic* (single-star). Avoid eating '**'.
    if (c == '*' && c2 != '*') {
      final inner = _readDelimited('*', '*');
      if (inner != null) return MfmItalic(_subParse(inner));
    }

    // <small>
    if (c == '<') {
      final tag = _tryParseTag('small', _wrapSmall);
      if (tag != null) return tag;
    }

    // $[fn ...]
    if (c == r'$' && c2 == '[') {
      final fn = _tryParseFn();
      if (fn != null) return fn;
    }

    // [label](url)
    if (c == '[') {
      final link = _tryParseLink();
      if (link != null) return link;
    }

    // :emoji:
    if (c == ':') {
      final emoji = _tryParseEmoji();
      if (emoji != null) return emoji;
    }

    // @mention
    if (c == '@') {
      final mention = _tryParseMention();
      if (mention != null) return mention;
    }

    // #hashtag
    if (c == '#') {
      final tag = _tryParseHashtag();
      if (tag != null) return tag;
    }

    // bare URL
    if (c == 'h' && _peek('http')) {
      final url = _tryParseUrl();
      if (url != null) return url;
    }

    return null;
  }

  // ------- block helpers -------

  bool _atLineStart() => pos == 0 || src[pos - 1] == '\n';

  bool _topLevelStop() => false;

  MfmNode? _tryParseCodeFence() {
    if (!_peek('```')) return null;
    final start = pos;
    pos += 3;
    // Optional language up to newline.
    final langStart = pos;
    while (!atEnd && src[pos] != '\n') {
      pos++;
    }
    final lang = src.substring(langStart, pos).trim();
    if (atEnd) {
      pos = start;
      return null;
    }
    pos++; // consume '\n'
    final codeStart = pos;
    final closeIdx = src.indexOf('\n```', pos);
    if (closeIdx < 0) {
      pos = start;
      return null;
    }
    final code = src.substring(codeStart, closeIdx);
    pos = closeIdx + 4;
    if (!atEnd && src[pos] == '\n') pos++;
    return MfmCodeBlock(language: lang.isEmpty ? null : lang, code: code);
  }

  MfmNode? _tryParseQuote() {
    if (src[pos] != '>') return null;
    final lines = <String>[];
    while (!atEnd && (pos == 0 || src[pos - 1] == '\n') && src[pos] == '>') {
      // consume `>` and optional space
      pos++;
      if (!atEnd && src[pos] == ' ') pos++;
      final lineStart = pos;
      while (!atEnd && src[pos] != '\n') {
        pos++;
      }
      lines.add(src.substring(lineStart, pos));
      if (!atEnd && src[pos] == '\n') pos++;
    }
    if (lines.isEmpty) return null;
    final inner = lines.join('\n');
    return MfmQuote(_subParse(inner));
  }

  // ------- inline helpers -------

  bool _peek(String s) {
    if (pos + s.length > src.length) return false;
    return src.startsWith(s, pos);
  }

  bool _peekNot(String s) => !_peek(s);

  /// Try to parse `<tag>...</tag>`. Builder receives parsed children.
  MfmNode? _tryParseTag(
    String tag,
    MfmNode Function(List<MfmNode>) builder,
  ) {
    final open = '<$tag>';
    final close = '</$tag>';
    if (!_peek(open)) return null;
    final start = pos;
    pos += open.length;
    final innerStart = pos;
    final closeIdx = src.indexOf(close, pos);
    if (closeIdx < 0) {
      pos = start;
      return null;
    }
    final inner = src.substring(innerStart, closeIdx);
    pos = closeIdx + close.length;
    return builder(_subParse(inner));
  }

  MfmNode _wrapCenter(List<MfmNode> children) => MfmCenter(children);
  MfmNode _wrapSmall(List<MfmNode> children) => MfmSmall(children);

  /// Read inline-code `code` between two markers. The opening backtick
  /// is at `pos`. Markers must not be inside other inline code.
  String? _readBalanced(String open, String close) {
    final start = pos;
    if (!_peek(open)) return null;
    pos += open.length;
    final innerStart = pos;
    final closeIdx = src.indexOf(close, pos);
    if (closeIdx < 0) {
      pos = start;
      return null;
    }
    final code = src.substring(innerStart, closeIdx);
    if (code.contains('\n')) {
      pos = start;
      return null;
    }
    pos = closeIdx + close.length;
    return code;
  }

  /// Read delimited inline content `<open>...content...<close>`. Used
  /// for **bold**, *italic*, ~~strike~~. Returns the inner string for
  /// recursive parsing.
  String? _readDelimited(String open, String close) {
    final start = pos;
    if (!_peek(open)) return null;
    pos += open.length;
    final innerStart = pos;
    final closeIdx = src.indexOf(close, pos);
    if (closeIdx < 0) {
      pos = start;
      return null;
    }
    final inner = src.substring(innerStart, closeIdx);
    // Forbid newline-only inner (avoid eating big chunks on stray
    // delimiters).
    if (inner.contains('\n\n')) {
      pos = start;
      return null;
    }
    pos = closeIdx + close.length;
    return inner;
  }

  static final _fnName = RegExp(r'[a-zA-Z][a-zA-Z0-9_]*');
  static final _fnValue = RegExp(r'[^,\s\]]+');

  /// Matches an fn header `$[name(.arg(=value)?(,arg(=value)?)*)? ` at
  /// [at] — mfm.js grammar: the first argument follows a `.`, further
  /// arguments are comma-separated (`$[scale.x=8,y=0.5 …]`). Returns
  /// the parsed name/args and the index just past the mandatory space,
  /// or null when the text isn't an fn header.
  ({String name, Map<String, String> args, int end})? _matchFnHeader(
    int at,
  ) {
    if (at + 1 >= src.length || src[at] != r'$' || src[at + 1] != '[') {
      return null;
    }
    var p = at + 2;
    final nameMatch = _fnName.matchAsPrefix(src, p);
    if (nameMatch == null) return null;
    final name = nameMatch.group(0)!;
    p += name.length;
    final args = <String, String>{};
    if (p < src.length && src[p] == '.') {
      p++;
      while (true) {
        final argMatch = _fnName.matchAsPrefix(src, p);
        if (argMatch == null) break;
        final argName = argMatch.group(0)!;
        p += argName.length;
        var value = 'true';
        if (p < src.length && src[p] == '=') {
          p++;
          final valMatch = _fnValue.matchAsPrefix(src, p);
          if (valMatch != null) {
            value = valMatch.group(0)!;
            p += value.length;
          }
        }
        args[argName] = value;
        if (p < src.length && src[p] == ',') {
          p++;
          continue;
        }
        break;
      }
    }
    // Expect a single space before content.
    if (p >= src.length || src[p] != ' ') return null;
    return (name: name, args: args, end: p + 1);
  }

  MfmNode? _tryParseFn() {
    final start = pos;
    final header = _matchFnHeader(start);
    if (header == null) return null;

    // Find the outer's closing `]` the way mfm.js's recursive grammar
    // does: an inner `$[…]` that would itself parse as an fn (valid
    // header + non-empty content) consumes its own `]`, so
    // `$[x2 $[shake hi]]` nests. An inner that would *fail* as an fn
    // (`$[bounce]` — no space; `$[bounce ]` — empty content) is plain
    // text, so the next `]` closes the outer and the stray one stays
    // literal. That keeps mfm.js's exact output for both shapes.
    var p = header.end;
    var depth = 0;
    while (p < src.length) {
      final c = src[p];
      if (c == ']') {
        if (depth == 0) break;
        depth--;
        p++;
        continue;
      }
      if (c == r'$' && p + 1 < src.length && src[p + 1] == '[') {
        final inner = _matchFnHeader(p);
        if (inner != null &&
            inner.end < src.length &&
            src[inner.end] != ']') {
          depth++;
          p = inner.end;
          continue;
        }
      }
      p++;
    }
    if (p >= src.length) return null; // unclosed
    final inner = src.substring(header.end, p);
    // Match mfm.js: empty content is NOT an fn.
    if (inner.isEmpty) return null;
    pos = p + 1; // consume ']'
    return MfmFn(
      name: header.name,
      args: header.args,
      children: _subParse(inner),
    );
  }

  MfmNode? _tryParseLink() {
    final start = pos;
    if (src[pos] != '[') return null;
    pos++;
    final labelStart = pos;
    final labelEnd = src.indexOf(']', pos);
    if (labelEnd < 0 || labelEnd >= src.length - 1 || src[labelEnd + 1] != '(') {
      pos = start;
      return null;
    }
    final label = src.substring(labelStart, labelEnd);
    pos = labelEnd + 2; // skip ']('
    final urlStart = pos;
    final urlEnd = src.indexOf(')', pos);
    if (urlEnd < 0) {
      pos = start;
      return null;
    }
    final url = src.substring(urlStart, urlEnd);
    pos = urlEnd + 1;
    return MfmLink(url: url, label: _subParse(label));
  }

  MfmNode? _tryParseEmoji() {
    if (src[pos] != ':') return null;
    final start = pos;
    pos++;
    final nameMatch =
        RegExp(r'[A-Za-z0-9_+\-]+').matchAsPrefix(src, pos);
    if (nameMatch == null) {
      pos = start;
      return null;
    }
    final name = nameMatch.group(0)!;
    pos += name.length;
    if (atEnd || src[pos] != ':') {
      pos = start;
      return null;
    }
    pos++;
    return MfmEmoji(name);
  }

  MfmNode? _tryParseMention() {
    if (src[pos] != '@') return null;
    final start = pos;
    pos++;
    final userMatch =
        RegExp(r'[A-Za-z0-9_]+').matchAsPrefix(src, pos);
    if (userMatch == null) {
      pos = start;
      return null;
    }
    final username = userMatch.group(0)!;
    pos += username.length;
    String? host;
    if (!atEnd && src[pos] == '@') {
      pos++;
      final hostMatch =
          RegExp(r'[A-Za-z0-9_.\-]+').matchAsPrefix(src, pos);
      if (hostMatch != null) {
        host = hostMatch.group(0)!;
        pos += host.length;
      }
    }
    return MfmMention(username: username, host: host);
  }

  MfmNode? _tryParseHashtag() {
    if (src[pos] != '#') return null;
    final start = pos;
    pos++;
    final tagMatch =
        RegExp(r"[\w぀-ヿ一-鿿]+").matchAsPrefix(src, pos);
    if (tagMatch == null) {
      pos = start;
      return null;
    }
    final tag = tagMatch.group(0)!;
    pos += tag.length;
    return MfmHashtag(tag);
  }

  MfmNode? _tryParseUrl() {
    final m = RegExp(r'https?://[^\s)\]]+').matchAsPrefix(src, pos);
    if (m == null) return null;
    final url = m.group(0)!;
    pos += url.length;
    return MfmUrl(url);
  }

  /// Recursively parse a substring, sharing the depth/node-count budget.
  List<MfmNode> _subParse(String inner) {
    if (_depth >= MfmLimits.maxNestingDepth) {
      return [MfmText(inner)];
    }
    _depth++;
    try {
      final sub = _Parser(inner).._depth = _depth;
      final out = sub.parseBlock();
      _nodeCount += sub._nodeCount;
      return out;
    } finally {
      _depth--;
    }
  }

  void _record() {
    _nodeCount++;
    if (_nodeCount > MfmLimits.maxNodeCount) {
      throw const MfmParseException('node count cap exceeded');
    }
  }

  /// Merge adjacent `MfmText` runs to keep the AST tidy for the
  /// renderer (avoids spawning extra TextSpans per character).
  List<MfmNode> _coalesceText(List<MfmNode> nodes) {
    final out = <MfmNode>[];
    final buf = StringBuffer();
    for (final n in nodes) {
      if (n is MfmText) {
        buf.write(n.text);
        continue;
      }
      if (buf.isNotEmpty) {
        out.add(MfmText(buf.toString()));
        buf.clear();
      }
      out.add(n);
    }
    if (buf.isNotEmpty) out.add(MfmText(buf.toString()));
    return out;
  }
}
