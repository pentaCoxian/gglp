import 'package:flutter/material.dart';

import 'plus_motion.dart';
import 'plus_theme.dart';
import 'plus_tokens.dart';

enum _PlusButtonKind { text, publish, danger, raised }

/// Flat 2014-style button.
///
/// - [PlusButton.text]: flat blue text action (default choice).
/// - [PlusButton.publish]: the share button — gray while disabled,
///   share-green fill when publishable, animating over 120ms.
/// - [PlusButton.danger]: red text for destructive actions.
/// - [PlusButton.raised]: white raised rectangle (2014 "raised button").
class PlusButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final String? tooltip;
  final String? semanticLabel;
  final _PlusButtonKind _kind;

  const PlusButton.text({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(
      horizontal: PlusSpacing.x4,
      vertical: PlusSpacing.x3,
    ),
    this.tooltip,
    this.semanticLabel,
  }) : _kind = _PlusButtonKind.text;

  const PlusButton.publish({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(
      horizontal: PlusSpacing.x4,
      vertical: PlusSpacing.x3,
    ),
    this.tooltip,
    this.semanticLabel,
  }) : _kind = _PlusButtonKind.publish;

  const PlusButton.danger({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(
      horizontal: PlusSpacing.x4,
      vertical: PlusSpacing.x3,
    ),
    this.tooltip,
    this.semanticLabel,
  }) : _kind = _PlusButtonKind.danger;

  const PlusButton.raised({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.symmetric(
      horizontal: PlusSpacing.x4,
      vertical: PlusSpacing.x3,
    ),
    this.tooltip,
    this.semanticLabel,
  }) : _kind = _PlusButtonKind.raised;

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final enabled = onTap != null;

    final (Color bg, Color fg, List<BoxShadow>? shadow) = switch (_kind) {
      _PlusButtonKind.text => (
        Colors.transparent,
        enabled ? plus.link : plus.textTertiary,
        null,
      ),
      _PlusButtonKind.danger => (
        Colors.transparent,
        enabled ? plus.danger : plus.textTertiary,
        null,
      ),
      _PlusButtonKind.publish => (
        enabled ? plus.success : plus.surfacePressed,
        enabled ? Colors.white : plus.textTertiary,
        null,
      ),
      _PlusButtonKind.raised => (
        plus.surface,
        enabled ? plus.textPrimary : plus.textTertiary,
        plus.isDark ? null : plus.shadowCard,
      ),
    };

    Widget button = AnimatedContainer(
      duration: PlusMotion.fast,
      curve: PlusMotion.easeStandard,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(PlusRadii.card),
        border:
            _kind == _PlusButtonKind.raised && plus.isDark
                ? Border.all(color: plus.border)
                : null,
        boxShadow: shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(PlusRadii.card),
          child: Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(color: fg),
              child: IconTheme.merge(
                data: IconThemeData(color: fg, size: 18),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    if (semanticLabel != null) {
      button = Semantics(label: semanticLabel, button: true, child: button);
    }
    return button;
  }
}
