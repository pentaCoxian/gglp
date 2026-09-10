import 'package:drift/drift.dart';

import '../app_database.dart';

part 'reaction_recent_dao.g.dart';

/// Per-account picker recents.
///
/// The reaction picker surfaces the user's most-used reactions (per the
/// active account so two accounts on different servers don't pollute
/// each other's lists) at the top of the unicode + custom-emoji tabs.
/// Stored as the canonical reaction `key` (unicode codepoint or
/// `:name@host:`) so it round-trips through `notes/reactions/create`.
@DriftAccessor(tables: [ReactionRecents])
class ReactionRecentDao extends DatabaseAccessor<AppDatabase>
    with _$ReactionRecentDaoMixin {
  ReactionRecentDao(super.db);

  /// Most-recently / most-used recents, capped at [limit].
  Future<List<String>> recent({
    required String accountId,
    int limit = 24,
  }) async {
    final rows = await (select(reactionRecents)
          ..where((t) => t.accountId.equals(accountId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.lastUsedAt,
                  mode: OrderingMode.desc,
                ),
            (t) => OrderingTerm(
                  expression: t.useCount,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit))
        .get();
    return rows.map((r) => r.reactionKey).toList(growable: false);
  }

  /// Bump the (count, lastUsedAt) for a given reaction. Insert-or-update
  /// in a single transaction so two rapid taps don't race.
  Future<void> bump({
    required String accountId,
    required String reactionKey,
  }) async {
    await transaction(() async {
      final existing = await (select(reactionRecents)
            ..where((t) =>
                t.accountId.equals(accountId) &
                t.reactionKey.equals(reactionKey)))
          .getSingleOrNull();
      if (existing == null) {
        await into(reactionRecents).insert(
          ReactionRecentsCompanion(
            accountId: Value(accountId),
            reactionKey: Value(reactionKey),
            useCount: const Value(1),
            lastUsedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await (update(reactionRecents)
              ..where((t) =>
                  t.accountId.equals(accountId) &
                  t.reactionKey.equals(reactionKey)))
            .write(
          ReactionRecentsCompanion(
            useCount: Value(existing.useCount + 1),
            lastUsedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }
}
