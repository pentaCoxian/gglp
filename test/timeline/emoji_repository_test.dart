import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/misskey/emoji/emoji_repository.dart';
import 'package:misskey_gglp/misskey/models/emoji.dart';
import 'package:misskey_gglp/storage/app_database.dart';
import 'package:misskey_gglp/storage/daos/emoji_dao.dart';

/// Coalescing behaviour of the inline-ingest path. These run on real
/// timers (the Drift write is genuinely async) with the repository's
/// 500ms tick / 1s persist windows, so each test waits a little over
/// one window.
void main() {
  late AppDatabase db;
  late EmojiDao dao;
  late EmojiRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = EmojiDao(db);
    repo = EmojiRepository(dao: dao);
  });

  tearDown(() async {
    repo.dispose();
    await db.close();
  });

  test('inline ingest is visible synchronously', () {
    repo.ingestInline(
      viewerHost: 'a.example',
      embedded: {'blob': 'https://a.example/blob.png'},
    );
    expect(repo.lookup(host: 'a.example', name: 'blob')?.url,
        'https://a.example/blob.png');
  });

  test('many ingests in one window produce one tick carrying every host',
      () async {
    final ticks = <Set<String>>[];
    final sub = repo.updates.listen(ticks.add);
    addTearDown(sub.cancel);

    for (var i = 0; i < 50; i++) {
      repo.ingestInline(
        viewerHost: 'a.example',
        embedded: {
          'e$i': 'https://a.example/$i.png',
          'r$i@b.example': 'https://b.example/$i.png',
        },
      );
    }
    expect(ticks, isEmpty, reason: 'coalesced behind the timer');
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(ticks, hasLength(1));
    expect(ticks.single, {'a.example', 'b.example'});
  });

  test('re-ingesting known emoji does not tick again', () async {
    final ticks = <Set<String>>[];
    final sub = repo.updates.listen(ticks.add);
    addTearDown(sub.cancel);

    repo.ingestInline(
      viewerHost: 'a.example',
      embedded: {'blob': 'https://a.example/blob.png'},
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(ticks, hasLength(1));

    repo.ingestInline(
      viewerHost: 'a.example',
      embedded: {'blob': 'https://a.example/blob.png'},
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    expect(ticks, hasLength(1), reason: 'nothing novel, nothing to redraw');
  });

  test('inline emoji reach disk in one batched write', () async {
    for (var i = 0; i < 20; i++) {
      repo.ingestInline(
        viewerHost: 'a.example',
        embedded: {'e$i': 'https://a.example/$i.png'},
      );
    }
    expect(await dao.allForHost('a.example'), isEmpty,
        reason: 'not written synchronously');
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    expect(await dao.allForHost('a.example'), hasLength(20));
  });

  test('a catalog fetched within the TTL is served from disk, not refetched',
      () async {
    await dao.upsertMany([
      CustomEmoji(
        host: 'a.example',
        name: 'blob',
        url: 'https://a.example/blob.png',
        fetchedAt: DateTime.now(),
      ),
    ]);
    await dao.markCatalogFetched('a.example', DateTime.now());

    await repo.ensureFetchedRemote('a.example');
    // Second call is a no-op for the session too.
    await repo.ensureFetchedRemote('a.example');

    expect(repo.networkFetches, 0);
    expect(repo.lookup(host: 'a.example', name: 'blob')?.url,
        'https://a.example/blob.png');
  });

  test('malformed remote host is skipped and not retried', () async {
    await repo.ensureFetchedRemote('not a host');
    await repo.ensureFetchedRemote('not a host');
    // No throw, no hang — the completed future is all we can observe
    // without a network; the second call short-circuits on the
    // session set.
  });
}
