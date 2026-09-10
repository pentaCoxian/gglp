import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/active_account.dart';
import '../../misskey/models/account.dart';
import '../../timeline/notifications_controller.dart';
import '../plus/plus.dart';
import 'account_picker.dart';
import 'activity_panel.dart';

/// Bell action for the red app bar: white outline bell with an
/// unread counter badge. Resolves which account's notifications to
/// open (asking when ambiguous), then opens the activity surface.
class ActivityBell extends ConsumerWidget {
  final List<Account> accounts;
  final TimelineSelection selection;
  final List<dynamic> customTimelines;

  const ActivityBell({
    super.key,
    required this.accounts,
    required this.selection,
    required this.customTimelines,
  });

  /// Account whose unread badge we should show. `null` if no single
  /// account owns the badge (multi-account unified mode) — the badge
  /// is skipped but the bell stays tappable.
  Account? _badgeAccount() {
    if (accounts.isEmpty) return null;
    switch (selection) {
      case SingleAccount(:final account):
        return account;
      case UnifiedAccounts():
        return accounts.length == 1 ? accounts.first : null;
      case CustomTimelineSelected(:final timelineId):
        final t = customTimelines.cast<dynamic>().firstWhere(
          (t) => t.id == timelineId,
          orElse: () => null,
        );
        if (t == null || (t.sources as List).isEmpty) {
          return accounts.first;
        }
        final firstId = (t.sources as List).first.accountId as String;
        return accounts.firstWhereOrNull((a) => a.id == firstId) ??
            accounts.first;
      case NoSelection():
        return null;
    }
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    if (accounts.isEmpty) return;
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    Account? target = _badgeAccount();
    if (target == null && accounts.length > 1) {
      target = await pickAccountFor(
        rootContext,
        accounts: accounts,
        title: 'Notifications for…',
      );
      if (target == null) return;
    }
    target ??= accounts.first;
    if (!rootContext.mounted) return;
    await ActivityPanel.open(rootContext, account: target);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plus = PlusTheme.of(context);
    final badgeAccount = _badgeAccount();
    int unread = 0;
    if (badgeAccount != null) {
      unread = ref.watch(
        notificationsControllerProvider(badgeAccount).select(
          (async) =>
              async.valueOrNull?.items.where((n) => !n.isRead).length ?? 0,
        ),
      );
    }
    return Tooltip(
      message: 'Notifications',
      child: Semantics(
        label: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
        button: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            onTap: () => _onTap(context, ref),
            radius: PlusDims.minTarget / 2,
            highlightColor: Colors.white.withValues(alpha: 0.18),
            splashColor: Colors.white.withValues(alpha: 0.10),
            hoverColor: Colors.white.withValues(alpha: 0.10),
            child: SizedBox(
              width: PlusDims.minTarget,
              height: PlusDims.minTarget,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: PlusDims.icon,
                    color: plus.textOnBrand,
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: plus.textOnBrand,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: plus.brand,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
