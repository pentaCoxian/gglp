import 'package:flutter/material.dart';

/// **The geometry invariant of the entire MFM rendering pipeline.**
///
/// Every Tier 3 motion effect (shake, jelly, jump, spin, tada, blur,
/// flip, rotate, bounce) wraps its child in this box. The wrapped
/// effect is allowed to render BEYOND the layout box (visually) but
/// must NOT change the reported [RenderBox.size] — otherwise the
/// `note_height_cache`  keyed on `(host, noteId, revision, width,
/// textScale, themeId, cwExpanded, mfmSettingsHash)` will silently
/// drift and the timeline scroll will jitter exactly when it matters
/// most (during streaming bursts).
///
/// How the invariant holds: every effect is a [Transform] (translate /
/// scale / rotate) or a paint-only filter, and `RenderTransform` is a
/// proxy box that reports its child's size untouched — nothing lays
/// out larger than the child, so no `OverflowBox` is needed. The test
/// `test/mfm/clipped_effect_box_test.dart` pins this for every effect.
///
/// Painting is deliberately NOT clipped for motion effects: `$[jump]`
/// rises 8px, `$[shake]` jitters 2px, `$[spin]` / `$[tada]` sweep past
/// the box corners. An unconditional `ClipRect` here used to chop those
/// glyphs mid-animation; Misskey web lets them overflow (inline-block,
/// visible overflow) and so do we.
///
/// [clip] is opt-in for effects whose *painting* needs a bound: a
/// [BackdropFilter] (`$[blur]`) filters everything inside its nearest
/// ancestor clip, so without one it would blur the whole card.
class ClippedEffectBox extends StatelessWidget {
  final Widget child;

  /// Hard-clip painting to the layout box. Off for motion effects.
  final bool clip;

  const ClippedEffectBox({super.key, required this.child, this.clip = false});

  @override
  Widget build(BuildContext context) {
    if (!clip) return child;
    return ClipRect(child: child);
  }
}
