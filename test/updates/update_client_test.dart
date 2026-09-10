import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/app/updates/update_client.dart';
import 'package:misskey_gglp/app/updates/update_manifest.dart';

const _releaseUrl =
    'https://api.github.com/repos/pentaCoxian/gglp/releases/latest';
const _base = 'https://github.com/pentaCoxian/gglp/releases/download/v0.9.1/';
const _apkName = 'gglp-0.9.1.apk';
final _manifest = <String, dynamic>{
  'schemaVersion': 1,
  'versionName': '0.9.1',
  'versionCode': 11,
  'packageId': updatePackageId,
  'minSdk': 21,
  'apkFileName': _apkName,
  'size': 4,
  'sha256': 'a' * 64,
};

Map<String, Object> _release() => {
  'draft': false,
  'prerelease': false,
  'tag_name': 'v0.9.1',
  'body': 'A small release.',
  'assets': [
    {
      'name': 'update.json',
      'size': 300,
      'state': 'uploaded',
      'browser_download_url': '${_base}update.json',
    },
    {
      'name': _apkName,
      'size': 4,
      'state': 'uploaded',
      'browser_download_url': '$_base$_apkName',
    },
  ],
};

class _Adapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) respond;
  final requests = <RequestOptions>[];
  _Adapter(this.respond);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  GitHubUpdateClient clientFor(
    FutureOr<ResponseBody> Function(RequestOptions) respond,
  ) {
    final dio = Dio()..httpClientAdapter = _Adapter(respond);
    final client = GitHubUpdateClient(dio: dio);
    addTearDown(client.close);
    return client;
  }

  AppUpdate candidate() => AppUpdate(
    manifest: UpdateManifest.fromJson(_manifest),
    apkUrl: Uri.parse('$_base$_apkName'),
  );

  test(
    'loads a complete stable release using independent unauthenticated requests',
    () async {
      final client = clientFor((request) {
        expect(
          request.headers.keys.map((key) => key.toLowerCase()),
          isNot(contains('authorization')),
        );
        expect(request.data, isNull);
        expect(request.followRedirects, isFalse);
        return ResponseBody.fromString(
          jsonEncode(
            request.uri.toString() == _releaseUrl ? _release() : _manifest,
          ),
          200,
        );
      });
      final update = await client.latest(CancelToken());
      expect(update.manifest.versionCode, 11);
      expect(update.apkUrl.toString(), '$_base$_apkName');
      expect(update.releaseNotes, 'A small release.');
    },
  );

  test(
    'rejects missing, wrongly typed, oversized and wrong-package metadata',
    () {
      for (final entry
          in <String, Object?>{
            'schemaVersion': 2,
            'versionCode': '11',
            'versionName': '0.9.1-beta',
            'packageId': 'some.other.app',
            'minSdk': 0,
            'size': maxApkBytes + 1,
            'sha256': 'bad',
            'apkFileName': '../update.apk',
          }.entries) {
        expect(
          () => UpdateManifest.fromJson({..._manifest, entry.key: entry.value}),
          throwsA(isA<UpdateException>()),
          reason: entry.key,
        );
      }
      for (final key in _manifest.keys) {
        expect(
          () => UpdateManifest.fromJson({..._manifest}..remove(key)),
          throwsA(isA<UpdateException>()),
          reason: 'missing $key',
        );
      }
    },
  );

  test('rejects draft or prerelease and incomplete release assets', () async {
    for (final release in [
      {..._release(), 'draft': true},
      {..._release(), 'prerelease': true},
      {..._release(), 'assets': []},
    ]) {
      final client = clientFor(
        (_) => ResponseBody.fromString(jsonEncode(release), 200),
      );
      await expectLater(
        client.latest(CancelToken()),
        throwsA(isA<UpdateException>()),
      );
    }
  });

  test(
    'allows GitHub asset CDN redirects and rejects untrusted destinations',
    () async {
      for (final location in [
        'https://release-assets.githubusercontent.com/asset?signed=yes',
        'https://objects.githubusercontent.com/asset?signed=yes',
        'https://evil.example/update.json',
        'http://release-assets.githubusercontent.com/asset',
        'https://github.com/another/repo/releases/download/v0.9.1/update.json',
        'https://github.com@evil.example/update.json',
      ]) {
        final client = clientFor((request) {
          if (request.uri.toString() == _releaseUrl) {
            return ResponseBody.fromString(jsonEncode(_release()), 200);
          }
          if (request.uri.toString() == '${_base}update.json') {
            return ResponseBody.fromString(
              '',
              302,
              headers: {
                'location': [location],
              },
            );
          }
          return ResponseBody.fromString(jsonEncode(_manifest), 200);
        });
        if (location.startsWith('https://release-assets.') ||
            location.startsWith('https://objects.')) {
          expect((await client.latest(CancelToken())).manifest.versionCode, 11);
        } else {
          await expectLater(
            client.latest(CancelToken()),
            throwsA(isA<UpdateException>()),
          );
        }
      }
    },
  );

  test('rejects a cross-repository URL before fetching it', () async {
    final release = _release();
    ((release['assets'] as List).first as Map)['browser_download_url'] =
        'https://github.com/another/gglp/releases/download/v0.9.1/update.json';
    var requests = 0;
    final client = clientFor((_) {
      requests++;
      return ResponseBody.fromString(jsonEncode(release), 200);
    });
    await expectLater(
      client.latest(CancelToken()),
      throwsA(isA<UpdateException>()),
    );
    expect(requests, 1);
  });

  test(
    'rate limiting and malformed JSON produce useful controlled failures',
    () async {
      final limited = clientFor((_) => ResponseBody.fromString('', 429));
      await expectLater(
        limited.latest(CancelToken()),
        throwsA(
          isA<UpdateException>().having(
            (e) => e.message,
            'message',
            contains('limiting'),
          ),
        ),
      );
      final malformed = clientFor(
        (_) => ResponseBody.fromString('not json', 200),
      );
      await expectLater(
        malformed.latest(CancelToken()),
        throwsA(isA<UpdateException>()),
      );
    },
  );

  test(
    'download enforces exact byte count and removes truncated/oversized partials',
    () async {
      final temp = await Directory.systemTemp.createTemp('gglp-update-test-');
      addTearDown(() => temp.delete(recursive: true));
      for (final count in [3, 5]) {
        final client = clientFor(
          (_) => ResponseBody.fromBytes(List.filled(count, 1), 200),
        );
        final path = '${temp.path}/candidate-$count.part';
        await expectLater(
          client.download(candidate(), path, CancelToken(), (_, __) {}),
          throwsA(isA<UpdateException>()),
        );
        expect(await File(path).exists(), isFalse);
      }
      final client = clientFor(
        (_) => ResponseBody.fromBytes([1, 2, 3, 4], 200),
      );
      final path = '${temp.path}/complete.part';
      await client.download(candidate(), path, CancelToken(), (_, __) {});
      expect(await File(path).readAsBytes(), [1, 2, 3, 4]);
    },
  );

  test(
    'cancellation closes the writer before removing the partial file',
    () async {
      final temp = await Directory.systemTemp.createTemp('gglp-update-test-');
      addTearDown(() => temp.delete(recursive: true));
      final token = CancelToken();
      final client = clientFor(
        (_) => ResponseBody(
          Stream.fromIterable([
            Uint8List.fromList([1, 2]),
            Uint8List.fromList([3, 4]),
          ]),
          200,
        ),
      );
      final path = '${temp.path}/cancelled.part';
      await expectLater(
        client.download(candidate(), path, token, (_, __) => token.cancel()),
        throwsA(isA<DioException>()),
      );
      expect(await File(path).exists(), isFalse);
    },
  );
}
