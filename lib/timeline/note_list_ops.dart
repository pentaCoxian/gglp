import '../misskey/models/note.dart';
import '../misskey/models/reaction_patch.dart';
import '../misskey/streaming/stream_messages.dart';
import 'note_keys.dart';

/// Result of [NoteListOps.applyEvents]: the replacement visible list,
/// its index, the pending buffer, and the notes that were newly added
/// (newest first) so the caller can ingest their emoji once.
class NoteBatchResult {
  final List<Note> notes;
  final Map<String, Note> byId;
  final List<Note> pending;
  final List<Note> added;

  const NoteBatchResult({
    required this.notes,
    required this.byId,
    required this.pending,
    required this.added,
  });
}

/// Pure list operations shared by the single-account timeline
/// controllers (per-kind, channel, antenna). They all keep the same
/// `(notes, byId, pending, holdPending)` shape and used to carry three
/// copies of the same per-note prepend / patch / remove code; this is
/// the one batched implementation, kept free of Riverpod so it can be
/// unit-tested directly.
class NoteListOps {
  const NoteListOps({required this.cap});

  /// Hard cap on the visible list and on the pending buffer.
  final int cap;

  /// `[...head, ...tail]` trimmed to [cap], built in one pass (no
  /// concat-then-sublist double copy).
  List<Note> prependCapped(List<Note> head, List<Note> tail) {
    final out = <Note>[];
    if (head.length >= cap) {
      out.addAll(head.take(cap));
      return out;
    }
    out.addAll(head);
    final room = cap - out.length;
    out.addAll(room >= tail.length ? tail : tail.take(room));
    return out;
  }

  /// Prepend [head] to the visible list and update the index
  /// incrementally: add the new keys, drop the keys of anything the
  /// cap pushed off the tail. Copies the index once.
  ({List<Note> notes, Map<String, Note> byId}) prependVisible(
    List<Note> head,
    List<Note> tail,
    Map<String, Note> byId,
  ) {
    final notes = prependCapped(head, tail);
    final index = Map.of(byId);
    final keptHead = head.length.clamp(0, cap);
    final keptTail = notes.length - keptHead;
    for (var i = keptTail; i < tail.length; i++) {
      index.remove(noteKey(tail[i]));
    }
    for (var i = 0; i < keptHead; i++) {
      index[noteKey(head[i])] = head[i];
    }
    return (notes: notes, byId: index);
  }

  /// Apply one buffered window of stream events.
  ///
  /// Events are replayed in arrival order so add → patch → delete
  /// sequences inside one window resolve exactly as they would have
  /// when applied one at a time:
  ///   - adds are deduped against the visible index, the pending
  ///     buffer and earlier adds in the same window (HTTP fetch +
  ///     stream race), then prepended newest-first
  ///   - patches hit notes still in the window in place; for visible
  ///     notes they're collected into an identity-keyed replace map so
  ///     the list is rebuilt at most once
  ///   - deletes drop from the window, the visible list and pending.
  /// Pending notes are not patched (unchanged from the per-note code).
  ///
  /// Returns null when the window changed nothing. [accepts] filters
  /// which `NoteAdded` events belong to this list (channel match).
  NoteBatchResult? applyEvents({
    required List<Note> notes,
    required Map<String, Note> byId,
    required List<Note> pending,
    required bool holdPending,
    required String? viewerUserId,
    required Iterable<MisskeyStreamEvent> batch,
    required bool Function(NoteAdded event) accepts,
  }) {
    // Keys currently held in the pending buffer; only needed for
    // dedupe when there is something pending.
    final pendingKeys =
        pending.isEmpty ? null : {for (final n in pending) noteKey(n)};

    // New notes in arrival order. A slot goes null when the same
    // window also deletes that note.
    final fresh = <Note?>[];
    final freshIndex = <String, int>{};
    // Visible notes replaced by a patch / removed by a delete, keyed by
    // the object currently in the list so the rebuild pass needs no
    // key allocation per row.
    final replace = Map<Note, Note>.identity();
    final gone = Set<Note>.identity();
    final goneKeys = <String>{};
    // (sourceHost, noteId) pairs to purge from pending, which isn't
    // indexed.
    final pendingDeletes = <(String, String)>[];

    for (final event in batch) {
      switch (event) {
        case NoteAdded(:final note):
          if (!accepts(event)) continue;
          final key = noteKey(note);
          if (byId.containsKey(key) && !goneKeys.contains(key)) continue;
          if (pendingKeys != null && pendingKeys.contains(key)) continue;
          if (freshIndex.containsKey(key)) continue;
          freshIndex[key] = fresh.length;
          fresh.add(note);
        case NoteDeleted(:final noteId, :final sourceHost):
          final key = noteKeyOf(sourceHost: sourceHost, noteId: noteId);
          final fi = freshIndex.remove(key);
          if (fi != null) {
            fresh[fi] = null;
            continue;
          }
          final visible = byId[key];
          if (visible != null) {
            gone.add(visible);
            goneKeys.add(key);
            replace.remove(visible);
          }
          if (pendingKeys != null && pendingKeys.contains(key)) {
            pendingDeletes.add((sourceHost, noteId));
          }
        case NoteUpdated(:final noteId, :final sourceHost, :final patch):
          if (patch == null) continue;
          final key = noteKeyOf(sourceHost: sourceHost, noteId: noteId);
          final fi = freshIndex[key];
          if (fi != null) {
            fresh[fi] = ReactionPatch.apply(
              fresh[fi]!,
              patch,
              viewerUserId: viewerUserId,
            );
            continue;
          }
          final original = byId[key];
          if (original == null || gone.contains(original)) continue;
          final base = replace[original] ?? original;
          final updated =
              ReactionPatch.apply(base, patch, viewerUserId: viewerUserId);
          if (!identical(updated, base)) replace[original] = updated;
        case ConnectionStateChanged():
        case NotificationReceived():
          break;
      }
    }

    var outNotes = notes;
    Map<String, Note>? index;
    var outPending = pending;
    var dirty = false;

    if (replace.isNotEmpty || gone.isNotEmpty) {
      outNotes = [
        for (final n in notes)
          if (!gone.contains(n)) replace[n] ?? n,
      ];
      index = Map.of(byId);
      for (final key in goneKeys) {
        index.remove(key);
      }
      for (final updated in replace.values) {
        index[noteKey(updated)] = updated;
      }
      dirty = true;
    }
    if (pendingDeletes.isNotEmpty) {
      outPending = [
        for (final n in pending)
          if (!pendingDeletes.any((d) => d.$1 == n.sourceHost && d.$2 == n.id))
            n,
      ];
      dirty = true;
    }

    // Newest arrival goes to the head, matching one-at-a-time prepends.
    final newestFirst = <Note>[
      for (var i = fresh.length - 1; i >= 0; i--)
        if (fresh[i] != null) fresh[i]!,
    ];
    if (newestFirst.isNotEmpty) {
      if (holdPending) {
        outPending = prependCapped(newestFirst, outPending);
      } else {
        final r = prependVisible(newestFirst, outNotes, index ?? byId);
        outNotes = r.notes;
        index = r.byId;
      }
      dirty = true;
    }

    if (!dirty) return null;
    return NoteBatchResult(
      notes: outNotes,
      byId: index ?? byId,
      pending: outPending,
      added: newestFirst,
    );
  }
}
