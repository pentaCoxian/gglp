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

/// Inbox of pending follow requests made TO [account] (locked
/// accounts approve followers by hand).
///
/// Rows come from `following/requests/list`; each entry wraps the
/// requesting user under `follower`, and the wrapper's own `id` is the
/// `untilId` pagination cursor. Accept / reject act on the *follower
/// user's* id and remove the row locally on success.
class FollowRequestsScreen extends ConsumerStatefulWidget {
  final Account account;

  const FollowRequestsScreen({super.key, required this.account});

  static Future<void> open(
    BuildContext context, {
    required Account account,
  }) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FollowRequestsScreen(account: account),
      ));

  @override
  ConsumerState<FollowRequestsScreen> createState() =>
      _FollowRequestsScreenState();
}

/// One decoded request row: the wrapper id (pagination cursor) plus
/// the parsed requesting user.
class _RequestRow {
  final String cursorId;
  final User user;
  const _RequestRow({required this.cursorId, required this.user});
}

class _FollowRequestsScreenState
    extends ConsumerState<FollowRequestsScreen> {
  static const _pageSize = 30;

  final _scroll = ScrollController();
  final _rows = <_RequestRow>[];

  /// Follower user ids with an accept/reject in flight, so their row's
  /// buttons disable instead of double-firing.
  final _busyUserIds = <String>{};

  bool _loading = false;
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

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
      _rows.clear();
      _reachedEnd = false;
    });
    try {
      final (page, endReached) = await _fetch(untilId: null);
      if (!mounted) return;
      setState(() {
        _rows.addAll(page);
        _loading = false;
        _reachedEnd = endReached;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_rows.isEmpty || _loading || _reachedEnd) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (page, endReached) = await _fetch(untilId: _rows.last.cursorId);
      if (!mounted) return;
      setState(() {
        _rows.addAll(page);
        _loading = false;
        _reachedEnd = endReached;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<(List<_RequestRow>, bool)> _fetch({String? untilId}) async {
    final endpoints =
        await ref.read(misskeyEndpointsProvider(widget.account).future);
    if (endpoints == null) {
      throw StateError('Account is not available.');
    }
    final raw = await endpoints.followingRequestsList(
      limit: _pageSize,
      untilId: untilId,
    );
    final rows = <_RequestRow>[];
    for (final r in raw) {
      final cursorId = r['id'] as String?;
      final userJson = r['follower'];
      if (cursorId == null || userJson is! Map<String, dynamic>) continue;
      rows.add(_RequestRow(
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

  Future<void> _respond(_RequestRow row, {required bool accept}) async {
    final userId = row.user.id;
    final handle =
        '@${row.user.username}@${row.user.host ?? widget.account.host}';
    setState(() => _busyUserIds.add(userId));
    try {
      final endpoints =
          await ref.read(misskeyEndpointsProvider(widget.account).future);
      if (endpoints == null) {
        throw StateError('Account is not available.');
      }
      if (accept) {
        await endpoints.followingRequestsAccept(userId);
      } else {
        await endpoints.followingRequestsReject(userId);
      }
      if (!mounted) return;
      setState(() {
        _busyUserIds.remove(userId);
        _rows.removeWhere((r) => r.user.id == userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(accept
            ? 'Accepted follow request from $handle'
            : 'Rejected follow request from $handle'),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyUserIds.remove(userId));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Failed to ${accept ? 'accept' : 'reject'} request: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Follow requests')),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading && _rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load follow requests.',
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: 6),
              Text(
                '$_error',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              PlusButton.text(
                onTap: _loadInitial,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadInitial,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(theme: theme),
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
          if (i == _rows.length) {
            if (_reachedEnd) return const SizedBox(height: 12);
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildRow(theme, _rows[i]);
        },
      ),
    );
  }

  Widget _buildRow(ThemeData theme, _RequestRow row) {
    final user = row.user;
    final handle = '@${user.username}@${user.host ?? widget.account.host}';
    final busy = _busyUserIds.contains(user.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
      child: PlusCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () => UserProfileScreen.openByHandle(
          context,
          viewerAccount: widget.account,
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
                    viewerHost: widget.account.host,
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
            const SizedBox(width: 8),
            PlusIconButton(
              icon: Icons.check,
              tooltip: 'Accept',
              color: theme.colorScheme.primary,
              onTap: busy ? null : () => _respond(row, accept: true),
            ),
            const SizedBox(width: 8),
            PlusIconButton(
              icon: Icons.close,
              tooltip: 'Reject',
              color: theme.colorScheme.error,
              onTap: busy ? null : () => _respond(row, accept: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty inbox: a flat bordered square holding the placeholder icon —
/// the same "empty slot" affordance as the timeline empty state.
class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: plus.surfaceSubtle,
              borderRadius: BorderRadius.circular(PlusRadii.card),
              border: Border.all(color: plus.border),
            ),
            child: Icon(
              Icons.how_to_reg_outlined,
              size: 48,
              color: plus.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No pending follow requests.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
