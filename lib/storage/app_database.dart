import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Persistent application data.
///
/// Identity rules:
///   - accounts.id      = "host:userId"
///   - notes:           composite PK (sourceHost, id)
///   - emoji:           composite PK (host, name)
///   - timeline_items:  cross-account merge rows; (accountId, timelineKey, noteSourceHost, noteId) unique
///
/// Forward-compat: every entity that mirrors a Misskey API object stores
/// `rawJson` so a future schema bump can extract new fields without a
/// re-fetch.

@DataClassName('ServerRow')
class Servers extends Table {
  TextColumn get host => text()();
  TextColumn get name => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get softwareName => text().nullable()();
  TextColumn get softwareVersion => text().nullable()();
  TextColumn get iconUrl => text().nullable()();
  TextColumn get bannerUrl => text().nullable()();
  DateTimeColumn get metaFetchedAt => dateTime().nullable()();
  TextColumn get rawJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {host};
}

@DataClassName('AccountRow')
class Accounts extends Table {
  /// "host:userId"
  TextColumn get id => text()();
  TextColumn get host => text()();
  TextColumn get userId => text()();
  TextColumn get username => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  BoolColumn get isCat => boolean().withDefault(const Constant(false))();
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserRow')
class Users extends Table {
  /// Observing host (which server's perspective stored this row).
  TextColumn get viewerHost => text()();

  /// User id from `viewerHost`'s perspective.
  TextColumn get id => text()();
  TextColumn get username => text()();

  /// User's home host (null = local to viewerHost).
  TextColumn get host => text().nullable()();
  TextColumn get name => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get avatarBlurhash => text().nullable()();
  BoolColumn get isBot => boolean().withDefault(const Constant(false))();
  BoolColumn get isCat => boolean().withDefault(const Constant(false))();
  DateTimeColumn get fetchedAt => dateTime()();
  TextColumn get rawJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {viewerHost, id};
}

@DataClassName('NoteRow')
class Notes extends Table {
  TextColumn get sourceHost => text()();
  TextColumn get id => text()();
  TextColumn get userViewerHost => text()();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get body => text().named('text').nullable()();
  TextColumn get cw => text().nullable()();
  TextColumn get visibility => text()(); // enum name
  TextColumn get replyId => text().nullable()();
  TextColumn get renoteId => text().nullable()();
  IntColumn get repliesCount => integer().withDefault(const Constant(0))();
  IntColumn get renoteCount => integer().withDefault(const Constant(0))();

  /// JSON-encoded reactions list. Counts churn fast; storing structured
  /// rows is more write traffic than this is worth at MVP.
  TextColumn get reactionsJson => text().nullable()();

  /// Full original JSON for forward-compat.
  TextColumn get rawJson => text().nullable()();

  /// Monotonic revision: bumped on edit/reaction/replyCount change so
  /// the height cache can key on it.
  IntColumn get revision => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {sourceHost, id};
}

@DataClassName('EmojiRow')
class Emojis extends Table {
  TextColumn get host => text()();
  TextColumn get name => text()();
  TextColumn get url => text()();

  /// JSON-encoded `List<String>` of aliases.
  TextColumn get aliasesJson => text().nullable()();
  TextColumn get category => text().nullable()();
  BoolColumn get sensitive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {host, name};
}

/// One row per host whose *full* `/api/emojis` catalog has been
/// fetched, stamped with when. `Emojis.fetchedAt` can't answer "is the
/// catalog fresh?" because inline-ingested emoji (from note payloads)
/// keep refreshing it on hosts that were never fully fetched.
@DataClassName('EmojiCatalogRow')
class EmojiCatalogs extends Table {
  TextColumn get host => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {host};
}

@DataClassName('TimelineItemRow')
class TimelineItems extends Table {
  /// Owning account ("host:userId").
  TextColumn get accountId => text()();

  /// Timeline this note appears in for `accountId`. Values:
  /// `home`, `local`, `hybrid`, `global`, `mentions`, `notifications`,
  /// or per-list keys later.
  TextColumn get timelineKey => text()();
  TextColumn get noteSourceHost => text()();
  TextColumn get noteId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get receivedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {
    accountId,
    timelineKey,
    noteSourceHost,
    noteId,
  };
}

@DataClassName('HeightCacheRow')
class HeightCache extends Table {
  /// Composite cache key for a particular note layout.
  TextColumn get host => text()();
  TextColumn get noteId => text()();
  IntColumn get revision => integer()();
  RealColumn get width => real()();
  RealColumn get textScale => real()();
  TextColumn get themeId => text()();
  BoolColumn get cwExpanded => boolean()();
  TextColumn get mfmSettingsHash => text()();

  RealColumn get height => real()();
  DateTimeColumn get computedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {
    host,
    noteId,
    revision,
    width,
    textScale,
    themeId,
    cwExpanded,
    mfmSettingsHash,
  };
}

@DataClassName('ReactionRecentRow')
class ReactionRecents extends Table {
  /// Owning account so each account remembers its own picker recents.
  TextColumn get accountId => text()();

  /// Same `key` shape as `Reaction.key` (unicode codepoint sequence
  /// or `:name@host:` for custom emoji).
  TextColumn get reactionKey => text()();
  IntColumn get useCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {accountId, reactionKey};
}

/// In-progress compose drafts, persisted across app restarts.
///
/// Identity: a v4 UUID minted at first save. Multiple drafts can coexist
/// per account (e.g. saved a long-form post, then started a quick reply).
/// Drafts hold parameters not raw rendered text — `fileIdsJson` is the
/// list of drive-file ids the user has already uploaded; we keep them so
/// "save draft + resume later" doesn't re-upload.
@DataClassName('DraftRow')
class Drafts extends Table {
  /// v4 UUID.
  TextColumn get id => text()();

  /// Owning account ("host:userId"). A draft is only visible to its
  /// owning account so two accounts on the same device don't pollute
  /// each other's draft list.
  TextColumn get accountId => text()();

  /// Renamed from `text` because `Table.text()` is the column-builder
  /// in Drift and would shadow the field.
  TextColumn get body => text().named('text').nullable()();
  TextColumn get cw => text().nullable()();

  /// `public` / `home` / `followers` / `specified`.
  TextColumn get visibility => text().withDefault(const Constant('public'))();
  BoolColumn get localOnly => boolean().withDefault(const Constant(false))();

  TextColumn get replyId => text().nullable()();
  TextColumn get renoteId => text().nullable()();

  /// Canonical ActivityPub URI of the source note when this draft is a
  /// reply or quote (`Note.originId`). Stored alongside replyId/renoteId
  /// because those are account-local ids — switching accounts in the
  /// composer requires re-resolving via `ap/show`, which keys on URI.
  TextColumn get sourceNoteUri => text().nullable()();

  /// host of the active account at the time the draft was saved
  /// (`accountId`'s host component) — kept so a stale `replyId` from
  /// before an account change can be discarded if the account isn't
  /// available any more.
  TextColumn get sourceHost => text().nullable()();

  /// JSON-encoded `List<String>` of drive file ids already uploaded.
  TextColumn get fileIdsJson => text().nullable()();

  /// Target channel (local to the owning account's server) when the
  /// draft was addressed to a channel. `channelName` is denormalised
  /// so the chip renders on resume without a `channels/show` round
  /// trip.
  TextColumn get channelId => text().nullable()();
  TextColumn get channelName => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Singleton row of app-wide preferences (theme, text scale, MFM
/// effects, etc.). The single-row pattern is simpler than a generic
/// kv table and keeps the schema explicit.
@DataClassName('AppPreferenceRow')
class AppPreferences extends Table {
  /// Always the literal `'singleton'`. The PK exists only so we can
  /// `insertOrReplace` to update.
  TextColumn get id => text().withDefault(const Constant('singleton'))();

  /// `system` / `light` / `dark`.
  TextColumn get themeMode => text().withDefault(const Constant('system'))();

  /// 1.0 = no override; otherwise multiplied with MediaQuery's text
  /// scaler to produce the effective scale.
  RealColumn get textScale => real().withDefault(const Constant(1.0))();

  BoolColumn get disableAnimatedMfm =>
      boolean().withDefault(const Constant(false))();

  /// `null` (inherit OS) is encoded as the empty string here so we
  /// can avoid making the column nullable + still distinguish unset.
  ///   '' = inherit, 'on' = force motion on, 'off' = force motion off.
  TextColumn get reducedMotionOverride =>
      text().withDefault(const Constant(''))();

  /// When true, blur the body / media / quote of notes posted in a
  /// channel flagged `isSensitive`. Default-on so a new install errs
  /// on the safe side; users can turn it off in Settings.
  BoolColumn get blurSensitiveChannels =>
      boolean().withDefault(const Constant(true))();

  /// Only the independent GitHub updater reads these preferences.
  BoolColumn get automaticUpdateChecks =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastUpdateCheckAt => dateTime().nullable()();
  IntColumn get dismissedUpdateVersionCode => integer().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// User-defined "custom unified" timelines.
///
/// A custom timeline is a named bag of sources, each source being a
/// `(account, kind, channelId?)` triple. The list is stored as JSON
/// because the shape is small and the relational alternative (a
/// separate `custom_timeline_sources` table with a foreign key) would
/// triple the migration surface for negligible query benefit — we
/// always read the whole timeline as one row.
@DataClassName('CustomTimelineRow')
class CustomTimelines extends Table {
  /// v4 UUID.
  TextColumn get id => text()();

  TextColumn get name => text()();

  /// Display order in the kind picker; lowest first.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// JSON-encoded `List<TimelineSource>`.
  TextColumn get sourcesJson => text()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Servers,
    Accounts,
    Users,
    Notes,
    Emojis,
    EmojiCatalogs,
    TimelineItems,
    HeightCache,
    ReactionRecents,
    Drafts,
    CustomTimelines,
    AppPreferences,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // v1 -> v2: drafts table.
      if (from < 2) {
        await m.createTable(drafts);
      }
      // v2 -> v3: source-note URI/host columns on drafts so a draft
      // can re-resolve its reply/quote target on a different account.
      if (from >= 2 && from < 3) {
        await m.addColumn(drafts, drafts.sourceNoteUri);
        await m.addColumn(drafts, drafts.sourceHost);
      }
      // v3 -> v4: custom-unified timelines.
      if (from < 4) {
        await m.createTable(customTimelines);
      }
      // v4 -> v5: persistent app preferences singleton.
      if (from < 5) {
        await m.createTable(appPreferences);
      }
      // v5 -> v6: blur-on-sensitive-channels preference. Default
      // true so existing users get the safe-by-default behaviour
      // until they opt out.
      if (from >= 5 && from < 6) {
        await m.addColumn(appPreferences, appPreferences.blurSensitiveChannels);
      }
      // v6 -> v7: drafts remember the channel they were addressed
      // to (compose-time channel picker).
      if (from >= 2 && from < 7) {
        await m.addColumn(drafts, drafts.channelId);
        await m.addColumn(drafts, drafts.channelName);
      }
      // v7 -> v8: per-host emoji catalog freshness, so launches
      // within the TTL serve the catalog from disk instead of
      // re-downloading thousands of entries per server.
      if (from < 8) {
        await m.createTable(emojiCatalogs);
      }
      // A database created while upgrading from before v5 already
      // has the current preferences columns.
      if (from >= 5 && from < 9) {
        await m.addColumn(appPreferences, appPreferences.automaticUpdateChecks);
        await m.addColumn(appPreferences, appPreferences.lastUpdateCheckAt);
        await m.addColumn(
          appPreferences,
          appPreferences.dismissedUpdateVersionCode,
        );
      }
    },
  );

  static QueryExecutor _open() {
    return driftDatabase(name: 'misskey_gglp');
  }
}
