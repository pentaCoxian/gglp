import 'package:drift/drift.dart';

import '../app_database.dart';

part 'height_cache_dao.g.dart';

/// DAO over the `height_cache` table.
///
/// Cached note heights survive app restarts so the timeline can give
/// `SliverList` a stable estimated extent on the very first frame after
/// a refresh / kind switch / cold start, instead of measuring every
/// note from scratch and jittering the scroll view.
///
/// The composite key `(host, noteId, revision, width, textScale, themeId,
/// cwExpanded, mfmSettingsHash)` is intentionally wide — any of those
/// inputs changing produces a different layout, so we want a fresh
/// measurement instead of stale data.
@DriftAccessor(tables: [HeightCache])
class HeightCacheDao extends DatabaseAccessor<AppDatabase>
    with _$HeightCacheDaoMixin {
  HeightCacheDao(super.db);

  /// Look up a cached height. Returns null on miss.
  Future<double?> get({
    required String host,
    required String noteId,
    required int revision,
    required double width,
    required double textScale,
    required String themeId,
    required bool cwExpanded,
    required String mfmSettingsHash,
  }) async {
    final row = await (select(heightCache)
          ..where((t) =>
              t.host.equals(host) &
              t.noteId.equals(noteId) &
              t.revision.equals(revision) &
              t.width.equals(width) &
              t.textScale.equals(textScale) &
              t.themeId.equals(themeId) &
              t.cwExpanded.equals(cwExpanded) &
              t.mfmSettingsHash.equals(mfmSettingsHash)))
        .getSingleOrNull();
    return row?.height;
  }

  /// Store a measured height.
  Future<void> put({
    required String host,
    required String noteId,
    required int revision,
    required double width,
    required double textScale,
    required String themeId,
    required bool cwExpanded,
    required String mfmSettingsHash,
    required double height,
  }) {
    return into(heightCache).insert(
      HeightCacheCompanion(
        host: Value(host),
        noteId: Value(noteId),
        revision: Value(revision),
        width: Value(width),
        textScale: Value(textScale),
        themeId: Value(themeId),
        cwExpanded: Value(cwExpanded),
        mfmSettingsHash: Value(mfmSettingsHash),
        height: Value(height),
        computedAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Drop entries for a note when its revision bumps. Cheaper to call
  /// this than to leave stale rows lying around — the table is keyed
  /// on revision so they'd never be hit again, but they'd grow forever.
  Future<void> deletePriorRevisions({
    required String host,
    required String noteId,
    required int currentRevision,
  }) {
    return (delete(heightCache)
          ..where((t) =>
              t.host.equals(host) &
              t.noteId.equals(noteId) &
              t.revision.isSmallerThanValue(currentRevision)))
        .go();
  }
}
