import 'package:flutter/material.dart';

import 'plus_theme.dart';
import 'plus_tokens.dart';

/// Small rectangular context label with a 2px blue right edge:
/// channel names, reply context, federation/local-only state, CW
/// status. Never a rounded chip.
class PlusContextTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? accent;
  final VoidCallback? onTap;
  final String? tooltip;

  const PlusContextTag({
    super.key,
    required this.label,
    this.icon,
    this.accent,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final edge = accent ?? plus.link;

    Widget tag = Container(
      decoration: BoxDecoration(
        color: plus.surface,
        border: Border(
          top: BorderSide(color: plus.border, width: 0.5),
          left: BorderSide(color: plus.border, width: 0.5),
          bottom: BorderSide(color: plus.border, width: 0.5),
          right: BorderSide(color: edge, width: 2),
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PlusSpacing.x2,
              vertical: 3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: accent ?? plus.textSecondary),
                  const SizedBox(width: PlusSpacing.x1),
                ],
                // Flexible so a bounded parent (a long federated host
                // beside a display name) ellipsizes the label instead
                // of overflowing inside the tag.
                Flexible(
                  child: Text(
                    label,
                    style: plus.metadata,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) tag = Tooltip(message: tooltip!, child: tag);
    return tag;
  }
}
