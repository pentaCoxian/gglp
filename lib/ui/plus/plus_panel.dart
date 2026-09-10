import 'package:flutter/material.dart';

import 'plus_theme.dart';

/// Right-anchored sliding surface: square white sheet with the
/// menu-level shadow on its left edge. The route/host owns the slide
/// animation; this is just the surface.
class PlusPanel extends StatelessWidget {
  final Widget child;

  const PlusPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: plus.surface,
        border:
            plus.isDark ? Border(left: BorderSide(color: plus.border)) : null,
        boxShadow: plus.isDark ? null : plus.shadowMenu,
      ),
      // The panel is pushed as its own route with no Scaffold, so it
      // must supply the Material ancestor that InkWell / PopupMenuButton
      // descendants assert on. Without it the note action row's "more"
      // button threw during build and Flutter swapped in its error box
      // — a 100000×100000 render object that stalled every frame.
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(left: false, child: child),
      ),
    );
  }
}
