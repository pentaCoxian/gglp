import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../misskey/auth/account_repository.dart';
import '../misskey/http/endpoint_registry.dart';
import '../misskey/http/misskey_http_client.dart';
import '../misskey/models/account.dart';
import '../storage/app_database.dart';
import '../timeline/custom_timeline.dart';
import '../storage/daos/account_dao.dart';
import '../storage/daos/custom_timeline_dao.dart';
import '../storage/daos/draft_dao.dart';
import '../storage/daos/emoji_dao.dart';
import '../storage/daos/height_cache_dao.dart';
import '../storage/daos/preferences_dao.dart';
import '../storage/daos/reaction_recent_dao.dart';
import '../storage/daos/server_dao.dart';
import '../storage/secure_token_store.dart';
import '../text_layout/note_height_cache.dart';

/// Singleton database. App-lifetime; never disposed.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final accountDaoProvider = Provider<AccountDao>((ref) {
  return AccountDao(ref.watch(appDatabaseProvider));
});

final serverDaoProvider = Provider<ServerDao>((ref) {
  return ServerDao(ref.watch(appDatabaseProvider));
});

final emojiDaoProvider = Provider<EmojiDao>((ref) {
  return EmojiDao(ref.watch(appDatabaseProvider));
});

final heightCacheDaoProvider = Provider<HeightCacheDao>((ref) {
  return HeightCacheDao(ref.watch(appDatabaseProvider));
});

final reactionRecentDaoProvider = Provider<ReactionRecentDao>((ref) {
  return ReactionRecentDao(ref.watch(appDatabaseProvider));
});

final draftDaoProvider = Provider<DraftDao>((ref) {
  return DraftDao(ref.watch(appDatabaseProvider));
});

final preferencesDaoProvider = Provider<PreferencesDao>((ref) {
  return PreferencesDao(ref.watch(appDatabaseProvider));
});

final customTimelineDaoProvider = Provider<CustomTimelineDao>((ref) {
  return CustomTimelineDao(ref.watch(appDatabaseProvider));
});

/// Live list of user-defined custom unified timelines, ordered by
/// `sortOrder` then creation time. Powers the AccountDrawer section.
final customTimelinesProvider = StreamProvider<List<CustomTimeline>>((ref) {
  return ref.watch(customTimelineDaoProvider).watchAll();
});

/// App-lifetime two-tier note-height cache (memory LRU + Drift).
final noteHeightCacheProvider = Provider<NoteHeightCache>((ref) {
  final cache = NoteHeightCache(dao: ref.watch(heightCacheDaoProvider));
  ref.onDispose(cache.dispose);
  return cache;
});

final secureTokenStoreProvider = Provider<SecureTokenStore>((_) {
  return SecureTokenStore();
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(
    accountDao: ref.watch(accountDaoProvider),
    serverDao: ref.watch(serverDaoProvider),
    tokens: ref.watch(secureTokenStoreProvider),
  );
});

/// Live list of all logged-in accounts.
final accountsProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountRepositoryProvider).watch();
});

/// Authenticated HTTP client per-account. Cached so repeat reads share
/// the same Dio (and its connection pool).
final misskeyClientProvider =
    FutureProvider.family<MisskeyHttpClient?, Account>((ref, account) async {
  return ref.watch(accountRepositoryProvider).clientFor(account);
});

/// Typed endpoint surface per-account. Most feature code should depend on
/// this, not on the raw HTTP client.
final misskeyEndpointsProvider =
    FutureProvider.family<MisskeyEndpoints?, Account>((ref, account) async {
  final client = await ref.watch(misskeyClientProvider(account).future);
  return client == null ? null : MisskeyEndpoints(client);
});
