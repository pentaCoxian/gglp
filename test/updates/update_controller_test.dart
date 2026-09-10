import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/app/updates/update_bridge.dart';
import 'package:misskey_gglp/app/updates/update_client.dart';
import 'package:misskey_gglp/app/updates/update_controller.dart';
import 'package:misskey_gglp/app/updates/update_manifest.dart';
import 'package:misskey_gglp/app/updates/update_preferences.dart';

AppUpdate _update({
  int code = 11,
  String name = '0.9.1',
  int minSdk = 21,
}) => AppUpdate(
  manifest: UpdateManifest(
    versionName: name,
    versionCode: code,
    packageId: updatePackageId,
    minSdk: minSdk,
    apkFileName: 'gglp-$name.apk',
    size: 4,
    sha256: code.toRadixString(16).padLeft(64, '0'),
  ),
  apkUrl: Uri.parse(
    'https://github.com/pentaCoxian/gglp/releases/download/v$name/gglp-$name.apk',
  ),
  releaseNotes: 'Some release notes.',
);

class _Store implements UpdatePreferenceStore {
  UpdatePreferences value = const UpdatePreferences();
  final writes = <UpdatePreferences>[];
  @override
  Future<UpdatePreferences> read() async => value;
  @override
  Future<void> write(UpdatePreferences preferences) async {
    writes.add(preferences);
    value = preferences;
  }
}

class _Source implements UpdateSource {
  AppUpdate update = _update();
  Object? failure;
  int checks = 0;
  int downloads = 0;
  Completer<AppUpdate>? checkGate;
  Completer<void>? downloadGate;
  bool writerClosed = true;

  @override
  Future<AppUpdate> latest(CancelToken cancelToken) async {
    checks++;
    if (failure != null) throw failure!;
    return checkGate == null ? update : await checkGate!.future;
  }

  @override
  Future<void> download(
    AppUpdate update,
    String path,
    CancelToken cancelToken,
    void Function(int received, int total) onProgress,
  ) async {
    downloads++;
    writerClosed = false;
    try {
      if (downloadGate != null) {
        await Future.any([
          downloadGate!.future,
          cancelToken.whenCancel.then((error) => throw error),
        ]);
      }
      if (cancelToken.isCancelled) throw cancelToken.cancelError!;
      onProgress(4, 4);
    } finally {
      writerClosed = true;
    }
  }

  @override
  void close() {}
}

class _Bridge implements UpdateBridge {
  InstalledApp installed = const InstalledApp(
    packageId: updatePackageId,
    versionName: '0.9.0',
    versionCode: 10,
    sdkInt: 36,
  );
  AppUpdate? pending;
  bool permission = true;
  int permissionRequests = 0;
  int installations = 0;
  int verifications = 0;
  int cleanups = 0;
  Object? verificationFailure;
  Object? installFailure;
  Completer<String>? prepareGate;
  Completer<AppUpdate?>? pendingGate;
  Completer<void>? cleanupGate;
  void Function()? onCleanup;

  @override
  Future<InstalledApp> installedApp() async => installed;
  @override
  Future<String> prepareDownload(int versionCode) async =>
      prepareGate == null
          ? '/not-a-real-directory/gglp-$versionCode.part'
          : await prepareGate!.future;
  @override
  Future<AppUpdate?> pendingUpdate() async =>
      pendingGate == null ? pending : await pendingGate!.future;
  @override
  Future<String> verify(String path, UpdateManifest manifest) async {
    verifications++;
    if (verificationFailure != null) throw verificationFailure!;
    final verified = path.replaceAll('.part', '.apk');
    pending = AppUpdate(manifest: manifest, downloadedPath: verified);
    return verified;
  }

  @override
  Future<bool> canInstall() async => permission;
  @override
  Future<void> openPermissionSettings() async => permissionRequests++;
  @override
  Future<void> install(String path, UpdateManifest manifest) async {
    if (installFailure != null) throw installFailure!;
    installations++;
  }

  @override
  Future<void> cleanup() async {
    cleanups++;
    onCleanup?.call();
    await cleanupGate?.future;
    if (pending != null &&
        pending!.manifest.versionCode <= installed.versionCode) {
      pending = null;
    }
  }
}

Future<void> _flush() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _Source source;
  late _Bridge bridge;
  late _Store store;
  late DateTime now;
  final controllers = <UpdateController>[];

  UpdateController create({bool supported = true}) {
    final controller = UpdateController(
      source: source,
      bridge: bridge,
      store: store,
      supported: supported,
      now: () => now,
    );
    controllers.add(controller);
    return controller;
  }

  setUp(() {
    source = _Source();
    bridge = _Bridge();
    store = _Store();
    now = DateTime.utc(2026, 9, 11, 10);
  });
  tearDown(() {
    for (final controller in controllers) {
      controller.dispose();
    }
    controllers.clear();
  });

  test(
    'automatic checks are foreground-only, daily and persisted across restart',
    () async {
      final first = create();
      await first.initialized;
      expect(source.checks, 0);
      await first.foreground();
      expect(source.checks, 1);
      expect(
        source.downloads,
        0,
        reason: 'Available updates never download themselves',
      );
      await first.background();
      await first.foreground();
      expect(source.checks, 1);
      final restarted = create();
      await restarted.foreground();
      expect(source.checks, 1);
      now = now.add(const Duration(days: 1));
      await restarted.foreground();
      expect(source.checks, 2);
      expect(store.value.lastCheckAt, now);
    },
  );

  test('opt-out persists while manual checks remain available', () async {
    final controller = create();
    await controller.setAutomaticChecks(false);
    await controller.foreground();
    expect(source.checks, 0);
    expect(store.value.automaticChecks, isFalse);
    await controller.check();
    expect(source.checks, 1);
  });

  test(
    'offline automatic failures are quiet and count toward daily cadence',
    () async {
      source.failure = const SocketException('offline');
      final controller = create();
      await controller.foreground();
      expect(source.checks, 1);
      expect(controller.snapshot.error, isNull);
      await controller.foreground();
      expect(source.checks, 1);
      await controller.check();
      expect(controller.snapshot.error, contains('Could not check GitHub'));
      expect(controller.snapshot.stage, UpdateStage.idle);
    },
  );

  test('concurrent manual requests coalesce', () async {
    source.checkGate = Completer();
    final controller = create();
    final tasks = [controller.check(), controller.check(), controller.check()];
    await _flush();
    expect(source.checks, 1);
    source.checkGate!.complete(source.update);
    await Future.wait(tasks);
    expect(controller.snapshot.update?.manifest.versionCode, 11);
  });

  test(
    'integer build numbers control updates, including equal and older builds',
    () async {
      final controller = create();
      for (final code in [9, 10]) {
        source.update = _update(code: code, name: '99.0.0');
        await controller.check();
        expect(controller.snapshot.update, isNull);
        expect(controller.snapshot.message, 'GGLP is up to date.');
      }
      source.update = _update(code: 12, name: '0.1.0');
      await controller.check();
      expect(controller.snapshot.update?.manifest.versionCode, 12);
    },
  );

  test(
    'incompatible Android SDK and malformed metadata are controlled errors',
    () async {
      final controller = create();
      source.update = _update(minSdk: 37);
      await controller.check();
      expect(controller.snapshot.update, isNull);
      expect(controller.snapshot.error, contains('does not support'));
      source.failure = const UpdateException('Bad manifest.');
      await controller.check();
      expect(controller.snapshot.error, 'Bad manifest.');
    },
  );

  test(
    'dismissal hides the notice for one version but keeps Settings available',
    () async {
      final controller = create();
      await controller.check();
      expect(controller.snapshot.showNotice, isTrue);
      await controller.dismiss();
      expect(controller.snapshot.showNotice, isFalse);
      expect(controller.snapshot.update, isNotNull);
      final restarted = create();
      await restarted.check();
      expect(restarted.snapshot.showNotice, isFalse);
      source.update = _update(code: 12, name: '0.9.2');
      await restarted.check();
      expect(restarted.snapshot.showNotice, isTrue);
    },
  );

  test(
    'verified download waits for explicit installation and survives restart',
    () async {
      final controller = create();
      await controller.check();
      await controller.download();
      expect(bridge.verifications, 1);
      expect(bridge.installations, 0);
      expect(controller.snapshot.stage, UpdateStage.readyToInstall);
      final restarted = create();
      await restarted.initialized;
      expect(restarted.snapshot.update?.downloadedPath, endsWith('.apk'));
      expect(source.downloads, 1);
      await restarted.install();
      expect(bridge.installations, 1);
      expect(restarted.snapshot.stage, UpdateStage.installerOpened);
      expect(
        restarted.snapshot.installed?.versionCode,
        10,
        reason: 'Opening the installer is not success',
      );
      await restarted.foreground();
      expect(restarted.snapshot.stage, UpdateStage.readyToInstall);
      expect(restarted.snapshot.message, contains('unchanged'));
    },
  );

  test(
    'permission denial is recoverable and grant resumes only explicit install',
    () async {
      bridge.permission = false;
      final controller = create();
      await controller.check();
      await controller.download();
      await controller.install();
      expect(bridge.permissionRequests, 1);
      expect(bridge.installations, 0);
      await controller.foreground();
      expect(controller.snapshot.message, contains('not granted'));
      expect(bridge.installations, 0);
      await controller.install();
      bridge.permission = true;
      await controller.foreground();
      expect(bridge.installations, 1);
    },
  );

  test(
    'verification and installation failures expose retry without claiming success',
    () async {
      bridge.verificationFailure = PlatformException(code: 'invalid_apk');
      final controller = create();
      await controller.check();
      await controller.download();
      expect(controller.snapshot.update?.downloadedPath, isNull);
      expect(controller.snapshot.error, contains('failed verification'));
      bridge.verificationFailure = null;
      await controller.download();
      bridge.installFailure = PlatformException(code: 'invalid_apk');
      await controller.install();
      expect(controller.snapshot.update?.downloadedPath, isNull);
      expect(controller.snapshot.update?.apkUrl, isNotNull);
      expect(bridge.installations, 0);
    },
  );

  test(
    'background cancellation waits for download writer before cleanup',
    () async {
      source.downloadGate = Completer();
      final controller = create();
      await controller.check();
      final downloading = controller.download();
      await _flush();
      expect(source.writerClosed, isFalse);
      bridge.onCleanup = () => expect(source.writerClosed, isTrue);
      await controller.background();
      await downloading;
      expect(controller.snapshot.stage, UpdateStage.idle);
      expect(controller.snapshot.error, isNull);
    },
  );

  test(
    'cancellation after preparing a file removes it before HTTP starts',
    () async {
      final temp = await Directory.systemTemp.createTemp('gglp-prepare-test-');
      addTearDown(() => temp.delete(recursive: true));
      final file = await File('${temp.path}/update.part').create();
      bridge.prepareGate = Completer();
      final controller = create();
      await controller.check();
      final downloading = controller.download();
      await _flush();
      final cancelling = controller.cancelDownload();
      bridge.prepareGate!.complete(file.path);
      await Future.wait([downloading, cancelling]);
      expect(source.downloads, 0);
      expect(await file.exists(), isFalse);
    },
  );

  test('a slow resume cannot overwrite a newer download operation', () async {
    store.value = const UpdatePreferences(automaticChecks: false);
    final controller = create();
    await controller.check();
    bridge.pendingGate = Completer();
    final resuming = controller.foreground();
    await _flush();
    source.downloadGate = Completer();
    final downloading = controller.download();
    await _flush();
    bridge.pendingGate!.complete(null);
    await resuming;
    expect(controller.snapshot.stage, UpdateStage.downloading);
    await controller.download();
    expect(source.downloads, 1);
    await controller.cancelDownload();
    await downloading;
  });

  test(
    'an older cached APK does not replace a newly discovered release on resume',
    () async {
      final controller = create();
      await controller.check();
      await controller.download();
      source.update = _update(code: 12, name: '0.9.2');
      await controller.check();
      expect(controller.snapshot.update?.manifest.versionCode, 12);
      await controller.foreground();
      expect(controller.snapshot.update?.manifest.versionCode, 12);
      expect(controller.snapshot.update?.downloadedPath, isNull);
    },
  );

  test(
    'no action can overlap a completed download still cleaning up',
    () async {
      final controller = create();
      await controller.check();
      bridge.cleanupGate = Completer();
      final downloading = controller.download();
      await _flush();
      expect(controller.snapshot.busy, isTrue);
      await controller.download();
      await controller.install();
      await controller.check();
      expect(source.downloads, 1);
      expect(source.checks, 1);
      expect(bridge.installations, 0);
      await controller.setAutomaticChecks(false);
      bridge.cleanupGate!.complete();
      await downloading;
      expect(controller.snapshot.automaticChecks, isFalse);
      expect(controller.snapshot.stage, UpdateStage.readyToInstall);
    },
  );

  test(
    'non-Android clients do not initialize native code or check GitHub',
    () async {
      final controller = create(supported: false);
      await controller.foreground();
      await controller.check();
      expect(source.checks, 0);
      expect(bridge.cleanups, 0);
      expect(controller.snapshot.supported, isFalse);
    },
  );
}
