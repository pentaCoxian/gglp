const updateRepository = 'pentaCoxian/gglp';
const updatePackageId = 'io.pentacoxian.gglp';
const maxApkBytes = 200 * 1024 * 1024;

class UpdateException implements Exception {
  final String message;
  const UpdateException(this.message);
  @override
  String toString() => message;
}

class InstalledApp {
  final String packageId;
  final String versionName;
  final int versionCode;
  final int sdkInt;

  const InstalledApp({
    required this.packageId,
    required this.versionName,
    required this.versionCode,
    required this.sdkInt,
  });

  factory InstalledApp.fromMap(Map<dynamic, dynamic> data) => InstalledApp(
    packageId: data['packageId'] as String,
    versionName: data['versionName'] as String,
    versionCode: data['versionCode'] as int,
    sdkInt: data['sdkInt'] as int,
  );
}

class UpdateManifest {
  final String versionName;
  final int versionCode;
  final String packageId;
  final int minSdk;
  final String apkFileName;
  final int size;
  final String sha256;

  const UpdateManifest({
    required this.versionName,
    required this.versionCode,
    required this.packageId,
    required this.minSdk,
    required this.apkFileName,
    required this.size,
    required this.sha256,
  });

  factory UpdateManifest.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['schemaVersion'] != 1 ||
        value['versionName'] is! String ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(value['versionName'] as String) ||
        value['versionCode'] is! int ||
        (value['versionCode'] as int) <= 0 ||
        (value['versionCode'] as int) > 2100000000 ||
        value['packageId'] != updatePackageId ||
        value['minSdk'] is! int ||
        (value['minSdk'] as int) < 21 ||
        value['apkFileName'] is! String ||
        !RegExp(
          r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}\.apk$',
        ).hasMatch(value['apkFileName'] as String) ||
        value['size'] is! int ||
        (value['size'] as int) <= 0 ||
        (value['size'] as int) > maxApkBytes ||
        value['sha256'] is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(value['sha256'] as String)) {
      throw const UpdateException('The release has invalid update metadata.');
    }
    return UpdateManifest(
      versionName: value['versionName'] as String,
      versionCode: value['versionCode'] as int,
      packageId: value['packageId'] as String,
      minSdk: value['minSdk'] as int,
      apkFileName: value['apkFileName'] as String,
      size: value['size'] as int,
      sha256: value['sha256'] as String,
    );
  }

  Map<String, Object> verificationArguments(String path) => {
    'path': path,
    'versionName': versionName,
    'versionCode': versionCode,
    'packageId': packageId,
    'size': size,
    'sha256': sha256,
  };
}

class AppUpdate {
  final UpdateManifest manifest;
  final Uri? apkUrl;
  final String releaseNotes;
  final String? downloadedPath;

  const AppUpdate({
    required this.manifest,
    this.apkUrl,
    this.releaseNotes = '',
    this.downloadedPath,
  });

  AppUpdate withPath(String path) => AppUpdate(
    manifest: manifest,
    apkUrl: apkUrl,
    releaseNotes: releaseNotes,
    downloadedPath: path,
  );
}

/// Initial asset URLs must belong to this repository and release. Every
/// redirect is separately checked by the unauthenticated HTTP client.
bool isReleaseAssetUrl(Uri uri, String tag, String fileName) =>
    isHttpsUrl(uri) &&
    uri.host == 'github.com' &&
    uri.query.isEmpty &&
    uri.pathSegments.length == 6 &&
    uri.pathSegments[0].toLowerCase() ==
        updateRepository.split('/')[0].toLowerCase() &&
    uri.pathSegments[1].toLowerCase() ==
        updateRepository.split('/')[1].toLowerCase() &&
    uri.pathSegments[2] == 'releases' &&
    uri.pathSegments[3] == 'download' &&
    uri.pathSegments[4] == tag &&
    uri.pathSegments[5] == fileName;

bool isHttpsUrl(Uri uri) =>
    uri.scheme == 'https' &&
    uri.userInfo.isEmpty &&
    uri.port == 443 &&
    uri.fragment.isEmpty;

bool isAllowedUpdateRedirect(Uri uri) {
  if (!isHttpsUrl(uri)) return false;
  if (uri.host == 'release-assets.githubusercontent.com' ||
      uri.host == 'objects.githubusercontent.com') {
    return true;
  }
  if (uri.host != 'github.com' || uri.pathSegments.length != 6) return false;
  return isReleaseAssetUrl(uri, uri.pathSegments[4], uri.pathSegments[5]);
}
