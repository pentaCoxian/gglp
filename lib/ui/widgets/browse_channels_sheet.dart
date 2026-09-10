import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/note_channel.dart';
import '../plus/plus.dart';
import '../screens/channel_timeline_screen.dart';

/// Bottom sheet for discovering channels on the active account's
/// server.
///
/// Three tabs:
///   - Mine: favorites ∪ owned ∪ followed (`channels/my-favorites`,
///     `channels/owned`, `channels/followed`). Requires the
///     `read:channels` scope; if the token doesn't have it, Misskey
///     403s and the sheet error-arms with a hint to re-auth.
///   - Featured: `channels/featured`. No-credential endpoint — works
///     regardless of scope and gives a useful fallback list when the
///     user hasn't joined anything yet.
///   - Search: `channels/search`. Free-text. Also no-credential.
///
/// In browse mode (`show`) tapping a row opens the channel timeline
/// scoped to this account. In pick mode (`pick`) the sheet pops with
/// the tapped channel so the composer can target it.
class BrowseChannelsSheet extends ConsumerStatefulWidget {
  final Account account;

  /// When true, rows return a [NoteChannel] via `Navigator.pop`
  /// instead of navigating to the channel timeline.
  final bool pickMode;

  /// Channel to mark as current in pick mode.
  final String? selectedChannelId;

  const BrowseChannelsSheet({
    super.key,
    required this.account,
    this.pickMode = false,
    this.selectedChannelId,
  });

  static Future<void> show(
    BuildContext context, {
    required Account account,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BrowseChannelsSheet(account: account),
    );
  }

  /// Picker flavour for the composer. Resolves to the chosen channel,
  /// or null when dismissed without choosing.
  static Future<NoteChannel?> pick(
    BuildContext context, {
    required Account account,
    String? selectedChannelId,
  }) {
    return showModalBottomSheet<NoteChannel>(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => BrowseChannelsSheet(
            account: account,
            pickMode: true,
            selectedChannelId: selectedChannelId,
          ),
    );
  }

  @override
  ConsumerState<BrowseChannelsSheet> createState() =>
      _BrowseChannelsSheetState();
}

class _BrowseChannelsSheetState extends ConsumerState<BrowseChannelsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    // Keep the flat mode tabs in sync when the TabBarView is swiped
    // (the tabs replace the stock TabBar as tab selectors).
    _tabs.addListener(_onTabIndexChanged);
  }

  void _onTabIndexChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tabs.removeListener(_onTabIndexChanged);
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
    });
  }

  void _onSelect(Map<String, dynamic> raw) {
    final id = raw['id'] as String? ?? '';
    final name = raw['name'] as String? ?? id;
    if (widget.pickMode) {
      Navigator.of(context).pop(
        NoteChannel(
          id: id,
          name: name,
          color: raw['color'] as String?,
          isSensitive: raw['isSensitive'] == true,
        ),
      );
      return;
    }
    Navigator.of(context).pop();
    ChannelTimelineScreen.open(
      context,
      account: widget.account,
      channelId: id,
      initialName: name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Size against the viewport that's actually free: the keyboard
    // (Search tab) shrinks it, and `size.height` alone would leave the
    // fixed-height column overflowing behind the keyboard.
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final free = MediaQuery.sizeOf(context).height - insets;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        child: SizedBox(
          height: (free * 0.75).clamp(240.0, free),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.pickMode ? 'Post to channel' : 'Channels',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '@${widget.account.username}@${widget.account.host}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Flat mode tabs: the active tab gets primary text and a
              // 2px blue underline (2014 tab styling).
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabChip(
                        label: 'Mine',
                        selected: _tabs.index == 0,
                        onTap: () => _tabs.animateTo(0),
                      ),
                    ),
                    Expanded(
                      child: _TabChip(
                        label: 'Featured',
                        selected: _tabs.index == 1,
                        onTap: () => _tabs.animateTo(1),
                      ),
                    ),
                    Expanded(
                      child: _TabChip(
                        label: 'Search',
                        selected: _tabs.index == 2,
                        onTap: () => _tabs.animateTo(2),
                      ),
                    ),
                  ],
                ),
              ),
              const PlusDivider(),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _ChannelsList(
                      futureProvider: _channelsMineProvider(widget.account),
                      emptyMessage:
                          "You aren't following or running any channels "
                          "on ${widget.account.host} yet — try Featured "
                          'to discover some.',
                      notFollowingHint: true,
                      selectedChannelId: widget.selectedChannelId,
                      onSelect: _onSelect,
                    ),
                    _ChannelsList(
                      futureProvider:
                          _channelsFeaturedProvider(widget.account),
                      emptyMessage: 'No featured channels right now.',
                      selectedChannelId: widget.selectedChannelId,
                      onSelect: _onSelect,
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          // Plain field: the theme's underline input
                          // decoration provides the flat 2014 look.
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              isDense: true,
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Search channels…',
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                        Expanded(
                          child:
                              _searchQuery.isEmpty
                                  ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        'Type to search channels '
                                        'on ${widget.account.host}.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color:
                                              theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  )
                                  : _ChannelsList(
                                    futureProvider: _channelsSearchProvider((
                                      widget.account,
                                      _searchQuery,
                                    )),
                                    emptyMessage:
                                        'No channels match "$_searchQuery".',
                                    selectedChannelId:
                                        widget.selectedChannelId,
                                    onSelect: _onSelect,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flat mode tab standing in for a TabBar tab: secondary text when
/// idle, primary text plus a 2px blue underline when active.
class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? plus.selected : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? plus.textPrimary : plus.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ChannelsList extends ConsumerWidget {
  final ProviderListenable<AsyncValue<List<Map<String, dynamic>>>>
  futureProvider;
  final String emptyMessage;
  final bool notFollowingHint;
  final String? selectedChannelId;
  final void Function(Map<String, dynamic> raw) onSelect;
  const _ChannelsList({
    required this.futureProvider,
    required this.emptyMessage,
    required this.onSelect,
    this.selectedChannelId,
    this.notFollowingHint = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    return ref
        .watch(futureProvider)
        .when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Failed to load channels.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$e',
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (notFollowingHint) ...[
                        const SizedBox(height: 12),
                        Text(
                          'If this account was added before channels '
                          'were enabled, remove and re-add it to grant '
                          'the new permissions.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          data: (channels) {
            if (channels.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    emptyMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }
            // Flat white rows with an ink press state (2014 list
            // styling).
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: channels.length,
              itemBuilder: (_, i) {
                final c = channels[i];
                final id = c['id'] as String? ?? '';
                final name = c['name'] as String? ?? id;
                final color = parseChannelColor(c['color'] as String?);
                final desc = c['description'] as String? ?? '';
                final usersCount = c['usersCount'] as int?;
                final notesCount = c['notesCount'] as int?;
                final selected = selectedChannelId != null && id == selectedChannelId;
                return InkWell(
                  onTap: () => onSelect(c),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color ?? theme.colorScheme.primary,
                          child: const Icon(
                            Icons.tag,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge,
                              ),
                              if (desc.isNotEmpty)
                                Text(
                                  desc,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (usersCount != null || notesCount != null)
                                Text(
                                  [
                                    if (usersCount != null)
                                      '$usersCount members',
                                    if (notesCount != null)
                                      '$notesCount notes',
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.check, size: 20, color: plus.selected),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
  }
}

/// Parses Misskey's `#rrggbb` / `#rrggbbaa` channel colour. Null for
/// anything else so callers fall back to the theme accent.
Color? parseChannelColor(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final hex = raw.replaceAll('#', '');
  final padded = switch (hex.length) {
    6 => 'ff$hex',
    8 => hex,
    _ => null,
  };
  if (padded == null) return null;
  final p = int.tryParse(padded, radix: 16);
  return p == null ? null : Color(p);
}

Future<List<Map<String, dynamic>>> _orEmpty(
  Future<List<Map<String, dynamic>>> f,
) async {
  try {
    return await f;
  } catch (_) {
    return const [];
  }
}

/// favorites ∪ owned ∪ followed, in that order, de-duplicated by id.
/// `channels/followed` is the load-bearing call (its 403 is what
/// surfaces the missing-scope hint); the other two are additive and
/// tolerated when a server lacks the endpoint.
final _channelsMineProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Account>((ref, account) async {
      final endpoints = await ref.watch(misskeyEndpointsProvider(account).future);
      if (endpoints == null) return const [];
      final results = await Future.wait([
        _orEmpty(endpoints.channelsMyFavorites()),
        _orEmpty(endpoints.channelsOwned()),
        endpoints.channelsFollowed(),
      ]);
      final seen = <String>{};
      final merged = <Map<String, dynamic>>[];
      for (final list in results) {
        for (final c in list) {
          final id = c['id'] as String?;
          if (id == null || !seen.add(id)) continue;
          merged.add(c);
        }
      }
      return merged;
    });

final _channelsFeaturedProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Account>((ref, account) async {
      final endpoints = await ref.watch(misskeyEndpointsProvider(account).future);
      if (endpoints == null) return const [];
      return endpoints.channelsFeatured();
    });

final _channelsSearchProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, (Account, String)>((ref, key) async {
      final endpoints = await ref.watch(misskeyEndpointsProvider(key.$1).future);
      if (endpoints == null) return const [];
      if (key.$2.isEmpty) return const [];
      return endpoints.channelsSearch(query: key.$2);
    });
