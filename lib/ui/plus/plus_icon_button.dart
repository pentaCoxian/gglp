import 'package:flutter/material.dart';

import 'plus_theme.dart';
import 'plus_tokens.dart';

/// Icon action with a 48×48 target and a 24px glyph.
///
/// On light surfaces: secondary-gray icon, blue when [selected]. With
/// [onBrand] (controls living on the red app bar, ): white icon
/// with white press/hover overlays and a white focus ring.
class PlusIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;
  final double size;
  final bool selected;
  final bool onBrand;
  final Color? color;
  final Color? selectedColor;

  const PlusIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.onLongPress,
    this.tooltip,
    this.size = PlusDims.icon,
    this.selected = false,
    this.onBrand = false,
    this.color,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final enabled = onTap != null;

    final Color fg;
    if (!enabled) {
      fg =
          onBrand
              ? plus.textOnBrand.withValues(alpha: 0.38)
              : plus.textTertiary;
    } else if (selected) {
      fg = selectedColor ?? (onBrand ? plus.textOnBrand : plus.selected);
    } else {
      fg = color ?? (onBrand ? plus.textOnBrand : plus.textSecondary);
    }

    Widget button = Material(
      type: MaterialType.transparency,
      child: InkResponse(
        onTap: onTap,
        onLongPress: onLongPress,
        radius: PlusDims.minTarget / 2,
        highlightColor:
            onBrand
                ? Colors.white.withValues(alpha: 0.18)
                : plus.textPrimary.withValues(alpha: 0.06),
        splashColor:
            onBrand
                ? Colors.white.withValues(alpha: 0.10)
                : plus.textPrimary.withValues(alpha: 0.08),
        hoverColor:
            onBrand ? Colors.white.withValues(alpha: 0.10) : plus.surfaceHover,
        focusColor:
            onBrand
                ? Colors.white.withValues(alpha: 0.12)
                : plus.link.withValues(alpha: 0.12),
        child: Container(
          width: PlusDims.minTarget,
          height: PlusDims.minTarget,
          alignment: Alignment.center,
          // Persistent overlay marks the active/selected panel.
          decoration:
              selected && onBrand
                  ? BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(PlusRadii.card),
                  )
                  : null,
          child: Icon(icon, size: size, color: fg),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
