import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../misskey/models/account.dart';
import '../../timeline/custom_timeline.dart';
import '../../timeline/timeline_source.dart';
import '../plus/plus.dart';

/// Create or edit a custom unified timeline.
///
/// Pass [existing] to edit (the screen pre-fills name and sources);
/// omit it to create a fresh timeline.
class ManageCustomTimelineScreen extends ConsumerStatefulWidget {
  final CustomTimeline? existing;
  const ManageCustomTimelineScreen({super.key, this.existing});

  static Future<void> open(BuildContext context, {CustomTimeline? existing}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ManageCustomTimelineScreen(existing: existing),
      ),
    );
  }

  @override
  ConsumerState<ManageCustomTimelineScreen> createState() =>
      _ManageCustomTimelineScreenState();
}

class _ManageCustomTimelineScreenState
    extends ConsumerState<ManageCustomTimelineScreen> {
  late final TextEditingController _name;
  late final List<TimelineSource> _sources;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _sources = [...?widget.existing?.sources];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _name.text.trim().isNotEmpty && _sources.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null
            ? 'New custom timeline'
            : 'Edit timeline'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: const Text('Save'),
          ),
          if (widget.existing != null)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            // Flat underline input straight from the theme.
            child: TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sources',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          Expanded(
            child: _sources.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Add at least one source to start.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                    itemCount: _sources.length,
                    onReorder: _onReorder,
                    itemBuilder: (_, i) {
                      final s = _sources[i];
                      return _SourceTile(
                        key: ValueKey(s.fingerprint),
                        source: s,
                        onRemove: () => setState(() => _sources.removeAt(i)),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSource,
        icon: const Icon(Icons.add),
        label: const Text('Add source'),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      // ReorderableListView semantics: newIndex is post-removal.
      var to = newIndex;
      if (to > oldIndex) to -= 1;
      final item = _sources.removeAt(oldIndex);
      _sources.insert(to, item);
    });
  }

  Future<void> _addSource() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? const [];
    if (accounts.isEmpty) {
      _toast('Add an account first.');
      return;
    }
    final picked = await showModalBottomSheet<TimelineSource>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AddSourceSheet(accounts: accounts),
    );
    if (picked == null) return;
    if (_sources.contains(picked)) {
      _toast('That source is already in the timeline.');
      return;
    }
    setState(() => _sources.add(picked));
  }

  Future<void> _save() async {
    final dao = ref.read(customTimelineDaoProvider);
    final now = DateTime.now();
    final timeline = CustomTimeline(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      sortOrder: widget.existing?.sortOrder ?? now.millisecondsSinceEpoch,
      sources: List.unmodifiable(_sources),
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
    await dao.upsert(timeline);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete timeline?'),
        content: Text('"${existing.name}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(customTimelineDaoProvider).removeById(existing.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _SourceTile extends ConsumerWidget {
  final TimelineSource source;
  final VoidCallback onRemove;
  const _SourceTile({
    super.key,
    required this.source,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
    final account =
        accounts.firstWhereOrNull((a) => a.id == source.accountId);
    final theme = Theme.of(context);
    final kindIcon = switch (source.kind) {
      TimelineSourceKind.home => Icons.home_outlined,
      TimelineSourceKind.local => Icons.location_city_outlined,
      TimelineSourceKind.hybrid => Icons.merge_type,
      TimelineSourceKind.global => Icons.public,
      TimelineSourceKind.channel => Icons.tag,
      TimelineSourceKind.antenna => Icons.satellite_alt_outlined,
    };
    final kindLabel = switch (source.kind) {
      TimelineSourceKind.home => 'Home',
      TimelineSourceKind.local => 'Local',
      TimelineSourceKind.hybrid => 'Hybrid',
      TimelineSourceKind.global => 'Global',
      TimelineSourceKind.channel => 'Channel',
      TimelineSourceKind.antenna => 'Antenna',
    };
    final accountLabel = account == null
        ? '(missing) ${source.accountId}'
        : '@${account.username}@${account.host}';
    // Flat white Plus card.
    return PlusCard(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(kindIcon, color: theme.colorScheme.primary),
        title: Row(
          children: [
            Text(kindLabel, style: theme.textTheme.titleSmall),
            if (source.kind == TimelineSourceKind.channel &&
                source.channelId != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '#${source.channelId}',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (source.kind == TimelineSourceKind.antenna &&
                source.antennaId != null) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  source.antennaId!,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(accountLabel,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        trailing: PlusIconButton(
          icon: Icons.remove_circle_outline,
          tooltip: 'Remove source',
          size: 18,
          onTap: onRemove,
        ),
      ),
    );
  }
}

/// Two-step bottom sheet: pick an account, then pick a kind. If the
/// kind is `channel`, push another sheet for channel selection from
/// `channels/followed`.
class _AddSourceSheet extends ConsumerStatefulWidget {
  final List<Account> accounts;
  const _AddSourceSheet({required this.accounts});

  @override
  ConsumerState<_AddSourceSheet> createState() => _AddSourceSheetState();
}

class _AddSourceSheetState extends ConsumerState<_AddSourceSheet> {
  Account? _account;

  @override
  void initState() {
    super.initState();
    if (widget.accounts.length == 1) _account = widget.accounts.first;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Snapshot the picked account once; the kind callbacks await a
    // nested sheet, so they must not re-read (and force-unwrap) state
    // that may have changed by the time they resume.
    final account = _account;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  account == null ? 'Pick account' : 'Pick kind',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            Expanded(
              child: account == null
                  ? _AccountList(
                      accounts: widget.accounts,
                      onPick: (a) => setState(() => _account = a),
                    )
                  : _KindList(
                      account: account,
                      onChangeAccount: () => setState(() => _account = null),
                      onPick: (kind) async {
                        if (kind == TimelineSourceKind.channel) {
                          final picked = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (_) =>
                                _ChannelPickerSheet(account: account),
                          );
                          if (picked == null || !context.mounted) return;
                          Navigator.of(context).pop(
                            TimelineSource(
                              accountId: account.id,
                              kind: TimelineSourceKind.channel,
                              channelId: picked,
                            ),
                          );
                          return;
                        }
                        if (kind == TimelineSourceKind.antenna) {
                          final picked = await showModalBottomSheet<String>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (_) =>
                                _AntennaPickerSheet(account: account),
                          );
                          if (picked == null || !context.mounted) return;
                          Navigator.of(context).pop(
                            TimelineSource(
                              accountId: account.id,
                              kind: TimelineSourceKind.antenna,
                              antennaId: picked,
                            ),
                          );
                          return;
                        }
                        Navigator.of(context).pop(
                          TimelineSource(
                            accountId: account.id,
                            kind: kind,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountList extends StatelessWidget {
  final List<Account> accounts;
  final ValueChanged<Account> onPick;
  const _AccountList({required this.accounts, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: accounts.length,
      itemBuilder: (_, i) {
        final a = accounts[i];
        return ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(a.displayName ?? a.username),
          subtitle: Text('@${a.username}@${a.host}'),
          onTap: () => onPick(a),
        );
      },
    );
  }
}

class _KindList extends StatelessWidget {
  final Account account;
  final VoidCallback onChangeAccount;
  final ValueChanged<TimelineSourceKind> onPick;
  const _KindList({
    required this.account,
    required this.onChangeAccount,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '@${account.username}@${account.host}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Change'),
                onPressed: onChangeAccount,
              ),
            ],
          ),
        ),
        const PlusDivider(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final k in TimelineSourceKind.values)
                ListTile(
                  leading: Icon(_iconFor(k)),
                  title: Text(_labelFor(k)),
                  subtitle: Text(_descFor(k),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  onTap: () => onPick(k),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static IconData _iconFor(TimelineSourceKind k) => switch (k) {
        TimelineSourceKind.home => Icons.home_outlined,
        TimelineSourceKind.local => Icons.location_city_outlined,
        TimelineSourceKind.hybrid => Icons.merge_type,
        TimelineSourceKind.global => Icons.public,
        TimelineSourceKind.channel => Icons.tag,
        TimelineSourceKind.antenna => Icons.satellite_alt_outlined,
      };
  static String _labelFor(TimelineSourceKind k) => switch (k) {
        TimelineSourceKind.home => 'Home',
        TimelineSourceKind.local => 'Local',
        TimelineSourceKind.hybrid => 'Hybrid',
        TimelineSourceKind.global => 'Global',
        TimelineSourceKind.channel => 'Channel…',
        TimelineSourceKind.antenna => 'Antenna…',
      };
  static String _descFor(TimelineSourceKind k) => switch (k) {
        TimelineSourceKind.home => 'Notes from people you follow',
        TimelineSourceKind.local => 'Notes from this server',
        TimelineSourceKind.hybrid => 'Home + local',
        TimelineSourceKind.global => 'Every public note this server sees',
        TimelineSourceKind.channel => 'Pick a Misskey channel',
        TimelineSourceKind.antenna =>
          "Notes matching one of this account's antennas",
      };
}

class _ChannelPickerSheet extends ConsumerWidget {
  final Account account;
  const _ChannelPickerSheet({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Followed channels',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Expanded(
              child: ref.watch(_channelsFollowedProvider(account)).when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Failed to load channels: $e'),
                      ),
                    ),
                    data: (channels) {
                      if (channels.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              "You aren't following any channels on "
                              "${account.host}.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: channels.length,
                        itemBuilder: (_, i) {
                          final c = channels[i];
                          final id = c['id'] as String? ?? '';
                          final name = c['name'] as String? ?? id;
                          final color = c['color'] as String?;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _parseHex(color) ??
                                  Theme.of(context).colorScheme.primary,
                              child: const Icon(Icons.tag,
                                  color: Colors.white, size: 18),
                            ),
                            title: Text(name),
                            subtitle: Text(id),
                            onTap: () => Navigator.of(context).pop(id),
                          );
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  static Color? _parseHex(String? raw) {
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
}

/// Per-account `channels/followed` snapshot. autoDispose so the request
/// doesn't linger after the sheet closes.
final _channelsFollowedProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Account>((ref, account) async {
  final endpoints =
      await ref.watch(misskeyEndpointsProvider(account).future);
  if (endpoints == null) return const [];
  return endpoints.channelsFollowed();
});

class _AntennaPickerSheet extends ConsumerWidget {
  final Account account;
  const _AntennaPickerSheet({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Antennas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            Expanded(
              child: ref.watch(_antennasListProvider(account)).when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Failed to load antennas: $e'),
                      ),
                    ),
                    data: (antennas) {
                      if (antennas.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              "You haven't created any antennas on "
                              "${account.host} yet.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: antennas.length,
                        itemBuilder: (_, i) {
                          final a = antennas[i];
                          final id = a['id'] as String? ?? '';
                          final name = a['name'] as String? ?? id;
                          final keywords = (a['keywords'] as List?)
                                  ?.expand((g) => (g as List).cast<String>())
                                  .join(', ') ??
                              '';
                          return ListTile(
                            leading: const Icon(Icons.satellite_alt_outlined),
                            title: Text(name),
                            subtitle: keywords.isEmpty
                                ? null
                                : Text(
                                    keywords,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            onTap: () => Navigator.of(context).pop(id),
                          );
                        },
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-account `antennas/list` snapshot.
final _antennasListProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Account>((ref, account) async {
  final endpoints =
      await ref.watch(misskeyEndpointsProvider(account).future);
  if (endpoints == null) return const [];
  return endpoints.antennasList();
});
