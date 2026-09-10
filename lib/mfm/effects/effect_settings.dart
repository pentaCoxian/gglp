import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/settings/settings_controller.dart';

/// Resolves whether motion effects should animate, combining the user
/// preference with `MediaQuery.disableAnimations` (OS reduced-motion).
class EffectSettings {
  /// True iff Tier 3 effects should actively animate.
  static bool shouldAnimate(BuildContext context, WidgetRef ref) {
    final user = ref.watch(settingsProvider);
    if (user.disableAnimatedMfm) return false;
    final override = user.reducedMotionOverride;
    if (override != null) return !override;
    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return !reducedMotion;
  }
}
