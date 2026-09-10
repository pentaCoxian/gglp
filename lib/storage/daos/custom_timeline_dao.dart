import 'package:drift/drift.dart';

import '../../timeline/custom_timeline.dart';
import '../app_database.dart';

part 'custom_timeline_dao.g.dart';

/// CRUD over user-defined unified timelines.
///
/// The DAO returns the in-memory [CustomTimeline] model rather than the
/// raw drift row so callers don't have to decode the sources blob
/// themselves. `watchAll` powers the AccountDrawer's live list.
@DriftAccessor(tables: [CustomTimelines])
class CustomTimelineDao extends DatabaseAccessor<AppDatabase>
    with _$CustomTimelineDaoMixin {
  CustomTimelineDao(super.db);

  Stream<List<CustomTimeline>> watchAll() {
    return (select(customTimelines)
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch()
        .map((rows) => rows.map(_toModel).toList(growable: false));
  }

  Future<List<CustomTimeline>> getAll() async {
    final rows = await (select(customTimelines)
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .get();
    return rows.map(_toModel).toList(growable: false);
  }

  Future<CustomTimeline?> get(String id) async {
    final row = await (select(customTimelines)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<void> upsert(CustomTimeline timeline) {
    return into(customTimelines).insert(
      CustomTimelinesCompanion(
        id: Value(timeline.id),
        name: Value(timeline.name),
        sortOrder: Value(timeline.sortOrder),
        sourcesJson: Value(CustomTimeline.encodeSources(timeline.sources)),
        createdAt: Value(timeline.createdAt),
        updatedAt: Value(timeline.updatedAt),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> removeById(String id) {
    return (delete(customTimelines)..where((t) => t.id.equals(id))).go();
  }

  static CustomTimeline _toModel(CustomTimelineRow r) => CustomTimeline(
        id: r.id,
        name: r.name,
        sortOrder: r.sortOrder,
        sources: CustomTimeline.decodeSources(r.sourcesJson),
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );
}
