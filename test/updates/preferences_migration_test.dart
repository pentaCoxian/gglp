import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/storage/app_database.dart';
import 'package:misskey_gglp/storage/daos/preferences_dao.dart';

void main() {
  test(
    'schema 8 upgrades preferences without changing existing settings',
    () async {
      final db = AppDatabase.forTesting(
        NativeDatabase.memory(
          setup: (sqlite) {
            sqlite.execute('''
        CREATE TABLE app_preferences (
          id TEXT NOT NULL PRIMARY KEY DEFAULT 'singleton',
          theme_mode TEXT NOT NULL DEFAULT 'system',
          text_scale REAL NOT NULL DEFAULT 1.0,
          disable_animated_mfm INTEGER NOT NULL DEFAULT 0,
          reduced_motion_override TEXT NOT NULL DEFAULT '',
          blur_sensitive_channels INTEGER NOT NULL DEFAULT 1,
          updated_at INTEGER NOT NULL
        );
        INSERT INTO app_preferences VALUES
          ('singleton', 'dark', 1.3, 1, 'off', 0, 123456);
        PRAGMA user_version = 8;
      ''');
          },
        ),
      );
      addTearDown(db.close);
      final row = (await PreferencesDao(db).read())!;
      expect(row.themeMode, 'dark');
      expect(row.textScale, 1.3);
      expect(row.disableAnimatedMfm, isTrue);
      expect(row.reducedMotionOverride, 'off');
      expect(row.blurSensitiveChannels, isFalse);
      expect(row.automaticUpdateChecks, isTrue);
      expect(row.lastUpdateCheckAt, isNull);
      expect(row.dismissedUpdateVersionCode, isNull);
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 9);
    },
  );

  test(
    'updater and appearance writes preserve each other, including first write',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final dao = PreferencesDao(db);
      final checked = DateTime.utc(2026, 9, 11, 3, 30);
      await dao.writeUpdatePreferences(
        automaticChecks: false,
        lastCheckAt: checked,
        dismissedVersionCode: 11,
      );
      expect((await dao.read())!.themeMode, 'system');
      await dao.write(
        themeMode: 'dark',
        textScale: 1.4,
        disableAnimatedMfm: true,
        reducedMotionOverride: 'off',
        blurSensitiveChannels: false,
      );
      var row = (await dao.read())!;
      expect(row.automaticUpdateChecks, isFalse);
      expect(row.lastUpdateCheckAt?.toUtc(), checked);
      expect(row.dismissedUpdateVersionCode, 11);
      await dao.writeUpdatePreferences(
        automaticChecks: true,
        lastCheckAt: null,
        dismissedVersionCode: null,
      );
      row = (await dao.read())!;
      expect(row.themeMode, 'dark');
      expect(row.textScale, 1.4);
      expect(row.disableAnimatedMfm, isTrue);
      expect(row.reducedMotionOverride, 'off');
      expect(row.blurSensitiveChannels, isFalse);
      expect(row.lastUpdateCheckAt, isNull);
    },
  );
}
