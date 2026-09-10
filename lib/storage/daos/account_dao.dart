import 'package:drift/drift.dart';

import '../../misskey/models/account.dart';
import '../app_database.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  Future<List<Account>> getAll() async {
    final rows = await select(accounts).get();
    return rows.map(_toModel).toList();
  }

  Stream<List<Account>> watchAll() {
    return select(accounts).watch().map(
          (rows) => rows.map(_toModel).toList(),
        );
  }

  Future<Account?> getById(String id) async {
    final row = await (select(accounts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<void> upsert(Account a) async {
    await into(accounts).insertOnConflictUpdate(_toRow(a));
  }

  Future<void> remove(String id) async {
    await (delete(accounts)..where((t) => t.id.equals(id))).go();
  }

  Future<void> touch(String id) async {
    await (update(accounts)..where((t) => t.id.equals(id))).write(
      AccountsCompanion(lastUsedAt: Value(DateTime.now())),
    );
  }

  static Account _toModel(AccountRow r) => Account(
        id: r.id,
        host: r.host,
        userId: r.userId,
        username: r.username,
        displayName: r.displayName,
        avatarUrl: r.avatarUrl,
        isCat: r.isCat,
        isAdmin: r.isAdmin,
        addedAt: r.addedAt,
        lastUsedAt: r.lastUsedAt,
      );

  static AccountsCompanion _toRow(Account a) => AccountsCompanion(
        id: Value(a.id),
        host: Value(a.host),
        userId: Value(a.userId),
        username: Value(a.username),
        displayName: Value(a.displayName),
        avatarUrl: Value(a.avatarUrl),
        isCat: Value(a.isCat),
        isAdmin: Value(a.isAdmin),
        addedAt: Value(a.addedAt ?? DateTime.now()),
        lastUsedAt: Value(a.lastUsedAt),
      );
}
