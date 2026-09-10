import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'update_manifest.dart';

abstract interface class UpdateSource {
  Future<AppUpdate> latest(CancelToken cancelToken);
  Future<void> download(
    AppUpdate update,
    String path,
    CancelToken cancelToken,
    void Function(int received, int total) onProgress,
  );
  void close();
}

/// Deliberately independent of the Misskey client: no account, token,
/// cookies, authenticated interceptors, or instance URLs enter this client.
class GitHubUpdateClient implements UpdateSource {
  final Dio _dio;

  GitHubUpdateClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 20)
      ..receiveTimeout = const Duration(seconds: 45);
  }

  @override
  Future<AppUpdate> latest(CancelToken cancelToken) async {
    final release = await _json(
      Uri.https('api.github.com', '/repos/$updateRepository/releases/latest'),
      512 * 1024,
      cancelToken,
    );
    if (release is! Map<String, dynamic> ||
        release['draft'] != false ||
        release['prerelease'] != false ||
        release['tag_name'] is! String ||
        !RegExp(r'^v\d+\.\d+\.\d+$').hasMatch(release['tag_name'] as String) ||
        release['assets'] is! List) {
      throw const UpdateException('GitHub returned an invalid stable release.');
    }
    final tag = release['tag_name'] as String;
    final assets = release['assets'] as List;
    final manifestAsset = _asset(assets, 'update.json', tag);
    if (manifestAsset['size'] is! int ||
        (manifestAsset['size'] as int) <= 0 ||
        (manifestAsset['size'] as int) > 32 * 1024) {
      throw const UpdateException('The release has invalid update metadata.');
    }
    final manifest = UpdateManifest.fromJson(
      await _json(
        Uri.parse(manifestAsset['browser_download_url'] as String),
        32 * 1024,
        cancelToken,
      ),
    );
    if (tag != 'v${manifest.versionName}') {
      throw const UpdateException(
        'The release version does not match its tag.',
      );
    }
    final apkAsset = _asset(assets, manifest.apkFileName, tag);
    if (apkAsset['size'] != manifest.size) {
      throw const UpdateException('The APK size does not match the release.');
    }
    final notes = release['body'];
    return AppUpdate(
      manifest: manifest,
      apkUrl: Uri.parse(apkAsset['browser_download_url'] as String),
      releaseNotes:
          notes is String
              ? (notes.length > 100000 ? notes.substring(0, 100000) : notes)
              : '',
    );
  }

  Map<String, dynamic> _asset(List assets, String name, String tag) {
    final matches = assets.whereType<Map<String, dynamic>>().where(
      (asset) => asset['name'] == name,
    );
    if (matches.length != 1) {
      throw const UpdateException('The release is missing a required asset.');
    }
    final asset = matches.single;
    final url = asset['browser_download_url'];
    if (asset['state'] != 'uploaded' ||
        url is! String ||
        !isReleaseAssetUrl(Uri.parse(url), tag, name)) {
      throw const UpdateException(
        'The release contains an unexpected asset URL.',
      );
    }
    return asset;
  }

  Future<Object?> _json(Uri uri, int maxBytes, CancelToken token) async {
    final body = await _open(uri, token, maxBytes);
    final bytes = <int>[];
    await for (final chunk in body.stream.timeout(
      const Duration(seconds: 45),
    )) {
      _throwIfCancelled(token);
      if (bytes.length + chunk.length > maxBytes) {
        throw const UpdateException('The update response is too large.');
      }
      bytes.addAll(chunk);
    }
    _throwIfCancelled(token);
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const UpdateException('The release has invalid update metadata.');
    }
  }

  Future<ResponseBody> _open(Uri uri, CancelToken token, int maxBytes) async {
    for (var redirects = 0; redirects <= 5; redirects++) {
      _throwIfCancelled(token);
      final response = await _dio.get<ResponseBody>(
        uri.toString(),
        cancelToken: token,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: false,
          validateStatus: (_) => true,
          headers: {
            'User-Agent': 'GGLP-Updater',
            'Accept-Encoding': 'identity',
          },
        ),
      );
      final status = response.statusCode;
      final body = response.data!;
      if ([301, 302, 303, 307, 308].contains(status)) {
        await body.stream.listen((_) {}).cancel();
        final location = response.headers.value('location');
        if (location == null || redirects == 5) {
          throw const UpdateException(
            'The update download redirected too often.',
          );
        }
        final next = uri.resolve(location);
        if (!isAllowedUpdateRedirect(next)) {
          throw const UpdateException(
            'The update redirected to an untrusted URL.',
          );
        }
        uri = next;
        continue;
      }
      if (status != 200) {
        await body.stream.listen((_) {}).cancel();
        if (status == 404) {
          throw const UpdateException(
            'No complete stable release is available yet.',
          );
        }
        if (status == 403 || status == 429) {
          throw const UpdateException(
            'GitHub is limiting requests. Try again later.',
          );
        }
        throw const UpdateException(
          'GitHub could not serve the update. Try again later.',
        );
      }
      final length = int.tryParse(
        response.headers.value('content-length') ?? '',
      );
      if (length != null && (length < 0 || length > maxBytes)) {
        await body.stream.listen((_) {}).cancel();
        throw const UpdateException('The update response is too large.');
      }
      return body;
    }
    throw const UpdateException('The update download redirected too often.');
  }

  @override
  Future<void> download(
    AppUpdate update,
    String path,
    CancelToken cancelToken,
    void Function(int received, int total) onProgress,
  ) async {
    final url = update.apkUrl;
    final manifest = update.manifest;
    if (url == null ||
        !isReleaseAssetUrl(
          url,
          'v${manifest.versionName}',
          manifest.apkFileName,
        ) ||
        manifest.size <= 0 ||
        manifest.size > maxApkBytes) {
      throw const UpdateException(
        'Check for updates again before downloading.',
      );
    }
    final file = File(path);
    RandomAccessFile? writer;
    var complete = false;
    try {
      final body = await _open(url, cancelToken, manifest.size);
      final length = int.tryParse(body.headers['content-length']?.first ?? '');
      if (length != null && length != manifest.size) {
        await body.stream.listen((_) {}).cancel();
        throw const UpdateException('The APK size does not match the release.');
      }
      writer = await file.open(mode: FileMode.write);
      var received = 0;
      await for (final chunk in body.stream.timeout(
        const Duration(seconds: 45),
      )) {
        _throwIfCancelled(cancelToken);
        received += chunk.length;
        if (received > manifest.size) {
          throw const UpdateException(
            'The APK is larger than the release metadata.',
          );
        }
        await writer.writeFrom(chunk);
        onProgress(received, manifest.size);
      }
      _throwIfCancelled(cancelToken);
      if (received != manifest.size) {
        throw const UpdateException(
          'The APK download was incomplete. Please retry.',
        );
      }
      await writer.flush();
      complete = true;
    } finally {
      // Await the writer before deleting: cancellation must never leave
      // a still-running stream recreating or appending to the partial file.
      await writer?.close();
      if (!complete && await file.exists()) await file.delete();
    }
  }

  static void _throwIfCancelled(CancelToken token) {
    if (token.isCancelled) throw token.cancelError!;
  }

  @override
  void close() => _dio.close(force: true);
}
