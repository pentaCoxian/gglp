/// GGLP's Plus design system.
///
/// Foundations: [PlusTheme] (palette + shadows, installed as a
/// ThemeExtension by `AppTheme`), `PlusSpacing`/`PlusRadii`/`PlusDims`
/// (layout constants), `PlusMotion` (durations/easing), and
/// `plusTextTheme` (the type ramp).
///
/// Widget vocabulary:
///   [PlusCard]         white ~square stream card
///   [PlusChip]         rect chip; selected = brand-soft + brand border
///   [PlusButton]       flat text / publish-green / danger / raised
///   [PlusIconButton]   48px-target icon action ([onBrand] for red bar)
///   [PlusDivider]      1px hairline
///   [PlusContextTag]   white rect label with 2px blue right edge
///   [PlusTabBar]       48px white tabs, 2px blue underline
///   [PlusStreamBar]    white bar under the red app bar
///   [PlusMenuItem]     48px menu rows via [showPlusMenu]
///   [PlusScrim]        32%/54% overlay scrims
///   [PlusPanel]        right-anchored sliding surface
///   [PlusComposeDisc]  white disc, red pencil
///   [PlusLinearProgress] thin blue loading line
///
library;

export 'plus_button.dart';
export 'plus_card.dart';
export 'plus_chip.dart';
export 'plus_compose_disc.dart';
export 'plus_context_tag.dart';
export 'plus_divider.dart';
export 'plus_icon_button.dart';
export 'plus_menu.dart';
export 'plus_motion.dart';
export 'plus_panel.dart';
export 'plus_progress.dart';
export 'plus_scrim.dart';
export 'plus_stream_bar.dart';
export 'plus_tabs.dart';
export 'plus_theme.dart';
export 'plus_tokens.dart';
export 'plus_typography.dart';
