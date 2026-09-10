import '../misskey/models/note.dart';
import 'note_keys.dart';

/// One slot in a merged feed: a note plus the per-account context that
/// produced it. Multiple accounts can deliver the same federated note;
/// we dedup but remember the first account that surfaced it.
class MergedTimelineItem {
  /// The account that delivered this note (host:userId).
  final String accountId;
  final Note note;
  final DateTime receivedAt;

  /// Federation-aware identity for cross-account dedup. Computed once
  /// here rather than via [Note.originId] on every comparison — the
  /// merge/dedup loops touch it for every item on every insert, and
  /// the getter allocates a string for local notes.
  final String originId;

  MergedTimelineItem({
    required this.accountId,
    required this.note,
    required this.receivedAt,
  }) : originId = note.originId;

  String get globalId => note.globalId;

  /// Same row, possibly with an updated note. Preserves [receivedAt]
  /// so a reaction patch doesn't reorder the feed.
  MergedTimelineItem withNote(Note next) => MergedTimelineItem(
        accountId: accountId,
        note: next,
        receivedAt: receivedAt,
      );

  /// Value equality on the parts a row renders from. [receivedAt] is
  /// deliberately excluded: a re-merge (pagination, releasing pending
  /// notes) stamps every item with a fresh `now`, and without this
  /// exclusion each of those would look like a changed row to a
  /// Riverpod `select` and rebuild every card on screen.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MergedTimelineItem &&
          other.accountId == accountId &&
          other.note == note);

  @override
  int get hashCode => Object.hash(accountId, note.sourceHost, note.id);
}

/// Pure functions for merging multi-account note streams.
///
/// sort key is
///   (createdAt desc, receivedAt desc, sourceHost, noteId).
///
/// Dedup uses [Note.originId] — the same federated note received by
/// multiple of our accounts collapses to one row. We keep the copy
/// delivered by the note's HOME server when available (it's the
/// authoritative source of reactions); otherwise the earliest-received.
class TimelineMergeEngine {
  const TimelineMergeEngine();

  /// Merge any number of per-account note lists into a single sorted,
  /// deduped feed.
  ///
  /// `now` is the fallback `receivedAt` for notes that came from an
  /// HTTP page (no per-note receive time). Pass it explicitly so tests
  /// stay deterministic.
  List<MergedTimelineItem> merge(
    Map<String, List<Note>> perAccount, {
    required DateTime now,
  }) {
    final byOriginId = <String, MergedTimelineItem>{};
    for (final entry in perAccount.entries) {
      final accountId = entry.key;
      for (final note in entry.value) {
        final candidate = MergedTimelineItem(
          accountId: accountId,
          note: note,
          receivedAt: now,
        );
        final id = candidate.originId;
        final existing = byOriginId[id];
        if (existing == null || _preferReplace(existing, candidate)) {
          byOriginId[id] = candidate;
        }
      }
    }
    final list = byOriginId.values.toList(growable: false);
    list.sort(_compare);
    return list;
  }

  /// Insert one new item (typically a streamed note) into an
  /// already-sorted merged list. Returns the new list; if an item with
  /// the same [originId] already exists, the better copy wins per
  /// [_preferReplace]. Thin wrapper over [insertMany].
  List<MergedTimelineItem> insertOne(
    List<MergedTimelineItem> sorted,
    MergedTimelineItem item,
  ) =>
      insertMany(sorted, [item]);

  /// Insert a batch of items into an already-sorted merged list with a
  /// single pass and a single output allocation.
  ///
  /// The streaming flush hands us every note that arrived in the last
  /// window at once; inserting them one by one would copy the whole
  /// list per note. Instead:
  ///   1. dedup the batch against itself by [originId] (best copy wins)
  ///   2. resolve each batch item against the existing list — an
  ///      existing copy that is better drops the incoming one, otherwise
  ///      the existing copy is marked for removal
  ///   3. sort the survivors and merge them with the existing list in
  ///      one linear walk.
  ///
  /// Returns [sorted] itself (no copy) when nothing changes.
  List<MergedTimelineItem> insertMany(
    List<MergedTimelineItem> sorted,
    Iterable<MergedTimelineItem> batch,
  ) {
    final incomingByOrigin = <String, MergedTimelineItem>{};
    for (final it in batch) {
      final existing = incomingByOrigin[it.originId];
      if (existing == null || _preferReplace(existing, it)) {
        incomingByOrigin[it.originId] = it;
      }
    }
    if (incomingByOrigin.isEmpty) return sorted;

    final dropExisting = <String>{};
    for (final existing in sorted) {
      final incoming = incomingByOrigin[existing.originId];
      if (incoming == null) continue;
      if (_preferReplace(existing, incoming)) {
        dropExisting.add(existing.originId);
      } else {
        // Existing copy is already the better one; drop incoming.
        incomingByOrigin.remove(existing.originId);
      }
    }
    if (incomingByOrigin.isEmpty) return sorted;

    final incoming = incomingByOrigin.values.toList(growable: false)
      ..sort(_compare);
    final out = <MergedTimelineItem>[];
    var i = 0;
    for (final existing in sorted) {
      if (dropExisting.contains(existing.originId)) continue;
      while (i < incoming.length && _compare(incoming[i], existing) <= 0) {
        out.add(incoming[i++]);
      }
      out.add(existing);
    }
    while (i < incoming.length) {
      out.add(incoming[i++]);
    }
    return out;
  }

  /// Remove all items matching the federation origin
  /// `(userHost ?? sourceHost, userId, noteId)`. We accept the same
  /// `(sourceHost, noteId)` tuple the streaming layer emits and resolve
  /// to origin via the items themselves.
  List<MergedTimelineItem> removeNote(
    List<MergedTimelineItem> sorted, {
    required String sourceHost,
    required String noteId,
  }) {
    // The deletion event tells us which receiving host saw the delete;
    // we need to remove every item that shares the SAME origin, not
    // just the one with matching sourceHost — otherwise a note deleted
    // on its home server would still show via the federated copy in
    // the unified feed.
    String? targetOriginId;
    for (final it in sorted) {
      if (it.note.sourceHost == sourceHost && it.note.id == noteId) {
        targetOriginId = it.originId;
        break;
      }
    }
    if (targetOriginId == null) return sorted;
    return sorted
        .where((it) => it.originId != targetOriginId)
        .toList(growable: false);
  }

  /// Decide whether `incoming` should replace `existing` in the deduped
  /// view. Rules in priority order:
  ///   1. The copy received by the note's HOME server wins (authoritative
  ///      reactions; correct emoji `@.` markers).
  ///   2. The newer-edit version wins.
  ///   3. Otherwise keep existing (stable on ties).
  static bool _preferReplace(
    MergedTimelineItem existing,
    MergedTimelineItem incoming,
  ) {
    final existingHome = existing.note.user.host == null;
    final incomingHome = incoming.note.user.host == null;
    if (existingHome != incomingHome) return incomingHome;

    final existingTime =
        existing.note.updatedAt ?? existing.note.createdAt;
    final incomingTime =
        incoming.note.updatedAt ?? incoming.note.createdAt;
    return incomingTime.isAfter(existingTime);
  }

  static int _compare(MergedTimelineItem a, MergedTimelineItem b) {
    final byCreated = b.note.createdAt.compareTo(a.note.createdAt);
    if (byCreated != 0) return byCreated;
    final byReceived = b.receivedAt.compareTo(a.receivedAt);
    if (byReceived != 0) return byReceived;
    final byHost = a.note.sourceHost.compareTo(b.note.sourceHost);
    if (byHost != 0) return byHost;
    return a.note.id.compareTo(b.note.id);
  }
}

/// Lookup indexes over a merged, deduped list.
///
/// [byId] is keyed by [MergedTimelineItem.originId] — the identity the
/// merged rows render under — so a row can watch `byId[originId]`
/// through a Riverpod `select` in O(1). [originByReceiver] maps the
/// `sourceHost:noteId` pair carried by streaming patch/delete events to
/// the originId of the copy we kept, so those events resolve to a row
/// without scanning the list.
typedef MergedIndex = ({
  Map<String, MergedTimelineItem> byId,
  Map<String, String> originByReceiver,
});

const MergedIndex emptyMergedIndex = (byId: {}, originByReceiver: {});

/// Build both indexes in one pass. O(n); called whenever the merged
/// list is replaced (one flush window, pagination, release-pending).
MergedIndex indexMerged(List<MergedTimelineItem> items) {
  final byId = <String, MergedTimelineItem>{};
  final originByReceiver = <String, String>{};
  for (final it in items) {
    byId[it.originId] = it;
    originByReceiver[noteKey(it.note)] = it.originId;
  }
  return (byId: byId, originByReceiver: originByReceiver);
}
