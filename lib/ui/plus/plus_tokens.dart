/// Brightness-invariant layout constants for the Plus design system.
library;

/// 4px-base spacing scale.
abstract final class PlusSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x12 = 48;
  static const double x16 = 64;
}

/// Corner radii — corners stay nearly square everywhere; only
/// avatars and the compose disc are circles.
abstract final class PlusRadii {
  static const double card = 2;
  static const double menu = 2;
  static const double dialog = 2;
  static const double chip = 2;

  /// Media panels stay square and flush on every form factor.
  static const double media = 0;
}

/// Standard dimensions.
abstract final class PlusDims {
  static const double appBarMobile = 56;
  static const double appBarDesktop = 64;
  static const double streamBar = 48;
  static const double navRow = 48;
  static const double icon = 24;
  static const double minTarget = 48;

  /// App-bar identity avatar.
  static const double avatar = 40;

  static const double noteAvatar = 48;

  static const double cardGap = 8;
  static const double cardPadding = 16;
  static const double composeDisc = 56;
  static const double profileAvatar = 120;
  static const double actionRow = 48;
  static const double reactionChip = 28;
  static const double menuMinWidth = 192;
  static const double menuRow = 48;

  /// Anchored navigation panel on wide layouts.
  static const double navPanelWidth = 320;

  /// Activity panel width cap.
  static const double activityPanelWidth = 360;

  /// Desktop breakpoint.
  static const double desktopMinWidth = 960;

  /// Composer / dialog max width on wide layouts.
  static const double composerMaxWidth = 600;

  /// Feed column cap on wide layouts.
  static const double feedMaxWidth = 720;
}
