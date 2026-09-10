import 'package:flutter/material.dart';

import 'plus_theme.dart';

/// Tappable scrim layer behind menus, the composer, and panels.
/// [light] is the 32% composer scrim; the default is the 54% panel
/// scrim. Drive [opacity] from the owning animation (0–1).
class PlusScrim extends StatelessWidget {
  final double opacity;
  final bool light;
  final VoidCallback? onTap;

  const PlusScrim({
    super.key,
    this.opacity = 1,
    this.light = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final color = light ? plus.scrimLight : plus.scrim;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: color.withValues(alpha: color.a * opacity),
        child: const SizedBox.expand(),
      ),
    );
  }
}
