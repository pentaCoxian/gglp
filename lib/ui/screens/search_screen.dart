import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/note.dart';
import '../plus/plus.dart';
import '../widgets/note_card.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_display_name.dart';
import 'user_profile_screen.dart';

/// Full-screen search over the given account's server.
///
/// Three modes, switched by flat underline tabs under the search
/// field:
///   - Notes:   `notes/search` — dense stream rows with untilId
///              pagination. Some servers disable this endpoint; the
///              error state carries a hint about that.
///   - Users:   `users/search` — white card rows, tap opens the
///              profile via the (username, host) handle bridge.
///   - Hashtag: `notes/search-by-tag` — same stream rows/pagination;
///              a leading `#` in the input is stripped before the
///              call.
class SearchScreen extends ConsumerStatefulWidget {
  final Account account;
  final String? initialQuery;
  final String? initialTag;

  const SearchScreen({
    super.key,
    required this.account,
    this.initialQuery,
    this.initialTag,
  });

  /// Push the search screen for [account]. [initialTag] (a hashtag
  /// WITHOUT the `#`) preselects hashtag mode and searches
  /// immediately; [initialQuery] pre-fills notes search.
  static Future<void> open(
    BuildContext context, {
    required Account account,
    String? initialQuery,
    String? initialTag,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(
          account: account,
          initialQuery: initialQuery,
          initialTag: initialTag,
        ),
      ),
    );
  }

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

enum _SearchMode { notes, users, hashtag }

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  Timer? _debounce;

  _SearchMode _mode = _SearchMode.notes;

  /// The committed (debounced) query text driving the results view.
  String _query = '';

  /// Focus the field when the screen opens without anything to show.
  late final bool _autofocus;

  @override
  void initState() {
    super.initState();
    final tag = widget.initialTag?.trim() ?? '';
    final seed = tag.isNotEmpty ? tag : (widget.initialQuery?.trim() ?? '');
    if (tag.isNotEmpty) _mode = _SearchMode.hashtag;
    _query = seed;
    _autofocus = seed.isEmpty;
    _controller = TextEditingController(text: seed);
    // Rebuild on every keystroke so the clear button tracks whether
    // the field is non-empty (the *results* only follow the debounce).
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  /// Commit immediately (Enter / search key), skipping the debounce.
  void _commitNow(String value) {
    _debounce?.cancel();
    setState(() => _query = value.trim());
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() => _query = '');
  }

  /// Effective hashtag: user input minus a leading `#`.
  String get _tag {
    final q = _query;
    return (q.startsWith('#') ? q.substring(1) : q).trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          // Flat underline search field straight from the theme.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: TextField(
              controller: _controller,
              autofocus: _autofocus,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: Icon(
                  _mode == _SearchMode.hashtag ? Icons.tag : Icons.search,
                ),
                hintText: switch (_mode) {
                  _SearchMode.notes => 'Search notes…',
                  _SearchMode.users => 'Search users…',
                  _SearchMode.hashtag => 'Search a hashtag…',
                },
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close),
                        color: theme.colorScheme.onSurfaceVariant,
                        onPressed: _clear,
                      ),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _commitNow,
            ),
          ),
          // Flat mode tabs: the active mode gets a 2px blue underline.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _ModeChip(
                    label: 'Notes',
                    selected: _mode == _SearchMode.notes,
                    onTap: () => setState(() => _mode = _SearchMode.notes),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeChip(
                    label: 'Users',
                    selected: _mode == _SearchMode.users,
                    onTap: () => setState(() => _mode = _SearchMode.users),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeChip(
                    label: 'Hashtag',
                    selected: _mode == _SearchMode.hashtag,
                    onTap: () =>
                        setState(() => _mode = _SearchMode.hashtag),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final host = widget.account.host;
    switch (_mode) {
      case _SearchMode.notes:
        if (_query.isEmpty) {
          return _CenteredMessage('Type to search notes on $host.');
        }
        return _PagedNoteResults(
          key: ValueKey('notes/${widget.account.id}/$_query'),
          account: widget.account,
          mode: _SearchMode.notes,
          query: _query,
        );
      case _SearchMode.users:
        if (_query.isEmpty) {
          return _CenteredMessage('Type to search users on $host.');
        }
        return _UserResults(account: widget.account, query: _query);
      case _SearchMode.hashtag:
        final tag = _tag;
        if (tag.isEmpty) {
          return _CenteredMessage(
              'Type a hashtag to browse notes on $host.');
        }
        return _PagedNoteResults(
          key: ValueKey('tag/${widget.account.id}/$tag'),
          account: widget.account,
          mode: _SearchMode.hashtag,
          query: tag,
        );
    }
  }
}

/// Flat 2014-style mode tab: 48px tall, secondary-gray label at rest,
/// primary label plus a 2px blue underline when active.
class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip({
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
        height: 48,
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
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? plus.textPrimary : plus.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Dense-stream note results with untilId infinite scroll. Handles
/// both free-text (`notes/search`) and hashtag
/// (`notes/search-by-tag`) queries; the hosting screen keys this
/// widget by (mode, query) so a new search resets the state.
class _PagedNoteResults extends ConsumerStatefulWidget {
  final Account account;
  final _SearchMode mode;

  /// Free text for [_SearchMode.notes]; the bare tag (no `#`) for
  /// [_SearchMode.hashtag].
  final String query;

  const _PagedNoteResults({
    super.key,
    required this.account,
    required this.mode,
    required this.query,
  });

  @override
  ConsumerState<_PagedNoteResults> createState() =>
      _PagedNoteResultsState();
}

class _PagedNoteResultsState extends ConsumerState<_PagedNoteResults> {
  static const _limit = 30;

  final _scroll = ScrollController();
  final List<Note> _notes = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _reachedEnd = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<List<Note>> _fetch(String? untilId) async {
    final endpoints =
        await ref.read(misskeyEndpointsProvider(widget.account).future);
    if (endpoints == null) {
      throw StateError('Account is not signed in.');
    }
    return switch (widget.mode) {
      _SearchMode.hashtag => endpoints.notesSearchByTag(
          tag: widget.query,
          limit: _limit,
          untilId: untilId,
        ),
      _ => endpoints.notesSearch(
          query: widget.query,
          limit: _limit,
          untilId: untilId,
        ),
    };
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _fetch(null);
      if (!mounted) return;
      setState(() {
        _notes
          ..clear()
          ..addAll(page);
        _reachedEnd = page.length < _limit;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _reachedEnd || _notes.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetch(_notes.last.id);
      if (!mounted) return;
      setState(() {
        final seen = {for (final n in _notes) n.id};
        _notes.addAll(page.where((n) => !seen.contains(n.id)));
        _reachedEnd = page.length < _limit;
        _loadingMore = false;
      });
    } catch (_) {
      // Pagination failures are non-fatal: keep what we have and let a
      // further scroll retry.
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null) {
      return _SearchErrorBlock(
        message: 'Search failed.',
        detail: '$error',
        hint: 'This server may have search disabled.',
        onRetry: _loadInitial,
      );
    }
    if (_notes.isEmpty) {
      final what = widget.mode == _SearchMode.hashtag
          ? 'No notes tagged #${widget.query}.'
          : 'No notes match "${widget.query}".';
      return _CenteredMessage(what);
    }
    // Dense continuous stream: flat full-width rows separated by a
    // hairline rule, matching the timeline convention.
    return ListView.builder(
      controller: _scroll,
      itemCount: _notes.length + 1,
      itemBuilder: (context, i) {
        if (i >= _notes.length) {
          return _reachedEnd
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('— end —')),
                )
              : const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
        }
        final note = _notes[i];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NoteCard(
              key: ValueKey(note.id),
              note: note,
              attributionAccount: widget.account,
              stream: true,
            ),
            const PlusDivider(),
          ],
        );
      },
    );
  }
}

/// User search results: white card rows that open the profile via the
/// (username, host) handle bridge, so the id stays local to the
/// viewer's own server.
class _UserResults extends ConsumerWidget {
  final Account account;
  final String query;
  const _UserResults({required this.account, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final key = (account, query);
    return ref.watch(_usersSearchProvider(key)).when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => _SearchErrorBlock(
            message: 'User search failed.',
            detail: '$e',
            onRetry: () => ref.invalidate(_usersSearchProvider(key)),
          ),
          data: (users) {
            if (users.isEmpty) {
              return _CenteredMessage('No users match "$query".');
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: users.length,
              itemBuilder: (context, i) {
                final raw = users[i];
                final username = raw['username'] as String? ?? '';
                final name = raw['name'] as String?;
                final userHost = raw['host'] as String?;
                final handle =
                    '@$username@${userHost ?? account.host}';
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 5, horizontal: 14),
                  child: PlusCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    onTap: username.isEmpty
                        ? null
                        : () => UserProfileScreen.openByHandle(
                              context,
                              viewerAccount: account,
                              username: username,
                              userHost: userHost,
                            ),
                    child: Row(
                      children: [
                        UserAvatar(
                          url: raw['avatarUrl'] as String?,
                          seed: (name?.isNotEmpty ?? false)
                              ? name!
                              : username,
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              UserDisplayName(
                                name: (name?.isNotEmpty ?? false)
                                    ? name!
                                    : username,
                                viewerHost: account.host,
                                style: theme.textTheme.bodyLarge,
                              ),
                              Text(
                                handle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
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

/// Friendly centered prompt / empty-state text.
class _CenteredMessage extends StatelessWidget {
  final String message;
  const _CenteredMessage(this.message);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Error state with the raw server message, an optional hint (used
/// for the "this server disabled notes/search" case), and a flat
/// retry button.
class _SearchErrorBlock extends StatelessWidget {
  final String message;
  final String detail;
  final String? hint;
  final VoidCallback onRetry;
  const _SearchErrorBlock({
    required this.message,
    required this.detail,
    required this.onRetry,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 6),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 12),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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

/// One shot of `users/search` per (account, query) — the same
/// provider-per-query pattern the channel browser uses, so results
/// cache while the query is unchanged and dispose when it isn't.
final _usersSearchProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, (Account, String)>((ref, key) async {
  final endpoints =
      await ref.watch(misskeyEndpointsProvider(key.$1).future);
  if (endpoints == null) return const [];
  if (key.$2.isEmpty) return const [];
  return endpoints.usersSearch(query: key.$2);
});
