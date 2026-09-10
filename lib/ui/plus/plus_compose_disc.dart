import 'package:flutter/material.dart';

import 'plus_motion.dart';
import 'plus_theme.dart';
import 'plus_tokens.dart';

/// A white compose disc with a red pencil and elevated surface.
///
/// States: hover → light-gray disc; pressed → brand-soft disc with a
/// 0.97 scale over 80ms; focus → 2px blue outer ring; disabled → 38%
/// opacity. While the composer is open ([shrunk]) the disc scales to
/// 0.9 and fades, so the composer appears to reclaim it.
class PlusComposeDisc extends StatefulWidget {
  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;
  final bool shrunk;

  const PlusComposeDisc({
    super.key,
    required this.onPressed,
    this.tooltip = 'New note',
    this.icon = Icons.edit,
    this.shrunk = false,
  });

  @override
  State<PlusComposeDisc> createState() => _PlusComposeDiscState();
}

class _PlusComposeDiscState extends State<PlusComposeDisc> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final enabled = widget.onPressed != null;
    final reduce = PlusMotion.reduce(context);

    final disc =
        _pressed
            ? plus.brandSoft
            : _hovered
            ? plus.surfaceHover
            : plus.surface;

    final scale =
        reduce
            ? 1.0
            : widget.shrunk
            ? 0.9
            : _pressed
            ? PlusMotion.scalePress
            : 1.0;

    return Semantics(
      label: widget.tooltip,
      button: true,
      enabled: enabled,
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedOpacity(
          duration: PlusMotion.fast,
          opacity:
              !enabled
                  ? 0.38
                  : widget.shrunk
                  ? 0.0
                  : 1.0,
          child: AnimatedScale(
            duration: _pressed ? PlusMotion.instant : PlusMotion.fast,
            curve: PlusMotion.easeStandard,
            scale: scale,
            child: FocusableActionDetector(
              enabled: enabled,
              onShowHoverHighlight: (v) => setState(() => _hovered = v),
              onShowFocusHighlight: (v) => setState(() => _focused = v),
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    widget.onPressed?.call();
                    return null;
                  },
                ),
              },
              child: GestureDetector(
                onTapDown:
                    enabled ? (_) => setState(() => _pressed = true) : null,
                onTapUp:
                    enabled ? (_) => setState(() => _pressed = false) : null,
                onTapCancel:
                    enabled ? () => setState(() => _pressed = false) : null,
                onTap: widget.onPressed,
                child: AnimatedContainer(
                  duration: PlusMotion.fast,
                  width: PlusDims.composeDisc,
                  height: PlusDims.composeDisc,
                  decoration: BoxDecoration(
                    color: disc,
                    shape: BoxShape.circle,
                    boxShadow: plus.shadowFab,
                    border:
                        _focused
                            ? Border.all(color: plus.link, width: 2)
                            : plus.isDark
                            ? Border.all(color: plus.border)
                            : null,
                  ),
                  child: Icon(
                    widget.icon,
                    color: plus.brand,
                    size: PlusDims.icon,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
