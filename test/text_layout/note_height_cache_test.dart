import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:misskey_gglp/storage/app_database.dart';
import 'package:misskey_gglp/storage/daos/height_cache_dao.dart';
import 'package:misskey_gglp/text_layout/note_height_cache.dart';

void main() {
  late AppDatabase db;
  late HeightCacheDao dao;
  late NoteHeightCache cache;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = HeightCacheDao(db);
    cache = NoteHeightCache(dao: dao);
  });

  tearDown(() async {
    cache.dispose();
    await db.close();
  });

  NoteHeightKey k({
    String host = 'misskey.io',
    String noteId = 'abc',
    int revision = 1,
    double width = 360,
    double textScale = 1.0,
    String themeId = 'light',
    bool cwExpanded = false,
    String mfmSettingsHash = 'v1',
  }) =>
      NoteHeightKey(
        host: host,
        noteId: noteId,
        revision: revision,
        width: width,
        textScale: textScale,
        themeId: themeId,
        cwExpanded: cwExpanded,
        mfmSettingsHash: mfmSettingsHash,
      );

  test('miss returns null then hits after put (memory tier)', () async {
    expect(cache.getSync(k()), isNull);
    cache.put(k(), 142.5);
    expect(cache.getSync(k()), 142.5);
  });

  test('different revision => miss', () async {
    cache.put(k(revision: 1), 100);
    expect(cache.getSync(k(revision: 2)), isNull);
  });

  test('different width => miss', () {
    cache.put(k(width: 360), 100);
    expect(cache.getSync(k(width: 480)), isNull);
  });

  test('different theme => miss', () {
    cache.put(k(themeId: 'light'), 100);
    expect(cache.getSync(k(themeId: 'dark')), isNull);
  });

  test('cwExpanded uses a separate cache slot', () {
    cache.put(k(cwExpanded: false), 80);
    cache.put(k(cwExpanded: true), 200);
    expect(cache.getSync(k(cwExpanded: false)), 80);
    expect(cache.getSync(k(cwExpanded: true)), 200);
  });

  test('disk warm-fill: a fresh cache reading the same DAO sees prior puts',
      () async {
    cache.put(k(), 99.9);
    // Wait one event-loop turn for the fire-and-forget Drift write.
    await Future<void>.delayed(Duration.zero);

    // New cache instance sharing the same DAO — simulates app restart.
    final cold = NoteHeightCache(dao: dao);
    addTearDown(cold.dispose);

    // First call schedules the disk fetch (returns null synchronously).
    expect(cold.getSync(k()), isNull);

    // Drain microtasks until the cache exposes the disk-loaded value.
    for (var i = 0; i < 20; i++) {
      if (cold.getSync(k()) != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(cold.getSync(k()), 99.9);
  });

  test('purgePriorRevisions removes both memory + disk entries below cutoff',
      () async {
    cache.put(k(revision: 1), 100);
    cache.put(k(revision: 2), 110);
    cache.put(k(revision: 3), 120);
    await Future<void>.delayed(Duration.zero);

    cache.purgePriorRevisions(
      host: 'misskey.io',
      noteId: 'abc',
      currentRevision: 3,
    );

    expect(cache.getSync(k(revision: 1)), isNull);
    expect(cache.getSync(k(revision: 2)), isNull);
    expect(cache.getSync(k(revision: 3)), 120);

    // Disk-side: revisions 1 and 2 should be gone too.
    expect(
      await dao.get(
        host: 'misskey.io',
        noteId: 'abc',
        revision: 1,
        width: 360,
        textScale: 1.0,
        themeId: 'light',
        cwExpanded: false,
        mfmSettingsHash: 'v1',
      ),
      isNull,
    );
  });
}
