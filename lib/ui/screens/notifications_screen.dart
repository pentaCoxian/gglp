import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../misskey/models/account.dart';
import '../../misskey/models/notification.dart';
import '../../timeline/notifications_controller.dart';
import '../plus/plus.dart';
import '../widgets/captured_note_card.dart';
import '../widgets/emoji_image.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_display_name.dart';
import 'user_profile_screen.dart';

/// Full-screen notifications inbox — the fallback presentation. The
/// default UI path opens the right-side activity panel instead
/// (`ActivityPanel.open`); this route remains for deep links and any
/// flow that needs a whole screen.
class NotificationsScreen extends ConsumerWidget {
  final Account account;
  const NotificationsScreen({super.key, required this.account});

  static Future<void> open(
    BuildContext context, {
    required Account account,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(account: account),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.done_all),
            onPressed: () => ref
                .read(notificationsControllerProvider(account).notifier)
                .markAllRead(),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(notificationsControllerProvider(account).notifier)
                .refresh(),
          ),
        ],
      ),
      body: NotificationsList(account: account),
    );
  }
}

/// The notifications feed itself, reusable by both the full screen
/// above and the right-side activity panel.
///
/// [onBeforeNavigate] runs before any navigation a row initiates —
/// the activity panel passes its own dismissal so selecting an item
/// closes the panel and then focuses the target.
class NotificationsList extends ConsumerWidget {
  final Account account;
  final VoidCallback? onBeforeNavigate;

  const NotificationsList({
    super.key,
    required this.account,
    this.onBeforeNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider(account));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to load: $e'),
        ),
      ),
      data: (s) {
        if (s.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No notifications yet.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref
              .read(notificationsControllerProvider(account).notifier)
              .refresh(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollEndNotification) {
                if (n.metrics.pixels >=
                    n.metrics.maxScrollExtent - 400) {
                  ref
                      .read(notificationsControllerProvider(account)
                          .notifier)
                      .loadMore();
                }
              }
              return false;
            },
            // Each notification is its own flat white card (see
            // _NotificationRow), so no divider separators — the
            // card margins provide the rhythm.
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: s.items.length + 1,
              itemBuilder: (_, i) {
                if (i == s.items.length) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: s.reachedEnd
                          ? const Text('— end —')
                          : const CircularProgressIndicator(),
                    ),
                  );
                }
                return _NotificationRow(
                  notification: s.items[i],
                  account: account,
                  onBeforeNavigate: onBeforeNavigate,
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final MisskeyNotification notification;
  final Account account;
  final VoidCallback? onBeforeNavigate;
  const _NotificationRow({
    required this.notification,
    required this.account,
    this.onBeforeNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    final user = notification.user;
    final note = notification.note;
    final (icon, accent, label) = _styleFor(notification, theme, plus);
    final unreadDot = notification.isRead
        ? const SizedBox(width: 8)
        : Container(
            margin: const EdgeInsets.only(right: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          );
    // Flat white stream card per notification; unread rows carry the
    // 2014 gray unread tint. The whole card stays tappable to open
    // the actor's profile.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: user == null
          ? null
          : () {
              // Selecting an item closes the hosting panel first
              //, then focuses the actor's profile on the
              // root navigator.
              final rootNav =
                  Navigator.of(context, rootNavigator: true);
              onBeforeNavigate?.call();
              UserProfileScreen.openById(
                rootNav.context,
                viewerAccount: account,
                userId: user.id,
              );
            },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: PlusDims.cardGap,
          vertical: PlusDims.cardGap / 2,
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          color: notification.isRead ? plus.surface : plus.surfacePressed,
          borderRadius: BorderRadius.circular(PlusRadii.card),
          border: plus.isDark ? Border.all(color: plus.border) : null,
          boxShadow: plus.isDark ? null : plus.shadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                unreadDot,
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: 6),
                if (user != null)
                  UserAvatar(
                    url: user.avatarUrl,
                    seed: user.name ?? user.username,
                    radius: 14,
                  ),
                if (user != null) const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle.merge(
                        style: theme.textTheme.bodyMedium ??
                            const TextStyle(),
                        child: _NotificationHeader(
                          user: user,
                          label: label,
                          reaction: notification.reaction,
                          viewerHost: account.host,
                        ),
                      ),
                      Text(
                        _relative(notification.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: 8),
              // The originating note in collapsed form. Tapping the
              // card itself routes to the same actions as the timeline.
              CapturedNoteCard(
                note: note,
                attributionAccount: account,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static (IconData, Color, String) _styleFor(
    MisskeyNotification n,
    ThemeData theme,
    PlusTheme plus,
  ) {
    final cs = theme.colorScheme;
    switch (n.kind) {
      case NotificationKind.follow:
        return (Icons.person_add, cs.primary, 'followed you');
      case NotificationKind.unfollow:
        return (Icons.person_remove, cs.outline, 'unfollowed you');
      case NotificationKind.followRequest:
        return (Icons.person_add_alt_1, cs.tertiary,
            'sent you a follow request');
      case NotificationKind.followRequestAccepted:
        return (Icons.check_circle_outline, cs.primary,
            'accepted your follow request');
      case NotificationKind.mention:
        return (Icons.alternate_email, cs.tertiary, 'mentioned you');
      case NotificationKind.reply:
        return (Icons.reply, cs.primary, 'replied to your note');
      case NotificationKind.renote:
        return (Icons.repeat, plus.renote, 'renoted your note');
      case NotificationKind.quote:
        return (Icons.format_quote, cs.tertiary, 'quoted your note');
      case NotificationKind.reaction:
        return (Icons.add_reaction, plus.brand,
            'reacted to your note');
      case NotificationKind.reactionGrouped:
        return (Icons.add_reaction_outlined, plus.brand,
            'reacted to your note');
      case NotificationKind.renoteGrouped:
        return (Icons.repeat, plus.renote,
            'renoted your note');
      case NotificationKind.achievementEarned:
        return (Icons.emoji_events, cs.tertiary, 'earned an achievement');
      case NotificationKind.pollEnded:
        return (Icons.how_to_vote, cs.outline, 'a poll ended');
      case NotificationKind.other:
        return (Icons.notifications_none, cs.outline, n.rawType);
    }
  }

  static String _relative(DateTime t) {
    final delta = DateTime.now().difference(t);
    if (delta.inSeconds < 60) return '${delta.inSeconds}s';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m';
    if (delta.inHours < 24) return '${delta.inHours}h';
    return '${delta.inDays}d';
  }
}

class _NotificationHeader extends StatelessWidget {
  final dynamic user; // User?
  final String label;
  final String? reaction;
  final String viewerHost;
  const _NotificationHeader({
    required this.user,
    required this.label,
    required this.reaction,
    required this.viewerHost,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (user != null)
          Flexible(
            child: UserDisplayName(
              name: (user.name as String?) ?? user.username as String,
              viewerHost: user.host as String? ?? viewerHost,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (reaction != null) ...[
          const SizedBox(width: 6),
          if (reaction!.startsWith(':') && reaction!.endsWith(':'))
            EmojiImage(
              rawName:
                  reaction!.substring(1, reaction!.length - 1),
              viewerHost: viewerHost,
              size: 18,
            )
          else
            Text(reaction!, style: const TextStyle(fontSize: 16)),
        ],
      ],
    );
  }
}
