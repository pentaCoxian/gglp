import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/note.dart';
import '../../misskey/models/parsers.dart';
import '../plus/plus.dart';
import '../widgets/note_card.dart';

/// The active account's bookmarks ("favorites" in Misskey API terms),
/// newest first.
///
/// `i/favorites` rows are `{id, createdAt, note}` — the wrapper `id`
/// is the pagination cursor (`untilId`), NOT the note id, so we keep
/// each cursor alongside its parsed note.
class BookmarksScreen extends ConsumerStatefulWidget {
  final Account account;

  const BookmarksScreen({super.key, required this.account});

  static Future<void> open(
    BuildContext context, {
    required Account account,
  }) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookmarksScreen(account: account),
        ),
      );

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  static const _pageSize = 30;

  final _scroll = ScrollController();

  /// Parsed rows: the wrapper cursor id + the bookmarked note.
  final List<({String cursorId, Note note})> _rows = [];

  bool _loading = false;
  bool _loadedOnce = false;
  bool _reachedEnd = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _load();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    if (_reachedEnd && !refresh) return;
    setState(() {
      _loading = true;
      if (refresh) _error = null;
    });
    try {
      final endpoints =
          await ref.read(misskeyEndpointsProvider(widget.account).future);
      if (endpoints == null) {
        throw StateError('No client for @${widget.account.username}');
      }
      final untilId =
          refresh || _rows.isEmpty ? null : _rows.last.cursorId;
      final raw = await endpoints.iFavorites(
        limit: _pageSize,
        untilId: untilId,
      );
      final parsed = <({String cursorId, Note note})>[];
      for (final j in raw) {
        final cursorId = j['id'] as String?;
        final noteJson = j['note'];
        if (cursorId == null || noteJson is! Map<String, dynamic>) continue;
        parsed.add((
          cursorId: cursorId,
          note: MisskeyParsers.noteFromJson(
            noteJson,
            sourceHost: widget.account.host,
          ),
        ));
      }
      if (!mounted) return;
      setState(() {
        if (refresh) _rows.clear();
        _rows.addAll(parsed);
        // End detection off the raw page size: a page shorter than the
        // limit means the server has nothing older.
        _reachedEnd = raw.length < _pageSize;
        _loadedOnce = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loadedOnce = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() => _load(refresh: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (!_loadedOnce) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _rows.isEmpty) {
      return _ErrorBlock(message: _error!, onRetry: _refresh);
    }
    if (_rows.isEmpty) {
      // Keep the empty state pull-to-refreshable: a full-height single
      // "row" inside an always-scrollable list.
      return RefreshIndicator(
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                child: const _EmptyState(),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _rows.length + 1,
        itemBuilder: (context, index) {
          if (index >= _rows.length) {
            // Footer: end marker or loading spinner for the next page.
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: _reachedEnd
                    ? const Text('— end —')
                    : const CircularProgressIndicator(),
              ),
            );
          }
          final row = _rows[index];
          // Dense stream row: flat full-width note + hairline rule,
          // matching the timeline's stream convention.
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NoteCard(
                key: ValueKey(row.cursorId),
                note: row.note,
                attributionAccount: widget.account,
                stream: true,
              ),
              const PlusDivider(),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Flat bordered square holding the placeholder icon — the
          // empty slot where bookmarked notes will live.
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: plus.surfaceSubtle,
              borderRadius: BorderRadius.circular(PlusRadii.card),
              border: Border.all(color: plus.border),
            ),
            child: Icon(
              Icons.bookmark_outline,
              size: 48,
              color: plus.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          const Text('No bookmarks yet.'),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
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
            const SizedBox(height: 16),
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
