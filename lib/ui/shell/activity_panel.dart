import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../misskey/models/account.dart';
import '../../timeline/notifications_controller.dart';
import '../plus/plus.dart';
import '../screens/notifications_screen.dart';

/// Right-side sliding activity panel: notifications layer over
/// the current screen behind a 54% scrim instead of navigating to a
/// full page. Slides from the right edge over 220ms, exits in 180ms;
/// reduced motion swaps the slide for a fade.
class ActivityPanel {
  static Future<void> open(BuildContext context, {required Account account}) {
    final plus = PlusTheme.of(context);
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: plus.scrim,
        barrierDismissible: true,
        barrierLabel: 'Close notifications',
        transitionDuration: PlusMotion.panel,
        reverseTransitionDuration: PlusMotion.exitOf(PlusMotion.panel),
        pageBuilder:
            (ctx, _, __) => Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: math.min(
                  MediaQuery.sizeOf(ctx).width * 0.86,
                  PlusDims.activityPanelWidth,
                ),
                child: PlusPanel(child: _ActivityPanelBody(account: account)),
              ),
            ),
        transitionsBuilder: (ctx, animation, _, child) {
          if (MediaQuery.disableAnimationsOf(ctx)) {
            return FadeTransition(opacity: animation, child: child);
          }
          return SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: PlusMotion.easeEnter,
                reverseCurve: PlusMotion.easeExit,
              ),
            ),
            child: child,
          );
        },
      ),
    );
  }
}

class _ActivityPanelBody extends ConsumerWidget {
  final Account account;
  const _ActivityPanelBody({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plus = PlusTheme.of(context);
    return Column(
      children: [
        SizedBox(
          height: PlusDims.streamBar,
          child: Row(
            children: [
              const SizedBox(width: PlusDims.cardPadding),
              Expanded(
                child: Text(
                  'Notifications',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: plus.textPrimary),
                ),
              ),
              PlusIconButton(
                icon: Icons.done_all,
                tooltip: 'Mark all read',
                onTap:
                    () =>
                        ref
                            .read(
                              notificationsControllerProvider(account).notifier,
                            )
                            .markAllRead(),
              ),
              PlusIconButton(
                icon: Icons.refresh,
                tooltip: 'Refresh',
                onTap:
                    () =>
                        ref
                            .read(
                              notificationsControllerProvider(account).notifier,
                            )
                            .refresh(),
              ),
            ],
          ),
        ),
        const PlusDivider(),
        Expanded(
          child: NotificationsList(
            account: account,
            onBeforeNavigate:
                () => Navigator.of(context, rootNavigator: true).pop(),
          ),
        ),
      ],
    );
  }
}
