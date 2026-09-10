import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../misskey/models/account.dart';
import '../../../misskey/models/note.dart';
import '../../../misskey/models/reaction.dart';
import '../../plus/plus.dart';
import '../../screens/user_profile_screen.dart';
import '../emoji_image.dart';
import '../user_avatar.dart';
import '../user_display_name.dart';

/// Bottom sheet listing who reacted to a note, filterable by reaction.
///
/// Data comes from `notes/reactions` on [account]'s server, so the
/// note id must be valid there — callers either pass a note whose
/// `sourceHost == account.host` or accept that federated notes may
/// 404; in that case we degrade to a friendly message instead of an
/// error screen.
class WhoReactedSheet extends ConsumerStatefulWidget {
  final Account account;
  final Note note;

  const WhoReactedSheet({
    super.key,
    required this.account,
    required this.note,
  });

  static Future<void> show(
    BuildContext context, {
    required Account account,
    required Note note,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => WhoReactedSheet(account: account, note: note),
      );

  @override
  ConsumerState<WhoReactedSheet> createState() => _WhoReactedSheetState();
}

class _WhoReactedSheetState extends ConsumerState<WhoReactedSheet> {
  static const _pageSize = 30;

  final _scroll = ScrollController();

  /// Selected reaction key; null = the 'All' chip.
  String? _selectedKey;

  /// Raw `{id, createdAt, user, type}` rows from `notes/reactions`.
  final List<Map<String, dynamic>> _rows = [];

  /// Offset-based cursor (the endpoint paginates by offset, not id).
  int _offset = 0;

  bool _loading = false;
  bool _loadedOnce = false;
  bool _reachedEnd = false;
  bool _unavailable = false;

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
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_loading || _reachedEnd || _unavailable) return;
    setState(() => _loading = true);
    try {
      final endpoints =
          await ref.read(misskeyEndpointsProvider(widget.account).future);
      if (endpoints == null) {
        throw StateError('No client for @${widget.account.username}');
      }
      final rows = await endpoints.notesReactionsList(
        noteId: widget.note.id,
        type: _selectedKey,
        limit: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        _rows.addAll(rows);
        _offset += rows.length;
        _reachedEnd = rows.length < _pageSize;
        _loadedOnce = true;
      });
    } catch (_) {
      // Federated note whose id isn't valid on account.host (or the
      // server hides reaction lists) — degrade gracefully.
      if (!mounted) return;
      setState(() {
        _unavailable = true;
        _loadedOnce = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectFilter(String? key) {
    if (key == _selectedKey) return;
    setState(() {
      _selectedKey = key;
      _rows.clear();
      _offset = 0;
      _reachedEnd = false;
      _loadedOnce = false;
      _unavailable = false;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = widget.note;
    final total = note.reactions.fold<int>(0, (sum, r) => sum + r.count);
    final emojiSize = (theme.textTheme.bodyMedium?.fontSize ?? 14) * 1.4;
    // Size against the *visible* viewport: with a keyboard up when the
    // sheet opens, 75% of the full screen would leave the sheet's
    // bottom under the keyboard.
    final viewport = math.max(
      0.0,
      MediaQuery.sizeOf(context).height -
          MediaQuery.viewInsetsOf(context).bottom,
    );
    final maxHeight = viewport * 0.75;

    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Reactions',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '$total',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Horizontal filter strip: 'All' first, then one chip per
            // reaction key on the note. Selected chip shows the
            // brand-soft fill with a brand border.
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _filterChip(
                    context,
                    selected: _selectedKey == null,
                    onTap: () => _selectFilter(null),
                    child: Text(
                      'All',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  for (final r in note.reactions) ...[
                    const SizedBox(width: 8),
                    _filterChip(
                      context,
                      selected: _selectedKey == r.key,
                      onTap: () => _selectFilter(r.key),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _reactionEmoji(r, emojiSize),
                          const SizedBox(width: 4),
                          Text(
                            '${r.count}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const PlusDivider(margin: EdgeInsets.only(top: 6)),
            Expanded(child: _userList(context, emojiSize)),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    BuildContext context, {
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return PlusChip(
      onTap: onTap,
      selected: selected,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: child,
    );
  }

  /// Emoji for a reaction key: [EmojiImage] for `:name:` / `:name@host:`
  /// custom keys (colons stripped for `rawName`), plain text for
  /// unicode emoji.
  Widget _reactionEmoji(Reaction r, double size) {
    // `isCustom` is derived from the colons alone, so guard the length
    // too: a malformed `:` / `::` key must not throw in substring.
    if (r.isCustom && r.key.length > 2) {
      return EmojiImage(
        rawName: r.key.substring(1, r.key.length - 1),
        viewerHost: widget.note.sourceHost,
        size: size,
      );
    }
    return Text(r.key, style: TextStyle(fontSize: size * 0.85));
  }

  /// Trailing reaction glyph in a user row. [EmojiImage] bounds its
  /// own width; a unicode reaction is bounded here because a ZWJ
  /// sequence the platform font can't join renders as several glyphs
  /// wide and would push the row over.
  Widget _typeEmoji(String type, double size) {
    if (type.length > 2 && type.startsWith(':') && type.endsWith(':')) {
      return EmojiImage(
        rawName: type.substring(1, type.length - 1),
        viewerHost: widget.note.sourceHost,
        size: size,
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: size * 3),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          type,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(fontSize: size * 0.85),
        ),
      ),
    );
  }

  Widget _userList(BuildContext context, double emojiSize) {
    final theme = Theme.of(context);
    if (_unavailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Reaction list unavailable for this note.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    if (!_loadedOnce) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_rows.isEmpty) {
      return Center(
        child: Text(
          'No reactions yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      itemCount: _rows.length + 1,
      itemBuilder: (context, index) {
        if (index >= _rows.length) {
          if (_reachedEnd) return const SizedBox(height: 8);
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _userRow(context, _rows[index], emojiSize);
      },
    );
  }

  Widget _userRow(
    BuildContext context,
    Map<String, dynamic> row,
    double emojiSize,
  ) {
    final theme = Theme.of(context);
    final user = row['user'];
    if (user is! Map<String, dynamic>) return const SizedBox.shrink();
    final username = user['username'] as String? ?? '?';
    final name = user['name'] as String? ?? username;
    final userHost = user['host'] as String?;
    final handle = '@$username@${userHost ?? widget.note.sourceHost}';
    final type = row['type'] as String? ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => UserProfileScreen.openByHandle(
            context,
            viewerAccount: widget.account,
            username: username,
            userHost: userHost,
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                UserAvatar(
                  url: user['avatarUrl'] as String?,
                  seed: name,
                  radius: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserDisplayName(
                        name: name,
                        viewerHost: widget.note.sourceHost,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        handle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _typeEmoji(type, emojiSize),
              ],
            ),
          ),
        ),
        const PlusDivider(margin: EdgeInsets.symmetric(horizontal: 16)),
      ],
    );
  }
}
