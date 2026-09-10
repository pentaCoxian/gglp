import '../misskey/models/note.dart';

/// Per-receiver identity key — the same value as [Note.globalId].
///
/// Kept as a free function so hot paths can build the key once and use
/// it for map lookups, instead of calling the (allocating) getter
/// inside a comparison loop.
String noteKey(Note n) => '${n.sourceHost}:${n.id}';

/// Key for a raw `(sourceHost, noteId)` pair as carried by streaming
/// `noteUpdated` / delete events.
String noteKeyOf({required String sourceHost, required String noteId}) =>
    '$sourceHost:$noteId';

/// Build the `globalId -> Note` index for a visible list. O(n); used when
/// a list is replaced wholesale (initial page, refresh, pagination). The
/// streaming flush paths maintain the index incrementally instead.
Map<String, Note> indexNotes(Iterable<Note> notes) =>
    {for (final n in notes) noteKey(n): n};
