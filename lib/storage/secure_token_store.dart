import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Per-account access tokens. Keyed by account id ("host:userId") so the
/// same `userId` on two different hosts doesn't collide.
class SecureTokenStore {
  final FlutterSecureStorage _storage;

  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? _defaultStorage;

  static const _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    // Disable data-protection keychain on macOS. The data-protection
    // variant requires a real provisioning profile + matching
    // keychain-access-group entitlement, which we don't have for
    // ad-hoc/development signing. Falling back to the legacy file-backed
    // keychain works under the macOS sandbox without extra setup.
    mOptions: MacOsOptions(useDataProtectionKeyChain: false),
  );

  static String _key(String accountId) => 'token:$accountId';

  Future<void> write({required String accountId, required String token}) =>
      _storage.write(key: _key(accountId), value: token);

  Future<String?> read({required String accountId}) =>
      _storage.read(key: _key(accountId));

  Future<void> delete({required String accountId}) =>
      _storage.delete(key: _key(accountId));

  Future<void> deleteAll() => _storage.deleteAll();
}
