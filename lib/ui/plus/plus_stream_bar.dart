import 'package:flutter/material.dart';

import 'plus_theme.dart';
import 'plus_tokens.dart';

/// The white 48px stream-selection bar that sits directly below the
/// red application bar: current timeline name (+ caret) on the
/// left, a thin divider before the trailing action on the right.
class PlusStreamBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final VoidCallback? onTitleTap;
  final bool showCaret;
  final Widget? trailing;

  const PlusStreamBar({
    super.key,
    required this.title,
    this.onTitleTap,
    this.showCaret = true,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(PlusDims.streamBar);

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    return Container(
      height: PlusDims.streamBar,
      decoration: BoxDecoration(
        color: plus.surface,
        border:
            plus.isDark ? Border(bottom: BorderSide(color: plus.border)) : null,
        boxShadow: plus.isDark ? null : plus.shadowBar,
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTitleTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PlusDims.cardPadding,
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: DefaultTextStyle.merge(
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(color: plus.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: title,
                        ),
                      ),
                      if (showCaret && onTitleTap != null) ...[
                        const SizedBox(width: PlusSpacing.x1),
                        Icon(Icons.arrow_drop_down, color: plus.textSecondary),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: PlusSpacing.x3,
              endIndent: PlusSpacing.x3,
              color: plus.divider,
            ),
            trailing!,
          ],
        ],
      ),
    );
  }
}
