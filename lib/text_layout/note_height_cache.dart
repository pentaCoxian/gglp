import 'dart:async';
import 'dart:collection';

import '../core/logger.dart';
import '../storage/daos/height_cache_dao.dart';

/// Cache key for a single rendered note height.
///
/// any change to one of these inputs implies a
/// different on-screen layout. The renderer must agree with the
/// calculator on every component used here, otherwise we cache a
/// height that doesn't match what we draw.
class NoteHeightKey {
  final String host;
  final String noteId;
  final int revision;
  final double width;
  final double textScale;
  final String themeId;
  final bool cwExpanded;
  final String mfmSettingsHash;

  const NoteHeightKey({
    required this.host,
    required this.noteId,
    required this.revision,
    required this.width,
    required this.textScale,
    required this.themeId,
    required this.cwExpanded,
    required this.mfmSettingsHash,
  });

  @override
  bool operator ==(Object other) =>
      other is NoteHeightKey &&
      other.host == host &&
      other.noteId == noteId &&
      other.revision == revision &&
      other.width == width &&
      other.textScale == textScale &&
      other.themeId == themeId &&
      other.cwExpanded == cwExpanded &&
      other.mfmSettingsHash == mfmSettingsHash;

  @override
  int get hashCode => Object.hash(
        host,
        noteId,
        revision,
        width,
        textScale,
        themeId,
        cwExpanded,
        mfmSettingsHash,
      );
}

/// Two-tier height cache.
///
/// Tier 1: bounded LRU in memory for the working set of currently /
///   recently visible notes. Lookups are synchronous so the timeline
///   can ask for a height during `findChildIndexCallback` /
///   `addAutomaticKeepAlives` paths.
/// Tier 2: Drift-backed table (`height_cache`) so heights survive
///   refresh, kind switch, and cold start. Disk reads are async and
///   trigger a hot-cache fill plus a `notifyListeners` callback so
///   the timeline can re-render with the cached extent.
///
/// Concurrency: writes are fire-and-forget; failures are logged.
class NoteHeightCache {
  static const int _maxMemoryEntries = 4096;

  final _log = const Log('NoteHeightCache');
  final HeightCacheDao _dao;

  /// LRU: insertion order = most-recently-used first.
  final LinkedHashMap<NoteHeightKey, double> _hot = LinkedHashMap();

  /// Keys whose disk row we've checked already (hit or miss). Avoids
  /// hammering Drift with the same query when the renderer paints the
  /// same off-screen item repeatedly during overscroll.
  final Set<NoteHeightKey> _coldChecked = {};

  /// Outstanding disk reads, so the same key isn't fetched twice.
  final Map<NoteHeightKey, Future<double?>> _inFlight = {};

  /// Listeners for "the cache changed" — the timeline subscribes so it
  /// can rebuild with the freshly-loaded extent.
  final _changes = StreamController<NoteHeightKey>.broadcast();
  Stream<NoteHeightKey> get changes => _changes.stream;

  NoteHeightCache({required HeightCacheDao dao}) : _dao = dao;

  /// Synchronous lookup. Returns null on miss; the call also schedules
  /// a disk fetch the first time we see a given key, so the next
  /// timeline rebuild after the fetch completes will hit.
  double? getSync(NoteHeightKey key) {
    final hot = _hot[key];
    if (hot != null) {
      // Touch for LRU.
      _hot.remove(key);
      _hot[key] = hot;
      return hot;
    }
    if (_coldChecked.add(key)) {
      _scheduleDiskFetch(key);
    }
    return null;
  }

  /// Insert/update. Hot cache eviction is FIFO on the LRU; disk write
  /// is fire-and-forget.
  void put(NoteHeightKey key, double height) {
    _hot.remove(key);
    _hot[key] = height;
    _coldChecked.add(key);
    if (_hot.length > _maxMemoryEntries) {
      _hot.remove(_hot.keys.first);
    }
    unawaited(_dao
        .put(
      host: key.host,
      noteId: key.noteId,
      revision: key.revision,
      width: key.width,
      textScale: key.textScale,
      themeId: key.themeId,
      cwExpanded: key.cwExpanded,
      mfmSettingsHash: key.mfmSettingsHash,
      height: height,
    )
        .catchError((Object e, StackTrace st) {
      _log.warn('persist height failed: $e', stack: st);
    }));
    _changes.add(key);
  }

  void _scheduleDiskFetch(NoteHeightKey key) {
    if (_inFlight.containsKey(key)) return;
    final f = _dao
        .get(
      host: key.host,
      noteId: key.noteId,
      revision: key.revision,
      width: key.width,
      textScale: key.textScale,
      themeId: key.themeId,
      cwExpanded: key.cwExpanded,
      mfmSettingsHash: key.mfmSettingsHash,
    )
        .then<double?>((h) {
      if (h != null) {
        _hot[key] = h;
        if (_hot.length > _maxMemoryEntries) {
          _hot.remove(_hot.keys.first);
        }
        _changes.add(key);
      }
      return h;
    }).catchError((Object e, StackTrace st) {
      _log.warn('disk fetch failed: $e', stack: st);
      return null;
    }).whenComplete(() => _inFlight.remove(key));
    _inFlight[key] = f;
  }

  /// Clean up stale revisions for a note when we observe a bumped
  /// revision. Best-effort — failure is logged.
  void purgePriorRevisions({
    required String host,
    required String noteId,
    required int currentRevision,
  }) {
    _hot.removeWhere((k, _) =>
        k.host == host && k.noteId == noteId && k.revision < currentRevision);
    _coldChecked.removeWhere((k) =>
        k.host == host && k.noteId == noteId && k.revision < currentRevision);
    unawaited(_dao
        .deletePriorRevisions(
      host: host,
      noteId: noteId,
      currentRevision: currentRevision,
    )
        .catchError((Object e, StackTrace st) {
      _log.warn('purge prior revisions failed: $e', stack: st);
    }));
  }

  void dispose() {
    _changes.close();
  }
}
