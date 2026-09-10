import 'package:flutter/material.dart';

import 'plus_theme.dart';

/// 1px hairline rule on the Plus divider color.
class PlusDivider extends StatelessWidget {
  final EdgeInsetsGeometry margin;

  const PlusDivider({super.key, this.margin = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: margin,
      color: PlusTheme.of(context).divider,
    );
  }
}
