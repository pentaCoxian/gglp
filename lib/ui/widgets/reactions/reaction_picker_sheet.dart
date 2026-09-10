import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../misskey/emoji/emoji_providers.dart';
import '../../../misskey/emoji/emoji_ref.dart';
import '../../../misskey/emoji/emoji_repository.dart';
import '../../../misskey/models/account.dart';
import '../../../misskey/models/emoji.dart';
import '../../plus/plus.dart';
import '../net_image.dart';
import 'unicode_emoji_set.dart';

/// Shared cell geometry for every emoji grid in the picker.
const _gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 48,
  childAspectRatio: 1,
);

/// Two-tab bottom-sheet reaction picker.
///
/// Tab 1: unicode (curated set + recents row).
/// Tab 2: per-host custom emoji (the host of `account` — the user can
///   only react with emoji their own server knows about), grouped into
///   collapsible per-category folders like the Misskey PWA.
///
/// Returns the selected reaction key (`👍` or `:name@host:` style)
/// via [Navigator.pop]. The caller is responsible for posting it via
/// `notes/reactions/create` and bumping the recents DAO.
class ReactionPickerSheet extends ConsumerStatefulWidget {
  final Account account;
  const ReactionPickerSheet({super.key, required this.account});

  /// Convenience launcher.
  static Future<String?> show(
    BuildContext context, {
    required Account account,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReactionPickerSheet(account: account),
    );
  }

  @override
  ConsumerState<ReactionPickerSheet> createState() =>
      _ReactionPickerSheetState();
}

class _ReactionPickerSheetState extends ConsumerState<ReactionPickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  /// Recents are read once per sheet open and shared by both tabs.
  /// (Creating the future inside `build` would re-query Drift on every
  /// keystroke of the search field.)
  late final Future<List<String>> _recents;

  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _recents = ref
        .read(reactionRecentDaoProvider)
        .recent(accountId: widget.account.id)
        .catchError((Object _, StackTrace __) => const <String>[]);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Size from the viewport that remains once the keyboard is up, and
    // lift the whole sheet above the keyboard so the search field is
    // never covered (modal sheets don't do this on their own).
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final height = (MediaQuery.sizeOf(context).height - insets) * 0.6;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SafeArea(
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.emoji_emotions_outlined),
                    text: 'Emoji',
                  ),
                  Tab(icon: Icon(Icons.image_outlined), text: 'Custom'),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PlusSpacing.x3,
                  vertical: PlusSpacing.x2,
                ),
                // Plain field: the theme's underline input decoration
                // provides the flat 2014 look.
                child: TextField(
                  autofocus: false,
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search…',
                  ),
                  onChanged: (s) =>
                      setState(() => _query = s.trim().toLowerCase()),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _recents,
                  builder: (context, snap) {
                    final recents = snap.data ?? const <String>[];
                    return TabBarView(
                      controller: _tabs,
                      children: [
                        _UnicodeTab(
                          recents: recents,
                          query: _query,
                          onPick: _pick,
                        ),
                        _CustomTab(
                          account: widget.account,
                          recents: recents,
                          query: _query,
                          onPick: _pick,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pick(String key) {
    // Bump recents asynchronously; the UI doesn't wait for the write
    // and a failed bookkeeping write must never block the pick.
    unawaited(
      ref
          .read(reactionRecentDaoProvider)
          .bump(accountId: widget.account.id, reactionKey: key)
          .catchError((Object _, StackTrace __) {}),
    );
    Navigator.of(context).pop(key);
  }
}

// ---------------------------------------------------------------------------
// Unicode tab
// ---------------------------------------------------------------------------

class _UnicodeTab extends StatelessWidget {
  /// Raw recents (unicode + `:custom:` keys); this tab keeps unicode only.
  final List<String> recents;
  final String query;
  final void Function(String key) onPick;
  const _UnicodeTab({
    required this.recents,
    required this.query,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final recent = recents
        // Only unicode entries (skip `:name:` keys) on this tab.
        .where((k) => !k.startsWith(':'))
        .toList(growable: false);

    // Filter each category exactly once per build.
    final sections = <(String, List<String>)>[];
    for (final entry in UnicodeEmojiSet.categories.entries) {
      final items = _filtered(entry.value);
      if (items.isNotEmpty) sections.add((entry.key, items));
    }

    return CustomScrollView(
      slivers: [
        if (recent.isNotEmpty) ...[
          const _SectionHeader(label: 'Recent'),
          _unicodeGrid(recent),
        ],
        for (final (label, items) in sections) ...[
          _SectionHeader(label: label),
          _unicodeGrid(items),
        ],
      ],
    );
  }

  Widget _unicodeGrid(List<String> items) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        PlusSpacing.x3,
        0,
        PlusSpacing.x3,
        PlusSpacing.x2,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: _gridDelegate,
        itemCount: items.length,
        itemBuilder: (_, i) => _UnicodeButton(emoji: items[i], onTap: onPick),
      ),
    );
  }

  List<String> _filtered(List<String> source) {
    if (query.isEmpty) return source;
    // Unicode emoji aren't searchable by name without a Unicode names
    // table. For MVP, treat the query as a literal codepoint match
    // (e.g. typing "👍" still works).
    return source.where((e) => e.contains(query)).toList(growable: false);
  }
}

class _UnicodeButton extends StatelessWidget {
  final String emoji;
  final void Function(String) onTap;
  const _UnicodeButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(emoji),
      borderRadius: BorderRadius.circular(PlusRadii.chip),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: PlusTheme.of(context).textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom tab — folders per category
// ---------------------------------------------------------------------------

/// One collapsible folder of custom emoji.
class _EmojiFolder {
  final String id;
  final String label;
  final List<CustomEmoji> emoji;
  const _EmojiFolder({
    required this.id,
    required this.label,
    required this.emoji,
  });

  /// The folder's first emoji doubles as its icon (header + jump bar).
  CustomEmoji? get icon => emoji.isEmpty ? null : emoji.first;
}

class _CustomTab extends ConsumerStatefulWidget {
  final Account account;

  /// Raw recents (unicode + `:custom:` keys); this tab keeps custom only.
  final List<String> recents;
  final String query;
  final void Function(String key) onPick;
  const _CustomTab({
    required this.account,
    required this.recents,
    required this.query,
    required this.onPick,
  });

  @override
  ConsumerState<_CustomTab> createState() => _CustomTabState();
}

class _CustomTabState extends ConsumerState<_CustomTab>
    with AutomaticKeepAliveClientMixin {
  static const _recentId = 'recent';
  static const _uncategorizedId = 'uncategorized';

  /// Folders the user has opened while this sheet is up. Lives only in
  /// State (kept alive across tab swipes); nothing is persisted.
  final _expanded = <String>{_recentId};

  /// One key per folder header so the jump bar can `ensureVisible` it.
  final _headerKeys = <String, GlobalKey>{};
  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String id) =>
      _headerKeys.putIfAbsent(id, () => GlobalKey(debugLabel: 'folder:$id'));

  void _toggle(String id) {
    setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
    });
  }

  /// Jump-bar tap: open the folder, then scroll its header to the top
  /// once the expanded layout has been laid out.
  void _jumpTo(String id) {
    setState(() => _expanded.add(id));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _headerKeys[id]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0,
        duration: PlusMotion.reduced(context, PlusMotion.surface),
        curve: PlusMotion.easeStandard,
      );
    });
  }

  /// Custom-emoji recents, resolved through the repository so the
  /// folder shows the real image. Unresolvable keys (catalog not yet
  /// loaded, emoji deleted on the server) are skipped.
  List<CustomEmoji> _recentEmoji(EmojiRepository repo) {
    final out = <CustomEmoji>[];
    final seen = <String>{};
    for (final key in widget.recents) {
      if (key.length < 3 || !key.startsWith(':') || !key.endsWith(':')) {
        continue;
      }
      final eref = EmojiRef.parse(
        key.substring(1, key.length - 1),
        viewerHost: widget.account.host,
      );
      final e = repo.lookup(host: eref.host, name: eref.name);
      if (e == null) continue;
      if (seen.add('${e.host}/${e.name}')) out.add(e);
    }
    return out;
  }

  /// Group by `category`: Recent first, categories A→Z (case-
  /// insensitive), then everything without a category last.
  List<_EmojiFolder> _folders(List<CustomEmoji> all, List<CustomEmoji> recent) {
    final byCategory = <String, List<CustomEmoji>>{};
    final uncategorized = <CustomEmoji>[];
    for (final e in all) {
      final c = e.category?.trim();
      if (c == null || c.isEmpty) {
        uncategorized.add(e);
      } else {
        byCategory.putIfAbsent(c, () => []).add(e);
      }
    }
    final names = byCategory.keys.toList()
      ..sort((a, b) {
        final c = a.toLowerCase().compareTo(b.toLowerCase());
        return c != 0 ? c : a.compareTo(b);
      });
    return [
      if (recent.isNotEmpty)
        _EmojiFolder(id: _recentId, label: 'Recent', emoji: recent),
      for (final n in names)
        _EmojiFolder(id: 'cat:$n', label: n, emoji: byCategory[n]!),
      if (uncategorized.isNotEmpty)
        _EmojiFolder(
          id: _uncategorizedId,
          label: 'Uncategorized',
          emoji: uncategorized,
        ),
    ];
  }

  /// Name/alias search (case-insensitive). Prefix matches rank first
  /// (name, then alias), substring matches after; each bucket keeps
  /// catalog order (List.sort is not stable, so no sort here).
  static List<CustomEmoji> _search(List<CustomEmoji> all, String q) {
    final namePrefix = <CustomEmoji>[];
    final aliasPrefix = <CustomEmoji>[];
    final rest = <CustomEmoji>[];
    for (final e in all) {
      final name = e.name.toLowerCase();
      if (name.startsWith(q)) {
        namePrefix.add(e);
        continue;
      }
      final aliases = e.aliases.map((a) => a.toLowerCase()).toList();
      if (aliases.any((a) => a.startsWith(q))) {
        aliasPrefix.add(e);
        continue;
      }
      if (name.contains(q) || aliases.any((a) => a.contains(q))) {
        rest.add(e);
      }
    }
    return [...namePrefix, ...aliasPrefix, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Subscribe to the catalog tick so a background `/emojis` fetch
    // populates the picker without requiring a re-open.
    ref.watch(emojiCatalogTickProvider);
    final repo = ref.watch(emojiRepositoryProvider);
    final all = repo.allForHost(widget.account.host);
    final query = widget.query;

    if (all.isEmpty) {
      return _EmptyMessage('Loading custom emoji from ${widget.account.host}…');
    }

    if (query.isNotEmpty) {
      final hits = _search(all, query);
      if (hits.isEmpty) {
        return _EmptyMessage('No custom emoji match "$query".');
      }
      // Search flattens the folders: one 'Results' header, all hits.
      return CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(
            child: _FolderHeader(
              label: 'Results',
              count: hits.length,
              fallbackIcon: Icons.search,
              expanded: true,
              onTap: null,
            ),
          ),
          _grid(hits),
        ],
      );
    }

    final folders = _folders(all, _recentEmoji(repo));
    return Column(
      children: [
        _FolderJumpBar(
          folders: folders,
          expanded: _expanded,
          onTap: _jumpTo,
        ),
        const PlusDivider(
          margin: EdgeInsets.symmetric(horizontal: PlusSpacing.x3),
        ),
        Expanded(
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              for (final f in folders) ...[
                SliverToBoxAdapter(
                  child: _FolderHeader(
                    key: _keyFor(f.id),
                    label: f.label,
                    count: f.emoji.length,
                    icon: f.icon,
                    expanded: _expanded.contains(f.id),
                    onTap: () => _toggle(f.id),
                  ),
                ),
                if (_expanded.contains(f.id)) _grid(f.emoji),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _grid(List<CustomEmoji> items) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        PlusSpacing.x3,
        0,
        PlusSpacing.x3,
        PlusSpacing.x2,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: _gridDelegate,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final emoji = items[i];
          return _CustomEmojiButton(
            emoji: emoji,
            // Single source of truth for `:name:` vs `:name@host:` is
            // [EmojiRef.tokenFor] — also used by the compose-time
            // autocomplete so reaction recents and compose recents agree.
            onTap: () =>
                widget.onPick(EmojiRef.tokenFor(emoji, widget.account.host)),
          );
        },
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;
  const _EmptyMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlusSpacing.x6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: PlusTheme.of(context).textSecondary),
        ),
      ),
    );
  }
}

/// Single-line, horizontally scrolling row of folder chips under the
/// search field. Tapping one opens that folder and scrolls to it.
class _FolderJumpBar extends StatelessWidget {
  final List<_EmojiFolder> folders;
  final Set<String> expanded;
  final void Function(String id) onTap;
  const _FolderJumpBar({
    required this.folders,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: PlusSpacing.x3,
          vertical: 6,
        ),
        itemCount: folders.length,
        separatorBuilder: (_, __) => const SizedBox(width: PlusSpacing.x1),
        itemBuilder: (_, i) {
          final f = folders[i];
          return _FolderChip(
            folder: f,
            selected: expanded.contains(f.id),
            onTap: () => onTap(f.id),
          );
        },
      ),
    );
  }
}

/// 28px square chip (2px radius) showing the folder's first emoji at
/// 18px. Blue border marks folders that are currently open.
class _FolderChip extends StatelessWidget {
  final _EmojiFolder folder;
  final bool selected;
  final VoidCallback onTap;
  const _FolderChip({
    required this.folder,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final icon = folder.icon;
    return Tooltip(
      message: folder.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PlusRadii.chip),
        child: AnimatedContainer(
          duration: PlusMotion.fast,
          curve: PlusMotion.easeStandard,
          width: PlusDims.reactionChip,
          height: PlusDims.reactionChip,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? plus.surface : plus.surfaceSubtle,
            borderRadius: BorderRadius.circular(PlusRadii.chip),
            border: Border.all(color: selected ? plus.selected : plus.border),
          ),
          child: icon == null
              ? Icon(Icons.folder_outlined, size: 18, color: plus.textSecondary)
              : _EmojiThumb(emoji: icon, size: 18),
        ),
      ),
    );
  }
}

/// 40px folder header row: icon, name, count, rotating chevron.
/// `onTap == null` renders a static header (search results).
class _FolderHeader extends StatelessWidget {
  final String label;
  final int count;
  final CustomEmoji? icon;
  final IconData fallbackIcon;
  final bool expanded;
  final VoidCallback? onTap;
  const _FolderHeader({
    super.key,
    required this.label,
    required this.count,
    this.icon,
    this.fallbackIcon = Icons.folder_outlined,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final text = Theme.of(context).textTheme;
    final icon = this.icon;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        // 40px at default scale; grows (never overflows) at large text.
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PlusSpacing.x3,
            vertical: PlusSpacing.x1,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: icon == null
                    ? Icon(fallbackIcon, size: 20, color: plus.textSecondary)
                    : _EmojiThumb(emoji: icon, size: 20),
              ),
              const SizedBox(width: PlusSpacing.x2),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(
                    color: plus.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: PlusSpacing.x2),
              Text(
                '$count',
                maxLines: 1,
                style: text.labelMedium?.copyWith(color: plus.textSecondary),
              ),
              if (onTap != null) ...[
                const SizedBox(width: PlusSpacing.x1),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: PlusMotion.reduced(context, PlusMotion.control),
                  curve: PlusMotion.easeStandard,
                  child: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: plus.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small emoji image for headers / chips.
class _EmojiThumb extends StatelessWidget {
  final CustomEmoji emoji;
  final double size;
  const _EmojiThumb({required this.emoji, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: NetImage(
        url: emoji.url,
        fit: BoxFit.contain,
        errorWidget: Icon(
          Icons.broken_image_outlined,
          size: size,
          color: PlusTheme.of(context).textTertiary,
        ),
      ),
    );
  }
}

class _CustomEmojiButton extends StatelessWidget {
  final CustomEmoji emoji;
  final VoidCallback onTap;
  const _CustomEmojiButton({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PlusRadii.chip),
      child: Tooltip(
        message: emoji.name,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: NetImage(
            url: emoji.url,
            fit: BoxFit.contain,
            errorWidget: Center(
              child: Text(
                ':${emoji.name}:',
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
