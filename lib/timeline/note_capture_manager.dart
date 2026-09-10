import 'dart:async';

import '../core/logger.dart';
import '../misskey/streaming/stream_connection.dart';

/// Tracks visible notes and tells the streaming connection to capture
/// (subNote) / un-capture (unsubNote) them.
///
/// Strategy:
///   - tracked: full set of currently-on-screen note ids (sourceHost
///     filter applied per-account)
///   - debounce: when a note leaves the viewport, wait `_leaveDebounce`
///     before unsubscribing — small scrolls would otherwise thrash
///   - cap: never have more than `_inFlightCap` notes captured; if the
///     viewport contains more, drop the oldest captures
///
/// Routes its decisions to a single [StreamConnection]. The unified
/// timeline uses one manager per (account, kind); the supervisor tracks
/// nothing centrally — capture is per-connection because subNote frames
/// are scoped to the websocket they're sent on.
class NoteCaptureManager {
  static const _leaveDebounce = Duration(milliseconds: 500);
  static const _inFlightCap = 200;

  final StreamConnection _conn;
  final _log = const Log('NoteCapture');

  /// Notes currently in the viewport. Distinguished from [_captured]
  /// because we may capture more (recently visible) than are visible
  /// right now.
  final _visible = <String>{};

  /// Notes the connection currently has captured.
  final _captured = <String>{};

  /// Pending unsubscribe timers per noteId. Cancelled if the note
  /// becomes visible again before the debounce fires.
  final _pendingLeaves = <String, Timer>{};

  NoteCaptureManager(this._conn);

  void onVisible(String noteId) {
    _pendingLeaves.remove(noteId)?.cancel();
    if (!_visible.add(noteId)) return;
    _ensureCaptured(noteId);
  }

  void onHidden(String noteId) {
    if (!_visible.remove(noteId)) return;
    _pendingLeaves[noteId]?.cancel();
    _pendingLeaves[noteId] = Timer(_leaveDebounce, () {
      _pendingLeaves.remove(noteId);
      // Only release if still not visible.
      if (_visible.contains(noteId)) return;
      _release(noteId);
    });
  }

  void dispose() {
    for (final t in _pendingLeaves.values) {
      t.cancel();
    }
    _pendingLeaves.clear();
    for (final id in _captured.toList()) {
      _conn.uncaptureNote(id);
    }
    _captured.clear();
    _visible.clear();
  }

  void _ensureCaptured(String noteId) {
    if (_captured.contains(noteId)) return;
    if (_captured.length >= _inFlightCap) {
      // Evict an arbitrary captured note that's NOT currently visible
      // to make room. With LinkedHashSet semantics this picks the
      // oldest insertion that's also not visible.
      String? evict;
      for (final id in _captured) {
        if (!_visible.contains(id)) {
          evict = id;
          break;
        }
      }
      if (evict != null) {
        _release(evict);
      } else {
        // Everything captured is also visible — over the cap. Skip
        // capturing this new one rather than thrashing.
        _log.warn('capture cap full, skipping $noteId');
        return;
      }
    }
    _captured.add(noteId);
    _conn.captureNote(noteId);
  }

  void _release(String noteId) {
    if (!_captured.remove(noteId)) return;
    _conn.uncaptureNote(noteId);
  }
}
