import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'update_bridge.dart';
import 'update_client.dart';
import 'update_manifest.dart';
import 'update_preferences.dart';

enum UpdateStage {
  idle,
  checking,
  downloading,
  verifying,
  readyToInstall,
  waitingForPermission,
  installing,
  installerOpened,
}

class UpdateState {
  final bool supported;
  final bool initialized;
  final bool automaticChecks;
  final InstalledApp? installed;
  final AppUpdate? update;
  final int? dismissedVersionCode;
  final UpdateStage stage;
  final int received;
  final String? message;
  final String? error;

  const UpdateState({
    required this.supported,
    this.initialized = false,
    this.automaticChecks = true,
    this.installed,
    this.update,
    this.dismissedVersionCode,
    this.stage = UpdateStage.idle,
    this.received = 0,
    this.message,
    this.error,
  });

  bool get busy => [
    UpdateStage.checking,
    UpdateStage.downloading,
    UpdateStage.verifying,
    UpdateStage.installing,
  ].contains(stage);

  bool get showNotice =>
      update != null &&
      update!.manifest.versionCode != dismissedVersionCode &&
      !busy;

  UpdateState copyWith({
    bool? initialized,
    bool? automaticChecks,
    InstalledApp? installed,
    Object? update = _unset,
    Object? dismissedVersionCode = _unset,
    UpdateStage? stage,
    int? received,
    String? message,
    String? error,
  }) => UpdateState(
    supported: supported,
    initialized: initialized ?? this.initialized,
    automaticChecks: automaticChecks ?? this.automaticChecks,
    installed: installed ?? this.installed,
    update: identical(update, _unset) ? this.update : update as AppUpdate?,
    dismissedVersionCode:
        identical(dismissedVersionCode, _unset)
            ? this.dismissedVersionCode
            : dismissedVersionCode as int?,
    stage: stage ?? this.stage,
    received: received ?? this.received,
    message: message,
    error: error,
  );
}

const _unset = Object();

class UpdateController extends StateNotifier<UpdateState> {
  final UpdateSource _source;
  final UpdateBridge _bridge;
  final UpdatePreferenceStore _store;
  final DateTime Function() _now;
  late final Future<void> initialized;
  UpdatePreferences _preferences = const UpdatePreferences();
  Future<void> _saveTail = Future.value();
  Future<void>? _checkTask;
  Future<void>? _downloadTask;
  Future<void>? _foregroundTask;
  Future<void>? _backgroundTask;
  CancelToken? _checkToken;
  CancelToken? _downloadToken;
  bool _inForeground = false;
  bool _waitingForPermission = false;
  bool _disposed = false;
  int _operationEpoch = 0;

  UpdateController({
    required UpdateSource source,
    required UpdateBridge bridge,
    required UpdatePreferenceStore store,
    required bool supported,
    DateTime Function()? now,
  }) : _source = source,
       _bridge = bridge,
       _store = store,
       _now = now ?? DateTime.now,
       super(UpdateState(supported: supported)) {
    initialized = _initialize();
  }

  UpdateState get snapshot => state;

  Future<void> _initialize() async {
    if (!state.supported) {
      state = state.copyWith(initialized: true);
      return;
    }
    try {
      _preferences = await _store.read();
      final installed = await _bridge.installedApp();
      if (installed.packageId != updatePackageId) {
        throw const UpdateException(
          'Updates are only available for the OSS GGLP app.',
        );
      }
      await _bridge.cleanup();
      final pending = await _bridge.pendingUpdate();
      if (_disposed) return;
      state = state.copyWith(
        initialized: true,
        automaticChecks: _preferences.automaticChecks,
        dismissedVersionCode: _preferences.dismissedVersionCode,
        installed: installed,
        update: pending,
        stage: pending == null ? UpdateStage.idle : UpdateStage.readyToInstall,
      );
    } catch (_) {
      if (!_disposed) {
        state = state.copyWith(
          initialized: true,
          automaticChecks: _preferences.automaticChecks,
          error: 'Updates could not be initialized. Restart GGLP to try again.',
        );
      }
    }
  }

  Future<void> foreground() {
    _inForeground = true;
    return _foregroundTask ??= _resume().whenComplete(
      () => _foregroundTask = null,
    );
  }

  Future<void> _resume() async {
    await initialized;
    await _backgroundTask;
    if (_disposed ||
        !state.supported ||
        state.installed == null ||
        !_inForeground) {
      return;
    }
    if (state.busy || _downloadTask != null) return;
    final epoch = _operationEpoch;
    try {
      final installed = await _bridge.installedApp();
      if (_disposed ||
          !_inForeground ||
          epoch != _operationEpoch ||
          _downloadTask != null) {
        return;
      }
      await _bridge.cleanup();
      if (_disposed ||
          !_inForeground ||
          epoch != _operationEpoch ||
          _downloadTask != null) {
        return;
      }
      final pending = await _bridge.pendingUpdate();
      if (_disposed ||
          !_inForeground ||
          epoch != _operationEpoch ||
          state.busy) {
        return;
      }
      final previous = state.update;
      AppUpdate? candidate = previous;
      if (candidate != null &&
          installed.versionCode >= candidate.manifest.versionCode) {
        candidate = null;
      } else if (pending != null) {
        if (candidate == null ||
            pending.manifest.versionCode > candidate.manifest.versionCode) {
          candidate = pending;
        } else if (candidate.manifest.versionCode ==
                pending.manifest.versionCode &&
            candidate.manifest.sha256 == pending.manifest.sha256) {
          candidate = candidate.withPath(pending.downloadedPath!);
        }
      } else if (candidate?.downloadedPath != null) {
        candidate =
            candidate!.apkUrl == null
                ? null
                : AppUpdate(
                  manifest: candidate.manifest,
                  apkUrl: candidate.apkUrl,
                  releaseNotes: candidate.releaseNotes,
                );
      }
      final wasInstallerOpened = state.stage == UpdateStage.installerOpened;
      state = state.copyWith(
        installed: installed,
        update: candidate,
        stage:
            candidate?.downloadedPath == null
                ? UpdateStage.idle
                : UpdateStage.readyToInstall,
        message:
            wasInstallerOpened && candidate != null
                ? 'The installed version is unchanged. You can try installing again.'
                : null,
      );
      if (_waitingForPermission) {
        _waitingForPermission = false;
        if (await _bridge.canInstall()) {
          await install();
        } else if (!_disposed) {
          state = state.copyWith(
            message:
                'Installation permission was not granted. Tap Install to try again.',
          );
        }
      }
    } catch (_) {
      // A resume must never interrupt ordinary app use. Explicit actions
      // report their own failures, and another resume can restore the cache.
    }
    if (!_disposed && _inForeground) await check(manual: false);
  }

  Future<void> background() {
    _inForeground = false;
    _checkToken?.cancel('App backgrounded');
    _downloadToken?.cancel('App backgrounded');
    return _backgroundTask ??= _suspend().whenComplete(
      () => _backgroundTask = null,
    );
  }

  Future<void> _suspend() async {
    await initialized;
    await _checkTask;
    await _downloadTask;
    if (_disposed || !state.supported || state.installed == null) return;
    try {
      // The downloader has closed its writer before native cleanup runs.
      await _bridge.cleanup();
    } catch (_) {
      // Startup/resume will retry cache cleanup.
    }
  }

  Future<void> check({bool manual = true}) async {
    await initialized;
    if (_disposed || !state.supported || state.installed == null) return;
    if (_checkTask != null) return _checkTask;
    if (state.busy || _downloadTask != null || _waitingForPermission) return;
    if (!manual && (!_inForeground || !_preferences.shouldCheck(_now()))) {
      return;
    }
    _checkTask = _check(manual).whenComplete(() => _checkTask = null);
    return _checkTask;
  }

  Future<void> _check(bool manual) async {
    _operationEpoch++;
    final token = _checkToken = CancelToken();
    state = state.copyWith(stage: UpdateStage.checking);
    try {
      _preferences = UpdatePreferences(
        automaticChecks: _preferences.automaticChecks,
        lastCheckAt: _now().toUtc(),
        dismissedVersionCode: _preferences.dismissedVersionCode,
      );
      // Persist attempts, including offline/rate-limited checks, so resume
      // events or process restarts cannot hammer GitHub every few seconds.
      await _savePreferences();
      if (token.isCancelled) throw token.cancelError!;
      var update = await _source.latest(token);
      if (_disposed || token.isCancelled) return;
      final installed = state.installed!;
      if (update.manifest.packageId != installed.packageId ||
          update.manifest.minSdk > installed.sdkInt) {
        throw const UpdateException(
          'The latest update does not support this Android version.',
        );
      }
      if (update.manifest.versionCode <= installed.versionCode) {
        state = state.copyWith(
          stage: UpdateStage.idle,
          update: null,
          message: manual ? 'GGLP is up to date.' : null,
        );
      } else {
        final old = state.update;
        if (old?.downloadedPath != null &&
            old!.manifest.sha256 == update.manifest.sha256 &&
            old.manifest.versionCode == update.manifest.versionCode &&
            old.manifest.size == update.manifest.size) {
          update = update.withPath(old.downloadedPath!);
        }
        state = state.copyWith(
          update: update,
          stage:
              update.downloadedPath == null
                  ? UpdateStage.idle
                  : UpdateStage.readyToInstall,
        );
      }
    } catch (error) {
      if (!_disposed) {
        state = state.copyWith(
          stage:
              state.update?.downloadedPath == null
                  ? UpdateStage.idle
                  : UpdateStage.readyToInstall,
          error:
              manual && !token.isCancelled
                  ? _errorMessage(
                    error,
                    'Could not check GitHub. Please try again later.',
                  )
                  : null,
        );
      }
    } finally {
      if (!_disposed && state.stage == UpdateStage.checking) {
        state = state.copyWith(stage: UpdateStage.idle);
      }
      _checkToken = null;
    }
  }

  Future<void> setAutomaticChecks(bool enabled) async {
    await initialized;
    if (_disposed) return;
    _preferences = UpdatePreferences(
      automaticChecks: enabled,
      lastCheckAt: _preferences.lastCheckAt,
      dismissedVersionCode: _preferences.dismissedVersionCode,
    );
    state = state.copyWith(automaticChecks: enabled);
    if (!enabled) _checkToken?.cancel('Automatic checks disabled');
    try {
      await _savePreferences();
    } catch (_) {
      if (!_disposed) {
        state = state.copyWith(error: 'Could not save the update preference.');
      }
    }
  }

  Future<void> dismiss() async {
    await initialized;
    if (_disposed) return;
    final update = state.update;
    if (update == null) return;
    _preferences = UpdatePreferences(
      automaticChecks: _preferences.automaticChecks,
      lastCheckAt: _preferences.lastCheckAt,
      dismissedVersionCode: update.manifest.versionCode,
    );
    state = state.copyWith(dismissedVersionCode: update.manifest.versionCode);
    try {
      await _savePreferences();
    } catch (_) {
      if (!_disposed) {
        state = state.copyWith(error: 'Could not save the dismissed update.');
      }
    }
  }

  Future<void> _savePreferences() {
    final preferences = _preferences;
    final task = _saveTail.then((_) => _store.write(preferences));
    // The caller sees this write's error; later writes may still proceed.
    _saveTail = task.catchError((Object _) {});
    return task;
  }

  Future<void> download() async {
    await initialized;
    if (_disposed ||
        state.busy ||
        _downloadTask != null ||
        state.update?.apkUrl == null) {
      return;
    }
    _downloadTask = _download().whenComplete(() => _downloadTask = null);
    return _downloadTask;
  }

  Future<void> _download() async {
    _operationEpoch++;
    final update = state.update!;
    final token = _downloadToken = CancelToken();
    String? preparedPath;
    UpdateState? resultState;
    state = state.copyWith(stage: UpdateStage.downloading, received: 0);
    try {
      final path =
          preparedPath = await _bridge.prepareDownload(
            update.manifest.versionCode,
          );
      if (token.isCancelled) throw token.cancelError!;
      await _source.download(update, path, token, (received, _) {
        if (!_disposed && !token.isCancelled) {
          state = state.copyWith(received: received);
        }
      });
      if (token.isCancelled) throw token.cancelError!;
      if (_disposed) return;
      state = state.copyWith(stage: UpdateStage.verifying);
      final verifiedPath = await _bridge.verify(path, update.manifest);
      if (_disposed) return;
      // A background event during verification may cancel the request;
      // the completed verified candidate is safe to restore on next resume.
      resultState = state.copyWith(
        update: update.withPath(verifiedPath),
        stage: UpdateStage.readyToInstall,
        message: 'Download verified. Tap Install when you are ready.',
      );
    } catch (error) {
      if (!_disposed) {
        resultState = state.copyWith(
          stage: UpdateStage.idle,
          error:
              token.isCancelled
                  ? null
                  : _errorMessage(
                    error,
                    'The download could not be verified. Please retry.',
                  ),
          message:
              token.isCancelled
                  ? 'Download cancelled. Tap Download to retry.'
                  : null,
        );
      }
    } finally {
      _downloadToken = null;
      try {
        // Also covers cancellation after prepareDownload but before the
        // HTTP writer starts, and a fully downloaded APK rejected by native
        // verification. A verified APK has been renamed and is preserved.
        if (preparedPath != null) {
          final partial = File(preparedPath);
          if (await partial.exists()) await partial.delete();
        }
        await _bridge.cleanup();
      } catch (_) {
        // Cleanup is retried on lifecycle changes and next startup.
      }
    }
    if (!_disposed && resultState != null) {
      state = state.copyWith(
        update: resultState.update,
        stage: resultState.stage,
        message: resultState.message,
        error: resultState.error,
      );
    }
  }

  Future<void> cancelDownload() async {
    _downloadToken?.cancel('Cancelled');
    await _downloadTask;
  }

  Future<void> install() async {
    await initialized;
    if (_disposed || state.busy || _downloadTask != null) return;
    final update = state.update;
    final path = update?.downloadedPath;
    if (update == null || path == null) return;
    _operationEpoch++;
    state = state.copyWith(stage: UpdateStage.installing);
    try {
      if (!await _bridge.canInstall()) {
        _waitingForPermission = true;
        state = state.copyWith(
          stage: UpdateStage.waitingForPermission,
          message: 'Allow GGLP to install apps, then return to continue.',
        );
        await _bridge.openPermissionSettings();
        return;
      }
      // Native code rechecks bytes, metadata and signing certificate here,
      // including after permission settings or a previous installer cancel.
      await _bridge.install(path, update.manifest);
      if (!_disposed) {
        state = state.copyWith(
          stage: UpdateStage.installerOpened,
          message: 'Android installer opened. Confirm the update there.',
        );
      }
    } catch (error) {
      _waitingForPermission = false;
      if (!_disposed) {
        final invalid =
            error is PlatformException &&
            (error.code == 'invalid_apk' || error.code == 'io_error');
        state = state.copyWith(
          update:
              invalid
                  ? AppUpdate(
                    manifest: update.manifest,
                    apkUrl: update.apkUrl,
                    releaseNotes: update.releaseNotes,
                  )
                  : update,
          stage: invalid ? UpdateStage.idle : UpdateStage.readyToInstall,
          error: _errorMessage(
            error,
            'Could not open the installer. Check for updates and retry.',
          ),
        );
      }
    }
  }

  static String _errorMessage(Object error, String fallback) {
    if (error is UpdateException) return error.message;
    if (error is PlatformException && error.code == 'invalid_apk') {
      return 'This APK failed verification. Check for updates and download it again.';
    }
    return fallback;
  }

  @override
  void dispose() {
    _disposed = true;
    _checkToken?.cancel('Disposed');
    _downloadToken?.cancel('Disposed');
    _source.close();
    super.dispose();
  }
}

final updateControllerProvider =
    StateNotifierProvider<UpdateController, UpdateState>((ref) {
      final supported = !kIsWeb && Platform.isAndroid;
      return UpdateController(
        source: GitHubUpdateClient(),
        bridge: const AndroidUpdateBridge(),
        // Resolve storage only when the Android updater actually reads it.
        store: DatabaseUpdatePreferenceStore(
          () => ref.read(preferencesDaoProvider),
        ),
        supported: supported,
      );
    });
