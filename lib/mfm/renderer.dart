import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'ast.dart';
import 'effects/effect_widgets.dart';
import 'nyaise.dart';

// Re-export EffectSettings so consumers don't need a second import.
export 'effects/effect_settings.dart' show EffectSettings;

/// Top-level callbacks the host app can plug in. Defaults to opening
/// URLs via the system handler / no-ops.
class MfmCallbacks {
  final void Function(String url)? onUrlTap;
  final void Function(MfmMention mention)? onMentionTap;
  final void Function(String tag)? onHashtagTap;

  /// Resolve a custom emoji `:name:` to a render widget (image, fallback
  /// text, etc.). The host attribution is provided by the caller of the
  /// renderer (typically the note's `sourceHost`); the resolver
  /// implementation owns the per-host emoji cache.
  final Widget Function(String name)? resolveEmoji;

  const MfmCallbacks({
    this.onUrlTap,
    this.onMentionTap,
    this.onHashtagTap,
    this.resolveEmoji,
  });
}

/// Public entry point. Renders an MFM AST as a column of widgets,
/// inlining contiguous inline runs into a single `Text.rich` for layout
/// efficiency.
///
/// **Ownership: callers MUST call [dispose].** Every [render] allocates
/// one [TapGestureRecognizer] per link / mention / hashtag span, and
/// those are only released by [dispose]. The intended pattern is one
/// renderer per build of the owning `State`: keep it in a field,
/// dispose the previous one when you rebuild, and dispose the last one
/// in `State.dispose()`. Don't [render] again after [dispose].
class MfmRenderer {
  final BuildContext context;
  final MfmCallbacks callbacks;

  /// Every recognizer handed to a span, so [dispose] can release them.
  final List<GestureRecognizer> _recognizers = [];

  /// Body font size the `x2/x3/x4` cap is relative to (resolved lazily
  /// from the ambient [DefaultTextStyle] on first use).
  double? _rootFontSize;

  /// `$[x4 $[x4 …]]` must not compound without bound: the effective
  /// font size is capped at this multiple of the root body size.
  static const double _maxFontScale = 4.0;

  /// Whether tier-3 motion effects should animate. False on reduced-
  /// motion or when the user has disabled animated MFM.
  final bool animateEffects;

  /// When true, plain text (only) is run through [nyaise] — Misskey's
  /// `na -> nya` transform applied to notes from cat users
  /// (`user.isCat`). The AST is unchanged; the transform happens at
  /// render time so the same note rendered for a non-cat viewer is
  /// not affected.
  final bool nyaiseText;

  MfmRenderer({
    required this.context,
    this.callbacks = const MfmCallbacks(),
    required this.animateEffects,
    this.nyaiseText = false,
  });

  /// Release every gesture recognizer created by [render]. Safe to call
  /// more than once.
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer _tap(VoidCallback onTap) {
    final r = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(r);
    return r;
  }

  Widget render(List<MfmNode> nodes) {
    if (nodes.isEmpty) return const SizedBox.shrink();
    final children = <Widget>[];
    final inlineBuf = <MfmNode>[];

    void flushInline() {
      if (inlineBuf.isEmpty) return;
      children.add(_renderInlineRun(List.of(inlineBuf)));
      inlineBuf.clear();
    }

    for (final n in nodes) {
      if (_isBlock(n)) {
        flushInline();
        children.add(_renderBlock(n));
      } else {
        inlineBuf.add(n);
      }
    }
    flushInline();

    if (children.length == 1) return children.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  // ------- block / inline classification -------

  bool _isBlock(MfmNode n) =>
      n is MfmCenter || n is MfmQuote || n is MfmCodeBlock;

  Widget _renderBlock(MfmNode n) {
    switch (n) {
      case MfmCenter(:final children):
        return Align(
          alignment: Alignment.center,
          child: render(children),
        );
      case MfmQuote(:final children):
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.surfaceContainerHigh,
            border: Border(
              left: BorderSide(
                width: 3,
                color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.4,
                    ),
              ),
            ),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.85),
            ),
            child: render(children),
          ),
        );
      case MfmCodeBlock(:final code, :final language):
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (language != null && language.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    language,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              // Horizontal scroll instead of wrapping, so one long
              // unbroken token can't push the card wider than its
              // column; the text stays selectable inside the viewport.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontFamilyFallback: ['Menlo', 'Consolas', 'monospace'],
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        // Defensive: if a non-block falls through, render inline.
        return _renderInlineRun([n]);
    }
  }

  // ------- inline rendering -------

  Widget _renderInlineRun(List<MfmNode> nodes) {
    if (nodes.isEmpty) return const SizedBox.shrink();
    final spans = nodes.map(_toSpan).toList(growable: false);
    return Text.rich(TextSpan(children: spans));
  }

  InlineSpan _toSpan(MfmNode n, {TextStyle? style}) {
    final base = style ?? const TextStyle();
    switch (n) {
      case MfmText(:final text):
        return TextSpan(
          text: nyaiseText ? nyaise(text) : text,
          style: base,
        );
      case MfmBreak():
        return const TextSpan(text: '\n');
      case MfmBold(:final children):
        return TextSpan(
          children: children
              .map((c) => _toSpan(c,
                  style: base.copyWith(fontWeight: FontWeight.bold)))
              .toList(),
        );
      case MfmItalic(:final children):
        return TextSpan(
          children: children
              .map((c) => _toSpan(c,
                  style: base.copyWith(fontStyle: FontStyle.italic)))
              .toList(),
        );
      case MfmStrike(:final children):
        return TextSpan(
          children: children
              .map((c) => _toSpan(c,
                  style: base.copyWith(decoration: TextDecoration.lineThrough)))
              .toList(),
        );
      case MfmSmall(:final children):
        return TextSpan(
          children: children
              .map((c) => _toSpan(c,
                  style: base.copyWith(
                    fontSize: (base.fontSize ?? 14) * 0.85,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )))
              .toList(),
        );
      case MfmInlineCode(:final code):
        return TextSpan(
          text: code,
          style: base.copyWith(
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Menlo', 'Consolas', 'monospace'],
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHigh,
          ),
        );
      case MfmUrl(:final url):
        return _linkSpan(url, url, base);
      case MfmLink(:final url, :final label):
        return TextSpan(
          children: label
              .map((c) => _toSpan(c,
                  style: base.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  )))
              .toList(),
          recognizer: _tap(() => callbacks.onUrlTap?.call(url)),
        );
      case MfmMention(:final username, :final host):
        final text = host == null ? '@$username' : '@$username@$host';
        return TextSpan(
          text: text,
          style: base.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
          recognizer: _tap(() => callbacks.onMentionTap
              ?.call(MfmMention(username: username, host: host))),
        );
      case MfmHashtag(:final tag):
        return TextSpan(
          text: '#$tag',
          style: base.copyWith(
            color: Theme.of(context).colorScheme.tertiary,
          ),
          recognizer: _tap(() => callbacks.onHashtagTap?.call(tag)),
        );
      case MfmEmoji(:final name):
        final widget = callbacks.resolveEmoji?.call(name) ??
            Text(':$name:', style: base);
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(
            height: (base.fontSize ?? 14) * 1.4,
            child: FittedBox(child: widget),
          ),
        );
      case MfmFn(:final name, :final args, :final children):
        return _fnSpan(name: name, args: args, children: children, base: base);
      case MfmCenter() || MfmQuote() || MfmCodeBlock():
        // Block nodes never reach here in well-formed input. Render the
        // best inline approximation for safety.
        if (n is MfmCenter) return _toSpan(MfmText(_flatten(n.children)));
        if (n is MfmQuote) return _toSpan(MfmText(_flatten(n.children)));
        if (n is MfmCodeBlock) return TextSpan(text: n.code, style: base);
        return TextSpan(text: '', style: base);
    }
  }

  InlineSpan _linkSpan(String visible, String url, TextStyle base) {
    return TextSpan(
      text: visible,
      style: base.copyWith(
        color: Theme.of(context).colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
      recognizer: _tap(() => callbacks.onUrlTap?.call(url)),
    );
  }

  /// `$[fn ...]` dispatch. Tier 2 styling (x2, fg, bg, font, ruby) +
  /// Tier 3 motion effects (shake, spin, jump, jelly, tada, blur, flip,
  /// rotate, bounce). Unknown names render children unchanged.
  InlineSpan _fnSpan({
    required String name,
    required Map<String, String> args,
    required List<MfmNode> children,
    required TextStyle base,
  }) {
    // Tier 2: text-style modifiers that stay inline.
    switch (name) {
      case 'x2':
      case 'x3':
      case 'x4':
        final scale = name == 'x2'
            ? 2.0
            : name == 'x3'
                ? 3.0
                : 4.0;
        // Nested `$[x4 $[x4 …]]` would otherwise compound to 16x; cap
        // the effective size at 4x the root body size (what a single
        // x4 on plain text produces — the largest Misskey web renders).
        final root = _rootFontSize ??=
            DefaultTextStyle.of(context).style.fontSize ?? 14;
        final fontSize =
            math.min((base.fontSize ?? root) * scale, root * _maxFontScale);
        return TextSpan(
          children: children
              .map((c) => _toSpan(c,
                  style: base.copyWith(
                    fontSize: fontSize,
                    height: 1.0,
                  )))
              .toList(),
        );
      case 'fg':
        final color = _parseHexColor(args['color']);
        if (color == null) {
          return TextSpan(children: children.map((c) => _toSpan(c, style: base)).toList());
        }
        return TextSpan(
          children: children
              .map((c) => _toSpan(c, style: base.copyWith(color: color)))
              .toList(),
        );
      case 'bg':
        final color = _parseHexColor(args['color']);
        if (color == null) {
          return TextSpan(children: children.map((c) => _toSpan(c, style: base)).toList());
        }
        return TextSpan(
          children: children
              .map((c) => _toSpan(c,
                  style: base.copyWith(backgroundColor: color)))
              .toList(),
        );
      case 'font':
        final fam = _parseFontFamily(args);
        return TextSpan(
          children: children
              .map((c) => _toSpan(c, style: base.copyWith(fontFamily: fam)))
              .toList(),
        );
      case 'center':
        // <center> via $[ syntax — block-ish but used inline by some;
        // approximate inline.
        return TextSpan(
          children:
              children.map((c) => _toSpan(c, style: base)).toList(),
        );
    }

    // Tier 3: motion effects. Each wraps the children in an effect
    // widget that, when animated, MUST not change the rendered Size
    // (handled by ClippedEffectBox inside the effect widgets).
    //
    // We delegate to `render` (not `_renderInlineRun`) so that when an
    // effect's children include ANOTHER effect, the inner effect is
    // built as its own Widget rather than becoming a WidgetSpan inside
    // a Text.rich that is itself a WidgetSpan inside the outer effect's
    // Text.rich. The double-WidgetSpan-in-Text.rich nesting causes
    // layout/baseline collapses in Flutter.
    final effectBuilder = effectBuilderFor(name);
    if (effectBuilder != null) {
      final inner = render(children);
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        baseline: TextBaseline.alphabetic,
        child: effectBuilder(
          context: context,
          args: args,
          animate: animateEffects,
          child: inner,
        ),
      );
    }

    // Unknown function: render children unchanged.
    return TextSpan(
      children: children.map((c) => _toSpan(c, style: base)).toList(),
    );
  }

  static Color? _parseHexColor(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final hex = raw.replaceAll('#', '');
    final padded = switch (hex.length) {
      6 => 'ff$hex',
      8 => hex,
      _ => null,
    };
    if (padded == null) return null;
    final parsed = int.tryParse(padded, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }

  static String? _parseFontFamily(Map<String, String> args) {
    if (args.containsKey('serif')) return 'serif';
    if (args.containsKey('monospace')) return 'monospace';
    if (args.containsKey('sansSerif')) return 'sans-serif';
    return null;
  }

  static String _flatten(List<MfmNode> nodes) {
    final buf = StringBuffer();
    for (final n in nodes) {
      switch (n) {
        case MfmText(:final text):
          buf.write(text);
        case MfmBreak():
          buf.write('\n');
        case MfmBold(:final children):
        case MfmItalic(:final children):
        case MfmStrike(:final children):
        case MfmSmall(:final children):
        case MfmCenter(:final children):
        case MfmQuote(:final children):
        case MfmFn(:final children):
          buf.write(_flatten(children));
        case MfmInlineCode(:final code):
        case MfmCodeBlock(:final code):
          buf.write(code);
        case MfmUrl(:final url):
          buf.write(url);
        case MfmLink(:final label):
          buf.write(_flatten(label));
        case MfmMention(:final username, :final host):
          buf.write('@$username${host == null ? '' : '@$host'}');
        case MfmHashtag(:final tag):
          buf.write('#$tag');
        case MfmEmoji(:final name):
          buf.write(':$name:');
      }
    }
    return buf.toString();
  }
}
