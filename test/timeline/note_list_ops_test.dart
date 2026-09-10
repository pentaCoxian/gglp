import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/misskey/models/note.dart';
import 'package:misskey_gglp/misskey/models/user.dart';
import 'package:misskey_gglp/misskey/streaming/stream_messages.dart';
import 'package:misskey_gglp/timeline/note_keys.dart';
import 'package:misskey_gglp/timeline/note_list_ops.dart';

void main() {
  final t0 = DateTime(2026, 5, 4, 12, 0, 0);
  const host = 'a.example';
  const channel = 'tl:test';

  Note note(String id, {int minutesAgo = 0}) => Note(
        id: id,
        sourceHost: host,
        user: const User(id: 'u', username: 'u'),
        createdAt: t0.subtract(Duration(minutes: minutesAgo)),
      );

  NoteAdded added(Note n, {String on = channel}) =>
      NoteAdded(channelId: on, note: n);
  NoteDeleted deleted(String id) => NoteDeleted(noteId: id, sourceHost: host);
  NoteUpdated reacted(String id, {String key = '👍', String user = 'other'}) =>
      NoteUpdated(
        noteId: id,
        sourceHost: host,
        patch: {
          'type': 'reacted',
          'body': {'reaction': key, 'userId': user},
        },
      );

  const ops = NoteListOps(cap: 5);

  ({List<Note> notes, Map<String, Note> byId}) seed(List<Note> notes) =>
      (notes: notes, byId: indexNotes(notes));

  NoteBatchResult? apply(
    List<MisskeyStreamEvent> batch, {
    required List<Note> notes,
    List<Note> pending = const [],
    bool hold = false,
  }) {
    final s = seed(notes);
    return ops.applyEvents(
      notes: s.notes,
      byId: s.byId,
      pending: pending,
      holdPending: hold,
      viewerUserId: 'me',
      batch: batch,
      accepts: (e) => e.channelId == channel,
    );
  }

  List<String> ids(Iterable<Note> ns) => ns.map((n) => n.id).toList();

  void expectIndexed(NoteBatchResult r) {
    expect(r.byId.length, r.notes.length, reason: 'index size');
    for (final n in r.notes) {
      expect(identical(r.byId[noteKey(n)], n), isTrue,
          reason: 'index must point at the list object for ${n.id}');
    }
  }

  test('prepends newest arrival first and indexes it', () {
    final r = apply(
      [added(note('n1')), added(note('n2')), added(note('n3'))],
      notes: [note('o1', minutesAgo: 5)],
    )!;
    expect(ids(r.notes), ['n3', 'n2', 'n1', 'o1']);
    expect(ids(r.added), ['n3', 'n2', 'n1']);
    expectIndexed(r);
  });

  test('dedups against visible, pending and the same window', () {
    final r = apply(
      [
        added(note('o1')), // already visible
        added(note('p1')), // already pending
        added(note('n1')),
        added(note('n1')), // repeat in-window
      ],
      notes: [note('o1')],
      pending: [note('p1')],
      hold: true,
    )!;
    expect(ids(r.pending), ['n1', 'p1']);
    expect(ids(r.notes), ['o1'], reason: 'held: visible untouched');
    expect(ids(r.added), ['n1']);
  });

  test('ignores adds from other channels', () {
    final r = apply(
      [added(note('x'), on: 'tl:other')],
      notes: [note('o1')],
    );
    expect(r, isNull);
  });

  test('trims to the cap and keeps the index consistent', () {
    final r = apply(
      [for (var i = 0; i < 4; i++) added(note('n$i'))],
      notes: [note('o1'), note('o2'), note('o3')],
    )!;
    expect(r.notes, hasLength(5));
    expect(ids(r.notes), ['n3', 'n2', 'n1', 'n0', 'o1']);
    expectIndexed(r);
    expect(r.byId.containsKey(noteKey(note('o3'))), isFalse);
  });

  test('a batch larger than the cap keeps only the newest', () {
    final r = apply(
      [for (var i = 0; i < 8; i++) added(note('n$i'))],
      notes: [note('o1')],
    )!;
    expect(ids(r.notes), ['n7', 'n6', 'n5', 'n4', 'n3']);
    expectIndexed(r);
  });

  test('patches a visible note in one list pass and re-points the index', () {
    final base = [note('o1'), note('o2')];
    final r = apply(
      [reacted('o2'), reacted('o2', key: '❤'), reacted('o2', user: 'me')],
      notes: base,
    )!;
    expect(identical(r.notes[0], base[0]), isTrue,
        reason: 'untouched rows keep identity');
    final patched = r.notes[1];
    expect(patched.reactions.map((x) => '${x.key}:${x.count}'),
        containsAll(['👍:2', '❤:1']));
    expect(patched.myReaction, '👍', reason: 'viewer patch mirrored');
    expectIndexed(r);
  });

  test('patches a note that arrived in the same window', () {
    final r = apply(
      [added(note('n1')), reacted('n1')],
      notes: const [],
    )!;
    expect(r.notes.single.reactions.single.count, 1);
  });

  test('patch for an unknown note changes nothing', () {
    expect(apply([reacted('ghost')], notes: [note('o1')]), isNull);
  });

  test('deletes from visible, pending and the window', () {
    final r = apply(
      [
        added(note('n1')),
        deleted('n1'), // in-window add cancelled
        deleted('o2'), // visible
        deleted('p1'), // pending
        reacted('o2'), // patch after delete is dropped
      ],
      notes: [note('o1'), note('o2')],
      pending: [note('p1'), note('p2')],
      hold: true,
    )!;
    expect(ids(r.notes), ['o1']);
    expect(ids(r.pending), ['p2']);
    expect(r.added, isEmpty);
    expectIndexed(r);
  });

  test('add → delete → add for the same id lands once', () {
    final r = apply(
      [deleted('o1'), added(note('o1'))],
      notes: [note('o1'), note('o2')],
    )!;
    expect(ids(r.notes), ['o1', 'o2']);
    expectIndexed(r);
  });

  test('returns null when nothing changed', () {
    expect(apply(const [], notes: [note('o1')]), isNull);
    expect(apply([deleted('nope')], notes: [note('o1')]), isNull);
  });

  test('prependVisible releases pending on top and drops trimmed keys', () {
    final s = seed([note('o1'), note('o2'), note('o3'), note('o4')]);
    final r = ops.prependVisible([note('p1'), note('p2')], s.notes, s.byId);
    expect(ids(r.notes), ['p1', 'p2', 'o1', 'o2', 'o3']);
    expect(r.byId.keys.toSet(), r.notes.map(noteKey).toSet());
  });
}
