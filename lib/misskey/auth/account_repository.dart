import '../../core/logger.dart';
import '../../storage/daos/account_dao.dart';
import '../../storage/daos/server_dao.dart';
import '../../storage/secure_token_store.dart';
import '../http/host.dart';
import '../http/misskey_http_client.dart';
import '../http/endpoint_registry.dart';
import '../models/account.dart';
import '../models/server.dart';
import 'miauth_service.dart';

/// Owns the lifecycle of logged-in Misskey accounts:
///   - kicks off MiAuth, persists token + account row + server meta
///   - lists existing accounts (Drift-backed)
///   - removes accounts (Drift row + secure token)
///
/// HTTP clients for streaming/timeline/etc. should be created via
/// [clientFor] so the access token is injected from secure storage.
class AccountRepository {
  final _log = const Log('AccountRepo');
  final AccountDao _accountDao;
  final ServerDao _serverDao;
  final SecureTokenStore _tokens;
  final MiAuthService _miauth;

  AccountRepository({
    required AccountDao accountDao,
    required ServerDao serverDao,
    required SecureTokenStore tokens,
    MiAuthService? miauth,
  })  : _accountDao = accountDao,
        _serverDao = serverDao,
        _tokens = tokens,
        _miauth = miauth ?? MiAuthService();

  Stream<List<Account>> watch() => _accountDao.watchAll();
  Future<List<Account>> list() => _accountDao.getAll();

  /// Run MiAuth against [hostInput], persist the result, return the
  /// new account.
  Future<Account> addAccount(String hostInput) async {
    final host = MisskeyHost.parse(hostInput);
    _log.info('Adding account on ${host.value}');

    // 1. Probe server meta first so we fail fast on bad hosts.
    final unauthHttp = MisskeyHttpClient(host: host);
    final meta = await MisskeyEndpoints(unauthHttp).meta();
    await _serverDao.upsert(meta);

    // 2. MiAuth.
    final result = await _miauth.authorize(host);
    final userJson = result.user;
    final userId = userJson['id'] as String;
    final username = userJson['username'] as String;
    final accountId = Account.makeId(host: host.value, userId: userId);

    // 3. Persist token + account row.
    await _tokens.write(accountId: accountId, token: result.token);
    final account = Account(
      id: accountId,
      host: host.value,
      userId: userId,
      username: username,
      displayName: userJson['name'] as String?,
      avatarUrl: userJson['avatarUrl'] as String?,
      isCat: userJson['isCat'] == true,
      isAdmin: userJson['isAdmin'] == true,
      addedAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
    );
    await _accountDao.upsert(account);
    _log.info('Added ${account.id}');
    return account;
  }

  Future<void> remove(String accountId) async {
    await _tokens.delete(accountId: accountId);
    await _accountDao.remove(accountId);
  }

  /// Build an authenticated HTTP client for [account] using the token
  /// stored at the time of login. Returns null if the token is missing
  /// (revoked, secure storage cleared, etc.) — callers should treat that
  /// as a re-auth signal.
  Future<MisskeyHttpClient?> clientFor(Account account) async {
    final token = await _tokens.read(accountId: account.id);
    if (token == null) return null;
    return MisskeyHttpClient(host: MisskeyHost.parse(account.host), token: token);
  }

  Future<Server?> serverFor(String host) => _serverDao.getByHost(host);
}
