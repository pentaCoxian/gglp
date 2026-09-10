import 'package:flutter/material.dart';

import 'plus_motion.dart';
import 'plus_theme.dart';
import 'plus_tokens.dart';

/// Anchored menu row: 48px tall, 16px text, no per-row icons
/// unless they carry meaning. A blue check marks the current choice.
class PlusMenuItem<T> extends PopupMenuItem<T> {
  PlusMenuItem({
    super.key,
    required String label,
    super.value,
    super.enabled,
    bool checked = false,
    IconData? icon,
    Color? iconColor,
    bool destructive = false,
    super.onTap,
  }) : super(
         height: PlusDims.menuRow,
         child: _PlusMenuRow(
           label: label,
           checked: checked,
           icon: icon,
           iconColor: iconColor,
           destructive: destructive,
         ),
       );
}

class _PlusMenuRow extends StatelessWidget {
  final String label;
  final bool checked;
  final IconData? icon;
  final Color? iconColor;
  final bool destructive;

  const _PlusMenuRow({
    required this.label,
    required this.checked,
    required this.icon,
    required this.iconColor,
    required this.destructive,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: iconColor ?? plus.textSecondary),
          const SizedBox(width: PlusSpacing.x4),
        ],
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: destructive ? plus.danger : plus.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (checked) ...[
          const SizedBox(width: PlusSpacing.x3),
          Icon(Icons.check, size: 20, color: plus.selected),
        ],
      ],
    );
  }
}

/// Shows an anchored Plus menu at [position] (fade + scale from the
/// anchor over ~150ms, ). Prefer [plusMenuPosition] to derive the
/// position from the tapped widget's render box.
Future<T?> showPlusMenu<T>({
  required BuildContext context,
  required RelativeRect position,
  required List<PopupMenuEntry<T>> items,
}) {
  return showMenu<T>(
    context: context,
    position: position,
    items: items,
    constraints: const BoxConstraints(minWidth: PlusDims.menuMinWidth),
    popUpAnimationStyle:
        PlusMotion.reduce(context)
            ? AnimationStyle(duration: PlusMotion.instant)
            : AnimationStyle(
              duration: PlusMotion.control,
              curve: PlusMotion.easeEnter,
              reverseDuration: PlusMotion.fast,
              reverseCurve: PlusMotion.easeExit,
            ),
  );
}

/// Menu position anchored to [anchorContext]'s widget, offset below it.
RelativeRect plusMenuPosition(BuildContext anchorContext) {
  final box = anchorContext.findRenderObject()! as RenderBox;
  final overlay =
      Overlay.of(anchorContext).context.findRenderObject()! as RenderBox;
  final rect = Rect.fromPoints(
    box.localToGlobal(Offset.zero, ancestor: overlay),
    box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
  );
  return RelativeRect.fromRect(rect, Offset.zero & overlay.size);
}
