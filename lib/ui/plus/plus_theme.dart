import 'package:flutter/material.dart';

/// GGLP's color palette and surface decoration.
///
/// Material roles are also mapped into [ColorScheme] by AppTheme.
class PlusTheme extends ThemeExtension<PlusTheme> {
  // Brand — the app-bar red family. Chrome only: red is never used as a
  // generic active-control color (selection is [link] blue).
  final Color brand;
  final Color brandDark;
  final Color brandDeep;
  final Color brandSoft;

  // Neutral surfaces.
  final Color canvas;
  final Color surface;
  final Color surfaceSubtle;
  final Color surfaceHover;
  final Color surfacePressed;
  final Color border;
  final Color divider;

  // Text.
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnBrand;

  // Functional.
  final Color link;
  final Color success;
  final Color warning;
  final Color danger;

  // Misskey semantics.
  final Color remote;

  // Overlays.
  final Color scrimLight;
  final Color scrim;

  const PlusTheme({
    required this.brand,
    required this.brandDark,
    required this.brandDeep,
    required this.brandSoft,
    required this.canvas,
    required this.surface,
    required this.surfaceSubtle,
    required this.surfaceHover,
    required this.surfacePressed,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnBrand,
    required this.link,
    required this.success,
    required this.warning,
    required this.danger,
    required this.remote,
    required this.scrimLight,
    required this.scrim,
  });

  /// Selection/active indicator color — always the functional blue.
  Color get selected => link;

  /// Renote/publish share the 2014 share-button green.
  Color get renote => success;

  /// Background of a reaction chip the viewer has selected.
  Color get reactionActive => brandSoft;

  /// Local-only federation state marker.
  Color get localOnly => warning;

  static const light = PlusTheme(
    brand: Color(0xFFB93221), // action_bar_background
    brandDark: Color(0xFF9F291D),
    brandDeep: Color(0xFF842219),
    brandSoft: Color(0xFFF7E7E4),
    canvas: Color(0xFFE5E5E5), // host_background
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF5F5F5), // riviera_comment_background
    surfaceHover: Color(0xFFEEEEEE),
    surfacePressed: Color(0xFFEBEBEB), // *_pressed_color
    border: Color(0xFFDADADA),
    divider: Color(0xFFE5E5E5), // card_separator
    textPrimary: Color(0xFF404040), // talladega_text_normal
    textSecondary: Color(0xFF737373), // talladega_text_gray
    textTertiary: Color(0xFF9E9E9E),
    textOnBrand: Color(0xFFFFFFFF),
    link: Color(0xFF4285F4), // talladega_text_blue
    success: Color(0xFF54AA41), // btn_green / square_green
    warning: Color(0xFFF4B400),
    danger: Color(0xFFC3352C), // talladega_text_red
    remote: Color(0xFF6F52A2),
    scrimLight: Color(0x52000000), // 32%
    scrim: Color(0x8A000000), // 54%
  );

  /// Dark extension with the same square geometry and functional colors
  /// chosen for AA contrast on #1e1e1e.
  static const dark = PlusTheme(
    brand: Color(0xFFD95748),
    brandDark: Color(0xFFC34537),
    brandDeep: Color(0xFFA83A2E),
    brandSoft: Color(0xFF482522),
    canvas: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceSubtle: Color(0xFF252525),
    surfaceHover: Color(0xFF303030),
    surfacePressed: Color(0xFF353535),
    border: Color(0xFF3C4043),
    divider: Color(0xFF333638),
    textPrimary: Color(0xFFF1F3F4),
    textSecondary: Color(0xFFBDC1C6),
    textTertiary: Color(0xFF8A9095),
    textOnBrand: Color(0xFFFFFFFF),
    link: Color(0xFF8AB4F8),
    success: Color(0xFF34A853),
    warning: Color(0xFFFDD663),
    danger: Color(0xFFF28B82),
    remote: Color(0xFF9A7FD1),
    scrimLight: Color(0x52000000),
    scrim: Color(0x8A000000),
  );

  static PlusTheme of(BuildContext context) =>
      Theme.of(context).extension<PlusTheme>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  bool get isDark => brand == dark.brand;

  // Elevation — five shadow levels. Dark surfaces pair
  // these with a 1px [border] outline instead, drawn by the widgets.
  /// bottom-weighted ~12% black fading over ~3px, near-zero side/top
  /// spill.
  List<BoxShadow> get shadowCard => const [
    BoxShadow(
      color: Color(0x1F000000), // 12%
      offset: Offset(0, 1.5),
      blurRadius: 3,
    ),
  ];

  List<BoxShadow> get shadowBar => const [
    BoxShadow(
      color: Color(0x33000000), // 20%
      offset: Offset(0, 2),
      blurRadius: 3,
    ),
  ];

  List<BoxShadow> get shadowMenu => const [
    BoxShadow(
      color: Color(0x47000000), // 28%
      offset: Offset(0, 3),
      blurRadius: 8,
    ),
  ];

  List<BoxShadow> get shadowFab => const [
    BoxShadow(
      color: Color(0x4D000000), // 30%
      offset: Offset(0, 4),
      blurRadius: 10,
    ),
  ];

  List<BoxShadow> get shadowDialog => const [
    BoxShadow(
      color: Color(0x52000000), // 32%
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  // Typography overflow — slots Flutter's TextTheme doesn't carry.
  // Component themes can use these directly without inheriting TextTheme,
  // so they need the same Japanese glyph hint as the main type ramp.

  /// Username, visibility, and timestamp metadata (13/18).
  TextStyle get metadata => TextStyle(
    locale: const Locale('ja'),
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: textSecondary,
  );

  /// Counters and helper text (12/16), tertiary-colored.
  TextStyle get caption => TextStyle(
    locale: const Locale('ja'),
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: textTertiary,
  );

  @override
  PlusTheme copyWith({
    Color? brand,
    Color? brandDark,
    Color? brandDeep,
    Color? brandSoft,
    Color? canvas,
    Color? surface,
    Color? surfaceSubtle,
    Color? surfaceHover,
    Color? surfacePressed,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnBrand,
    Color? link,
    Color? success,
    Color? warning,
    Color? danger,
    Color? remote,
    Color? scrimLight,
    Color? scrim,
  }) {
    return PlusTheme(
      brand: brand ?? this.brand,
      brandDark: brandDark ?? this.brandDark,
      brandDeep: brandDeep ?? this.brandDeep,
      brandSoft: brandSoft ?? this.brandSoft,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      surfacePressed: surfacePressed ?? this.surfacePressed,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textOnBrand: textOnBrand ?? this.textOnBrand,
      link: link ?? this.link,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      remote: remote ?? this.remote,
      scrimLight: scrimLight ?? this.scrimLight,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  PlusTheme lerp(PlusTheme? other, double t) {
    if (other is! PlusTheme) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return PlusTheme(
      brand: c(brand, other.brand),
      brandDark: c(brandDark, other.brandDark),
      brandDeep: c(brandDeep, other.brandDeep),
      brandSoft: c(brandSoft, other.brandSoft),
      canvas: c(canvas, other.canvas),
      surface: c(surface, other.surface),
      surfaceSubtle: c(surfaceSubtle, other.surfaceSubtle),
      surfaceHover: c(surfaceHover, other.surfaceHover),
      surfacePressed: c(surfacePressed, other.surfacePressed),
      border: c(border, other.border),
      divider: c(divider, other.divider),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      textOnBrand: c(textOnBrand, other.textOnBrand),
      link: c(link, other.link),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      danger: c(danger, other.danger),
      remote: c(remote, other.remote),
      scrimLight: c(scrimLight, other.scrimLight),
      scrim: c(scrim, other.scrim),
    );
  }
}
