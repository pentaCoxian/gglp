import 'package:drift/drift.dart';

import '../../misskey/models/server.dart';
import '../app_database.dart';

part 'server_dao.g.dart';

@DriftAccessor(tables: [Servers])
class ServerDao extends DatabaseAccessor<AppDatabase> with _$ServerDaoMixin {
  ServerDao(super.db);

  Future<Server?> getByHost(String host) async {
    final r = await (select(servers)..where((t) => t.host.equals(host)))
        .getSingleOrNull();
    return r == null ? null : _toModel(r);
  }

  Future<void> upsert(Server s) async {
    await into(servers).insertOnConflictUpdate(_toRow(s));
  }

  static Server _toModel(ServerRow r) => Server(
        host: r.host,
        name: r.name,
        description: r.description,
        softwareName: r.softwareName,
        softwareVersion: r.softwareVersion,
        iconUrl: r.iconUrl,
        bannerUrl: r.bannerUrl,
        metaFetchedAt: r.metaFetchedAt,
      );

  static ServersCompanion _toRow(Server s) => ServersCompanion(
        host: Value(s.host),
        name: Value(s.name),
        description: Value(s.description),
        softwareName: Value(s.softwareName),
        softwareVersion: Value(s.softwareVersion),
        iconUrl: Value(s.iconUrl),
        bannerUrl: Value(s.bannerUrl),
        metaFetchedAt: Value(s.metaFetchedAt),
      );
}
