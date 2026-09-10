import 'package:flutter/material.dart';

import 'plus_divider.dart';
import 'plus_theme.dart';
import 'plus_tokens.dart';

/// 48px white tab bar. The 2px blue underline indicator comes
/// from the app-level TabBarTheme; this adds the white surface, the
/// bottom hairline, and an optional bar shadow.
class PlusTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? controller;
  final List<Widget> tabs;
  final bool isScrollable;
  final bool shadow;

  const PlusTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.shadow = false,
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
        boxShadow: shadow && !plus.isDark ? plus.shadowBar : null,
      ),
      child: Column(
        children: [
          Expanded(
            child: TabBar(
              controller: controller,
              tabs: tabs,
              isScrollable: isScrollable,
            ),
          ),
          const PlusDivider(),
        ],
      ),
    );
  }
}
