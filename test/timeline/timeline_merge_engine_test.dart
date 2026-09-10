import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/misskey/models/note.dart';
import 'package:misskey_gglp/misskey/models/user.dart';
import 'package:misskey_gglp/timeline/timeline_merge_engine.dart';

void main() {
  Note makeNote({
    required String id,
    required String host,
    required DateTime createdAt,
    DateTime? updatedAt,
    String userId = 'u',
    String? userHost,
    String? uri,
  }) =>
      Note(
        id: id,
        sourceHost: host,
        user: User(id: userId, username: userId, host: userHost),
        createdAt: createdAt,
        updatedAt: updatedAt,
        uri: uri,
      );

  test('merge sorts by createdAt desc and dedups by globalId', () {
    final t0 = DateTime(2026, 5, 4, 12, 0, 0);
    final engine = const TimelineMergeEngine();

    final acctA = [
      makeNote(id: '2', host: 'a.example', createdAt: t0),
      makeNote(id: '1', host: 'a.example', createdAt: t0.subtract(const Duration(seconds: 30))),
    ];
    final acctB = [
      makeNote(id: '2', host: 'a.example', createdAt: t0), // dup of A's note 2
      makeNote(id: '5', host: 'b.example', createdAt: t0.add(const Duration(seconds: 10))),
    ];

    final merged = engine.merge(
      {'A': acctA, 'B': acctB},
      now: t0.add(const Duration(seconds: 30)),
    );

    expect(merged.map((m) => '${m.note.sourceHost}:${m.note.id}').toList(), [
      'b.example:5', // newest createdAt
      'a.example:2',
      'a.example:1',
    ]);
  });

  test('insertOne places new note at correct sorted position', () {
    final t0 = DateTime(2026, 5, 4, 12, 0, 0);
    final engine = const TimelineMergeEngine();

    final start = engine.merge(
      {
        'A': [
          makeNote(id: '1', host: 'a.example', createdAt: t0),
          makeNote(id: '0', host: 'a.example', createdAt: t0.subtract(const Duration(minutes: 5))),
        ],
      },
      now: t0,
    );

    // Newest streamed note → should land at the head.
    final newer = MergedTimelineItem(
      accountId: 'A',
      note: makeNote(
        id: '99',
        host: 'a.example',
        createdAt: t0.add(const Duration(seconds: 5)),
      ),
      receivedAt: t0.add(const Duration(seconds: 5)),
    );
    final after = engine.insertOne(start, newer);
    expect(after.first.note.id, '99');
    expect(after.length, 3);

    // Stream re-emits the same note (revision update). Should replace
    // in place, not duplicate.
    final replayed = MergedTimelineItem(
      accountId: 'A',
      note: makeNote(
        id: '99',
        host: 'a.example',
        createdAt: t0.add(const Duration(seconds: 5)),
      ),
      receivedAt: t0.add(const Duration(seconds: 6)),
    );
    final replayedList = engine.insertOne(after, replayed);
    expect(replayedList.length, 3);
  });

  test('removeNote drops matching items', () {
    final t0 = DateTime(2026, 5, 4, 12, 0, 0);
    final engine = const TimelineMergeEngine();
    final start = engine.merge(
      {
        'A': [
          makeNote(id: '1', host: 'a.example', createdAt: t0),
          makeNote(id: '2', host: 'a.example', createdAt: t0.subtract(const Duration(seconds: 1))),
        ],
      },
      now: t0,
    );
    final after = engine.removeNote(start, sourceHost: 'a.example', noteId: '1');
    expect(after.map((m) => m.note.id).toList(), ['2']);
  });

  test('dedups same federated note across multiple receivers (uri)', () {
    final t0 = DateTime(2026, 5, 4, 12, 0, 0);
    final engine = const TimelineMergeEngine();
    const apUri = 'https://misskey.systems/notes/HOMEID';

    // Same federated note. Misskey assigns DIFFERENT local ids on each
    // receiving server; only `uri` is stable across federation.
    // (Note: when received by the home server itself, `uri` is null —
    // Misskey only populates it for federated notes. The home copy
    // dedups against itself only via globalId; the federated copy
    // dedups against other federated copies via uri.)
    final fromFederatedIo = makeNote(
      id: 'IOID',
      host: 'misskey.io',
      createdAt: t0,
      userId: 'pentacoxian',
      userHost: 'misskey.systems',
      uri: apUri,
    );
    final fromFederatedNijimi = makeNote(
      id: 'NIJIID',
      host: 'nijimiss.moe',
      createdAt: t0,
      userId: 'pentacoxian',
      userHost: 'misskey.systems',
      uri: apUri,
    );

    final merged = engine.merge(
      {
        'ioAcct': [fromFederatedIo],
        'nijiAcct': [fromFederatedNijimi],
      },
      now: t0,
    );

    expect(merged, hasLength(1),
        reason: 'two federated copies of the same uri collapse');
  });

  test('dedups home copy (no uri) against federated copy (with uri)', () {
    final t0 = DateTime(2026, 5, 4, 12, 0, 0);
    final engine = const TimelineMergeEngine();

    // Home server: author is local, so Misskey omits `uri`. Local
    // id = HOMEID.
    final homeCopy = makeNote(
      id: 'HOMEID',
      host: 'misskey.io',
      createdAt: t0,
      userId: 'pentacoxian',
      // userHost null, uri null — local-to-sourceHost note
    );

    // Federated copy on a different server. Misskey populates `uri`
    // pointing back to the home server's note path.
    final federated = makeNote(
      id: 'FEDID',
      host: 'misskey.systems',
      createdAt: t0,
      userId: 'pentacoxian',
      userHost: 'misskey.io',
      uri: 'https://misskey.io/notes/HOMEID',
    );

    final merged = engine.merge(
      {
        'ioAcct': [homeCopy],
        'systemsAcct': [federated],
      },
      now: t0,
    );

    expect(merged, hasLength(1),
        reason: 'home copy and federated copy must collapse '
            '(home synthesizes the same canonical AP URI)');
  });

  test('insertOne dedups federated copies via uri', () {
    final t0 = DateTime(2026, 5, 4, 12, 0, 0);
    final engine = const TimelineMergeEngine();
    const apUri = 'https://misskey.systems/notes/HOMEID';

    final start = engine.merge(
      {
        'ioAcct': [
          makeNote(
            id: 'IOID',
            host: 'misskey.io',
            createdAt: t0,
            userId: 'pentacoxian',
            userHost: 'misskey.systems',
            uri: apUri,
          ),
        ],
      },
      now: t0,
    );
    expect(start, hasLength(1));

    // Same note arrives via federation through a different account.
    // Different local id, same uri → must replace, not duplicate.
    final fromNiji = MergedTimelineItem(
      accountId: 'nijiAcct',
      note: makeNote(
        id: 'NIJIID',
        host: 'nijimiss.moe',
        createdAt: t0,
        userId: 'pentacoxian',
        userHost: 'misskey.systems',
        uri: apUri,
      ),
      receivedAt: t0.add(const Duration(seconds: 1)),
    );
    final after = engine.insertOne(start, fromNiji);
    expect(after, hasLength(1));
  });

  _batchTests();
}

// ---------------------------------------------------------------------------
// Batch insert + item equality (streaming flush path)
// ---------------------------------------------------------------------------

void _batchTests() {
  Note makeNote({
    required String id,
    required String host,
    required DateTime createdAt,
    DateTime? updatedAt,
    String userId = 'u',
    String? userHost,
    String? uri,
  }) =>
      Note(
        id: id,
        sourceHost: host,
        user: User(id: userId, username: userId, host: userHost),
        createdAt: createdAt,
        updatedAt: updatedAt,
        uri: uri,
      );

  MergedTimelineItem item(Note n, {String account = 'A', DateTime? at}) =>
      MergedTimelineItem(
        accountId: account,
        note: n,
        receivedAt: at ?? n.createdAt,
      );

  group('insertMany', () {
    final t0 = DateTime(2026, 5, 4, 12, 0, 0);
    const engine = TimelineMergeEngine();

    List<MergedTimelineItem> start() => engine.merge(
          {
            'A': [
              makeNote(id: '30', host: 'a', createdAt: t0),
              makeNote(
                  id: '20',
                  host: 'a',
                  createdAt: t0.subtract(const Duration(minutes: 1))),
              makeNote(
                  id: '10',
                  host: 'a',
                  createdAt: t0.subtract(const Duration(minutes: 2))),
            ],
          },
          now: t0,
        );

    test('merges an unsorted batch into sorted position in one pass', () {
      final batch = [
        // Older than everything → tail.
        item(makeNote(
            id: '05',
            host: 'a',
            createdAt: t0.subtract(const Duration(minutes: 3)))),
        // Newest → head.
        item(makeNote(
            id: '40', host: 'a', createdAt: t0.add(const Duration(seconds: 5)))),
        // Between 20 and 30.
        item(makeNote(
            id: '25',
            host: 'a',
            createdAt: t0.subtract(const Duration(seconds: 30)))),
      ];
      final out = engine.insertMany(start(), batch);
      expect(out.map((m) => m.note.id).toList(),
          ['40', '30', '25', '20', '10', '05']);
    });

    test('is equivalent to sequential insertOne', () {
      final batch = [
        item(makeNote(
            id: '40', host: 'a', createdAt: t0.add(const Duration(seconds: 5)))),
        item(makeNote(
            id: '25',
            host: 'a',
            createdAt: t0.subtract(const Duration(seconds: 30)))),
        item(makeNote(
            id: '41', host: 'a', createdAt: t0.add(const Duration(seconds: 6)))),
      ];
      final viaMany = engine.insertMany(start(), batch);
      var viaOne = start();
      for (final it in batch) {
        viaOne = engine.insertOne(viaOne, it);
      }
      expect(viaMany.map((m) => m.note.id).toList(),
          viaOne.map((m) => m.note.id).toList());
    });

    test('dedups within the batch by originId, keeping the better copy', () {
      const apUri = 'https://home.example/notes/X';
      final federated = item(
        makeNote(
          id: 'F1',
          host: 'a',
          createdAt: t0.add(const Duration(seconds: 1)),
          userHost: 'home.example',
          uri: apUri,
        ),
        account: 'A',
      );
      // Same note as received by its HOME server (author host null).
      // Home copy wins per _preferReplace, and the synthesized
      // originId matches the federated `uri`.
      final home = item(
        makeNote(
          id: 'X',
          host: 'home.example',
          createdAt: t0.add(const Duration(seconds: 1)),
        ),
        account: 'B',
      );
      final out = engine.insertMany(start(), [federated, home]);
      expect(out, hasLength(4));
      expect(out.first.note.id, 'X');
      expect(out.first.accountId, 'B');
    });

    test('existing better copy drops the incoming one; list is reused', () {
      final base = start();
      // Re-emit of note 30 with an identical timestamp: existing wins on
      // ties, so nothing changes and the very same list comes back.
      final replay = item(makeNote(id: '30', host: 'a', createdAt: t0));
      final out = engine.insertMany(base, [replay]);
      expect(identical(out, base), isTrue);
    });

    test('incoming newer edit replaces the existing copy in place', () {
      final base = start();
      final edited = item(makeNote(
        id: '30',
        host: 'a',
        createdAt: t0,
        updatedAt: t0.add(const Duration(minutes: 5)),
      ));
      final out = engine.insertMany(base, [edited]);
      expect(out, hasLength(3));
      expect(out.first.note.updatedAt, isNotNull);
    });

    test('empty batch returns the same list', () {
      final base = start();
      expect(identical(engine.insertMany(base, const []), base), isTrue);
    });
  });

  group('MergedTimelineItem equality', () {
    final t0 = DateTime(2026, 5, 4, 12, 0, 0);

    test('equal on accountId + note regardless of receivedAt', () {
      final n = makeNote(id: '1', host: 'a', createdAt: t0);
      final a = item(n, at: t0);
      final b = item(n, at: t0.add(const Duration(hours: 1)));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs when the note changed (reaction patch)', () {
      final n = makeNote(id: '1', host: 'a', createdAt: t0);
      final a = item(n);
      final b = a.withNote(n.copyWith(renoteCount: 3));
      expect(a == b, isFalse);
      expect(b.receivedAt, a.receivedAt);
    });

    test('caches originId', () {
      final n = makeNote(id: '1', host: 'a', createdAt: t0);
      expect(item(n).originId, n.originId);
    });
  });
}
