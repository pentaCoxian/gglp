import 'package:flutter/services.dart';

import 'update_manifest.dart';

abstract interface class UpdateBridge {
  Future<InstalledApp> installedApp();
  Future<String> prepareDownload(int versionCode);
  Future<AppUpdate?> pendingUpdate();
  Future<String> verify(String path, UpdateManifest manifest);
  Future<bool> canInstall();
  Future<void> openPermissionSettings();
  Future<void> install(String path, UpdateManifest manifest);
  Future<void> cleanup();
}

class AndroidUpdateBridge implements UpdateBridge {
  final MethodChannel _channel;
  const AndroidUpdateBridge([
    this._channel = const MethodChannel('gglp/updates'),
  ]);

  @override
  Future<InstalledApp> installedApp() async => InstalledApp.fromMap(
    (await _channel.invokeMapMethod<dynamic, dynamic>('getInstalledApp'))!,
  );

  @override
  Future<String> prepareDownload(int versionCode) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'prepareDownload',
      {'versionCode': versionCode},
    );
    return result!['path'] as String;
  }

  @override
  Future<AppUpdate?> pendingUpdate() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getPendingUpdate',
    );
    if (result == null) return null;
    // Native code revalidates the signature and metadata before returning
    // a cached candidate. Its remote URL/notes are intentionally not stored.
    return AppUpdate(
      manifest: UpdateManifest(
        versionName: result['versionName'] as String,
        versionCode: result['versionCode'] as int,
        packageId: result['packageId'] as String,
        minSdk: 21,
        apkFileName: 'cached-update.apk',
        size: result['size'] as int,
        sha256: result['sha256'] as String,
      ),
      downloadedPath: result['path'] as String,
    );
  }

  @override
  Future<String> verify(String path, UpdateManifest manifest) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'verifyApk',
      manifest.verificationArguments(path),
    );
    return result!['path'] as String;
  }

  @override
  Future<bool> canInstall() async =>
      (await _channel.invokeMethod<bool>('canInstallPackages'))!;

  @override
  Future<void> openPermissionSettings() =>
      _channel.invokeMethod<void>('openInstallPermissionSettings');

  @override
  Future<void> install(String path, UpdateManifest manifest) => _channel
      .invokeMethod<void>('installApk', manifest.verificationArguments(path));

  @override
  Future<void> cleanup() => _channel.invokeMethod<void>('cleanupDownloads');
}
