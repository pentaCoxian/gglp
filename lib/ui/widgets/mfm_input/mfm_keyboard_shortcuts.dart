import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'mfm_editing.dart';
import 'mfm_link_dialog.dart';

/// Wraps [child] with a `CallbackShortcuts` mapping the standard MFM
/// editing keystrokes to the same primitives [MfmToolbar] calls.
///
/// **Mobile users see no effect** — without a hardware keyboard these
/// activators never fire. On desktop, on Android with a Bluetooth
/// keyboard, and on a Mac (or iPad with hardware kbd), they produce
/// the same insert-then-type behaviour the toolbar buttons do.
///
/// The Ctrl-vs-Cmd choice follows the platform: Cmd on macOS / iOS,
/// Ctrl elsewhere. Activators are scoped to whatever has focus inside
/// [child] — the global timeline shortcuts at `timeline_screen.dart`
/// don't fire while a TextField is focused, so there's no collision.
class MfmKeyboardShortcuts extends StatelessWidget {
  final TextEditingController controller;
  final Widget child;

  /// Invoked when Ctrl/Cmd-J fires. Typically launches the
  /// reaction-picker sheet for compose-time emoji insertion.
  final VoidCallback? onOpenEmojiPicker;

  const MfmKeyboardShortcuts({
    super.key,
    required this.controller,
    required this.child,
    this.onOpenEmojiPicker,
  });

  void _wrap(String prefix, String suffix) {
    controller.value = insertWrapping(controller.value, prefix, suffix);
  }

  Future<void> _link(BuildContext context) async {
    final result = await showMfmLinkDialog(context);
    if (result == null) return;
    controller.value = insertAtCursor(
      controller.value,
      '[${result.label}](${result.url})',
    );
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isApple = platform == TargetPlatform.macOS ||
        platform == TargetPlatform.iOS;
    SingleActivator k(LogicalKeyboardKey key, {bool shift = false}) =>
        SingleActivator(
          key,
          control: !isApple,
          meta: isApple,
          shift: shift,
        );

    return CallbackShortcuts(
      bindings: {
        k(LogicalKeyboardKey.keyB): () => _wrap('**', '**'),
        k(LogicalKeyboardKey.keyI): () => _wrap('*', '*'),
        k(LogicalKeyboardKey.keyS, shift: true): () => _wrap('~~', '~~'),
        k(LogicalKeyboardKey.keyE): () => _wrap('`', '`'),
        k(LogicalKeyboardKey.keyE, shift: true): () {
          controller.value = insertCodeBlock(controller.value);
        },
        k(LogicalKeyboardKey.keyK): () => _link(context),
        // `>` on US layouts is shift-period.
        k(LogicalKeyboardKey.period, shift: true): () {
          controller.value = insertBlockquoteLine(controller.value);
        },
        k(LogicalKeyboardKey.keyJ): () {
          onOpenEmojiPicker?.call();
        },
      },
      child: child,
    );
  }
}
