import 'package:flutter/material.dart';

import 'plus_theme.dart';
import 'plus_tokens.dart';

/// White stream card: ~square corners, hairline card shadow.
///
/// Padding defaults to zero so media can bleed to the card edges —
/// text content brings its own 16px inset ([PlusDims.cardPadding]).
/// Dark mode swaps the shadow for a 1px border.
class PlusCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  const PlusCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(
      horizontal: PlusDims.cardGap,
      vertical: PlusDims.cardGap / 2,
    ),
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final body = Padding(padding: padding, child: child);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: plus.surface,
        borderRadius: BorderRadius.circular(PlusRadii.card),
        border: plus.isDark ? Border.all(color: plus.border) : null,
        boxShadow: plus.isDark ? null : plus.shadowCard,
      ),
      clipBehavior: clipBehavior,
      child:
          onTap == null
              ? body
              : Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap, child: body),
              ),
    );
  }
}
