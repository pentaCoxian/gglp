import 'dart:convert';

import 'package:drift/drift.dart';

import '../../misskey/models/emoji.dart';
import '../app_database.dart';

part 'emoji_dao.g.dart';

@DriftAccessor(tables: [Emojis, EmojiCatalogs])
class EmojiDao extends DatabaseAccessor<AppDatabase> with _$EmojiDaoMixin {
  EmojiDao(super.db);

  /// When [host]'s full catalog was last downloaded, or null if never.
  Future<DateTime?> catalogFetchedAt(String host) async {
    final r = await (select(emojiCatalogs)..where((t) => t.host.equals(host)))
        .getSingleOrNull();
    return r?.fetchedAt;
  }

  Future<void> markCatalogFetched(String host, DateTime at) {
    return into(emojiCatalogs).insert(
      EmojiCatalogsCompanion(host: Value(host), fetchedAt: Value(at)),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<CustomEmoji?> get(String host, String name) async {
    final r = await (select(emojis)
          ..where((t) => t.host.equals(host) & t.name.equals(name)))
        .getSingleOrNull();
    return r == null ? null : _toModel(r);
  }

  /// Bulk fetch — used when warming a per-host catalog from disk.
  Future<List<CustomEmoji>> allForHost(String host) async {
    final rows =
        await (select(emojis)..where((t) => t.host.equals(host))).get();
    return rows.map(_toModel).toList(growable: false);
  }

  Future<void> upsertMany(Iterable<CustomEmoji> items) async {
    await batch((b) {
      for (final e in items) {
        b.insert(emojis, _toRow(e), mode: InsertMode.insertOrReplace);
      }
    });
  }

  static CustomEmoji _toModel(EmojiRow r) {
    final aliases = r.aliasesJson == null
        ? const <String>[]
        : (jsonDecode(r.aliasesJson!) as List).cast<String>();
    return CustomEmoji(
      host: r.host,
      name: r.name,
      url: r.url,
      aliases: aliases,
      category: r.category,
      sensitive: r.sensitive,
      fetchedAt: r.fetchedAt,
    );
  }

  static EmojisCompanion _toRow(CustomEmoji e) => EmojisCompanion(
        host: Value(e.host),
        name: Value(e.name),
        url: Value(e.url),
        aliasesJson: Value(jsonEncode(e.aliases)),
        category: Value(e.category),
        sensitive: Value(e.sensitive),
        fetchedAt: Value(e.fetchedAt ?? DateTime.now()),
      );
}
