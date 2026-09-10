import 'package:flutter/material.dart';

import 'plus_motion.dart';
import 'plus_theme.dart';
import 'plus_tokens.dart';

/// Rectangular 2px-radius chip: subtle-gray at rest; selected
/// state is brand-soft with a 1px brand border. Background/border
/// animate over 120ms.
class PlusChip extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final String? tooltip;
  final String? semanticLabel;
  final Color? foreground;

  const PlusChip({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: PlusSpacing.x3,
      vertical: 5,
    ),
    this.tooltip,
    this.semanticLabel,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final fg = foreground ?? (selected ? plus.brand : plus.textPrimary);

    Widget chip = AnimatedContainer(
      duration: PlusMotion.fast,
      curve: PlusMotion.easeStandard,
      constraints: const BoxConstraints(minHeight: PlusDims.reactionChip),
      decoration: BoxDecoration(
        color: selected ? plus.reactionActive : plus.surfaceSubtle,
        borderRadius: BorderRadius.circular(PlusRadii.chip),
        border: Border.all(color: selected ? plus.brand : Colors.transparent),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(PlusRadii.chip),
          child: Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: fg),
              child: IconTheme.merge(
                data: IconThemeData(color: fg, size: 16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) chip = Tooltip(message: tooltip!, child: chip);
    if (semanticLabel != null) {
      chip = Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: chip,
      );
    }
    return chip;
  }
}
