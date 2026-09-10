import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logger.dart';
import '../../storage/daos/emoji_dao.dart';
import '../http/host.dart';
import '../http/misskey_http_client.dart';
import '../http/endpoint_registry.dart';
import '../models/emoji.dart';
import 'emoji_ref.dart';

/// Per-host custom-emoji catalog.
///
/// Two stores:
///   - in-memory map keyed by `(host, name)` for hot lookups during MFM
///     rendering
///   - Drift-backed disk cache for cold start
///
/// Fetch policy:
///   - On first lookup against a fresh host, kick off a single `/emojis`
///     fetch in the background and cache everything it returns. Render
///     callers do NOT block on this — they get a synchronous null from
///     [lookup] and the renderer falls back to text. When the catalog
///     arrives, it notifies via [updates] so visible cards can rebuild.
///   - Subsequent lookups against the same host hit the cached map
///     synchronously.
///
/// Change notifications and disk writes are both coalesced: a busy
/// timeline ingests inline emoji from every arriving note, and firing
/// one tick + one Drift batch per note rebuilt every emoji widget on
/// screen and hammered the database for no visible benefit.
class EmojiRepository {
  static const _refreshThreshold = Duration(hours: 24);

  /// How long dirty hosts accumulate before one [updates] tick.
  static const _tickCoalesce = Duration(milliseconds: 500);

  /// How long inline-ingested emoji accumulate before one disk write.
  static const _persistCoalesce = Duration(seconds: 1);

  /// Concurrent token-less remote catalog fetches. A global timeline
  /// surfaces dozens of new federated hosts a minute; without a limit
  /// each one opened its own HTTPS connection at once.
  static const _maxConcurrentRemote = 2;

  final _log = const Log('EmojiRepo');
  final EmojiDao _dao;

  /// host -> (name -> emoji).
  final _byHost = <String, Map<String, CustomEmoji>>{};

  /// Hosts whose disk catalog has been merged into [_byHost].
  final _warmedHosts = <String>{};

  /// Hosts whose warm-from-disk has *completed* (hit or empty). A
  /// [lookup] miss after this point means the cached catalog genuinely
  /// lacks the emoji, which is the one trigger for an on-demand remote
  /// fetch — rendering otherwise relies on the inline emoji maps that
  /// ride along with every note, so nothing fetches catalogs eagerly.
  final _warmDone = <String>{};

  /// Full catalog downloads this session. Test hook for the "served
  /// from disk within the TTL" path.
  @visibleForTesting
  int networkFetches = 0;

  /// Hosts with an in-flight network fetch.
  final _inFlight = <String, Future<void>>{};

  /// Hosts whose full catalog fetch (authenticated or remote) has
  /// completed this session — success or failure. A failed host is not
  /// retried until restart so an offline or non-Misskey server can't
  /// be re-polled by every timeline that sees one of its users.
  final _fetchedThisSession = <String>{};

  /// Remote fetch queue: hosts waiting for a slot, and the completer
  /// callers of [ensureFetchedRemote] are handed while they wait.
  final _remoteQueue = <String>[];
  final _remoteWaiters = <String, Completer<void>>{};
  int _remoteActive = 0;

  /// Broadcast: emits the set of hosts whose catalog changed since the
  /// last tick. UI consumers subscribe to know when to redraw notes
  /// that previously rendered emoji as text fallback.
  final _updatesController = StreamController<Set<String>>.broadcast();
  Stream<Set<String>> get updates => _updatesController.stream;
  final _dirtyHosts = <String>{};
  Timer? _tickTimer;

  /// Inline-ingested emoji waiting for the next disk write, keyed by
  /// `host/name` so a name seen on many notes is written once.
  final _persistQueue = <String, CustomEmoji>{};
  Timer? _persistTimer;

  EmojiRepository({required EmojiDao dao}) : _dao = dao;

  /// Synchronous snapshot of every emoji we have cached for a host.
  /// De-duplicates by name (aliases map to their canonical entries
  /// inside `_byHost`, so the same emoji can appear under multiple
  /// keys; Set + identity-by-name strips the duplicates).
  List<CustomEmoji> allForHost(String host) {
    final m = _byHost[host];
    if (m == null) return const [];
    final seen = <String>{};
    final out = <CustomEmoji>[];
    for (final e in m.values) {
      if (seen.add(e.name)) out.add(e);
    }
    return out;
  }

  /// Synchronous lookup. Returns null if not yet cached for the host;
  /// the call also schedules a fetch + warm-from-disk.
  CustomEmoji? lookup({required String host, required String name}) {
    final hot = _byHost[host];
    if (hot != null && hot.containsKey(name)) return hot[name];

    // Schedule a warm-from-disk once per host. Disk I/O is async, so we
    // can't satisfy this call synchronously — the next render after the
    // warm completes will hit.
    if (!_warmedHosts.contains(host)) {
      _warmedHosts.add(host);
      _warmFromDisk(host);
    } else if (_warmDone.contains(host) &&
        !_fetchedThisSession.contains(host) &&
        !_inFlight.containsKey(host) &&
        !_remoteWaiters.containsKey(host)) {
      // Disk is loaded and still doesn't know this emoji: fetch the
      // catalog on demand (once per session, subject to the TTL).
      unawaited(ensureFetchedRemote(host));
    }
    return null;
  }

  /// Force-fetch a host's catalog from the network. Used on account
  /// add to warm the catalog, and as the fallback when [lookup]
  /// misses.
  ///
  /// Once per session, and only when the on-disk catalog is older than
  /// [ttl]: a fresh catalog is loaded from disk instead, so launching
  /// the app or opening another screen never re-downloads thousands of
  /// entries per server.
  Future<void> ensureFetched({
    required MisskeyHttpClient client,
    Duration ttl = _refreshThreshold,
  }) {
    final host = client.host.value;
    if (_fetchedThisSession.contains(host)) return Future.value();
    final existing = _inFlight[host];
    if (existing != null) return existing;

    final f = _fetchIfStale(client, ttl).whenComplete(() {
      _inFlight.remove(host);
    });
    _inFlight[host] = f;
    return f;
  }

  /// True when [host]'s full catalog was downloaded within [ttl].
  Future<bool> _catalogFresh(String host, Duration ttl) async {
    try {
      final at = await _dao.catalogFetchedAt(host);
      return at != null && DateTime.now().difference(at) < ttl;
    } catch (e, st) {
      _log.warn('catalog freshness for $host failed: $e', stack: st);
      return false;
    }
  }

  /// Serve from disk when fresh, otherwise download. Either way the
  /// host counts as fetched for the rest of the session.
  Future<void> _fetchIfStale(MisskeyHttpClient client, Duration ttl) async {
    final host = client.host.value;
    if (await _catalogFresh(host, ttl)) {
      if (_warmedHosts.add(host)) {
        await _warmFromDisk(host);
      }
      _fetchedThisSession.add(host);
      return;
    }
    await _fetchAndStore(client);
  }

  /// Token-less fetch of a remote host's emoji catalog.
  ///
  /// Use case: a federated note arrives carrying emoji from `host` but
  /// the user has no account there, so [ensureFetched] has no client
  /// to hand us. `/api/emojis` is `requireCredential: false` on vanilla
  /// Misskey (and is HTTP-cacheable for an hour), so a plain HTTPS POST
  /// works without a token. Falls back silently on hosts that are
  /// offline, gated, or non-Misskey.
  ///
  /// Fetches are queued behind [_maxConcurrentRemote] slots; a host
  /// already fetched this session, in flight, or queued is not fetched
  /// again. The returned future completes when that host's fetch does.
  Future<void> ensureFetchedRemote(String host) {
    if (_fetchedThisSession.contains(host)) return Future.value();
    final existing = _inFlight[host];
    if (existing != null) return existing;
    final waiting = _remoteWaiters[host];
    if (waiting != null) return waiting.future;
    try {
      MisskeyHost.parse(host);
    } on FormatException catch (e) {
      _log.warn('skip remote fetch for malformed host "$host": $e');
      // Don't keep re-validating a host we'll never fetch.
      _fetchedThisSession.add(host);
      return Future.value();
    }
    final completer = Completer<void>();
    _remoteWaiters[host] = completer;
    _remoteQueue.add(host);
    _pumpRemoteQueue();
    return completer.future;
  }

  void _pumpRemoteQueue() {
    while (_remoteActive < _maxConcurrentRemote && _remoteQueue.isNotEmpty) {
      final host = _remoteQueue.removeAt(0);
      final completer = _remoteWaiters.remove(host);
      if (_fetchedThisSession.contains(host) || _inFlight.containsKey(host)) {
        completer?.complete();
        continue;
      }
      _remoteActive++;
      final client = MisskeyHttpClient(host: MisskeyHost.parse(host));
      // _fetchAndStore never throws (it logs and swallows), so the
      // waiter can be completed unconditionally.
      final f = _fetchIfStale(client, _refreshThreshold).whenComplete(() {
        _inFlight.remove(host);
        _remoteActive--;
        completer?.complete();
        _pumpRemoteQueue();
      });
      _inFlight[host] = f;
    }
  }

  /// Ingest emoji metadata embedded in a note/user payload.
  ///
  /// Misskey embeds `{ "name@host": "url" }` (and `"name": "url"` for
  /// local emoji on the receiving server) in:
  ///   - `note.emojis`         — emoji used in note text/cw
  ///   - `note.reactionEmojis` — emoji used in reactions
  ///   - `note.user.emojis`    — emoji used in the author's display name
  ///
  /// Ingesting these is free (the data is already on the wire) and
  /// covers federated emoji on hosts the user has no account on, so
  /// no extra fetch is needed for the common case. Hosts whose
  /// catalog also gets ingested via [ensureFetched]/[ensureFetchedRemote]
  /// for browseability (reaction picker), but rendering does not depend
  /// on that.
  ///
  /// `viewerHost` is the receiving server: a bare `name` (no `@host`
  /// suffix) means the emoji is local to `viewerHost`.
  ///
  /// Only *novel* entries touch the tick / persist queues, so replaying
  /// the same emoji across hundreds of notes is a pure map lookup.
  void ingestInline({
    required String viewerHost,
    required Map<String, dynamic>? embedded,
  }) {
    if (embedded == null || embedded.isEmpty) return;
    DateTime? now;
    embedded.forEach((rawKey, value) {
      if (value is! String) return;
      final key = rawKey.endsWith(':') && rawKey.startsWith(':')
          ? rawKey.substring(1, rawKey.length - 1)
          : rawKey;
      final ref = EmojiRef.parse(key, viewerHost: viewerHost);
      // Don't clobber a richer cached entry (with aliases/category)
      // unless we don't have one yet.
      final map = _byHost.putIfAbsent(ref.host, () => {});
      final existing = map[ref.name];
      if (existing != null && existing.url == value) return;
      final emoji = CustomEmoji(
        host: ref.host,
        name: ref.name,
        url: value,
        aliases: const [],
        category: null,
        sensitive: false,
        fetchedAt: now ??= DateTime.now(),
      );
      map[ref.name] = emoji;
      _persistQueue['${ref.host}/${ref.name}'] = emoji;
      _markDirty(ref.host);
    });
    if (_persistQueue.isNotEmpty) {
      _persistTimer ??= Timer(_persistCoalesce, _flushPersist);
    }
  }

  /// Queue a change notification for [host]. Coalesced so a burst of
  /// notes produces one tick carrying every affected host.
  void _markDirty(String host, {bool immediate = false}) {
    _dirtyHosts.add(host);
    if (immediate) {
      _flushTicks();
      return;
    }
    _tickTimer ??= Timer(_tickCoalesce, _flushTicks);
  }

  void _flushTicks() {
    _tickTimer?.cancel();
    _tickTimer = null;
    if (_dirtyHosts.isEmpty || _updatesController.isClosed) return;
    final hosts = Set<String>.unmodifiable(_dirtyHosts);
    _dirtyHosts.clear();
    _updatesController.add(hosts);
  }

  /// Persist queued inline emoji in one Drift batch (one transaction).
  /// If the disk write fails we still have the in-memory copy for this
  /// session.
  Future<void> _flushPersist() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    if (_persistQueue.isEmpty) return;
    final items = _persistQueue.values.toList(growable: false);
    _persistQueue.clear();
    try {
      await _dao.upsertMany(items);
    } catch (e, st) {
      _log.warn('persist inline emoji failed: $e', stack: st);
    }
  }

  Future<void> _warmFromDisk(String host) async {
    try {
      final all = await _dao.allForHost(host);
      if (all.isEmpty) return;
      final map = _byHost.putIfAbsent(host, () => {});
      for (final e in all) {
        map[e.name] = e;
        for (final alias in e.aliases) {
          map.putIfAbsent(alias, () => e);
        }
      }
      // A whole catalog landing is a single event; no need to wait for
      // the coalescing window.
      _markDirty(host, immediate: true);
    } catch (e, st) {
      _log.warn('warm-from-disk for $host failed: $e', stack: st);
    } finally {
      _warmDone.add(host);
    }
  }

  Future<void> _fetchAndStore(MisskeyHttpClient client) async {
    final host = client.host.value;
    try {
      networkFetches++;
      final raw = await MisskeyEndpoints(client).emojis();
      final items = raw
          .map<CustomEmoji?>((j) {
            final name = j['name'];
            final url = j['url'];
            if (name is! String || url is! String) return null;
            final aliases = (j['aliases'] as List?)?.cast<String>() ?? const [];
            return CustomEmoji(
              host: host,
              name: name,
              url: url,
              aliases: aliases,
              category: j['category'] as String?,
              sensitive: j['isSensitive'] == true,
              fetchedAt: DateTime.now(),
            );
          })
          .whereType<CustomEmoji>()
          .toList(growable: false);
      await _dao.upsertMany(items);
      await _dao.markCatalogFetched(host, DateTime.now());
      final map = _byHost.putIfAbsent(host, () => {});
      for (final e in items) {
        map[e.name] = e;
        for (final alias in e.aliases) {
          map.putIfAbsent(alias, () => e);
        }
      }
      _warmedHosts.add(host);
      _warmDone.add(host);
      _markDirty(host, immediate: true);
      _log.info('fetched ${items.length} custom emoji for $host');
    } catch (e, st) {
      _log.warn('fetch emoji catalog for $host failed: $e', stack: st);
    } finally {
      _fetchedThisSession.add(host);
    }
  }

  void dispose() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _persistTimer?.cancel();
    _persistTimer = null;
    // Best-effort final write; the app-lifetime provider only disposes
    // on shutdown.
    unawaited(_flushPersist());
    for (final c in _remoteWaiters.values) {
      if (!c.isCompleted) c.complete();
    }
    _remoteWaiters.clear();
    _remoteQueue.clear();
    _updatesController.close();
  }
}
