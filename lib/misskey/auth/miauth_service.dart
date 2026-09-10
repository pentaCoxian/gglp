import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:uuid/uuid.dart';

import '../../core/logger.dart';
import '../http/host.dart';
import '../http/misskey_http_client.dart';

/// Result of a successful MiAuth handshake.
class MiAuthResult {
  final String token;
  final Map<String, dynamic> user;
  const MiAuthResult({required this.token, required this.user});
}

/// MiAuth flow.
///
/// 1. Generate a UUID session id.
/// 2. Redirect user to `https://<host>/miauth/<session>?...&callback=<scheme>`.
///    On mobile, `callback=gglp://miauth` round-trips via the OS deep
///    link. On desktop, `flutter_web_auth_2` spins an ephemeral loopback
///    on `http://127.0.0.1:<port>/callback` and we let the package detect
///    redirect itself; we still pass the same `callback=` so the server
///    redirects somewhere predictable, then the package intercepts.
/// 3. After the user approves, POST `miauth/<session>/check` to receive
///    `{ token, user }`.
///
/// On desktop, `flutter_web_auth_2` requires `setup` to be called once
/// at app startup. We do that lazily here so the rest of the app doesn't
/// need to import the package.
class MiAuthService {
  /// Permission scopes requested at MiAuth time.
  ///
  /// Picked to cover every write endpoint in `NoteActionsService`:
  ///   - `write:notes`    — notes/create, notes/delete, renote, quote
  ///   - `write:reactions` — notes/reactions/create + delete
  ///   - `write:following` — following/create + delete
  ///   - `write:drive`     — drive/files/create (image attachments)
  ///   - `write:favorites` — notes/favorites/create + delete (bookmarks)
  /// Plus the read scopes we already use.
  ///
  /// Adding new scopes here means existing accounts must re-auth before
  /// the new endpoints work — Misskey's token is bound to the original
  /// scope list.
  static const _scope = [
    'read:account',
    'read:notifications',
    'read:reactions',
    'read:drive',
    'read:following',
    // Channels: list followed channels, fetch channel metadata, browse
    // channel timelines. Misskey gates channels/followed + channels/show
    // behind read:channels even though the channel timeline endpoint
    // itself only needs the standard credential — without this scope
    // the browse-channels list silently comes back empty.
    'read:channels',
    // Pages: i/pages, pages/like / unlike (if we add it later). pages/show
    // and pages/featured are anonymous, but listing the active account's
    // own pages requires read:pages.
    'read:pages',
    // Bookmarks: i/favorites (the Bookmarks screen). Without it the
    // list 403s even though bookmarking itself only needs the write
    // scope.
    'read:favorites',
    'write:notes',
    'write:reactions',
    'write:notifications',
    'write:drive',
    'write:following',
    // Required for channels/follow + channels/unfollow if we add a
    // join/leave button later. Issued ahead of time so existing tokens
    // don't need yet another re-auth then.
    'write:channels',
    // Pages: pages/create, pages/update, pages/delete.
    'write:pages',
    // Bookmarks: notes/favorites/create + delete.
    'write:favorites',
  ];
  static const _callbackScheme = 'gglp';
  static const _callbackHost = 'miauth';
  static const _appName = 'GGLP';

  final _log = const Log('MiAuth');
  final Uuid _uuid;
  final MisskeyHttpClient Function(MisskeyHost) _clientFactory;

  MiAuthService({
    Uuid? uuid,
    MisskeyHttpClient Function(MisskeyHost)? clientFactory,
  })  : _uuid = uuid ?? const Uuid(),
        _clientFactory = clientFactory ?? ((h) => MisskeyHttpClient(host: h));

  /// Run the full MiAuth flow against [host]. Throws on user cancel or
  /// server failure.
  Future<MiAuthResult> authorize(MisskeyHost host) async {
    final session = _uuid.v4();
    final authUrl = host.uri('miauth/$session', {
      'name': _appName,
      'callback': '$_callbackScheme://$_callbackHost',
      'permission': _scope.join(','),
    });
    _log.info('Starting MiAuth on ${host.value} session=$session');

    // The web-auth package returns the deep link / loopback redirect URL.
    // We don't actually need to read it — the session id is enough to call
    // the check endpoint — but we still wait for the package to confirm
    // the user closed the browser.
    try {
      await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: _callbackScheme,
        options: const FlutterWebAuth2Options(
          // Android: FLAG_ACTIVITY_NO_HISTORY so the Chrome Custom Tab
          // is auto-dismissed when the redirect fires (otherwise the
          // user is left looking at the auth page after the app comes
          // back to the foreground).
          intentFlags: ephemeralIntentFlags,
          // Apple: ASWebAuthenticationSession runs in a private session
          // and auto-closes on redirect.
          preferEphemeral: true,
        ),
      );
    } catch (e) {
      _log.warn('MiAuth aborted: $e');
      rethrow;
    }

    // Poll the check endpoint. The user might race the redirect, so retry
    // a couple times before giving up.
    final client = _clientFactory(host);
    for (var attempt = 0; attempt < 4; attempt++) {
      final res = await client.call('miauth/$session/check')
          as Map<String, dynamic>;
      if (res['ok'] == true) {
        return MiAuthResult(
          token: res['token'] as String,
          user: res['user'] as Map<String, dynamic>,
        );
      }
      await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }
    throw const _MiAuthCheckFailed();
  }
}

class _MiAuthCheckFailed implements Exception {
  const _MiAuthCheckFailed();
  @override
  String toString() => 'MiAuth check did not return ok=true';
}
