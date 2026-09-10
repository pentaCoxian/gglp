import 'package:flutter/material.dart';

import '../../timeline/timeline_kind.dart';
import '../plus/plus.dart';

/// Display names for the four Misskey timeline kinds.
/// `hybrid` stays `hybrid` internally and on the wire; only the label
/// borrows the 2014 "Social" wording.
String streamLabelFor(TimelineKind kind) => switch (kind) {
  TimelineKind.home => 'Home',
  TimelineKind.local => 'Local',
  TimelineKind.hybrid => 'Social',
  TimelineKind.global => 'Global',
};

/// The white stream-selection bar directly below the red app bar.
/// The label + caret opens an anchored kind menu; timeline changes
/// update the label (crossfade) instead of adding a tab row.
class TimelineStreamBar extends StatelessWidget {
  /// Current label ("Home", "Social", or a custom timeline's name).
  final String label;

  /// Non-null when the selection supports kind switching; opens the
  /// anchored kind menu. Null hides the caret (custom timelines).
  final TimelineKind? kind;
  final ValueChanged<TimelineKind>? onKindSelected;
  final VoidCallback? onRefresh;

  const TimelineStreamBar({
    super.key,
    required this.label,
    this.kind,
    this.onKindSelected,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return PlusStreamBar(
      title: AnimatedSwitcher(
        duration: PlusMotion.reduced(context, PlusMotion.fast),
        child: Text(label, key: ValueKey(label)),
      ),
      showCaret: kind != null && onKindSelected != null,
      onTitleTap:
          kind == null || onKindSelected == null
              ? null
              : () => _openKindMenu(context),
      trailing:
          onRefresh == null
              ? null
              : PlusIconButton(
                icon: Icons.refresh,
                tooltip: 'Refresh',
                onTap: onRefresh,
              ),
    );
  }

  Future<void> _openKindMenu(BuildContext context) async {
    final picked = await showPlusMenu<TimelineKind>(
      context: context,
      position: plusMenuPosition(context),
      items: [
        for (final k in TimelineKind.values)
          PlusMenuItem(value: k, label: streamLabelFor(k), checked: k == kind),
      ],
    );
    if (picked != null) onKindSelected!(picked);
  }
}
