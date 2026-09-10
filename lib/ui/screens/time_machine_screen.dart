import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../misskey/http/endpoint_registry.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/note.dart';
import '../../timeline/timeline_kind.dart';
import '../plus/plus.dart';
import '../widgets/captured_note_card.dart';

/// Read-only "rewind" view of a timeline starting at a specific date.
///
/// Used as a non-destructive companion to the live timeline: pulls
/// notes with `untilDate` so the user can scroll backwards from a
/// chosen point in history without disturbing the streaming feed.
/// Streaming and reaction-patches are intentionally NOT wired — the
/// whole point of this screen is to show a frozen window into the past.
///
/// Source kinds supported:
///   - per-account (home / local / hybrid / global)
///   - one Misskey channel
///   - one Misskey antenna
class TimeMachineScreen extends ConsumerStatefulWidget {
  final Account account;
  final TimeMachineSource source;
  final DateTime startDate;

  const TimeMachineScreen({
    super.key,
    required this.account,
    required this.source,
    required this.startDate,
  });

  @override
  ConsumerState<TimeMachineScreen> createState() =>
      _TimeMachineScreenState();
}

/// What we're rewinding through.
sealed class TimeMachineSource {
  const TimeMachineSource();
  String get label;
}

class TimeMachineKindSource extends TimeMachineSource {
  final TimelineKind kind;
  const TimeMachineKindSource(this.kind);
  @override
  String get label => switch (kind) {
        TimelineKind.home => 'Home',
        TimelineKind.local => 'Local',
        TimelineKind.hybrid => 'Hybrid',
        TimelineKind.global => 'Global',
      };
}

class TimeMachineChannelSource extends TimeMachineSource {
  final String channelId;
  final String? channelName;
  const TimeMachineChannelSource({
    required this.channelId,
    this.channelName,
  });
  @override
  String get label => '#${channelName ?? channelId}';
}

class TimeMachineAntennaSource extends TimeMachineSource {
  final String antennaId;
  final String? antennaName;
  const TimeMachineAntennaSource({
    required this.antennaId,
    this.antennaName,
  });
  @override
  String get label => 'Antenna · ${antennaName ?? antennaId}';
}

class _TimeMachineScreenState extends ConsumerState<TimeMachineScreen> {
  static const _pageSize = 30;

  final _scroll = ScrollController();
  final _notes = <Note>[];
  bool _loading = false;
  bool _reachedEnd = false;
  Object? _error;
  late DateTime _anchor;

  @override
  void initState() {
    super.initState();
    _anchor = widget.startDate;
    _scroll.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loading || _reachedEnd) return;
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      _loadOlder();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final endpoints = await ref
          .read(misskeyEndpointsProvider(widget.account).future);
      if (endpoints == null) return;
      final page = await _fetch(endpoints, untilDate: _anchor);
      if (!mounted) return;
      setState(() {
        _notes
          ..clear()
          ..addAll(page);
        _loading = false;
        _reachedEnd = page.length < _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _loadOlder() async {
    if (_notes.isEmpty) return;
    setState(() => _loading = true);
    try {
      final endpoints = await ref
          .read(misskeyEndpointsProvider(widget.account).future);
      if (endpoints == null) return;
      // After the first page we have a real `untilId` cursor; that's
      // more efficient than stepping with `untilDate` again because
      // the server can use its own ordered index.
      final older = await _fetch(endpoints, untilId: _notes.last.id);
      if (!mounted) return;
      setState(() {
        _notes.addAll(older);
        _loading = false;
        _reachedEnd = older.length < _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<List<Note>> _fetch(
    MisskeyEndpoints endpoints, {
    DateTime? untilDate,
    String? untilId,
  }) {
    final src = widget.source;
    if (src is TimeMachineKindSource) {
      switch (src.kind) {
        case TimelineKind.home:
          return endpoints.homeTimeline(
              limit: _pageSize, untilDate: untilDate, untilId: untilId);
        case TimelineKind.local:
          return endpoints.localTimeline(
              limit: _pageSize, untilDate: untilDate, untilId: untilId);
        case TimelineKind.hybrid:
          return endpoints.hybridTimeline(
              limit: _pageSize, untilDate: untilDate, untilId: untilId);
        case TimelineKind.global:
          return endpoints.globalTimeline(
              limit: _pageSize, untilDate: untilDate, untilId: untilId);
      }
    } else if (src is TimeMachineChannelSource) {
      return endpoints.channelTimeline(
        channelId: src.channelId,
        limit: _pageSize,
        untilDate: untilDate,
        untilId: untilId,
      );
    } else if (src is TimeMachineAntennaSource) {
      return endpoints.antennasNotes(
        antennaId: src.antennaId,
        limit: _pageSize,
        untilDate: untilDate,
        untilId: untilId,
      );
    }
    return Future.value(const []);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2010),
      lastDate: now,
      initialDate: _anchor.isAfter(now) ? now : _anchor,
      helpText: 'Rewind to date',
    );
    if (picked == null) return;
    setState(() => _anchor = picked);
    _loadFirstPage();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.history, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Rewind · ${widget.source.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pick date',
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Rewind banner: the date readout sits in a flat bordered
          // rect, with a flat blue "Change" action as the jump control.
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: PlusTheme.of(context).surfaceSubtle,
                      borderRadius:
                          BorderRadius.circular(PlusRadii.card),
                      border: Border.all(
                          color: PlusTheme.of(context).border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.history,
                            size: 16, color: theme.colorScheme.tertiary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Read-only window starting '
                            '${_formatDate(_anchor)}.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PlusButton.text(
                  onTap: _pickDate,
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _notes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to rewind: $_error'),
        ),
      );
    }
    if (_notes.isEmpty) {
      return const Center(child: Text('No notes around this date.'));
    }
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notes.length + 1,
        itemBuilder: (_, i) {
          if (i == _notes.length) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: _reachedEnd
                    ? const Text('— end —')
                    : const CircularProgressIndicator(),
              ),
            );
          }
          return CapturedNoteCard(
            key: ValueKey(_notes[i].globalId),
            note: _notes[i],
            attributionAccount: widget.account,
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
