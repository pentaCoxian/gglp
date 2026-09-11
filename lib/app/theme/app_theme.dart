import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../ui/plus/plus.dart';

/// GGLP ("Plus") theme.
///
/// Red is chrome only: the app bar and the compose pencil. Functional
/// selection — links, active tabs, focus, checked rows — is blue, and
/// publish/renote is green.
/// Surfaces are white with ~square corners on a cool-gray canvas.
class AppTheme {
  static ThemeData light() => _build(Brightness.light, PlusTheme.light);

  static ThemeData dark() => _build(Brightness.dark, PlusTheme.dark);

  // Roboto has no CJK glyphs. Give the platform fallback a Japanese
  // shaping locale so shared kanji use Japanese forms even when the UI
  // language is English. Keep this on the styles so MFM spans, editable
  // text and standalone text measurement inherit the same glyph choice.
  static TextTheme _japaneseGlyphs(TextTheme theme) {
    TextStyle? japanese(TextStyle? style) =>
        style?.copyWith(locale: const Locale('ja'));
    return theme.copyWith(
      displayLarge: japanese(theme.displayLarge),
      displayMedium: japanese(theme.displayMedium),
      displaySmall: japanese(theme.displaySmall),
      headlineLarge: japanese(theme.headlineLarge),
      headlineMedium: japanese(theme.headlineMedium),
      headlineSmall: japanese(theme.headlineSmall),
      titleLarge: japanese(theme.titleLarge),
      titleMedium: japanese(theme.titleMedium),
      titleSmall: japanese(theme.titleSmall),
      bodyLarge: japanese(theme.bodyLarge),
      bodyMedium: japanese(theme.bodyMedium),
      bodySmall: japanese(theme.bodySmall),
      labelLarge: japanese(theme.labelLarge),
      labelMedium: japanese(theme.labelMedium),
      labelSmall: japanese(theme.labelSmall),
    );
  }

  static ThemeData _build(Brightness brightness, PlusTheme plus) {
    final isDark = brightness == Brightness.dark;

    // Only roles that stock Material widgets (and the MFM renderer,
    // which colors links/mentions with `primary`) actually read.
    // GGLP-specific colors stay on the PlusTheme extension.
    final scheme = ColorScheme(
      brightness: brightness,
      primary: plus.link,
      onPrimary: Colors.white,
      primaryContainer: plus.link.withValues(alpha: 0.12),
      onPrimaryContainer: plus.link,
      secondary: plus.success,
      onSecondary: Colors.white,
      secondaryContainer: plus.brandSoft,
      onSecondaryContainer: plus.brandDeep,
      tertiary: plus.remote,
      onTertiary: Colors.white,
      tertiaryContainer: plus.surfaceSubtle,
      onTertiaryContainer: plus.remote,
      error: plus.danger,
      onError: Colors.white,
      errorContainer: plus.brandSoft,
      onErrorContainer: plus.danger,
      surface: plus.surface,
      onSurface: plus.textPrimary,
      onSurfaceVariant: plus.textSecondary,
      surfaceContainerLowest: plus.surface,
      surfaceContainerLow: plus.surface,
      surfaceContainer: plus.surfaceSubtle,
      surfaceContainerHigh: plus.surfaceHover,
      surfaceContainerHighest: plus.surfacePressed,
      surfaceTint: Colors.transparent,
      outline: plus.border,
      outlineVariant: plus.divider,
      shadow: Colors.black,
      scrim: plus.scrim,
      inverseSurface: isDark ? plus.surfaceHover : const Color(0xFF323232),
      onInverseSurface: isDark ? plus.textPrimary : Colors.white,
      inversePrimary: plus.link,
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['NotoColorEmoji'],
      textTheme: plusTextTheme(plus),
    );
    final textTheme = _japaneseGlyphs(base.textTheme);

    OutlinedBorder rect([double r = PlusRadii.card]) =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: _japaneseGlyphs(base.primaryTextTheme),
      extensions: [plus],
      scaffoldBackgroundColor: plus.canvas,
      // Holo-era expanding splash, not the sparkle.
      splashFactory: InkSplash.splashFactory,
      splashColor: plus.textPrimary.withValues(alpha: 0.08),
      highlightColor: plus.textPrimary.withValues(alpha: 0.06),
      hoverColor: plus.surfaceHover,
      focusColor: plus.link.withValues(alpha: 0.12),
      // The 2014 "fade + translate upward" screen transition.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      iconTheme: IconThemeData(color: plus.textSecondary, size: PlusDims.icon),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: plus.brand,
        foregroundColor: plus.textOnBrand,
        elevation: 2,
        shadowColor: Colors.black,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle:
            textTheme.titleLarge?.copyWith(color: plus.textOnBrand),
        iconTheme: IconThemeData(color: plus.textOnBrand, size: PlusDims.icon),
        actionsIconTheme:
            IconThemeData(color: plus.textOnBrand, size: PlusDims.icon),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: plus.surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        shape: isDark
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PlusRadii.card),
                side: BorderSide(color: plus.border),
              )
            : rect(),
        margin: const EdgeInsets.symmetric(
          horizontal: PlusSpacing.x2,
          vertical: PlusSpacing.x1,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: plus.divider,
        thickness: 1,
        space: 1,
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor: plus.textPrimary,
        unselectedLabelColor: plus.textSecondary,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: plus.link, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        overlayColor: WidgetStatePropertyAll(plus.surfaceHover),
      ),
      // Defense-in-depth behind PlusComposeDisc: white disc, red pencil.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: plus.surface,
        foregroundColor: plus.brand,
        elevation: 4,
        highlightElevation: 2,
        shape: const CircleBorder(),
        sizeConstraints: const BoxConstraints.tightFor(
          width: PlusDims.composeDisc,
          height: PlusDims.composeDisc,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: plus.surface,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        shape: isDark
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(PlusRadii.menu),
                side: BorderSide(color: plus.border),
              )
            : rect(PlusRadii.menu),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.bodyLarge?.copyWith(color: plus.textPrimary),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: plus.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.32),
        shape: rect(PlusRadii.dialog),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: plus.surface,
        modalBackgroundColor: plus.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.32),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(PlusRadii.card)),
        ),
        showDragHandle: false,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: plus.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.32),
        shape: const RoundedRectangleBorder(),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: plus.textSecondary,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: plus.metadata,
        minTileHeight: PlusDims.navRow,
        shape: const RoundedRectangleBorder(),
      ),
      // 2014 EditText: underline field, blue when focused.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: PlusSpacing.x3,
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: plus.border),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: plus.border),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: plus.link, width: 2),
        ),
        hintStyle:
            textTheme.bodyLarge?.copyWith(color: plus.textTertiary),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: plus.surfaceSubtle,
        side: BorderSide.none,
        shape: rect(PlusRadii.chip),
        labelStyle: plus.metadata.copyWith(color: plus.textPrimary),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: plus.link,
          textStyle: textTheme.labelLarge,
          shape: rect(),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: plus.link,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: textTheme.labelLarge,
          shape: rect(),
          padding: const EdgeInsets.symmetric(
            horizontal: PlusSpacing.x4,
            vertical: PlusSpacing.x3,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: plus.surface,
          foregroundColor: plus.textPrimary,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.18),
          textStyle: textTheme.labelLarge,
          shape: rect(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: plus.textPrimary,
          side: BorderSide(color: plus.border),
          textStyle: textTheme.labelLarge,
          shape: rect(),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? plus.link
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: plus.textSecondary, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlusRadii.chip),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? plus.link
              : plus.textSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? plus.link
              : plus.surfacePressed,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : plus.border,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : plus.textSecondary,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: plus.link,
        inactiveTrackColor: plus.surfacePressed,
        thumbColor: Colors.white,
        overlayColor: plus.link.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: plus.link,
        linearTrackColor: Colors.transparent,
        circularTrackColor: plus.surfacePressed,
        linearMinHeight: 3,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.fixed,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        shape: const RoundedRectangleBorder(),
        elevation: 4,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF616161),
          borderRadius: BorderRadius.circular(PlusRadii.chip),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          plus.textTertiary.withValues(alpha: 0.38),
        ),
        radius: Radius.zero,
        thickness: const WidgetStatePropertyAll(4),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: plus.surface,
        elevation: 8,
        shape: rect(PlusRadii.dialog),
      ),
      bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
        color: plus.surface,
        elevation: 8,
      ),
    );
  }
}
