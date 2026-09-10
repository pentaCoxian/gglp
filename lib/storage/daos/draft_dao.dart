import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';

part 'draft_dao.g.dart';

/// In-progress compose drafts.
///
/// Drafts are owned by an account; the picker only lists drafts whose
/// `accountId` matches the active poster. We don't enforce a maximum
/// count — Drift handles thousands of rows fine and the UI lists them
/// most-recent-first, so the user can prune manually.
@DriftAccessor(tables: [Drafts])
class DraftDao extends DatabaseAccessor<AppDatabase> with _$DraftDaoMixin {
  DraftDao(super.db);

  /// Live stream for the current account, ordered by most-recently
  /// edited first.
  Stream<List<DraftRow>> watchForAccount(String accountId) {
    return (select(drafts)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.updatedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<DraftRow?> get(String id) {
    return (select(drafts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert-or-replace. Draft id is owned by the caller (a v4 UUID);
  /// passing the same id "saves" updates over the prior content.
  Future<void> upsert({
    required String id,
    required String accountId,
    String? text,
    String? cw,
    String visibility = 'public',
    bool localOnly = false,
    String? replyId,
    String? renoteId,
    String? sourceNoteUri,
    String? sourceHost,
    List<String>? fileIds,
    String? channelId,
    String? channelName,
    DateTime? createdAt,
  }) async {
    final now = DateTime.now();
    await into(drafts).insert(
      DraftsCompanion(
        id: Value(id),
        accountId: Value(accountId),
        body: Value(text),
        cw: Value(cw),
        visibility: Value(visibility),
        localOnly: Value(localOnly),
        replyId: Value(replyId),
        renoteId: Value(renoteId),
        sourceNoteUri: Value(sourceNoteUri),
        sourceHost: Value(sourceHost),
        fileIdsJson:
            Value(fileIds == null ? null : jsonEncode(fileIds)),
        channelId: Value(channelId),
        channelName: Value(channelName),
        createdAt: Value(createdAt ?? now),
        updatedAt: Value(now),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> removeById(String id) {
    return (delete(drafts)..where((t) => t.id.equals(id))).go();
  }

  static List<String> decodeFileIds(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      return (jsonDecode(json) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }
}
