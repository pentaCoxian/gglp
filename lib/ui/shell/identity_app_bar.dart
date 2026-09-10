import 'package:flutter/material.dart';

import '../plus/plus.dart';
import 'breakpoints.dart';

/// The red primary application bar: signed-in identity
/// (avatar + name + caret) on the left — tapping it toggles the
/// navigation menu — and white line-icon actions on the right.
class IdentityAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Leading identity cluster: avatar (or glyph) + label.
  final Widget? avatar;
  final IconData? glyph;
  final String label;

  /// Whether the navigation menu is currently open (caret flips and
  /// the identity region holds the persistent 12% white overlay).
  final bool menuOpen;
  final VoidCallback? onToggleMenu;
  final List<Widget> actions;

  /// Whether to use the desktop bar height. The caller decides
  /// with [isDesktopWidth] because [preferredSize] is resolved before
  /// this widget has a context; it must agree with the toolbar height
  /// or the bar overflows its scaffold slot.
  final bool desktop;

  const IdentityAppBar({
    super.key,
    required this.label,
    this.avatar,
    this.glyph,
    this.menuOpen = false,
    this.onToggleMenu,
    this.actions = const [],
    this.desktop = false,
  });

  double get _height =>
      desktop ? PlusDims.appBarDesktop : PlusDims.appBarMobile;

  @override
  Size get preferredSize => Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: _height,
      title: Semantics(
        button: onToggleMenu != null,
        label: menuOpen ? 'Close menu' : 'Open menu',
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onToggleMenu,
            child: AnimatedContainer(
              duration: PlusMotion.fast,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              color:
                  menuOpen
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (avatar != null)
                    SizedBox(
                      width: PlusDims.avatar,
                      height: PlusDims.avatar,
                      child: avatar,
                    )
                  else if (glyph != null)
                    Icon(glyph, color: plus.textOnBrand),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: plus.textOnBrand),
                    ),
                  ),
                  if (onToggleMenu != null)
                    AnimatedRotation(
                      duration: PlusMotion.fast,
                      turns: menuOpen ? 0.5 : 0,
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: plus.textOnBrand,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: actions,
    );
  }
}
