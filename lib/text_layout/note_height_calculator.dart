import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../mfm/ast.dart';
import '../mfm/parser.dart';
import '../misskey/models/note.dart';
import '../misskey/models/note_file.dart';
import 'inline_placeholder_metrics.dart';

/// Pure-arithmetic + TextPainter measurement of a `Note` rendered by
/// `NoteCard` at a given available width.
///
/// This exists so the timeline can hand the cache (and `SliverList`)
/// a stable `itemExtent` estimate **before** the note is laid out.
/// Without it, scroll position thrashes during streaming bursts and
/// after refresh / kind switch.
///
/// Accuracy contract: this function and `MfmRenderer` must agree on
/// the placeholder sizes from [InlinePlaceholderMetrics]. Effects are
/// required (per ) to preserve `RenderBox.size`, so we treat them
/// as identity for measurement.
class NoteHeightCalculator {
  final TextStyle bodyStyle;
  final TextStyle smallStyle;
  final double textScaleFactor;

  NoteHeightCalculator({
    required this.bodyStyle,
    required this.smallStyle,
    this.textScaleFactor = 1.0,
  });

  /// Convenience constructor that pulls the default body/small styles
  /// from [theme].
  factory NoteHeightCalculator.fromTheme(
    ThemeData theme, {
    double textScaleFactor = 1.0,
  }) {
    return NoteHeightCalculator(
      bodyStyle: theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14),
      smallStyle: theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12),
      textScaleFactor: textScaleFactor,
    );
  }

  /// Measure the full note card height for a given outer width
  /// (the width the timeline allocates to the card, before card margin
  /// is removed).
  double measure(Note note, {required double width}) {
    if (note.isPureRenote && note.renote != null) {
      return _measurePureRenote(note, width: width);
    }
    return _measureBody(note, width: width);
  }

  double _measurePureRenote(Note outer, {required double width}) {
    final inner = outer.renote!;
    // Card margin is unchanged; the inner body sits inside the same
    // padding plus a small "X renoted" header line.
    final headerHeight = (smallStyle.fontSize ?? 12) *
            (smallStyle.height ?? 1.2) *
            textScaleFactor +
        6;
    final contentWidth = _contentWidth(width);
    final innerHeight = _measureNoteContent(inner, contentWidth: contentWidth);
    final padding = InlinePlaceholderMetrics.cardPadding;
    final margin = InlinePlaceholderMetrics.cardMargin;
    return margin.vertical +
        padding.vertical +
        headerHeight +
        innerHeight;
  }

  double _measureBody(Note note, {required double width}) {
    final contentWidth = _contentWidth(width);
    final inner = _measureNoteContent(note, contentWidth: contentWidth);
    final padding = InlinePlaceholderMetrics.cardPadding;
    final margin = InlinePlaceholderMetrics.cardMargin;
    return margin.vertical + padding.vertical + inner;
  }

  /// Width available to the card *content* — outer width minus card
  /// horizontal margin minus card padding.
  double _contentWidth(double outerWidth) {
    final margin = InlinePlaceholderMetrics.cardMargin;
    final padding = InlinePlaceholderMetrics.cardPadding;
    return (outerWidth - margin.horizontal - padding.horizontal)
        .clamp(0.0, double.infinity);
  }

  /// Measure a Note's interior (header + cw + body + media + quote +
  /// reactions). Width given is the content-width (after padding).
  double _measureNoteContent(Note note, {required double contentWidth}) {
    double total = InlinePlaceholderMetrics.headerHeight;

    final cw = note.cw;
    if (cw != null && cw.isNotEmpty) {
      total += InlinePlaceholderMetrics.cwSeparatorHeight;
      total += _measureMfmBlock(parseMfm(cw), width: contentWidth);
      total += 4 + InlinePlaceholderMetrics.cwDividerHeight;
    }

    final body = note.text;
    if (body != null && body.isNotEmpty) {
      total += InlinePlaceholderMetrics.bodyVerticalPadding;
      total += _measureMfmBlock(parseMfm(body), width: contentWidth);
    }

    if (note.files.isNotEmpty) {
      total += InlinePlaceholderMetrics.sectionGap;
      total += InlinePlaceholderMetrics.mediaGridHeight(
        width: contentWidth,
        fileCount: note.files.length,
        singleFileAspectRatio:
            note.files.length == 1 ? note.files.first.aspectRatio : null,
      );
    }

    if (note.isQuoteRenote && note.renote != null) {
      total += InlinePlaceholderMetrics.sectionGap;
      // Quote box: 1px border + 10px padding + nested header.
      const quotePadding = 10.0 * 2 + 2;
      final quoteContent = _measureNoteContent(
        note.renote!,
        contentWidth:
            (contentWidth - quotePadding).clamp(0.0, double.infinity),
      );
      total += quoteContent + quotePadding;
    }

    if (note.reactions.isNotEmpty) {
      total += InlinePlaceholderMetrics.sectionGap;
      total += InlinePlaceholderMetrics.reactionRowHeight;
    }

    return total;
  }

  /// Measure the height of an MFM AST treated as a vertical column.
  /// Block nodes (quote, code, center) are measured with their own
  /// padding; consecutive inline nodes are concatenated into a single
  /// `TextPainter` paragraph.
  double _measureMfmBlock(List<MfmNode> nodes, {required double width}) {
    if (nodes.isEmpty) return 0;
    double total = 0;
    final inlineBuf = <MfmNode>[];

    void flushInline() {
      if (inlineBuf.isEmpty) return;
      total += _measureInlineRun(List.of(inlineBuf), width: width);
      inlineBuf.clear();
    }

    for (final n in nodes) {
      if (_isBlock(n)) {
        flushInline();
        total += _measureBlockNode(n, width: width);
      } else {
        inlineBuf.add(n);
      }
    }
    flushInline();
    return total;
  }

  bool _isBlock(MfmNode n) =>
      n is MfmCenter || n is MfmQuote || n is MfmCodeBlock;

  double _measureBlockNode(MfmNode n, {required double width}) {
    switch (n) {
      case MfmCenter(:final children):
        return _measureMfmBlock(children, width: width);
      case MfmQuote(:final children):
        // Quote: 4px vertical margin + 6px padding top/bottom + 12/8 padding left/right.
        const verticalChrome = 4.0 * 2 + 6.0 * 2;
        const horizontalChrome = 12.0 + 8.0;
        final inner = _measureMfmBlock(
          children,
          width: (width - horizontalChrome).clamp(0.0, double.infinity),
        );
        return inner + verticalChrome;
      case MfmCodeBlock(:final code, :final language):
        // 6px vertical margin + 10px padding all + label line + monospace lines.
        const verticalChrome = 6.0 * 2 + 10.0 * 2;
        final labelHeight = (language != null && language.isNotEmpty)
            ? (smallStyle.fontSize ?? 12) *
                    (smallStyle.height ?? 1.2) *
                    textScaleFactor +
                4
            : 0.0;
        final lineCount = '\n'.allMatches(code).length + 1;
        final monoLineHeight =
            (bodyStyle.fontSize ?? 14) * 1.4 * textScaleFactor;
        return verticalChrome + labelHeight + lineCount * monoLineHeight;
      default:
        return 0;
    }
  }

  /// Measure an inline run (a list of inline-only MFM nodes) as a
  /// single `Text.rich` paragraph with the given width.
  double _measureInlineRun(List<MfmNode> nodes, {required double width}) {
    if (width <= 0) return 0;
    final span = _spanFor(nodes, base: bodyStyle);
    final placeholders = _collectPlaceholders(nodes, base: bodyStyle);

    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      locale: bodyStyle.locale,
      maxLines: null,
      textScaler: TextScaler.linear(textScaleFactor),
    );
    if (placeholders.isNotEmpty) {
      tp.setPlaceholderDimensions(placeholders);
    }
    tp.layout(maxWidth: width);
    final h = tp.height;
    tp.dispose();
    return h;
  }

  /// Build a measurement-only `TextSpan`. Identity-effects (Tier 3) are
  /// passed through; emoji become `WidgetSpan(SizedBox)` with the
  /// renderer's exact box size so `setPlaceholderDimensions` produces
  /// the same line-break decisions as the rendered widget.
  InlineSpan _spanFor(List<MfmNode> nodes, {required TextStyle base}) {
    final children = nodes.map((n) => _toMeasurementSpan(n, base)).toList();
    return TextSpan(style: base, children: children);
  }

  InlineSpan _toMeasurementSpan(MfmNode n, TextStyle base) {
    switch (n) {
      case MfmText(:final text):
        return TextSpan(text: text, style: base);
      case MfmBreak():
        return const TextSpan(text: '\n');
      case MfmBold(:final children):
        return TextSpan(
          style: base.copyWith(fontWeight: FontWeight.bold),
          children: children
              .map((c) =>
                  _toMeasurementSpan(c, base.copyWith(fontWeight: FontWeight.bold)))
              .toList(),
        );
      case MfmItalic(:final children):
        return TextSpan(
          style: base.copyWith(fontStyle: FontStyle.italic),
          children: children
              .map((c) => _toMeasurementSpan(
                  c, base.copyWith(fontStyle: FontStyle.italic)))
              .toList(),
        );
      case MfmStrike(:final children):
        return TextSpan(
          children: children.map((c) => _toMeasurementSpan(c, base)).toList(),
        );
      case MfmSmall(:final children):
        final s = base.copyWith(fontSize: (base.fontSize ?? 14) * 0.85);
        return TextSpan(
          style: s,
          children: children.map((c) => _toMeasurementSpan(c, s)).toList(),
        );
      case MfmInlineCode(:final code):
        return TextSpan(text: code, style: base);
      case MfmUrl(:final url):
        return TextSpan(text: url, style: base);
      case MfmLink(:final label):
        return TextSpan(
          children: label.map((c) => _toMeasurementSpan(c, base)).toList(),
        );
      case MfmMention(:final username, :final host):
        return TextSpan(
          text: host == null ? '@$username' : '@$username@$host',
          style: base,
        );
      case MfmHashtag(:final tag):
        return TextSpan(text: '#$tag', style: base);
      case MfmEmoji():
        // Replaced with a placeholder span; the actual size is given
        // via setPlaceholderDimensions so TextPainter measures it
        // identically to the rendered SizedBox.
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: const SizedBox.shrink(),
        );
      case MfmFn(:final name, :final children):
        // Tier 3 motion effects MUST preserve size (contract). For
        // measurement they're identity. Tier 2 sizing modifiers we DO
        // need to apply (x2/x3/x4 changes line height).
        switch (name) {
          case 'x2':
          case 'x3':
          case 'x4':
            final scale = name == 'x2'
                ? 2.0
                : name == 'x3'
                    ? 3.0
                    : 4.0;
            // Mirror the renderer's cap: nested x4 never exceeds 4x the
            // body size, so the estimate can't outgrow what's painted.
            final s = base.copyWith(
              fontSize: math.min(
                (base.fontSize ?? 14) * scale,
                (bodyStyle.fontSize ?? 14) * 4.0,
              ),
              height: 1.0,
            );
            return TextSpan(
              style: s,
              children:
                  children.map((c) => _toMeasurementSpan(c, s)).toList(),
            );
          default:
            return TextSpan(
              children:
                  children.map((c) => _toMeasurementSpan(c, base)).toList(),
            );
        }
      case MfmCenter() || MfmQuote() || MfmCodeBlock():
        return const TextSpan(text: '');
    }
  }

  /// Walk the AST collecting [PlaceholderDimensions] in the order
  /// `TextPainter` will encounter them. Must mirror the order produced
  /// by [_toMeasurementSpan] above.
  List<PlaceholderDimensions> _collectPlaceholders(
    List<MfmNode> nodes, {
    required TextStyle base,
  }) {
    final out = <PlaceholderDimensions>[];
    void walk(List<MfmNode> ns, TextStyle b) {
      for (final n in ns) {
        switch (n) {
          case MfmEmoji():
            final h = (b.fontSize ?? 14) *
                InlinePlaceholderMetrics.emojiHeightFactor *
                textScaleFactor;
            out.add(PlaceholderDimensions(
              size: Size(
                  h * InlinePlaceholderMetrics.emojiAspectRatio, h),
              alignment: PlaceholderAlignment.middle,
            ));
          case MfmBold(:final children):
            walk(children, b.copyWith(fontWeight: FontWeight.bold));
          case MfmItalic(:final children):
            walk(children, b.copyWith(fontStyle: FontStyle.italic));
          case MfmStrike(:final children):
            walk(children, b);
          case MfmSmall(:final children):
            walk(children, b.copyWith(fontSize: (b.fontSize ?? 14) * 0.85));
          case MfmLink(:final label):
            walk(label, b);
          case MfmFn(:final name, :final children):
            final scale = switch (name) {
              'x2' => 2.0,
              'x3' => 3.0,
              'x4' => 4.0,
              _ => 1.0,
            };
            walk(
              children,
              scale == 1.0
                  ? b
                  : b.copyWith(
                      fontSize: math.min(
                        (b.fontSize ?? 14) * scale,
                        (bodyStyle.fontSize ?? 14) * 4.0,
                      ),
                      height: 1.0,
                    ),
            );
          case MfmText() ||
                MfmBreak() ||
                MfmInlineCode() ||
                MfmUrl() ||
                MfmMention() ||
                MfmHashtag() ||
                MfmCenter() ||
                MfmQuote() ||
                MfmCodeBlock():
            // No placeholders in these nodes themselves.
            break;
        }
      }
    }

    walk(nodes, base);
    return out;
  }
}

/// Public utility — unused by the calculator itself but exported for
/// tests so they can sanity-check media-grid math without re-importing
/// every module.
@visibleForTesting
double mediaGridHeight({
  required double width,
  required int fileCount,
  NoteFile? singleFile,
}) =>
    InlinePlaceholderMetrics.mediaGridHeight(
      width: width,
      fileCount: fileCount,
      singleFileAspectRatio: singleFile?.aspectRatio,
    );
