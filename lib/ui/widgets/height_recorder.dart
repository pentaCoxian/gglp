import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../misskey/models/note.dart';
import '../../text_layout/note_height_cache.dart';

/// Wraps a note card and records its actually-rendered height into the
/// `NoteHeightCache` after layout.
///
/// Why post-layout instead of pre-measuring? Pre-measuring requires a
/// stable viewport width and a separate measurement pass; post-layout
/// recording is "free" — Flutter already laid the widget out, so we
/// just observe `RenderBox.size.height`.
///
/// The cache is then warm for the next cold-start / refresh / kind-
/// switch — exactly the case where the timeline currently has no extent
/// hint and `SliverList` jitters.
class HeightRecorder extends ConsumerStatefulWidget {
  final Note note;
  final double width;
  final String themeId;
  final double textScale;
  final bool cwExpanded;
  final String mfmSettingsHash;
  final Widget child;

  const HeightRecorder({
    super.key,
    required this.note,
    required this.width,
    required this.themeId,
    required this.textScale,
    required this.cwExpanded,
    required this.mfmSettingsHash,
    required this.child,
  });

  @override
  ConsumerState<HeightRecorder> createState() => _HeightRecorderState();
}

class _HeightRecorderState extends ConsumerState<HeightRecorder> {
  final _key = GlobalKey();
  double? _lastRecordedHeight;

  /// True while a post-frame `_record` is pending, so N rebuilds in one
  /// frame (an effect-laden note rebuilds every tick) queue one
  /// callback, not N.
  bool _scheduled = false;

  @override
  void didUpdateWidget(covariant HeightRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Note revision bumped => any cached height for prior revisions is
    // stale. Clear the local debounce so we re-record after the new
    // layout pass.
    if (oldWidget.note.revision != widget.note.revision ||
        oldWidget.width != widget.width) {
      _lastRecordedHeight = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduled = false;
        if (!mounted) return;
        _record();
      });
    }
    return SizedBox(
      key: _key,
      child: widget.child,
    );
  }

  void _record() {
    if (!mounted) return;
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final h = box.size.height;
    if (h <= 0) return;
    // Debounce: identical height => skip the cache write so we don't
    // spam Drift on every animation frame for an effect-laden note.
    if (_lastRecordedHeight != null &&
        (h - _lastRecordedHeight!).abs() < 0.5) {
      return;
    }
    _lastRecordedHeight = h;
    final cache = ref.read(noteHeightCacheProvider);
    cache.put(
      NoteHeightKey(
        host: widget.note.sourceHost,
        noteId: widget.note.id,
        revision: widget.note.revision,
        width: widget.width,
        textScale: widget.textScale,
        themeId: widget.themeId,
        cwExpanded: widget.cwExpanded,
        mfmSettingsHash: widget.mfmSettingsHash,
      ),
      h,
    );
  }
}
