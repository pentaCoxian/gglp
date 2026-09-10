import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../misskey/models/account.dart';
import '../../misskey/models/note.dart';
import '../../timeline/note_actions_service.dart';
import '../plus/plus.dart';
import '../screens/compose_screen.dart';
import 'reactions/reaction_picker_sheet.dart';
import 'reactions/who_reacted_sheet.dart';

/// The reply / renote / quote / react / more row at the bottom of a
/// note card. Shown only when an [account] is attributed to the card
/// (i.e. when we have a viewer that can perform actions).
///
/// Action attribution rule: actions are performed by the
/// [attributionAccount] — the same account whose websocket delivered
/// the note to us. In unified mode that's the per-row account; in
/// single-account mode it's the active account.
class NoteActionsRow extends ConsumerWidget {
  final Note note;
  final Account attributionAccount;

  /// Groove between the note body and this row. On raised cards it
  /// visually caps the content; in the dense stream layout it's
  /// turned off — the between-note groove is the only separator, so
  /// the action row reads as unambiguously attached to its note.
  final bool showDivider;

  const NoteActionsRow({
    super.key,
    required this.note,
    required this.attributionAccount,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actionsAsync = ref.watch(noteActionsProvider(attributionAccount));
    final actions = actionsAsync.valueOrNull;

    Future<void> doReact() async {
      if (actions == null) return;
      final picked = await ReactionPickerSheet.show(
        context,
        account: attributionAccount,
      );
      if (picked == null) return;
      try {
        await actions.react(note: note, reaction: picked);
        if (context.mounted) _toast(context, 'Reacted');
      } catch (e) {
        if (context.mounted) _toast(context, 'Reaction failed: $e');
      }
    }

    Future<void> doReply() async {
      await ComposeScreen.open(
        context,
        account: attributionAccount,
        mode: ComposeMode.reply,
        inReplyTo: note,
      );
    }

    Future<void> doRenote() async {
      if (actions == null) return;
      try {
        await actions.renote(note);
        if (context.mounted) _toast(context, 'Renoted');
      } catch (e) {
        if (context.mounted) _toast(context, 'Renote failed: $e');
      }
    }

    Future<void> doQuote() async {
      await ComposeScreen.open(
        context,
        account: attributionAccount,
        mode: ComposeMode.quote,
        renoteSource: note,
      );
    }

    final disabled = actions == null;
    final plus = PlusTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: showDivider ? 4 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDivider) ...[
            const PlusDivider(),
            const SizedBox(height: 2),
          ],
          Row(
            children: [
              // Color allocation: reply = functional blue,
              // renote/quote = green, react = brand red family.
              Expanded(
                child: _ActionPill(
                  icon: Icons.reply,
                  activeIcon: Icons.reply,
                  label: 'Reply',
                  count: note.repliesCount,
                  accent: theme.colorScheme.primary,
                  onTap: disabled ? null : doReply,
                ),
              ),
              Expanded(
                child: _ActionPill(
                  icon: Icons.repeat,
                  activeIcon: Icons.repeat,
                  label: 'Renote',
                  count: note.renoteCount,
                  accent: plus.renote,
                  onTap: disabled ? null : doRenote,
                ),
              ),
              Expanded(
                child: _ActionPill(
                  icon: Icons.format_quote,
                  activeIcon: Icons.format_quote,
                  label: 'Quote',
                  accent: plus.renote,
                  onTap: disabled ? null : doQuote,
                ),
              ),
              Expanded(
                child: _ActionPill(
                  icon: Icons.add_reaction_outlined,
                  activeIcon: Icons.add_reaction,
                  label: 'React',
                  accent: plus.brand,
                  onTap: disabled ? null : doReact,
                ),
              ),
              _MoreButton(
                tooltip: 'More',
                onSelected: (v) => _handleMenu(context, ref, actions, v),
                itemBuilder: () => [
                  const PopupMenuItem(
                    value: 'bookmark',
                    child: _MenuTile(
                        icon: Icons.bookmark_add_outlined,
                        label: 'Bookmark'),
                  ),
                  if (note.reactions.isNotEmpty)
                    const PopupMenuItem(
                      value: 'who_reacted',
                      child: _MenuTile(
                          icon: Icons.people_outline,
                          label: 'See who reacted'),
                    ),
                  const PopupMenuItem(
                    value: 'unreact',
                    child: _MenuTile(
                        icon: Icons.heart_broken_outlined,
                        label: 'Remove my reaction'),
                  ),
                  if (note.uri != null || note.user.host == null)
                    const PopupMenuItem(
                      value: 'copy_uri',
                      child: _MenuTile(
                          icon: Icons.link, label: 'Copy note link'),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'follow',
                    child: _MenuTile(
                        icon: Icons.person_add_alt_outlined,
                        label: 'Follow author'),
                  ),
                  const PopupMenuItem(
                    value: 'unfollow',
                    child: _MenuTile(
                        icon: Icons.person_remove_alt_1_outlined,
                        label: 'Unfollow author'),
                  ),
                  // Safety actions only make sense against other
                  // people's notes.
                  if (!_isOwnNote()) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'mute_author',
                      child: _MenuTile(
                          icon: Icons.volume_off_outlined,
                          label: 'Mute author'),
                    ),
                    const PopupMenuItem(
                      value: 'block_author',
                      child: _MenuTile(
                        icon: Icons.block_outlined,
                        label: 'Block author',
                        destructive: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report_author',
                      child: _MenuTile(
                        icon: Icons.flag_outlined,
                        label: 'Report author',
                        destructive: true,
                      ),
                    ),
                  ],
                  if (_isOwnNote()) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: _MenuTile(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        destructive: true,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isOwnNote() {
    // attributionAccount.userId is the account's id ON ITS OWN HOST.
    // The note's user.id is from the perspective of `note.sourceHost`,
    // which equals `attributionAccount.host` for non-federated notes
    // delivered to that account. For federated notes, `note.user.host`
    // is non-null so the note isn't ours regardless of id collision.
    if (note.user.host != null) return false;
    return note.user.id == attributionAccount.userId &&
        note.sourceHost == attributionAccount.host;
  }

  Future<void> _handleMenu(
    BuildContext context,
    WidgetRef ref,
    NoteActionsService? actions,
    String value,
  ) async {
    if (actions == null) return;
    switch (value) {
      case 'who_reacted':
        await WhoReactedSheet.show(
          context,
          account: attributionAccount,
          note: note,
        );
      case 'bookmark':
        try {
          await actions.favorite(note);
          if (context.mounted) _toast(context, 'Bookmarked');
        } catch (e) {
          if (context.mounted) _toast(context, 'Bookmark failed: $e');
        }
      case 'mute_author':
        try {
          await actions.muteByHandle(
            username: note.user.username,
            userHost: note.user.host,
          );
          if (context.mounted) _toast(context, 'Author muted');
        } catch (e) {
          if (context.mounted) _toast(context, 'Mute failed: $e');
        }
      case 'block_author':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Block @${note.user.username}?'),
            content: const Text(
              'They will not be able to follow you or see your notes. '
              'You can unblock later from their profile.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Block'),
              ),
            ],
          ),
        );
        if (confirmed != true) return;
        try {
          await actions.blockByHandle(
            username: note.user.username,
            userHost: note.user.host,
          );
          if (context.mounted) _toast(context, 'Author blocked');
        } catch (e) {
          if (context.mounted) _toast(context, 'Block failed: $e');
        }
      case 'report_author':
        final comment = await _promptReportComment(context);
        if (comment == null || comment.trim().isEmpty) return;
        try {
          await actions.reportByHandle(
            username: note.user.username,
            userHost: note.user.host,
            comment: comment.trim(),
          );
          if (context.mounted) {
            _toast(context, 'Report sent to moderators');
          }
        } catch (e) {
          if (context.mounted) _toast(context, 'Report failed: $e');
        }
      case 'unreact':
        try {
          await actions.unreact(note);
          if (context.mounted) _toast(context, 'Reaction removed');
        } catch (e) {
          if (context.mounted) _toast(context, 'Failed: $e');
        }
      case 'copy_uri':
        final uri = note.uri ?? 'https://${note.sourceHost}/notes/${note.id}';
        await Clipboard.setData(ClipboardData(text: uri));
        if (context.mounted) _toast(context, 'Link copied');
      case 'follow':
        try {
          await actions.followByHandle(
            username: note.user.username,
            userHost: note.user.host,
          );
          if (context.mounted) _toast(context, 'Followed');
        } catch (e) {
          if (context.mounted) _toast(context, 'Follow failed: $e');
        }
      case 'unfollow':
        try {
          await actions.unfollowByHandle(
            username: note.user.username,
            userHost: note.user.host,
          );
          if (context.mounted) _toast(context, 'Unfollowed');
        } catch (e) {
          if (context.mounted) _toast(context, 'Unfollow failed: $e');
        }
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete note?'),
            content: const Text('This cannot be undone.'),
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
        try {
          await actions.delete(note);
          if (context.mounted) _toast(context, 'Deleted');
        } catch (e) {
          if (context.mounted) _toast(context, 'Delete failed: $e');
        }
    }
  }

  static void _toast(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Free-text reason dialog for `users/report-abuse`. Misskey
  /// requires a non-empty comment; the Send button stays disabled
  /// until the user types one.
  Future<String?> _promptReportComment(BuildContext context) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Report @${note.user.username}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(
              hintText: 'What is wrong with this user\'s behavior? '
                  'This is sent to your server\'s moderators.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, v, __) => TextButton(
                onPressed: v.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(ctx).pop(controller.text),
                child: const Text('Send report'),
              ),
            ),
          ],
        ),
      );
    } finally {
      // The dialog has been popped by the time the future completes
      // (same pattern as mfm_link_dialog); the controller is only
      // read, never written, while the route animates out.
      controller.dispose();
    }
  }
}

/// Pill-shaped action button. Idle state is a borderless icon (with
/// optional count); hover/press flashes a tinted background in the
/// action's accent color so reply, renote, quote, and react each get
/// their own subtle hint of identity without screaming on every card.
class _ActionPill extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? count;
  final Color accent;
  final VoidCallback? onTap;

  const _ActionPill({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.accent,
    this.count,
    this.onTap,
  });

  @override
  State<_ActionPill> createState() => _ActionPillState();
}

class _ActionPillState extends State<_ActionPill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    final disabled = widget.onTap == null;
    // Idle actions are quiet gray; hover/press inks the action's
    // identity color (blue reply, green renote, red react).
    final Color iconColor = disabled
        ? plus.textTertiary
        : (_hover ? widget.accent : plus.textSecondary);
    final showCount = widget.count != null && widget.count! > 0;
    final a11yLabel = showCount
        ? '${widget.label}, ${widget.count} so far'
        : widget.label;
    return Tooltip(
      message: widget.label,
      child: Semantics(
        button: true,
        enabled: !disabled,
        label: a11yLabel,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          cursor: disabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              highlightColor: widget.accent.withValues(alpha: 0.10),
              splashColor: widget.accent.withValues(alpha: 0.12),
              child: Container(
                constraints:
                    const BoxConstraints(minHeight: PlusDims.actionRow),
                alignment: Alignment.center,
                // Four pills share the row with a fixed more-button; on
                // a 320px phone at a large text scale "12.3K" plus the
                // icon is wider than a pill. Scale the pair down rather
                // than overflow — an ellipsized count ("12…") is useless.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hover ? widget.activeIcon : widget.icon,
                        size: 18,
                        color: iconColor,
                      ),
                      if (showCount) ...[
                        const SizedBox(width: 4),
                        Text(
                          _formatCount(widget.count!),
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: iconColor,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// `12345 -> 12.3K`, etc. Avoids stretching the row when a viral
  /// note has thousands of renotes.
  static String _formatCount(int n) {
    if (n < 1000) return '$n';
    if (n < 10000) return '${(n / 1000).toStringAsFixed(1)}K';
    if (n < 1000000) return '${(n / 1000).round()}K';
    return '${(n / 1000000).toStringAsFixed(1)}M';
  }
}

/// The trailing "more" button. Borderless circular pill that mirrors
/// `_ActionPill`'s hover treatment so the row reads as a single
/// uniform control strip.
class _MoreButton extends StatefulWidget {
  final String tooltip;
  final ValueChanged<String> onSelected;
  final List<PopupMenuEntry<String>> Function() itemBuilder;
  const _MoreButton({
    required this.tooltip,
    required this.onSelected,
    required this.itemBuilder,
  });

  @override
  State<_MoreButton> createState() => _MoreButtonState();
}

class _MoreButtonState extends State<_MoreButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final iconColor = _hover ? plus.textPrimary : plus.textSecondary;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        // PopupMenuButton's InkWell needs a Material ancestor; carry
        // one so the row works on any host surface (panel, sheet).
        child: Material(
          type: MaterialType.transparency,
          child: PopupMenuButton<String>(
          tooltip: '',
          onSelected: widget.onSelected,
          itemBuilder: (_) => widget.itemBuilder(),
          position: PopupMenuPosition.under,
          child: AnimatedContainer(
            duration: PlusMotion.fast,
            margin: const EdgeInsets.only(left: 2),
            padding: const EdgeInsets.all(12),
            color: _hover ? plus.surfaceHover : Colors.transparent,
            child: Icon(Icons.more_vert, size: 18, color: iconColor),
          ),
          ),
        ),
      ),
    );
  }
}

/// A polished menu row used inside the more-button dropdown — keeps
/// icon and label tight without inheriting `ListTile`'s 56dp height.
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;
  const _MenuTile({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        destructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
