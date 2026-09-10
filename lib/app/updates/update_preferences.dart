import '../../storage/daos/preferences_dao.dart';

class UpdatePreferences {
  final bool automaticChecks;
  final DateTime? lastCheckAt;
  final int? dismissedVersionCode;

  const UpdatePreferences({
    this.automaticChecks = true,
    this.lastCheckAt,
    this.dismissedVersionCode,
  });

  bool shouldCheck(DateTime now) =>
      automaticChecks &&
      (lastCheckAt == null ||
          now.difference(lastCheckAt!) >= const Duration(days: 1));
}

abstract interface class UpdatePreferenceStore {
  Future<UpdatePreferences> read();
  Future<void> write(UpdatePreferences preferences);
}

class DatabaseUpdatePreferenceStore implements UpdatePreferenceStore {
  final PreferencesDao Function() _dao;
  const DatabaseUpdatePreferenceStore(this._dao);

  @override
  Future<UpdatePreferences> read() async {
    final row = await _dao().read();
    return UpdatePreferences(
      automaticChecks: row?.automaticUpdateChecks ?? true,
      lastCheckAt: row?.lastUpdateCheckAt,
      dismissedVersionCode: row?.dismissedUpdateVersionCode,
    );
  }

  @override
  Future<void> write(UpdatePreferences preferences) =>
      _dao().writeUpdatePreferences(
        automaticChecks: preferences.automaticChecks,
        lastCheckAt: preferences.lastCheckAt,
        dismissedVersionCode: preferences.dismissedVersionCode,
      );
}
