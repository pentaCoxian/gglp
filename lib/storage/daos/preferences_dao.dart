import 'package:drift/drift.dart';

import '../app_database.dart';

part 'preferences_dao.g.dart';

/// Singleton-row DAO for [AppPreferences].
///
/// `read()` returns null on first launch (table empty); the controller
/// treats that as "use defaults". Each writer updates only its own
/// columns, so appearance and update preferences cannot reset each other.
@DriftAccessor(tables: [AppPreferences])
class PreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$PreferencesDaoMixin {
  PreferencesDao(super.db);

  static const _id = 'singleton';

  Future<AppPreferenceRow?> read() {
    return (select(appPreferences)
      ..where((t) => t.id.equals(_id))).getSingleOrNull();
  }

  Stream<AppPreferenceRow?> watch() {
    return (select(appPreferences)
      ..where((t) => t.id.equals(_id))).watchSingleOrNull();
  }

  Future<void> write({
    required String themeMode,
    required double textScale,
    required bool disableAnimatedMfm,
    required String reducedMotionOverride,
    required bool blurSensitiveChannels,
  }) {
    return into(appPreferences).insertOnConflictUpdate(
      AppPreferencesCompanion(
        id: const Value(_id),
        themeMode: Value(themeMode),
        textScale: Value(textScale),
        disableAnimatedMfm: Value(disableAnimatedMfm),
        reducedMotionOverride: Value(reducedMotionOverride),
        blurSensitiveChannels: Value(blurSensitiveChannels),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> writeUpdatePreferences({
    required bool automaticChecks,
    required DateTime? lastCheckAt,
    required int? dismissedVersionCode,
  }) {
    return into(appPreferences).insertOnConflictUpdate(
      AppPreferencesCompanion(
        id: const Value(_id),
        automaticUpdateChecks: Value(automaticChecks),
        lastUpdateCheckAt: Value(lastCheckAt),
        dismissedUpdateVersionCode: Value(dismissedVersionCode),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
