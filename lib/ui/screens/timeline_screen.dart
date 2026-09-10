import 'package:flutter/material.dart';
// LogicalKeyboardKey for the CallbackShortcuts bindings below.
// (flutter/material does export it transitively, but the analyzer
// flags it as unnecessary in some Flutter versions; importing
// services explicitly is the supported path.)
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/active_account.dart';
import '../../app/providers.dart';
import '../../misskey/emoji/emoji_providers.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/note.dart';
import '../../misskey/streaming/stream_messages.dart';
import '../../misskey/streaming/stream_supervisor.dart';
import '../../timeline/custom_timeline_controller.dart';
import '../../timeline/timeline_controller.dart';
import '../../timeline/timeline_kind.dart';
import '../../timeline/timeline_merge_engine.dart';
import '../../timeline/unified_timeline_controller.dart';
import '../plus/plus.dart';
import '../shell/activity_bell.dart';
import '../shell/breakpoints.dart';
import '../shell/identity_app_bar.dart';
import '../shell/navigation_menu.dart';
import '../shell/stream_bar.dart';
import '../widgets/browse_antennas_sheet.dart';
import '../widgets/browse_channels_sheet.dart';
import '../widgets/captured_note_card.dart';
import '../widgets/user_avatar.dart';
import 'add_account_screen.dart';
import 'compose_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'thread_screen.dart';
import 'time_machine_screen.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen>
    with SingleTickerProviderStateMixin {
  TimelineKind _kind = TimelineKind.home;

  /// Navigation-menu open/close ("Account and navigation
  /// menu"): fade + translateY(-8→0) below the red bar.
  late final AnimationController _menuController = AnimationController(
    vsync: this,
    duration: PlusMotion.surface,
    reverseDuration: PlusMotion.control,
  );
  bool _menuOpen = false;

  /// True while the composer is open so the compose disc can shrink
  /// out of the way.
  bool _composerOpen = false;

  @override
  void initState() {
    super.initState();
    // Rebuild once the close animation finishes so the scrim/menu
    // layers unmount — otherwise the (now invisible) scrim keeps
    // swallowing every scroll and tap on the timeline.
    _menuController.addStatusListener(_onMenuAnimationStatus);
  }

  void _onMenuAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _menuOpen = !_menuOpen;
      if (_menuOpen) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    });
  }

  void _closeMenu() {
    if (!_menuOpen) return;
    setState(() {
      _menuOpen = false;
      _menuController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final selection = ref.watch(activeAccountProvider);
    // Touch the supervisor so it's instantiated at app start; it will
    // open + maintain a websocket per logged-in account regardless of
    // which timeline is currently shown.
    ref.watch(streamSupervisorProvider);
    // Touch the emoji bootstrap so it warms each host's `/emojis`
    // catalog the first time we see an account on that host.
    ref.watch(emojiCatalogBootstrapProvider);

    final customTimelines =
        ref.watch(customTimelinesProvider).valueOrNull ?? const [];
    final canPick = selection is! NoSelection;
    // Per-account/unified timelines have a kind picker. Custom
    // timelines don't (they bake the kind into each source).
    final showKindPicker = canPick && selection is! CustomTimelineSelected;
    final accounts = accountsAsync.valueOrNull ?? const <Account>[];
    final desktop = isDesktopWidth(context);

    // Identity cluster: WHO the app is acting as. The feed
    // choice lives in the stream bar below.
    final (
      Widget? identityAvatar,
      IconData? identityGlyph,
      String label,
    ) = switch (selection) {
      SingleAccount(:final account) => (
        UserAvatar(
          url: account.avatarUrl,
          seed: account.displayName ?? account.username,
          radius: PlusDims.avatar / 2,
        ),
        null,
        account.displayName ?? account.username,
      ),
      UnifiedAccounts() => (null, Icons.merge_type, 'All accounts'),
      CustomTimelineSelected() => (
        null,
        Icons.dashboard_customize_outlined,
        'Custom timeline',
      ),
      NoSelection() => (null, null, 'GGLP'),
    };

    final streamLabel = switch (selection) {
      CustomTimelineSelected(:final timelineId) => () {
        final t = customTimelines.cast<dynamic>().firstWhere(
          (t) => t.id == timelineId,
          orElse: () => null,
        );
        return t == null ? 'Custom timeline' : (t.name as String);
      }(),
      _ => streamLabelFor(_kind),
    };

    // Stream changes crossfade — the lists are keyed per
    // (selection, kind), so the switcher sees a new child on switch.
    final timelineBody = AnimatedSwitcher(
      duration: PlusMotion.reduced(context, PlusMotion.surface),
      switchInCurve: PlusMotion.easeEnter,
      switchOutCurve: PlusMotion.easeExit,
      child: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (accounts) {
          if (accounts.isEmpty) return const _EmptyState();
          return switch (selection) {
            NoSelection() => const _EmptyState(),
            SingleAccount(:final account) => _TimelineList(
              key: ValueKey('${account.id}/${_kind.key}'),
              account: account,
              kind: _kind,
            ),
            UnifiedAccounts() => _UnifiedTimelineList(
              key: ValueKey('unified/${_kind.key}'),
              kind: _kind,
            ),
            CustomTimelineSelected(:final timelineId) => _CustomTimelineList(
              key: ValueKey('custom/$timelineId'),
              timelineId: timelineId,
            ),
          };
        },
      ),
    );

    return PopScope(
      // System back closes the menu before popping anything.
      canPop: !_menuOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeMenu();
      },
      child: Scaffold(
        appBar: IdentityAppBar(
          label: label,
          avatar: identityAvatar,
          glyph: identityGlyph,
          desktop: desktop,
          menuOpen: _menuOpen,
          onToggleMenu: _toggleMenu,
          actions: [
            if (canPick)
              PlusIconButton(
                tooltip: 'Search',
                icon: Icons.search,
                onBrand: true,
                onTap: () => _openSearch(accounts, selection),
              ),
            ActivityBell(
              accounts: accounts,
              selection: selection,
              customTimelines: customTimelines,
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert),
              onSelected:
                  (v) =>
                      _handleOverflow(v, accounts, selection, customTimelines),
              itemBuilder:
                  (_) => [
                    if (canPick)
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Text('Refresh'),
                      ),
                    if (canPick && _canRewind(selection))
                      const PopupMenuItem(
                        value: 'rewind',
                        child: Text('Rewind (time machine)'),
                      ),
                    if (accounts.isNotEmpty) ...const [
                      PopupMenuItem(
                        value: 'channels',
                        child: Text('Browse channels'),
                      ),
                      PopupMenuItem(
                        value: 'antennas',
                        child: Text('Browse antennas'),
                      ),
                    ],
                    const PopupMenuItem(
                      value: 'settings',
                      child: Text('Settings'),
                    ),
                    const PopupMenuItem(
                      value: 'help',
                      child: Text('Keyboard shortcuts'),
                    ),
                  ],
            ),
          ],
        ),
        // Free-floating compose disc, 16px inset — no bottom
        // bar on phones.
        floatingActionButton:
            !canPick
                ? null
                : PlusComposeDisc(
                  shrunk: _composerOpen,
                  onPressed:
                      () => _composeNew(accounts, selection, customTimelines),
                ),
        body: CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            // n  → new note
            const SingleActivator(LogicalKeyboardKey.keyN):
                () => _composeNew(accounts, selection, customTimelines),
            // r  → refresh active timeline
            const SingleActivator(LogicalKeyboardKey.keyR):
                () => _refreshActive(selection),
            // ?  → keyboard-shortcut help
            const SingleActivator(LogicalKeyboardKey.slash, shift: true):
                () => _showHelp(),
            // .  → toggle the navigation menu
            const SingleActivator(LogicalKeyboardKey.period): _toggleMenu,
          },
          child: Focus(
            autofocus: true,
            child: Stack(
              children: [
                Column(
                  children: [
                    TimelineStreamBar(
                      label: streamLabel,
                      kind: showKindPicker ? _kind : null,
                      onKindSelected:
                          showKindPicker
                              ? (k) => setState(() => _kind = k)
                              : null,
                      onRefresh:
                          canPick ? () => _refreshActive(selection) : null,
                    ),
                    Expanded(
                      // Chronological feeds stay single-column; on
                      // wide layouts the column is capped.
                      child:
                          desktop
                              ? Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: PlusDims.feedMaxWidth,
                                  ),
                                  child: timelineBody,
                                ),
                              )
                              : timelineBody,
                    ),
                  ],
                ),
                // Navigation menu: scrim + white surface
                // dropping in below the red bar. The bar itself stays
                // visible and interactive above this Stack. Mounted
                // only while open/animating; the status listener above
                // unmounts it after the reverse completes.
                if (!_menuController.isDismissed) ...[
                  AnimatedBuilder(
                    animation: _menuController,
                    builder:
                        (_, __) => PlusScrim(
                          light: true,
                          opacity: _menuController.value,
                          onTap: _closeMenu,
                        ),
                  ),
                  Align(
                    alignment:
                        desktop ? Alignment.topLeft : Alignment.topCenter,
                    child: FadeTransition(
                      opacity: _menuController,
                      child: AnimatedBuilder(
                        animation: _menuController,
                        builder:
                            (context, child) => Transform.translate(
                              offset: Offset(
                                0,
                                PlusMotion.reduce(context)
                                    ? 0
                                    : -PlusMotion.distSm *
                                        (1 - _menuController.value),
                              ),
                              child: child,
                            ),
                        child: _MenuSurface(
                          width: desktop ? PlusDims.navPanelWidth : null,
                          child: NavigationMenu(onClose: _closeMenu),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleOverflow(
    String value,
    List<Account> accounts,
    TimelineSelection selection,
    List<dynamic> customTimelines,
  ) async {
    switch (value) {
      case 'refresh':
        _refreshActive(selection);
      case 'rewind':
        await _openTimeMachine(accounts, selection);
      case 'channels':
        await _openBrowseChannels(accounts, selection);
      case 'antennas':
        await _openBrowseAntennas(accounts, selection);
      case 'settings':
        if (mounted) await SettingsScreen.open(context);
      case 'help':
        _showHelp();
    }
  }

  Future<void> _composeNew(
    List<Account> accounts,
    TimelineSelection selection,
    List<dynamic> customTimelines,
  ) async {
    if (accounts.isEmpty) return;
    Account? poster;
    switch (selection) {
      case SingleAccount(:final account):
        poster = account;
      case CustomTimelineSelected(:final timelineId):
        final t = customTimelines.cast<dynamic>().firstWhere(
          (t) => t.id == timelineId,
          orElse: () => null,
        );
        if (t != null && (t.sources as List).isNotEmpty) {
          final firstId = (t.sources as List).first.accountId as String;
          poster = accounts.cast<Account?>().firstWhere(
            (a) => a!.id == firstId,
            orElse: () => null,
          );
        }
      case UnifiedAccounts():
      case NoSelection():
        break;
    }
    poster ??= accounts.first;
    // The disc scales away while the composer owns the screen and
    // reclaims its place when it closes.
    setState(() => _composerOpen = true);
    try {
      await ComposeScreen.open(context, account: poster);
    } finally {
      if (mounted) setState(() => _composerOpen = false);
    }
  }

  void _refreshActive(TimelineSelection selection) {
    switch (selection) {
      case SingleAccount(:final account):
        ref
            .read(
              timelineControllerProvider(TimelineArgs(account, _kind)).notifier,
            )
            .refresh();
      case UnifiedAccounts():
        ref.read(unifiedTimelineControllerProvider(_kind).notifier).refresh();
      case CustomTimelineSelected(:final timelineId):
        ref
            .read(customTimelineControllerProvider(timelineId).notifier)
            .refresh();
      case NoSelection():
        break;
    }
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (_) => const _ShortcutsHelpDialog(),
    );
  }

  /// True when the active selection has a single deterministic source
  /// we can rewind through. Custom timelines are excluded because
  /// they're built from heterogeneous (account, kind) sources;
  /// rewinding one of them would be ambiguous.
  bool _canRewind(TimelineSelection selection) =>
      selection is SingleAccount || selection is UnifiedAccounts;

  Future<void> _openTimeMachine(
    List<Account> accounts,
    TimelineSelection selection,
  ) async {
    if (accounts.isEmpty) return;
    Account? target;
    switch (selection) {
      case SingleAccount(:final account):
        target = account;
      case UnifiedAccounts():
        target =
            accounts.length == 1
                ? accounts.first
                : await _pickAccount(accounts, 'Rewind which account?');
      case CustomTimelineSelected():
      case NoSelection():
        return;
    }
    if (target == null || !mounted) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2010),
      lastDate: now,
      initialDate: now,
      helpText: 'Rewind to date',
    );
    if (picked == null || !mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => TimeMachineScreen(
              account: target!,
              source: TimeMachineKindSource(_kind),
              startDate: picked,
            ),
      ),
    );
  }

  Future<Account?> _pickAccount(List<Account> accounts, String title) {
    return showModalBottomSheet<Account>(
      context: context,
      showDragHandle: true,
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(title),
                  ),
                ),
                for (final a in accounts)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(a.displayName ?? a.username),
                    subtitle: Text('@${a.username}@${a.host}'),
                    onTap: () => Navigator.of(sheetContext).pop(a),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  /// App-bar entry point for note/user/hashtag search. Same
  /// account-pick semantics as the footer-bar sheets.
  Future<void> _openSearch(
    List<Account> accounts,
    TimelineSelection selection,
  ) async {
    final picked = await _pickAccountForSheet(
      accounts,
      selection,
      title: 'Search as…',
    );
    if (picked == null || !mounted) return;
    await SearchScreen.open(context, account: picked);
  }

  /// Footer-bar entry point for browsing the active account's followed/
  /// featured/searchable channels. Mirrors the drawer's "Browse channels"
  /// tile but stays in the timeline shell so the user doesn't have to
  /// open the drawer first. If the user has multiple accounts and the
  /// current selection isn't tied to one, we ask which to act on.
  Future<void> _openBrowseChannels(
    List<Account> accounts,
    TimelineSelection selection,
  ) async {
    final picked = await _pickAccountForSheet(
      accounts,
      selection,
      title: 'Browse channels from…',
    );
    if (picked == null || !mounted) return;
    await BrowseChannelsSheet.show(context, account: picked);
  }

  /// Footer-bar entry point for browsing the active account's antennas.
  /// Same account-pick semantics as [_openBrowseChannels].
  Future<void> _openBrowseAntennas(
    List<Account> accounts,
    TimelineSelection selection,
  ) async {
    final picked = await _pickAccountForSheet(
      accounts,
      selection,
      title: 'Antennas from…',
    );
    if (picked == null || !mounted) return;
    await BrowseAntennasSheet.show(context, account: picked);
  }

  /// Resolve which account a footer-bar action should target.
  ///
  /// - Single-account user: that account, no prompt.
  /// - Selection is `SingleAccount`: that account.
  /// - Otherwise: ask via [_pickAccount].
  ///
  /// Returns null if the user cancels or there are no accounts.
  Future<Account?> _pickAccountForSheet(
    List<Account> accounts,
    TimelineSelection selection, {
    required String title,
  }) async {
    if (accounts.isEmpty) return null;
    if (accounts.length == 1) return accounts.first;
    if (selection is SingleAccount) return selection.account;
    return _pickAccount(accounts, title);
  }
}

/// Tiny help overlay listing the keyboard shortcuts. Opened by `?`
/// on a hardware keyboard. Mirrors what we register in [_TimelineScreenState.build].
class _ShortcutsHelpDialog extends StatelessWidget {
  const _ShortcutsHelpDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    // Keycaps as flat bordered rectangles.
    Widget row(String key, String desc) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: plus.surfaceSubtle,
              borderRadius: BorderRadius.circular(PlusRadii.chip),
              border: Border.all(color: plus.border),
            ),
            child: Text(
              key,
              style: TextStyle(
                fontFamily: 'monospace',
                fontFamilyFallback: const ['Menlo', 'Consolas'],
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(desc)),
        ],
      ),
    );
    return AlertDialog(
      title: const Text('Keyboard shortcuts'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row('n', 'New note'),
          row('r', 'Refresh timeline'),
          row('.', 'Open menu'),
          row('?', 'Show this help'),
          row('Esc', 'Close dialog / popup'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _TimelineList extends ConsumerStatefulWidget {
  final Account account;
  final TimelineKind kind;
  const _TimelineList({super.key, required this.account, required this.kind});

  @override
  ConsumerState<_TimelineList> createState() => _TimelineListState();
}

/// Shared reconcile machinery for the three animated timeline lists.
///
/// Each list mirrors its controller's list into [rows] and drives a
/// [SliverAnimatedList] with explicit insert/remove calls. The mixin
/// owns the parts that are identical across them:
///
///   - one post-frame reconcile per frame, no matter how many state
///     emissions land in that frame (a busy stream used to enqueue one
///     reconcile per emission, each diffing the whole list)
///   - a persistent id set so the diff doesn't rebuild it per pass
///   - batched head insertions (one `insertAll` per run) with a cap on
///     how many rows animate at once, so a burst can't spawn dozens of
///     concurrent AnimationControllers
///   - scroll-position hysteresis for the hold-pending toggle
mixin _AnimatedTimelineList<W extends ConsumerStatefulWidget, T>
    on ConsumerState<W> {
  final scroll = ScrollController();
  final listKey = GlobalKey<SliverAnimatedListState>();

  /// Mirror of the controller's list. The animated list state is
  /// driven by explicit insert/remove calls, so we track exactly what's
  /// currently mounted ourselves and diff each rebuild.
  final List<T> rows = [];

  /// Ids of [rows], maintained on insert/remove.
  final Set<String> _mountedIds = {};

  List<T>? _pendingNext;
  bool _reconcileScheduled = false;
  bool _holdRequested = false;

  /// Hold-pending hysteresis (px). Engage once the user is clearly
  /// away from the head; only release when they're back at it. A
  /// single threshold flipped the mode on every tick while a finger
  /// rested near the boundary.
  static const _holdEngagePx = 48.0;
  static const _holdReleasePx = 16.0;

  static const _insertDuration = Duration(milliseconds: 180);
  static const _removeDuration = Duration(milliseconds: 160);

  /// Rows beyond this many in one insert run land without animation.
  static const _maxAnimatedInserts = 3;

  /// Identity a row is keyed and diffed by.
  String idOf(T item);

  /// Build the (animated) row for [item].
  Widget buildRow(T item, Animation<double> animation);

  void setHoldPending(bool hold);

  @override
  void initState() {
    super.initState();
    scroll.addListener(onScroll);
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void onScroll();

  void maybeUpdateHoldPending() {
    final px = scroll.position.pixels;
    final shouldHold =
        _holdRequested ? px > _holdReleasePx : px > _holdEngagePx;
    _holdRequested = shouldHold;
    // The controller early-returns when unchanged, so calling every
    // tick is cheap and re-syncs after a refresh reset the flag.
    setHoldPending(shouldHold);
  }

  /// Called from `build`. Seeds synchronously when the animated list
  /// isn't mounted (first frame, or returning from the loading/error
  /// branch) so it is built with the right `initialItemCount` and the
  /// initial page renders without a burst of insert animations;
  /// otherwise schedules at most one post-frame reconcile.
  void syncWith(List<T> next) {
    if (listKey.currentState == null) {
      _seed(next);
    } else {
      _scheduleReconcile(next);
    }
  }

  void _seed(List<T> next) {
    _pendingNext = null;
    rows
      ..clear()
      ..addAll(next);
    _mountedIds
      ..clear()
      ..addAll(next.map(idOf));
  }

  void _scheduleReconcile(List<T> next) {
    _pendingNext = next;
    if (_reconcileScheduled) return;
    _reconcileScheduled = true;
    // Reconcile in a post-frame so we don't mutate AnimatedList state
    // during a build phase (which would assert in debug).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reconcileScheduled = false;
      final target = _pendingNext;
      _pendingNext = null;
      if (!mounted || target == null) return;
      _reconcile(target);
    });
  }

  /// Reconcile the mounted list against the latest controller list.
  ///
  /// Strategy: identify items by [idOf]. Walk both lists; emit inserts
  /// for new ids (preferring the head, where streamed notes always
  /// land), and `removeItem` for ids no longer present. We don't try
  /// to diff *order* changes — the controller never reorders, only
  /// prepends, appends, or removes.
  void _reconcile(List<T> next) {
    if (!mounted) return;
    final state = listKey.currentState;
    if (state == null) {
      _seed(next);
      return;
    }

    // Ids computed once per pass; every row id is a fresh string.
    final ids = [for (final it in next) idOf(it)];
    var newCount = 0;
    for (final id in ids) {
      if (!_mountedIds.contains(id)) newCount++;
    }

    // Removals first so subsequent inserts use the right indices. On
    // the common pure-prepend path (every mounted row survives) the
    // length check lets us skip building the removal set entirely.
    if (next.length < rows.length + newCount) {
      final nextIds = ids.toSet();
      for (var i = rows.length - 1; i >= 0; i--) {
        final item = rows[i];
        final id = idOf(item);
        if (nextIds.contains(id)) continue;
        rows.removeAt(i);
        _mountedIds.remove(id);
        state.removeItem(
          i,
          (context, animation) => buildRow(item, animation),
          duration: _removeDuration,
        );
      }
    }

    // Insertions: walk the next list; gather runs of consecutive new
    // ids and insert each run in one go at its position in the
    // mounted list.
    var runStart = -1;
    final run = <T>[];
    void flushRun() {
      if (run.isEmpty) return;
      // Cap the index at rows.length so a brand-new tail item still
      // inserts in-bounds.
      final at = runStart.clamp(0, rows.length);
      rows.insertAll(at, run);
      for (final it in run) {
        _mountedIds.add(idOf(it));
      }
      final animated = run.length.clamp(0, _maxAnimatedInserts);
      state.insertAllItems(at, animated, duration: _insertDuration);
      if (run.length > animated) {
        state.insertAllItems(
          at + animated,
          run.length - animated,
          duration: Duration.zero,
        );
      }
      run.clear();
      runStart = -1;
    }

    for (var i = 0; i < next.length; i++) {
      if (_mountedIds.contains(ids[i])) {
        flushRun();
        continue;
      }
      if (run.isEmpty) runStart = i;
      run.add(next[i]);
    }
    flushRun();
  }

  /// Banner tap: drain pending into the visible list and animate scroll
  /// to the new top.
  void scrollToTop() {
    if (!scroll.hasClients) return;
    scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Widget buildAnimatedList() => SliverAnimatedList(
        key: listKey,
        initialItemCount: rows.length,
        itemBuilder: (context, index, animation) {
          if (index >= rows.length) {
            return const SizedBox.shrink();
          }
          return buildRow(rows[index], animation);
        },
      );
}

class _TimelineListState extends ConsumerState<_TimelineList>
    with _AnimatedTimelineList<_TimelineList, Note> {
  TimelineArgs get _args => TimelineArgs(widget.account, widget.kind);

  @override
  String idOf(Note item) => item.globalId;

  @override
  void setHoldPending(bool hold) =>
      ref.read(timelineControllerProvider(_args).notifier).setHoldPending(hold);

  @override
  void onScroll() {
    if (!scroll.hasClients) return;
    _maybeLoadMore();
    maybeUpdateHoldPending();
  }

  void _maybeLoadMore() {
    if (scroll.position.pixels >= scroll.position.maxScrollExtent - 400) {
      ref.read(timelineControllerProvider(_args).notifier).loadMore();
    }
  }

  void _onBannerTap() {
    ref.read(timelineControllerProvider(_args).notifier).releasePending();
    scrollToTop();
  }

  @override
  Widget buildRow(Note note, Animation<double> animation) {
    final args = _args;
    // Key computed once per row build; the selector below is then a
    // plain map lookup with no allocation, so re-running it for every
    // mounted row on every emission is cheap.
    final key = note.globalId;
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      axisAlignment: -1, // align to top so it slides down from above
      child: FadeTransition(
        opacity: animation,
        // Subscribe to the latest Note for this globalId via Riverpod
        // `select`. SliverAnimatedList caches its built children so a
        // simple itemBuilder rebuild doesn't pick up reaction patches.
        // Watching the controller here gives the row direct edge to
        // controller state changes (reactions, edits) without forcing
        // a full list reconcile.
        child: Consumer(
          builder: (context, ref, _) {
            final live = ref.watch(
              timelineControllerProvider(args).select(
                (async) => async.valueOrNull?.byId[key],
              ),
            );
            // Fall back to the snapshot the reconciler captured so an
            // animating-out row keeps its content.
            final shown = live ?? note;
            // Dense continuous stream: flat full-width rows scored
            // apart by a groove, instead of stacked raised cards.
            // Row tap (anywhere no inner control claims) opens the
            // thread; inner tappables win the gesture arena.
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap:
                  () => ThreadScreen.open(
                    context,
                    account: widget.account,
                    note: shown,
                  ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CapturedNoteCard(
                    key: ValueKey(key),
                    note: shown,
                    attributionAccount: widget.account,
                    stream: true,
                  ),
                  const PlusDivider(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    final state = ref.watch(timelineControllerProvider(args));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => _ErrorBlock(
            message: '$e',
            onRetry:
                () =>
                    ref
                        .read(timelineControllerProvider(args).notifier)
                        .refresh(),
          ),
      data: (s) {
        syncWith(s.notes);

        return Column(
          children: [
            _ConnectionBanner(phase: s.connectionPhase),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh:
                        () =>
                            ref
                                .read(timelineControllerProvider(args).notifier)
                                .refresh(),
                    child: CustomScrollView(
                      controller: scroll,
                      slivers: [
                        buildAnimatedList(),
                        SliverToBoxAdapter(
                          child:
                              s.reachedEnd
                                  ? const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(child: Text('— end —')),
                                  )
                                  : const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Floating "new notes" banner — only when there's
                  // something to release. Position above the list so
                  // tapping doesn't fight scroll gestures.
                  if (s.pending.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _NewNotesBanner(
                          count: s.pending.length,
                          onTap: _onBannerTap,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Resolve which account a merged row is attributed to. Falls back to
/// the first account (the row still renders, under a best-effort
/// identity) when the delivering account has been removed, and to null
/// when there are no accounts at all — the caller skips the row rather
/// than throwing mid-animation.
Account? _attributionFor(WidgetRef ref, String accountId) {
  final accounts = ref.read(accountsProvider).valueOrNull ?? const <Account>[];
  for (final a in accounts) {
    if (a.id == accountId) return a;
  }
  return accounts.isEmpty ? null : accounts.first;
}

/// Row for a merged (unified / custom) list. Watches the live item by
/// originId through [select] so reaction patches land in this row even
/// though SliverAnimatedList caches its built children.
Widget _buildMergedRow({
  required WidgetRef ref,
  required MergedTimelineItem item,
  required Animation<double> animation,
  required ProviderListenable<MergedTimelineItem?> live,
}) {
  final attribution = _attributionFor(ref, item.accountId);
  if (attribution == null) return const SizedBox.shrink();
  final key = item.originId;
  return SizeTransition(
    sizeFactor: CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ),
    axisAlignment: -1,
    child: FadeTransition(
      opacity: animation,
      child: Consumer(
        builder: (context, ref, _) {
          final shown = ref.watch(live) ?? item;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap:
                () => ThreadScreen.open(
                  context,
                  account: attribution,
                  note: shown.note,
                ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CapturedNoteCard(
                  key: ValueKey(key),
                  note: shown.note,
                  attributionAccount: attribution,
                  stream: true,
                ),
                const PlusDivider(),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _UnifiedTimelineList extends ConsumerStatefulWidget {
  final TimelineKind kind;
  const _UnifiedTimelineList({super.key, required this.kind});

  @override
  ConsumerState<_UnifiedTimelineList> createState() =>
      _UnifiedTimelineListState();
}

class _UnifiedTimelineListState extends ConsumerState<_UnifiedTimelineList>
    with _AnimatedTimelineList<_UnifiedTimelineList, MergedTimelineItem> {
  // Use originId for the unified list so the same federated note
  // delivered by multiple accounts is one row across edits/merges.
  @override
  String idOf(MergedTimelineItem item) => item.originId;

  @override
  void setHoldPending(bool hold) => ref
      .read(unifiedTimelineControllerProvider(widget.kind).notifier)
      .setHoldPending(hold);

  @override
  void onScroll() {
    if (!scroll.hasClients) return;
    _maybeLoadMore();
    maybeUpdateHoldPending();
  }

  void _maybeLoadMore() {
    if (scroll.position.pixels >= scroll.position.maxScrollExtent - 400) {
      ref
          .read(unifiedTimelineControllerProvider(widget.kind).notifier)
          .loadMore();
    }
  }

  void _onBannerTap() {
    ref
        .read(unifiedTimelineControllerProvider(widget.kind).notifier)
        .releasePending();
    scrollToTop();
  }

  @override
  Widget buildRow(MergedTimelineItem item, Animation<double> animation) {
    final key = item.originId;
    return _buildMergedRow(
      ref: ref,
      item: item,
      animation: animation,
      live: unifiedTimelineControllerProvider(widget.kind).select(
        (async) => async.valueOrNull?.byId[key],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(unifiedTimelineControllerProvider(widget.kind));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => _ErrorBlock(
            message: '$e',
            onRetry:
                () =>
                    ref
                        .read(
                          unifiedTimelineControllerProvider(
                            widget.kind,
                          ).notifier,
                        )
                        .refresh(),
          ),
      data: (s) {
        syncWith(s.items);
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh:
                  () =>
                      ref
                          .read(
                            unifiedTimelineControllerProvider(
                              widget.kind,
                            ).notifier,
                          )
                          .refresh(),
              child: CustomScrollView(
                controller: scroll,
                slivers: [
                  buildAnimatedList(),
                  SliverToBoxAdapter(
                    child:
                        s.reachedEnd
                            ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: Text('— end —')),
                            )
                            : const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                  ),
                ],
              ),
            ),
            if (s.pending.isNotEmpty)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: _NewNotesBanner(
                    count: s.pending.length,
                    onTap: _onBannerTap,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// User-defined custom unified timeline. Same UX as [_UnifiedTimelineList]
/// (animated list, scroll-position-aware pending banner, post-frame
/// reconcile, per-row Riverpod `select` for live reaction patches) but
/// driven by [customTimelineControllerProvider] which fans out to
/// arbitrary `(account, kind, channelId)` sources.
class _CustomTimelineList extends ConsumerStatefulWidget {
  final String timelineId;
  const _CustomTimelineList({super.key, required this.timelineId});

  @override
  ConsumerState<_CustomTimelineList> createState() =>
      _CustomTimelineListState();
}

class _CustomTimelineListState extends ConsumerState<_CustomTimelineList>
    with _AnimatedTimelineList<_CustomTimelineList, MergedTimelineItem> {
  @override
  String idOf(MergedTimelineItem item) => item.originId;

  @override
  void setHoldPending(bool hold) => ref
      .read(customTimelineControllerProvider(widget.timelineId).notifier)
      .setHoldPending(hold);

  @override
  void onScroll() {
    if (!scroll.hasClients) return;
    if (scroll.position.pixels >= scroll.position.maxScrollExtent - 400) {
      ref
          .read(customTimelineControllerProvider(widget.timelineId).notifier)
          .loadMore();
    }
    maybeUpdateHoldPending();
  }

  void _onBannerTap() {
    ref
        .read(customTimelineControllerProvider(widget.timelineId).notifier)
        .releasePending();
    scrollToTop();
  }

  @override
  Widget buildRow(MergedTimelineItem item, Animation<double> animation) {
    final key = item.originId;
    return _buildMergedRow(
      ref: ref,
      item: item,
      animation: animation,
      live: customTimelineControllerProvider(widget.timelineId).select(
        (async) => async.valueOrNull?.byId[key],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      customTimelineControllerProvider(widget.timelineId),
    );
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => _ErrorBlock(
            message: '$e',
            onRetry:
                () =>
                    ref
                        .read(
                          customTimelineControllerProvider(
                            widget.timelineId,
                          ).notifier,
                        )
                        .refresh(),
          ),
      data: (s) {
        syncWith(s.items);
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh:
                  () =>
                      ref
                          .read(
                            customTimelineControllerProvider(
                              widget.timelineId,
                            ).notifier,
                          )
                          .refresh(),
              child: CustomScrollView(
                controller: scroll,
                slivers: [
                  buildAnimatedList(),
                  SliverToBoxAdapter(
                    child:
                        s.reachedEnd
                            ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: Text('— end —')),
                            )
                            : const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                  ),
                ],
              ),
            ),
            if (s.pending.isNotEmpty)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: _NewNotesBanner(
                    count: s.pending.length,
                    onTap: _onBannerTap,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NewNotesBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NewNotesBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = count == 1 ? '1 new note' : '$count new notes';
    // Compact "New notes" control floating over the stream:
    // white raised rectangle, blue label.
    return PlusButton.raised(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_upward, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.primary),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  final ConnectionPhase phase;
  const _ConnectionBanner({required this.phase});

  @override
  Widget build(BuildContext context) {
    if (phase == ConnectionPhase.connected) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final (label, color) = switch (phase) {
      ConnectionPhase.connecting => (
        'Connecting…',
        theme.colorScheme.secondary,
      ),
      ConnectionPhase.reconnecting => (
        'Reconnecting…',
        theme.colorScheme.tertiary,
      ),
      ConnectionPhase.failed => (
        'Live updates unavailable',
        theme.colorScheme.error,
      ),
      ConnectionPhase.disconnected => (
        'Offline — pull to refresh',
        theme.colorScheme.onSurfaceVariant,
      ),
      ConnectionPhase.connected => ('', Colors.transparent),
    };
    return Material(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child:
                  phase == ConnectionPhase.connecting ||
                          phase == ConnectionPhase.reconnecting
                      ? CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: color,
                      )
                      : Icon(Icons.cloud_off, size: 12, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 64,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 20),
          const Text('No accounts yet.'),
          const SizedBox(height: 16),
          PlusButton.raised(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddAccountScreen()),
                ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Add account',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: scheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            PlusButton.text(
              onTap: onRetry,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 18),
                  SizedBox(width: 8),
                  Text('Retry'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White surface hosting the navigation menu below the app bar: full
/// content width on phones, a 320px anchored panel on wide layouts
class _MenuSurface extends StatelessWidget {
  final double? width;
  final Widget child;
  const _MenuSurface({required this.child, this.width});

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    return Container(
      width: width ?? double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      decoration: BoxDecoration(
        color: plus.surface,
        border:
            plus.isDark ? Border(bottom: BorderSide(color: plus.border)) : null,
        boxShadow: plus.isDark ? null : plus.shadowMenu,
      ),
      child: child,
    );
  }
}
