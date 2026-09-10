import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../plus/plus.dart';

/// Tap-to-reveal veil over sensitive content.
///
/// The content itself is blurred (an [ImageFiltered] on the child)
/// rather than covered by a frosted-glass rectangle, so what's hidden
/// still reads as a softened version of the note — shapes, colours,
/// line rhythm — with no hard glass edge. A translucent [scrim] settles
/// the blur toward the surface so the pill stays legible, and the pill
/// is the same compact label on every sensitive surface (note body,
/// media tile).
class SensitiveVeil extends StatelessWidget {
  final Widget child;
  final VoidCallback onReveal;

  /// Pill text, e.g. "Sensitive channel · Tap to reveal".
  final String label;

  /// Blur radius. Smaller keeps more structure visible.
  final double sigma;

  /// Colour laid over the blurred content. Defaults to the surface at
  /// 45% so text-heavy content fades into the card; media tiles pass
  /// a dark scrim so the pill reads on bright photos.
  final Color? scrim;

  /// True for fixed-size hosts (media tiles): the veil fills the box.
  /// False for content that sizes itself (note bodies), where the veil
  /// hugs the child but never collapses below [minHeight].
  final bool expand;
  final double minHeight;

  const SensitiveVeil({
    super.key,
    required this.child,
    required this.onReveal,
    required this.label,
    this.sigma = 12,
    this.scrim,
    this.expand = false,
    this.minHeight = 56,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    // Card white (not ColorScheme.surface, which maps to the canvas
    // grey) so the veil reads as the note fading out, not a grey box.
    final veil = scrim ?? plus.surface.withValues(alpha: 0.45);
    final blurred = ClipRect(
      // Clamp so edge pixels extend instead of feathering to
      // transparent; the clip stops the kernel's halo bleeding into
      // the surrounding card.
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.clamp,
        ),
        // Screen readers get the reveal button, not the hidden text.
        // Full width so a short note's veil spans the card like every
        // other content block instead of hugging the text's width.
        child: SizedBox(
          width: double.infinity,
          child: ExcludeSemantics(child: child),
        ),
      ),
    );
    Widget stack = Stack(
      fit: expand ? StackFit.expand : StackFit.loose,
      alignment: Alignment.topLeft,
      children: [
        blurred,
        Positioned.fill(child: ColoredBox(color: veil)),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: Semantics(
              button: true,
              label: '$label. Sensitive content hidden.',
              child: InkWell(
                onTap: onReveal,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    // Scale down rather than overflow when the host is
                    // shorter than the pill (a one-line note).
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _RevealPill(label: label),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    if (!expand) {
      stack = ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: stack,
      );
    }
    return stack;
  }
}

/// Dark translucent rectangle with a white "hidden" glyph and label.
class _RevealPill extends StatelessWidget {
  final String label;
  const _RevealPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(PlusRadii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_off, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
