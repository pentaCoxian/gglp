import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/screens/settings_screen.dart';
import 'router.dart';
import 'settings/settings_controller.dart';
import 'theme/app_theme.dart';
import 'updates/update_widgets.dart';

class MisskeyGglpApp extends ConsumerWidget {
  const MisskeyGglpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'GGLP',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Wrap the app in a MediaQuery override so the user's saved
        // text-scale multiplier and reduced-motion preference affect
        // every descendant. We multiply on top of the OS-provided
        // scaler so platform a11y settings still apply.
        final mq = MediaQuery.of(context);
        final osScale = mq.textScaler.scale(1.0);
        final reduceMotion =
            settings.reducedMotionOverride ?? mq.disableAnimations;
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(osScale * settings.textScale),
            disableAnimations: reduceMotion,
          ),
          child: UpdateHost(
            onReview:
                () => router.routerDelegate.navigatorKey.currentState?.push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
