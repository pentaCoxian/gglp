import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../misskey/models/account.dart';
import 'mfm_toolbar.dart';

/// Renders [child] (typically a TextField) plus a sticky [MfmToolbar]
/// pinned just above the soft keyboard whenever [focusNode] has focus.
///
/// On mobile, `MediaQuery.of(context).viewInsets.bottom` reports the
/// height of the soft keyboard; we position the bar at that offset so
/// it stays flush against the keyboard during the keyboard-show
/// animation. On desktop / external-keyboard tablets `viewInsets.bottom`
/// is 0, so the bar sits at the bottom of the screen.
///
/// The bar lives in an [OverlayEntry] inserted into the root [Overlay]
/// so it floats above whatever scaffold / nav-bar chrome the screen
/// provides, and is removed cleanly when [focusNode] loses focus or
/// the host widget is disposed.
///
/// Tapping a toolbar button re-grabs focus first (`onBeforeAction`)
/// so the soft keyboard doesn't dismiss mid-edit.
class MfmKeyboardBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Account account;
  final Set<MfmToolbarAction> actions;
  final bool dense;
  final VoidCallback? onOpenEmojiPicker;
  final Widget child;

  const MfmKeyboardBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.account,
    required this.child,
    this.actions = const {
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
    },
    this.dense = false,
    this.onOpenEmojiPicker,
  });

  @override
  State<MfmKeyboardBar> createState() => _MfmKeyboardBarState();
}

class _MfmKeyboardBarState extends State<MfmKeyboardBar>
    with WidgetsBindingObserver {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
    // Listen for keyboard show/hide so we can reposition the overlay
    // independently of the host's MediaQuery (which a scaffold with
    // `resizeToAvoidBottomInset: true` consumes before our build runs).
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    // Metrics can change mid-frame (keyboard animation); same deferral.
    if (mounted && _entry != null) _scheduleEntryRebuild();
  }

  @override
  void didUpdateWidget(covariant MfmKeyboardBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
    }
    // If actions / dense / callback changed, force the overlay to
    // rebuild so the new props take effect. didUpdateWidget runs inside
    // the host's build, and the entry is not our descendant, so the
    // rebuild must be deferred past this frame's build phase.
    if (_entry != null) _scheduleEntryRebuild();
  }

  bool _rebuildScheduled = false;

  void _scheduleEntryRebuild() {
    if (_rebuildScheduled) return;
    _rebuildScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _rebuildScheduled = false;
      if (mounted) _entry?.markNeedsBuild();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeEntry();
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  bool _syncScheduled = false;

  void _handleFocusChange() {
    if (!mounted) return;
    _scheduleSync();
  }

  /// Focus notifications can fire while the framework is mid-build
  /// (autofocus on a freshly pushed route, for one). `OverlayState.
  /// insert` is a setState on the overlay, which asserts in that
  /// window, so defer to after the frame; outside the build phase
  /// apply immediately so the bar tracks the keyboard without a lag.
  void _scheduleSync() {
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      _sync();
      return;
    }
    if (_syncScheduled) return;
    _syncScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (mounted) _sync();
    });
  }

  void _sync() {
    if (widget.focusNode.hasFocus) {
      _insertEntry();
    } else {
      _removeEntry();
    }
  }

  void _insertEntry() {
    if (_entry != null) return;
    // Resolve the overlay *before* creating the entry: a null overlay
    // (focus gained mid-route-transition) used to leave a never-
    // inserted entry behind, which both blocked every later insert and
    // asserted on removal.
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final entry = OverlayEntry(builder: _buildBar);
    overlay.insert(entry);
    _entry = entry;
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  Widget _buildBar(BuildContext overlayContext) {
    // Read the keyboard inset from the **root** [View], not the host
    // [MediaQuery]. A scaffold with `resizeToAvoidBottomInset: true`
    // (the default) consumes `viewInsets.bottom` while resizing its
    // body, so any descendant — including the host of this widget —
    // sees `bottom == 0` once the resize has applied. The Overlay
    // sits outside that resized chain, so positioning the bar at
    // `bottom = consumed-inset = 0` lands it under the keyboard.
    //
    // `View.of(context).viewInsets` reports physical pixels, so we
    // also have to divide by `devicePixelRatio` to get logical px
    // that match `Positioned`.
    // The entry can be built once more after the host is torn down
    // (removal is frame-deferred); paint nothing rather than touch a
    // defunct context. Read the view through the overlay's own context
    // so the inset is right even if the host lives in another View.
    if (!mounted) return const SizedBox.shrink();
    final view = View.of(overlayContext);
    final bottom = view.viewInsets.bottom / view.devicePixelRatio;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      // Transparent Material only so text/icon defaults resolve inside
      // the overlay — the toolbar paints its own flat white surface,
      // not Material elevation.
      child: Material(
        type: MaterialType.transparency,
        child: MfmToolbar(
          controller: widget.controller,
          account: widget.account,
          actions: widget.actions,
          dense: widget.dense,
          onOpenEmojiPicker: widget.onOpenEmojiPicker,
          // Re-focus before mutating so the keyboard stays up.
          onBeforeAction: () => widget.focusNode.requestFocus(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Overlay rebuilds are driven by `didChangeMetrics`, not by this
    // build call — the host's MediaQuery is already inset-consumed by
    // any wrapping Scaffold by the time we'd see it here.
    return widget.child;
  }
}
