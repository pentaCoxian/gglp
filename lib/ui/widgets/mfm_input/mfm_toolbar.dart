import 'package:flutter/material.dart';

import '../../../misskey/models/account.dart';
import '../../plus/plus.dart';
import 'mfm_editing.dart';
import 'mfm_effects_menu.dart';
import 'mfm_link_dialog.dart';

/// Which buttons appear in [MfmToolbar] / [MfmToolbarButtons].
///
/// Pass an explicit subset for surfaces where some actions don't make
/// sense — e.g. the compose CW field omits `quote` and `codeBlock`
/// because those are block-level constructs that don't fit a one-line
/// content warning.
enum MfmToolbarAction {
  bold,
  italic,
  strike,
  small,
  code,
  codeBlock,
  link,
  quote,
  effects,
  emoji,
}

const Set<MfmToolbarAction> kAllMfmToolbarActions = {
  MfmToolbarAction.bold,
  MfmToolbarAction.italic,
  MfmToolbarAction.strike,
  MfmToolbarAction.small,
  MfmToolbarAction.code,
  MfmToolbarAction.codeBlock,
  MfmToolbarAction.link,
  MfmToolbarAction.quote,
  MfmToolbarAction.effects,
  MfmToolbarAction.emoji,
};

/// Inline-safe subset for single-line fields (no block constructs).
const Set<MfmToolbarAction> kInlineMfmToolbarActions = {
  MfmToolbarAction.bold,
  MfmToolbarAction.italic,
  MfmToolbarAction.strike,
  MfmToolbarAction.small,
  MfmToolbarAction.code,
  MfmToolbarAction.link,
  MfmToolbarAction.effects,
  MfmToolbarAction.emoji,
};

/// The bare row of formatting buttons, with no surface of its own.
///
/// Hosts that already own a bar (the composer's bottom action row)
/// drop this into their horizontal scroller so attachments and
/// formatting share one line instead of stacking two bars above the
/// keyboard. [MfmToolbar] wraps it in the standalone white bar.
///
/// Buttons follow the **insert-then-type** model: tapping `B` inserts
/// `**|**` and the user types the bold content next. No selection is
/// required — this is the dominant mobile pattern.
class MfmToolbarButtons extends StatelessWidget {
  final TextEditingController controller;
  final Account account;
  final Set<MfmToolbarAction> actions;
  final double iconSize;
  final double gap;
  final VoidCallback? onOpenEmojiPicker;

  /// Optional — invoked just before the toolbar mutates [controller],
  /// so the caller can re-grab focus on the underlying TextField and
  /// the soft keyboard doesn't dismiss on a button tap.
  final VoidCallback? onBeforeAction;

  const MfmToolbarButtons({
    super.key,
    required this.controller,
    required this.account,
    this.actions = kAllMfmToolbarActions,
    this.iconSize = 22,
    this.gap = 4,
    this.onOpenEmojiPicker,
    this.onBeforeAction,
  });

  void _apply(TextEditingValue Function(TextEditingValue) op) {
    onBeforeAction?.call();
    controller.value = op(controller.value);
  }

  void _wrap(String prefix, String suffix) =>
      _apply((v) => insertWrapping(v, prefix, suffix));

  Future<void> _handleLink(BuildContext context) async {
    final result = await showMfmLinkDialog(context);
    if (result == null) return;
    onBeforeAction?.call();
    final v = controller.value;
    controller.value = insertAtCursor(v, '[${result.label}](${result.url})');
  }

  Future<void> _handleEffects(BuildContext context) async {
    final picked = await showMfmEffectsMenu(context);
    if (picked == null) return;
    onBeforeAction?.call();
    controller.value = insertWrapping(
      controller.value,
      picked.prefix,
      picked.suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget btn({
      required IconData icon,
      required String tooltip,
      required VoidCallback onTap,
    }) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: gap),
        child: PlusIconButton(
          icon: icon,
          tooltip: tooltip,
          size: iconSize,
          onTap: onTap,
        ),
      );
    }

    final children = <Widget>[];
    if (actions.contains(MfmToolbarAction.bold)) {
      children.add(
        btn(
          icon: Icons.format_bold,
          tooltip: 'Bold (**…**)',
          onTap: () => _wrap('**', '**'),
        ),
      );
    }
    if (actions.contains(MfmToolbarAction.italic)) {
      children.add(
        btn(
          icon: Icons.format_italic,
          tooltip: 'Italic (*…*)',
          onTap: () => _wrap('*', '*'),
        ),
      );
    }
    if (actions.contains(MfmToolbarAction.strike)) {
      children.add(
        btn(
          icon: Icons.format_strikethrough,
          tooltip: 'Strikethrough (~~…~~)',
          onTap: () => _wrap('~~', '~~'),
        ),
      );
    }
    if (actions.contains(MfmToolbarAction.small)) {
      children.add(
        btn(
          icon: Icons.text_decrease,
          tooltip: 'Small (<small>…</small>)',
          onTap: () => _wrap('<small>', '</small>'),
        ),
      );
    }
    if (actions.contains(MfmToolbarAction.code)) {
      children.add(
        btn(
          icon: Icons.code,
          tooltip: 'Inline code (`…`)',
          onTap: () => _wrap('`', '`'),
        ),
      );
    }
    if (actions.contains(MfmToolbarAction.codeBlock)) {
      children.add(
        btn(
          icon: Icons.data_object,
          tooltip: 'Code block (```​…```)',
          onTap: () => _apply(insertCodeBlock),
        ),
      );
    }
    if (actions.contains(MfmToolbarAction.link)) {
      children.add(
        btn(
          icon: Icons.link,
          tooltip: 'Link',
          onTap: () => _handleLink(context),
        ),
      );
    }
    if (actions.contains(MfmToolbarAction.quote)) {
      children.add(
        btn(
          icon: Icons.format_quote,
          tooltip: 'Blockquote (> …)',
          onTap: () => _apply(insertBlockquoteLine),
        ),
      );
    }
    if (actions.contains(MfmToolbarAction.effects)) {
      children.add(
        btn(
          icon: Icons.auto_awesome,
          tooltip: 'MFM effect',
          onTap: () => _handleEffects(context),
        ),
      );
    }
    if (actions.contains(MfmToolbarAction.emoji)) {
      children.add(
        btn(
          icon: Icons.emoji_emotions_outlined,
          tooltip: 'Insert emoji',
          onTap: onOpenEmojiPicker ?? () {},
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

/// Slot-in formatting toolbar: a flat white bar (square corners, 1px
/// top hairline) that scrolls [MfmToolbarButtons] horizontally.
///
/// All actions delegate to the pure helpers in [mfm_editing]. The
/// emoji button calls [onOpenEmojiPicker] (typically launches
/// `ReactionPickerSheet`); the link button shows a label/url dialog;
/// the effects button shows the [showMfmEffectsMenu] popup.
class MfmToolbar extends StatelessWidget {
  final TextEditingController controller;
  final Account account;
  final Set<MfmToolbarAction> actions;
  final bool dense;
  final VoidCallback? onOpenEmojiPicker;

  /// See [MfmToolbarButtons.onBeforeAction].
  final VoidCallback? onBeforeAction;

  const MfmToolbar({
    super.key,
    required this.controller,
    required this.account,
    this.actions = kAllMfmToolbarActions,
    this.dense = false,
    this.onOpenEmojiPicker,
    this.onBeforeAction,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    return SizedBox(
      height: dense ? 40 : 48,
      child: Container(
        decoration: BoxDecoration(
          color: plus.surface,
          border: Border(top: BorderSide(color: plus.border)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: MfmToolbarButtons(
            controller: controller,
            account: account,
            actions: actions,
            iconSize: dense ? 18 : 22,
            gap: dense ? 3 : 4,
            onOpenEmojiPicker: onOpenEmojiPicker,
            onBeforeAction: onBeforeAction,
          ),
        ),
      ),
    );
  }
}
