import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/active_account.dart';
import '../../app/providers.dart';
import '../../misskey/models/account.dart';
import '../../misskey/streaming/stream_messages.dart';
import '../../misskey/streaming/stream_providers.dart';
import '../../timeline/custom_timeline.dart';
import '../../timeline/timeline_source.dart';
import '../plus/plus.dart';
import '../screens/add_account_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/follow_requests_screen.dart';
import '../screens/manage_custom_timeline_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/user_profile_screen.dart';
import '../widgets/browse_antennas_sheet.dart';
import '../widgets/browse_channels_sheet.dart';
import '../widgets/connection_dot.dart';
import '../widgets/my_pages_sheet.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_display_name.dart';
import 'account_picker.dart';

/// The GGLP navigation menu: an explicit section menu
/// that opens *below* the red application bar — not a left drawer.
/// White surface, 48px rows, 12px section headings, blue check /
/// 3px blue left rule marking the current destination.
///
/// The hosting shell owns the open/close animation and scrim; this is
/// the menu content only. [onClose] dismisses the menu; every
/// navigation goes through it first so the stream behind stays the
/// obvious return point.
class NavigationMenu extends ConsumerWidget {
  final VoidCallback onClose;

  const NavigationMenu({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final customTimelines =
        ref.watch(customTimelinesProvider).valueOrNull ?? const [];
    final selection = ref.watch(activeAccountProvider);
    final activeId = switch (selection) {
      SingleAccount(:final account) => account.id,
      _ => null,
    };
    final activeCustomId = switch (selection) {
      CustomTimelineSelected(:final timelineId) => timelineId,
      _ => null,
    };
    final unifiedActive = selection is UnifiedAccounts;

    return accountsAsync.when(
      // Keep the menu populated while the account list re-resolves
      // (e.g. after an add/remove) instead of flashing a spinner.
      skipLoadingOnReload: true,
      loading:
          () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) =>
              Padding(padding: const EdgeInsets.all(24), child: Text('$e')),
      data:
          (accounts) => ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              const _SectionHeading('Accounts'),
              if (accounts.length > 1)
                _MenuRow(
                  active: unifiedActive,
                  leading: const Icon(Icons.merge_type),
                  title: const Text('All accounts (unified)'),
                  subtitle: Text('${accounts.length} accounts merged'),
                  onTap: () {
                    ref.read(activeAccountProvider.notifier).selectUnified();
                    onClose();
                  },
                ),
              for (final a in accounts)
                _AccountRow(a, isActive: a.id == activeId, onClose: onClose),
              _MenuRow(
                active: false,
                leading: const Icon(Icons.add),
                title: const Text('Add account'),
                onTap: () {
                  final rootNav = Navigator.of(context, rootNavigator: true);
                  onClose();
                  rootNav.push(
                    MaterialPageRoute(builder: (_) => const AddAccountScreen()),
                  );
                },
              ),
              const PlusDivider(margin: EdgeInsets.symmetric(vertical: 4)),
              const _SectionHeading('Timelines'),
              for (final t in customTimelines)
                _CustomTimelineRow(
                  timeline: t,
                  isActive: t.id == activeCustomId,
                  onClose: onClose,
                ),
              _MenuRow(
                active: false,
                enabled: accounts.isNotEmpty,
                leading: const Icon(Icons.dashboard_customize_outlined),
                title: const Text('New custom timeline'),
                subtitle:
                    customTimelines.isEmpty
                        ? const Text(
                          'Mix home, local, hybrid, global, and channel feeds '
                          'across accounts',
                        )
                        : null,
                onTap: () {
                  final rootNav = Navigator.of(context, rootNavigator: true);
                  onClose();
                  ManageCustomTimelineScreen.open(rootNav.context);
                },
              ),
              if (accounts.isNotEmpty) ...[
                const PlusDivider(margin: EdgeInsets.symmetric(vertical: 4)),
                const _SectionHeading('Personal'),
                _MenuRow(
                  active: false,
                  leading: const Icon(Icons.person_outline),
                  title: const Text('My profile'),
                  onTap:
                      () => _runWithAccount(
                        context,
                        accounts: accounts,
                        sheetTitle: 'View profile of…',
                        action:
                            (rootNav, picked) => rootNav.push(
                              MaterialPageRoute(
                                builder:
                                    (_) => UserProfileScreen(
                                      viewerAccount: picked,
                                      userId: picked.userId,
                                    ),
                              ),
                            ),
                      ),
                ),
                _MenuRow(
                  active: false,
                  leading: const Icon(Icons.bookmark_outline),
                  title: const Text('Bookmarks'),
                  onTap:
                      () => _runWithAccount(
                        context,
                        accounts: accounts,
                        sheetTitle: 'Bookmarks of…',
                        action:
                            (rootNav, picked) => BookmarksScreen.open(
                              rootNav.context,
                              account: picked,
                            ),
                      ),
                ),
                _MenuRow(
                  active: false,
                  leading: const Icon(Icons.how_to_reg_outlined),
                  title: const Text('Follow requests'),
                  onTap:
                      () => _runWithAccount(
                        context,
                        accounts: accounts,
                        sheetTitle: 'Follow requests for…',
                        action:
                            (rootNav, picked) => FollowRequestsScreen.open(
                              rootNav.context,
                              account: picked,
                            ),
                      ),
                ),
                _MenuRow(
                  active: false,
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('Pages'),
                  onTap:
                      () => _runWithAccount(
                        context,
                        accounts: accounts,
                        sheetTitle: 'Pages by…',
                        action:
                            (rootNav, picked) => MyPagesSheet.show(
                              rootNav.context,
                              account: picked,
                            ),
                      ),
                ),
                const PlusDivider(margin: EdgeInsets.symmetric(vertical: 4)),
                const _SectionHeading('Explore'),
                _MenuRow(
                  active: false,
                  leading: const Icon(Icons.tag),
                  title: const Text('Browse channels'),
                  onTap:
                      () => _runWithAccount(
                        context,
                        accounts: accounts,
                        sheetTitle: 'Browse channels from…',
                        action:
                            (rootNav, picked) => BrowseChannelsSheet.show(
                              rootNav.context,
                              account: picked,
                            ),
                      ),
                ),
                _MenuRow(
                  active: false,
                  leading: const Icon(Icons.satellite_alt_outlined),
                  title: const Text('Browse antennas'),
                  onTap:
                      () => _runWithAccount(
                        context,
                        accounts: accounts,
                        sheetTitle: 'Antennas from…',
                        action:
                            (rootNav, picked) => BrowseAntennasSheet.show(
                              rootNav.context,
                              account: picked,
                            ),
                      ),
                ),
              ],
              const PlusDivider(margin: EdgeInsets.symmetric(vertical: 4)),
              const _SectionHeading('Utility'),
              _MenuRow(
                active: false,
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  final rootNav = Navigator.of(context, rootNavigator: true);
                  onClose();
                  SettingsScreen.open(rootNav.context);
                },
              ),
            ],
          ),
    );
  }

  /// Closes the menu, optionally asks which account the entry should
  /// act on, then runs [action] against the root navigator (captured
  /// up front, matching the old drawer's defunct-context fix).
  Future<void> _runWithAccount(
    BuildContext context, {
    required List<Account> accounts,
    required String sheetTitle,
    required Future<void> Function(NavigatorState rootNav, Account picked)
    action,
  }) async {
    final rootNav = Navigator.of(context, rootNavigator: true);
    onClose();
    final Account? picked;
    if (accounts.length == 1) {
      picked = accounts.first;
    } else {
      picked = await pickAccountFor(
        rootNav.context,
        accounts: accounts,
        title: sheetTitle,
      );
    }
    if (picked == null) return;
    await action(rootNav, picked);
  }
}

class _SectionHeading extends StatelessWidget {
  final String label;
  const _SectionHeading(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: PlusTheme.of(context).textSecondary,
        ),
      ),
    );
  }
}

/// 48px destination row; the active destination carries the 3px blue
/// left rule + subtle fill + blue check.
class _MenuRow extends StatelessWidget {
  final bool active;
  final bool enabled;
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _MenuRow({
    required this.active,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final row = ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      onTap: onTap,
      onLongPress: onLongPress,
      trailing:
          trailing ??
          (active ? Icon(Icons.check, color: plus.selected, size: 20) : null),
    );
    if (!active) return row;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: plus.surfaceSubtle,
        border: Border(left: BorderSide(color: plus.selected, width: 3)),
      ),
      child: row,
    );
  }
}

class _AccountRow extends ConsumerWidget {
  final Account account;
  final bool isActive;
  final VoidCallback onClose;
  const _AccountRow(
    this.account, {
    required this.isActive,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase =
        ref.watch(connectionPhaseProvider(account)).valueOrNull ??
        ConnectionPhase.disconnected;
    final displayName = account.displayName ?? account.username;
    return _MenuRow(
      active: isActive,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          UserAvatar(url: account.avatarUrl, seed: displayName, radius: 20),
          Positioned(right: -2, bottom: -2, child: ConnectionDot(phase: phase)),
        ],
      ),
      title: UserDisplayName(name: displayName, viewerHost: account.host),
      subtitle: Text('@${account.username}@${account.host}'),
      onTap: () {
        ref.read(activeAccountProvider.notifier).selectAccount(account);
        onClose();
      },
      // Account removal moved off the row's trailing slot (one
      // action per row) onto long-press.
      onLongPress: () => _confirmRemove(context, ref),
    );
  }

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    // Resolve the repository up front: this row (and its ref) may be
    // gone by the time the dialog closes if the menu is dismissed.
    final repo = ref.read(accountRepositoryProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remove account?'),
            content: Text('Sign out of @${account.username}@${account.host}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
    if (confirmed == true) {
      await repo.remove(account.id);
    }
  }
}

class _CustomTimelineRow extends ConsumerWidget {
  final CustomTimeline timeline;
  final bool isActive;
  final VoidCallback onClose;
  const _CustomTimelineRow({
    required this.timeline,
    required this.isActive,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = _summarize(timeline.sources);
    return _MenuRow(
      active: isActive,
      leading: Icon(
        Icons.dashboard_customize_outlined,
        color: theme.colorScheme.primary,
      ),
      title: Text(timeline.name),
      subtitle: Text(
        summary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () {
        ref.read(activeAccountProvider.notifier).selectCustom(timeline.id);
        onClose();
      },
      trailing: PlusIconButton(
        tooltip: 'Edit',
        icon: Icons.edit_outlined,
        size: 16,
        onTap: () {
          final rootNav = Navigator.of(context, rootNavigator: true);
          onClose();
          ManageCustomTimelineScreen.open(rootNav.context, existing: timeline);
        },
      ),
    );
  }

  static String _summarize(List<TimelineSource> sources) {
    if (sources.isEmpty) return 'No sources';
    final n = sources.length;
    final kinds = <String>{};
    for (final s in sources) {
      kinds.add(switch (s.kind) {
        TimelineSourceKind.home => 'home',
        TimelineSourceKind.local => 'local',
        TimelineSourceKind.hybrid => 'hybrid',
        TimelineSourceKind.global => 'global',
        TimelineSourceKind.channel => 'channel',
        TimelineSourceKind.antenna => 'antenna',
      });
    }
    return '$n source${n == 1 ? '' : 's'} · ${kinds.join(', ')}';
  }
}
