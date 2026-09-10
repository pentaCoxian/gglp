import 'package:flutter/material.dart';

/// Single source of truth for the size of every inline non-text element
/// that lands inside a note's `RichText`/`Text.rich`.
///
/// Both the renderer and the height calculator must agree on these
/// numbers — otherwise the cached note height drifts from the actually-
/// rendered height and the timeline jitters during virtualization.
class InlinePlaceholderMetrics {
  const InlinePlaceholderMetrics._();

  /// Height of a custom-emoji `WidgetSpan` relative to the surrounding
  /// font. The renderer wraps emoji in `SizedBox(height: fontSize * factor)`,
  /// so any change here must be matched in [MfmRenderer._toSpan].
  static const double emojiHeightFactor = 1.4;

  /// Width-to-height ratio assumed for emoji while the actual image is
  /// loading. Most Misskey emoji are square; using 1.0 keeps the line
  /// width prediction stable enough for the height cache.
  static const double emojiAspectRatio = 1.0;

  /// Vertical padding above and below the body MFM block in a note card.
  static const double bodyVerticalPadding = 8.0;

  /// Vertical padding between the cw text and the body when the cw is
  /// shown.
  static const double cwSeparatorHeight = 8.0;

  /// Single horizontal divider drawn between cw and body.
  static const double cwDividerHeight = 1.0;

  /// Height of the avatar+name+timestamp header row at the top of every
  /// note card. The header is fixed-height because the avatar locks it.
  static const double headerHeight = 44.0;

  /// Height of the reaction-bar wrap row when present. We assume one
  /// row of chips; multi-row wrapping is rare and the cost of the extra
  /// row hitting the cache as a "wrong" estimate is one frame of jitter,
  /// which is acceptable.
  static const double reactionRowHeight = 36.0;

  /// Height of the quote-renote box (border + padding + nested header).
  /// Calibrated empirically against `_QuoteBox` + `_NoteBody(isQuoteEmbed: true)`.
  static const double quoteBoxBaseHeight = 60.0;

  /// Approximate height of the media grid relative to its width.
  ///
  /// Mirrors `NoteMediaGrid._gridAspect`: 1 file ≈ aspect-clamped,
  /// 2 files = 16:9, 3+ files = 4:3. We can't see the file objects
  /// here without re-importing the model, so callers pass the count
  /// and aspect explicitly.
  static double mediaGridHeight({
    required double width,
    required int fileCount,
    double? singleFileAspectRatio,
  }) {
    if (fileCount <= 0) return 0;
    final aspect = switch (fileCount) {
      1 => (singleFileAspectRatio ?? 1.0).clamp(0.75, 16 / 9),
      2 => 16 / 9,
      _ => 4 / 3,
    };
    return width / aspect;
  }

  /// Vertical gap separating the body from the reactions row (or media
  /// from reactions, etc.). Used by both the renderer and the
  /// calculator to add up section heights.
  static const double sectionGap = 8.0;

  /// Outer card padding (Card has `EdgeInsets.all(12)` body + Card's own
  /// `margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6)`).
  static const EdgeInsets cardPadding = EdgeInsets.all(12);
  static const EdgeInsets cardMargin =
      EdgeInsets.symmetric(horizontal: 12, vertical: 6);
}
