import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logger.dart';
import '../providers.dart';

/// App-wide user-controllable settings. Wired into MFM rendering, theme,
/// and (later) push behavior.
///
/// These persist to a singleton Drift row (`app_preferences`).
/// The controller loads on first build, exposes the snapshot via
/// `settingsProvider`, and writes-through on every mutation.
class AppSettings {
  final ThemeMode themeMode;

  /// Multiplier on top of the OS text scale. 1.0 = no override. Range
  /// clamped to [0.85, 1.6] in the UI; we don't enforce it in the model
  /// so future versions can reduce the cap without invalidating saved
  /// values.
  final double textScale;

  /// Global kill switch for animated MFM (Tier 3 effects). When true,
  /// every effect widget collapses to its static layout.
  final bool disableAnimatedMfm;

  /// Override for `MediaQuery.disableAnimations` reduced-motion. Null means
  /// inherit OS setting; true forces motion off; false forces it on.
  final bool? reducedMotionOverride;

  /// When true, notes whose channel is flagged `isSensitive` render with
  /// a frosted-glass blur over the body / media / quote until the user
  /// taps to reveal. Channel chip + author header stay visible so the
  /// user can still tell *what* is being hidden and from whom.
  ///
  /// Defaults on so a fresh install behaves conservatively. Users who
  /// want sensitive-channel notes inline can toggle off in Settings →
  /// Privacy & content.
  final bool blurSensitiveChannels;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.textScale = 1.0,
    this.disableAnimatedMfm = false,
    this.reducedMotionOverride,
    this.blurSensitiveChannels = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? textScale,
    bool? disableAnimatedMfm,
    Object? reducedMotionOverride = _unset,
    bool? blurSensitiveChannels,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    textScale: textScale ?? this.textScale,
    disableAnimatedMfm: disableAnimatedMfm ?? this.disableAnimatedMfm,
    reducedMotionOverride:
        identical(reducedMotionOverride, _unset)
            ? this.reducedMotionOverride
            : reducedMotionOverride as bool?,
    blurSensitiveChannels: blurSensitiveChannels ?? this.blurSensitiveChannels,
  );
}

/// Sentinel so [AppSettings.copyWith] can distinguish "not provided"
/// from an explicit `null` for the nullable [reducedMotionOverride].
const Object _unset = Object();

class SettingsController extends Notifier<AppSettings> {
  final _log = const Log('Settings');

  @override
  AppSettings build() {
    // Kick off the disk read; the initial returned state is the
    // defaults so the UI doesn't flash an undefined theme on cold
    // start. As soon as Drift returns we replace `state`.
    Future.microtask(_loadFromDisk);
    return const AppSettings();
  }

  Future<void> _loadFromDisk() async {
    try {
      final dao = ref.read(preferencesDaoProvider);
      final row = await dao.read();
      if (row == null) return;
      state = AppSettings(
        themeMode: _decodeThemeMode(row.themeMode),
        textScale: row.textScale,
        disableAnimatedMfm: row.disableAnimatedMfm,
        reducedMotionOverride: _decodeMotionOverride(row.reducedMotionOverride),
        blurSensitiveChannels: row.blurSensitiveChannels,
      );
    } catch (e, st) {
      _log.warn('settings disk read failed: $e', stack: st);
    }
  }

  Future<void> _persist() async {
    try {
      await ref
          .read(preferencesDaoProvider)
          .write(
            themeMode: _encodeThemeMode(state.themeMode),
            textScale: state.textScale,
            disableAnimatedMfm: state.disableAnimatedMfm,
            reducedMotionOverride: _encodeMotionOverride(
              state.reducedMotionOverride,
            ),
            blurSensitiveChannels: state.blurSensitiveChannels,
          );
    } catch (e, st) {
      _log.warn('settings disk write failed: $e', stack: st);
    }
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    unawaited(_persist());
  }

  void setTextScale(double scale) {
    state = state.copyWith(textScale: scale);
    unawaited(_persist());
  }

  void setDisableAnimatedMfm(bool v) {
    state = state.copyWith(disableAnimatedMfm: v);
    unawaited(_persist());
  }

  void setReducedMotionOverride(bool? v) {
    state = state.copyWith(reducedMotionOverride: v);
    unawaited(_persist());
  }

  void setBlurSensitiveChannels(bool v) {
    state = state.copyWith(blurSensitiveChannels: v);
    unawaited(_persist());
  }

  static ThemeMode _decodeThemeMode(String s) => switch (s) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  static String _encodeThemeMode(ThemeMode m) => switch (m) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
  static bool? _decodeMotionOverride(String s) => switch (s) {
    'on' => false, // 'on' = motion enabled = disableAnimations false
    'off' => true,
    _ => null,
  };
  static String _encodeMotionOverride(bool? v) {
    if (v == null) return '';
    return v ? 'off' : 'on';
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
