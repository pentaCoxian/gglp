import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../mfm/parser.dart';
import '../../mfm/renderer.dart';
import '../../misskey/emoji/emoji_providers.dart';
import '../../misskey/http/endpoint_registry.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/note.dart';
import '../../misskey/models/parsers.dart';
import '../../timeline/note_actions_service.dart';
import '../plus/plus.dart';
import '../widgets/captured_note_card.dart';
import '../widgets/emoji_image.dart';
import '../widgets/net_image.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_display_name.dart';
import 'compose_screen.dart';
import 'follow_list_screen.dart';

/// Single-user profile view.
///
/// Two ways to open:
///   - by id (already-known): pass [userId] only.
///   - by handle (e.g. mention tap): pass [username] + optional
///     [userHost]. The screen calls `users/show?username=...&host=...`
///     to resolve, which on Misskey triggers a WebFinger lookup for
///     federated handles.
///
/// The viewing account is always [viewerAccount] — the screen renders
/// from that account's perspective, follow/unfollow happens on its
/// behalf, and the user-notes timeline is fetched from that account's
/// server. To view a profile with a different account, pop the screen
/// and re-open with the desired account.
class UserProfileScreen extends ConsumerStatefulWidget {
  final Account viewerAccount;
  final String? userId;
  final String? username;
  final String? userHost;

  const UserProfileScreen({
    super.key,
    required this.viewerAccount,
    this.userId,
    this.username,
    this.userHost,
  })  : assert(userId != null || username != null,
            'pass userId or username');

  static Future<void> openById(
    BuildContext context, {
    required Account viewerAccount,
    required String userId,
  }) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          viewerAccount: viewerAccount,
          userId: userId,
        ),
      ));

  static Future<void> openByHandle(
    BuildContext context, {
    required Account viewerAccount,
    required String username,
    String? userHost,
  }) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          viewerAccount: viewerAccount,
          username: username,
          userHost: userHost,
        ),
      ));

  @override
  ConsumerState<UserProfileScreen> createState() =>
      _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _followLoading = false;

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(_userProfileProvider((
      widget.viewerAccount,
      widget.userId,
      widget.username,
      widget.userHost,
    )));

    // Exactly one Scaffold per branch. A Follow toggle invalidates the
    // provider; skipping the loading state on reload/refresh keeps the
    // fetched profile on screen instead of swapping in a spinner.
    return infoAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load profile: $e'),
          ),
        ),
      ),
      data: (raw) {
        if (raw == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('User not found.')),
          );
        }
        final id = raw['id'] as String;
        final username = raw['username'] as String;
        final host = raw['host'] as String?;
        final handle =
            host == null ? '@$username' : '@$username@$host';
        // Ingest the user's display-name emoji block on every load
        // so the header renders with images even on first paint.
        MisskeyParsers.ingestUserEmojis(
          raw,
          viewerHost: widget.viewerAccount.host,
          repo: ref.read(emojiRepositoryProvider),
        );
        // Re-watch the catalog tick so display-name emoji upgrade
        // from text to image when fetched in the background.
        ref.watch(emojiCatalogTickProvider);
        return DefaultTabController(
          length: 2,
          animationDuration: PlusMotion.control,
          child: Scaffold(
            floatingActionButton: PlusComposeDisc(
              onPressed: () => ComposeScreen.open(
                context,
                account: widget.viewerAccount,
              ),
            ),
            body: NestedScrollView(
              headerSliverBuilder: (_, __) => [
                // The red bar stays stable; the
                // handle becomes meaningful once the cover scrolls
                // under it.
                SliverAppBar(
                  pinned: true,
                  title: Text(handle),
                ),
                SliverToBoxAdapter(
                  child: _ProfileHeader(
                    raw: raw,
                    viewer: widget.viewerAccount,
                    isFollowLoading: _followLoading,
                    onFollowToggle: () => _toggleFollow(raw),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    const TabBar(
                      tabs: [
                        Tab(text: 'Notes'),
                        Tab(text: 'Notes & replies'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _UserNotesList(
                    args: _UserNotesArgs(
                      viewer: widget.viewerAccount,
                      userId: id,
                      withReplies: false,
                    ),
                  ),
                  _UserNotesList(
                    args: _UserNotesArgs(
                      viewer: widget.viewerAccount,
                      userId: id,
                      withReplies: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFollow(Map<String, dynamic> raw) async {
    final actions =
        await ref.read(noteActionsProvider(widget.viewerAccount).future);
    if (actions == null) return;
    final userId = raw['id'] as String;
    final isFollowing = raw['isFollowing'] == true;
    setState(() => _followLoading = true);
    try {
      if (isFollowing) {
        await actions.unfollow(userId);
      } else {
        await actions.follow(userId);
      }
      // Invalidate so the freshly-fetched isFollowing flag reflects
      // the new server state.
      ref.invalidate(_userProfileProvider((
        widget.viewerAccount,
        widget.userId,
        widget.username,
        widget.userHost,
      )));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Follow toggle failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }
}

/// Profile header: edge-to-edge cover photograph, a
/// large circular avatar overlapping the cover edge, centered identity
/// (32px name, handle, bio, follow CTA), and statistics separated by
/// thin vertical rules.
class _ProfileHeader extends StatelessWidget {
  /// Cover height (spec range 200–240).
  static const double _coverHeight = 224;

  /// How far the avatar overlaps the cover's bottom edge.
  static const double _avatarOverlap = 56;

  final Map<String, dynamic> raw;
  final Account viewer;
  final bool isFollowLoading;
  final VoidCallback onFollowToggle;

  const _ProfileHeader({
    required this.raw,
    required this.viewer,
    required this.isFollowLoading,
    required this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    final displayName = (raw['name'] as String?) ?? raw['username'] as String;
    final username = raw['username'] as String;
    final host = raw['host'] as String?;
    final handle = host == null ? '@$username' : '@$username@$host';
    final avatarUrl = raw['avatarUrl'] as String?;
    final bannerUrl = raw['bannerUrl'] as String?;
    final description = (raw['description'] as String?) ?? '';
    final followingCount = raw['followingCount'] as int? ?? 0;
    final followersCount = raw['followersCount'] as int? ?? 0;
    final notesCount = raw['notesCount'] as int? ?? 0;
    final isFollowing = raw['isFollowing'] == true;
    final hasPendingFollowRequest =
        raw['hasPendingFollowRequestFromYou'] == true;
    final isMe = raw['isMe'] == true || raw['id'] == viewer.userId;
    final viewerHost = host ?? viewer.host;

    final avatarSize = PlusDims.profileAvatar;

    return ColoredBox(
      color: plus.surface,
      child: Column(
        children: [
          // Cover + overlapping avatar. No parallax; a neutral
          // placeholder holds the slot until the cover decodes
          //.
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: _coverHeight,
                width: double.infinity,
                child: bannerUrl != null
                    ? NetImage(
                        url: bannerUrl,
                        fit: BoxFit.cover,
                        placeholder: ColoredBox(color: plus.surfacePressed),
                        errorWidget: ColoredBox(color: plus.surfacePressed),
                      )
                    : ColoredBox(color: plus.surfacePressed),
              ),
              Positioned(
                bottom: -_avatarOverlap,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: plus.surface,
                      shape: BoxShape.circle,
                    ),
                    child: UserAvatar(
                      url: avatarUrl,
                      seed: displayName,
                      radius: avatarSize / 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _avatarOverlap + PlusSpacing.x2),
          // Centered identity: 32px medium name over metadata.
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: PlusSpacing.x4),
            child: Column(
              children: [
                UserDisplayName(
                  name: displayName,
                  viewerHost: viewerHost,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 2),
                Text(handle, style: plus.metadata),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: PlusSpacing.x3),
                  _ProfileBio(
                    text: description,
                    viewerHost: viewerHost,
                  ),
                ],
                if (!isMe) ...[
                  const SizedBox(height: PlusSpacing.x3),
                  _FollowButton(
                    isFollowing: isFollowing,
                    isPending: hasPendingFollowRequest,
                    isLoading: isFollowLoading,
                    onTap: onFollowToggle,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: PlusSpacing.x3),
          // Statistics separated by thin vertical rules.
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              // Each stat is Flexible so the trio shrinks (ellipsis
              // inside _Stat) at narrow widths / large text scale
              // instead of overflowing the row.
              children: [
                Flexible(
                  child: _Stat(label: 'notes', value: notesCount),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 4,
                  endIndent: 4,
                  color: plus.divider,
                ),
                Flexible(
                  child: _Stat(
                    label: 'following',
                    value: followingCount,
                    onTap: () => FollowListScreen.open(
                      context,
                      account: viewer,
                      userId: raw['id'] as String,
                      followers: false,
                      displayName:
                          (raw['name'] ?? raw['username']) as String?,
                    ),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 4,
                  endIndent: 4,
                  color: plus.divider,
                ),
                Flexible(
                  child: _Stat(
                    label: 'followers',
                    value: followersCount,
                    onTap: () => FollowListScreen.open(
                      context,
                      account: viewer,
                      userId: raw['id'] as String,
                      followers: true,
                      displayName:
                          (raw['name'] ?? raw['username']) as String?,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PlusSpacing.x3),
        ],
      ),
    );
  }
}

class _ProfileBio extends ConsumerStatefulWidget {
  final String text;
  final String viewerHost;
  const _ProfileBio({required this.text, required this.viewerHost});

  @override
  ConsumerState<_ProfileBio> createState() => _ProfileBioState();
}

class _ProfileBioState extends ConsumerState<_ProfileBio> {
  /// Owns the tap recognizers the renderer creates; disposed on
  /// rebuild and unmount.
  MfmRenderer? _renderer;

  @override
  void dispose() {
    _renderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emojiSize = (theme.textTheme.bodyMedium?.fontSize ?? 14) * 1.4;
    _renderer?.dispose();
    final renderer = _renderer = MfmRenderer(
      context: context,
      animateEffects: EffectSettings.shouldAnimate(context, ref),
      callbacks: MfmCallbacks(
        resolveEmoji: (raw) => EmojiImage(
          rawName: raw,
          viewerHost: widget.viewerHost,
          size: emojiSize,
        ),
      ),
    );
    return renderer.render(parseMfm(widget.text));
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;

  /// When set, tapping the well navigates (followers/following lists).
  final VoidCallback? onTap;
  const _Stat({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    // Flat stat: value over label, separated from siblings by thin
    // vertical rules in the header.
    final stat = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: _formatCount(value),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: plus.textSecondary),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) return stat;
    return Semantics(
      button: true,
      label: '$value $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(cursor: SystemMouseCursors.click, child: stat),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n < 1000) return '$n';
    if (n < 10000) return '${(n / 1000).toStringAsFixed(1)}K';
    if (n < 1000000) return '${(n / 1000).round()}K';
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isPending;
  final bool isLoading;
  final VoidCallback onTap;
  const _FollowButton({
    required this.isFollowing,
    required this.isPending,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = isPending
        ? 'Requested'
        : isFollowing
            ? 'Following'
            : 'Follow';
    // Flat CTA: blue "Follow" while not yet following; once following
    // or requested, a bordered chip with a check — no filled capsule.
    final following = isFollowing || isPending;
    if (following) {
      return PlusChip(
        onTap: isLoading ? null : onTap,
        semanticLabel: label,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 14, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(label,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: scheme.primary)),
                ],
              ),
      );
    }
    return PlusButton.raised(
      onTap: isLoading ? null : onTap,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              label,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: scheme.primary),
            ),
    );
  }
}

/// Pinned-tab delegate so the TabBar stays under the header when the
/// user scrolls into the notes list.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: overlaps ? 1 : 0,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

class _UserNotesArgs {
  final Account viewer;
  final String userId;
  final bool withReplies;
  const _UserNotesArgs({
    required this.viewer,
    required this.userId,
    required this.withReplies,
  });
  @override
  bool operator ==(Object other) =>
      other is _UserNotesArgs &&
      other.viewer.id == viewer.id &&
      other.userId == userId &&
      other.withReplies == withReplies;
  @override
  int get hashCode => Object.hash(viewer.id, userId, withReplies);
}

/// User-notes list. Plain ListView with infinite scroll; no streaming
/// here — the timeline of one user is read-mostly and updates land
/// when the user re-enters the screen. Reactions still update live
/// because each row consumes the controller's `select` for its
/// matching note (none here — we hold the snapshot ourselves).
class _UserNotesList extends ConsumerStatefulWidget {
  final _UserNotesArgs args;
  const _UserNotesList({required this.args});

  @override
  ConsumerState<_UserNotesList> createState() => _UserNotesListState();
}

class _UserNotesListState extends ConsumerState<_UserNotesList>
    with AutomaticKeepAliveClientMixin {
  final _scroll = ScrollController();
  final _notes = <Note>[];
  bool _loading = false;
  bool _reachedEnd = false;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

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
    });
    try {
      final endpoints =
          await ref.read(misskeyEndpointsProvider(widget.args.viewer).future);
      if (endpoints == null) return;
      final page = await endpoints.usersNotes(
        userId: widget.args.userId,
        withReplies: widget.args.withReplies,
      );
      if (!mounted) return;
      setState(() {
        _notes
          ..clear()
          ..addAll(page);
        _loading = false;
        _reachedEnd = page.length < 30;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_reachedEnd || _loading) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_notes.isEmpty) return;
    setState(() => _loading = true);
    try {
      final endpoints =
          await ref.read(misskeyEndpointsProvider(widget.args.viewer).future);
      if (endpoints == null) return;
      final older = await endpoints.usersNotes(
        userId: widget.args.userId,
        withReplies: widget.args.withReplies,
        untilId: _notes.last.id,
      );
      if (!mounted) return;
      setState(() {
        _notes.addAll(older);
        _loading = false;
        _reachedEnd = older.length < 30;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading && _notes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _notes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Failed to load notes: $_error'),
        ),
      );
    }
    if (_notes.isEmpty) {
      return const Center(child: Text('No notes yet.'));
    }
    return RefreshIndicator(
      onRefresh: _loadInitial,
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
            attributionAccount: widget.args.viewer,
          );
        },
      ),
    );
  }
}

/// Per-(viewer, userId|username|host) user fetch. autoDispose so the
/// cache doesn't keep growing as users view more profiles.
final _userProfileProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?,
        (Account, String?, String?, String?)>((ref, key) async {
  final endpoints = await ref.watch(misskeyEndpointsProvider(key.$1).future);
  if (endpoints == null) return null;
  try {
    if (key.$2 != null) {
      // Lookup by id — fast path.
      // usersShow returns a parsed User; for the profile we want the
      // raw map (it carries fields not modeled in User: bio, banner,
      // counts, isFollowing, …). Reach for the underlying call.
      final raw = await _callUsersShow(
        endpoints,
        params: {'userId': key.$2},
      );
      return raw;
    }
    // Lookup by handle.
    final raw = await endpoints.usersShowByHandle(
      username: key.$3!,
      userHost: key.$4,
    );
    return raw;
  } catch (_) {
    return null;
  }
});

/// `users/show` returns a richer object than [User] models. We call it
/// directly via the http client to keep the unmodeled fields.
Future<Map<String, dynamic>> _callUsersShow(
  MisskeyEndpoints endpoints, {
  required Map<String, dynamic> params,
}) async {
  final raw = await endpoints.http.call('users/show', params: params)
      as Map<String, dynamic>;
  return raw;
}
