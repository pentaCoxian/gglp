import 'package:flutter/material.dart';

import 'plus_theme.dart';

/// GGLP type ramp mapped onto Flutter's TextTheme.
///
/// | doc token        | size/lh | weight | slot          |
/// | display-profile  | 32/40   | 500    | headlineLarge |
/// | heading-page     | 24/32   | 400    | headlineSmall |
/// | heading-card /   | 18/24   | 500    | titleLarge    |
/// |   title-appbar   |         |        |               |
/// | (stream titles)  | 16/24   | 500    | titleMedium   |
/// | body-note        | 16/24   | 400    | bodyLarge     |
/// | body-ui          | 14/20   | 400    | bodyMedium    |
/// | label            | 14/20   | 500    | labelLarge    |
/// | caption          | 12/16   | 400    | bodySmall     |
///
/// metadata (13/18) has no TextTheme slot — use [PlusTheme.metadata].
/// 2014 Roboto was untracked: letterSpacing is 0 everywhere.
TextTheme plusTextTheme(PlusTheme plus) {
  TextStyle s(double size, double lh, FontWeight w, [Color? color]) =>
      TextStyle(
        fontSize: size,
        height: lh / size,
        fontWeight: w,
        letterSpacing: 0,
        color: color ?? plus.textPrimary,
      );

  return TextTheme(
    headlineLarge: s(32, 40, FontWeight.w500),
    headlineMedium: s(28, 36, FontWeight.w400),
    headlineSmall: s(24, 32, FontWeight.w400),
    titleLarge: s(18, 24, FontWeight.w500),
    titleMedium: s(16, 24, FontWeight.w500),
    titleSmall: s(14, 20, FontWeight.w500),
    bodyLarge: s(16, 24, FontWeight.w400),
    bodyMedium: s(14, 20, FontWeight.w400),
    bodySmall: s(12, 16, FontWeight.w400, plus.textSecondary),
    labelLarge: s(14, 20, FontWeight.w500),
    labelMedium: s(13, 18, FontWeight.w500, plus.textSecondary),
    labelSmall: s(12, 16, FontWeight.w500, plus.textSecondary),
  );
}
