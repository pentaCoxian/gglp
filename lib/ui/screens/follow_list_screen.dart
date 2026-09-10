import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/parsers.dart';
import '../../misskey/models/user.dart';
import '../plus/plus.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_display_name.dart';
import 'user_profile_screen.dart';

/// Followers / Following list for a single user, viewed from
/// [account]'s server.
///
/// Two soft-UI mode chips at the top switch between the two relations
/// in place (no re-push). Rows come from `users/followers` /
/// `users/following`, whose entries are follow-relation wrappers:
/// the user payload lives under `follower` / `followee` and the
/// wrapper's own `id` is the `untilId` pagination cursor.
class FollowListScreen extends ConsumerStatefulWidget {
  final Account account;
  final String userId;
  final bool followers;
  final String? displayName;

  const FollowListScreen({
    super.key,
    required this.account,
    required this.userId,
    required this.followers,
    this.displayName,
  });

  static Future<void> open(
    BuildContext context, {
    required Account account,
    required String userId,
    required bool followers,
    String? displayName,
  }) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FollowListScreen(
          account: account,
          userId: userId,
          followers: followers,
          displayName: displayName,
        ),
      ));

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

/// One decoded relation row: the wrapper id (pagination cursor) plus
/// the parsed user it points at.
class _FollowRow {
  final String cursorId;
  final User user;
  const _FollowRow({required this.cursorId, required this.user});
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
  static const _pageSize = 30;

  final _scroll = ScrollController();
  final _rows = <_FollowRow>[];
  bool _showFollowers = true;
  bool _loading = false;
  bool _reachedEnd = false;
  Object? _error;

  /// Bumped on every fresh load so a slow response for the previous
  /// mode can't land in the list after the user switched chips.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _showFollowers = widget.followers;
    _scroll.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final gen = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _rows.clear();
      _reachedEnd = false;
    });
    try {
      final (page, endReached) = await _fetch(untilId: null);
      if (!mounted || gen != _generation) return;
      setState(() {
        _rows.addAll(page);
        _loading = false;
        _reachedEnd = endReached;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_rows.isEmpty || _loading || _reachedEnd) return;
    final gen = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (page, endReached) = await _fetch(untilId: _rows.last.cursorId);
      if (!mounted || gen != _generation) return;
      setState(() {
        _rows.addAll(page);
        _loading = false;
        _reachedEnd = endReached;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  /// Fetch one page for the active mode. Returns the decoded rows and
  /// whether the server signalled the end (short page).
  Future<(List<_FollowRow>, bool)> _fetch({String? untilId}) async {
    final endpoints =
        await ref.read(misskeyEndpointsProvider(widget.account).future);
    if (endpoints == null) {
      throw StateError('Account is not available.');
    }
    final followers = _showFollowers;
    final raw = followers
        ? await endpoints.usersFollowers(
            userId: widget.userId,
            limit: _pageSize,
            untilId: untilId,
          )
        : await endpoints.usersFollowing(
            userId: widget.userId,
            limit: _pageSize,
            untilId: untilId,
          );
    final rows = <_FollowRow>[];
    for (final r in raw) {
      final cursorId = r['id'] as String?;
      final userJson = r[followers ? 'follower' : 'followee'];
      if (cursorId == null || userJson is! Map<String, dynamic>) continue;
      rows.add(_FollowRow(
        cursorId: cursorId,
        user: MisskeyParsers.userFromJson(
          userJson,
          viewerHost: widget.account.host,
        ),
      ));
    }
    return (rows, raw.length < _pageSize);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_reachedEnd || _loading || _error != null) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  void _setMode({required bool followers}) {
    if (_showFollowers == followers) return;
    setState(() => _showFollowers = followers);
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        // Two stacked lines can outgrow the toolbar at large text
        // scales; bound the pair to the toolbar height and scale it
        // down to fit rather than spill past the bar.
        title: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height: AppBarTheme.of(context).toolbarHeight ?? kToolbarHeight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserDisplayName(
                      name: widget.displayName ?? 'User',
                      viewerHost: widget.account.host,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      _showFollowers ? 'Followers' : 'Following',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Flat mode tabs: the active relation gets a 2px blue
          // underline (2014 tab affordance).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _ModeChip(
                    label: 'Followers',
                    selected: _showFollowers,
                    onTap: () => _setMode(followers: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeChip(
                    label: 'Following',
                    selected: !_showFollowers,
                    onTap: () => _setMode(followers: false),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildList(theme)),
        ],
      ),
    );
  }

  Widget _buildList(ThemeData theme) {
    if (_loading && _rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _rows.isEmpty) {
      return _ErrorState(error: _error!, onRetry: _loadInitial);
    }
    if (_rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadInitial,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _showFollowers
                        ? 'No followers yet.'
                        : 'Not following anyone yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _rows.length + 1,
        itemBuilder: (_, i) {
          if (i == _rows.length) return _buildTail(theme);
          return _UserRow(account: widget.account, user: _rows[i].user);
        },
      ),
    );
  }

  Widget _buildTail(ThemeData theme) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: PlusButton.text(
            onTap: _loadMore,
            child: const Text('Retry'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: _reachedEnd
            ? Text(
                '— end —',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
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

/// White card row for one user; tap opens their profile from the
/// viewing account's perspective. The handle re-lookup in openByHandle
/// re-anchors federated ids onto the viewer's server.
class _UserRow extends StatelessWidget {
  final Account account;
  final User user;
  const _UserRow({required this.account, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handle = '@${user.username}@${user.host ?? account.host}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
      child: PlusCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () => UserProfileScreen.openByHandle(
          context,
          viewerAccount: account,
          username: user.username,
          userHost: user.host,
        ),
        child: Row(
          children: [
            UserAvatar(
              url: user.avatarUrl,
              seed: user.name ?? user.username,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserDisplayName(
                    name: user.name ?? user.username,
                    viewerHost: account.host,
                  ),
                  Text(
                    handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
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
  }
}

class _ErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load.', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 6),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            PlusButton.text(
              onTap: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
