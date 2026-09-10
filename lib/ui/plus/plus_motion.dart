import 'package:flutter/widgets.dart';

/// Motion tokens for the Plus design system.
///
/// Character: direct, spatial, layered, restrained, interruptible. No
/// springs, no overshoot. Exits run ~20% faster than entries. Always
/// gate transforms behind [reduce] — reduced motion means short fades
/// and ≤4px travel, never delayed feedback.
abstract final class PlusMotion {
  // Durations.
  static const instant = Duration(milliseconds: 80);
  static const fast = Duration(milliseconds: 120);
  static const control = Duration(milliseconds: 160);
  static const surface = Duration(milliseconds: 200);
  static const panel = Duration(milliseconds: 220);
  static const dialog = Duration(milliseconds: 240);
  static const navigation = Duration(milliseconds: 260);
  static const media = Duration(milliseconds: 300);

  /// exits are 15–25% faster than entries.
  static Duration exitOf(Duration enter) =>
      Duration(milliseconds: (enter.inMilliseconds * 0.8).round());

  // Easing.
  static const easeStandard = Cubic(0.4, 0, 0.2, 1);
  static const easeEnter = Cubic(0, 0, 0.2, 1);
  static const easeExit = Cubic(0.4, 0, 1, 1);

  // Distances.
  static const double distXs = 4;
  static const double distSm = 8;
  static const double distMd = 16;
  static const double distLg = 24;

  // Scales.
  static const double scaleEnter = 0.96;
  static const double scaleMenu = 0.98;
  static const double scalePress = 0.97;

  /// Whether reduced motion is requested (OS setting or the in-app
  /// override, both already merged into MediaQuery by `MisskeyGglpApp`).
  static bool reduce(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Clamp a duration for reduced-motion mode: 80–120ms fades.
  static Duration reduced(BuildContext context, Duration d) =>
      reduce(context) && d > fast ? fast : d;
}
