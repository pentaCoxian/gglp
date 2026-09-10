import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:async';

import '../app/providers.dart';
import '../core/clock.dart';
import '../core/logger.dart';
import '../misskey/emoji/emoji_providers.dart';
import '../misskey/emoji/emoji_repository.dart';
import '../misskey/http/endpoint_registry.dart';
import '../misskey/models/account.dart';
import '../misskey/models/note.dart';
import '../misskey/models/parsers.dart';
import '../misskey/models/reaction_patch.dart';
import '../misskey/streaming/stream_connection.dart';
import '../misskey/streaming/stream_messages.dart';
import '../misskey/streaming/stream_providers.dart';
import '../misskey/streaming/stream_subscription_spec.dart';
import '../misskey/streaming/stream_supervisor.dart';
import 'note_keys.dart';
import 'stream_event_batcher.dart';
import 'timeline_kind.dart';
import 'timeline_merge_engine.dart';

/// State for a unified, multi-account merged timeline.
class UnifiedTimelineState {
  final List<MergedTimelineItem> items;

  /// `originId -> item` over [items]; see [MergedIndex]. Rows watch
  /// `byId[originId]` instead of scanning [items] per emission.
  final Map<String, MergedTimelineItem> byId;

  /// `sourceHost:noteId -> originId` so streaming patch / delete events
  /// (tagged with the receiving host) resolve to a row in O(1).
  final Map<String, String> originByReceiver;

  /// See [TimelineState.pending].
  final List<MergedTimelineItem> pending;
  final bool holdPending;

  final bool isPaginating;
  final Map<String, bool> reachedEndPerAccount;
  final Object? error;

  const UnifiedTimelineState({
    this.items = const [],
    this.byId = const {},
    this.originByReceiver = const {},
    this.pending = const [],
    this.holdPending = false,
    this.isPaginating = false,
    this.reachedEndPerAccount = const {},
    this.error,
  });

  /// Build a state whose indexes match [items].
  factory UnifiedTimelineState.indexed({
    required List<MergedTimelineItem> items,
    List<MergedTimelineItem> pending = const [],
    bool holdPending = false,
    bool isPaginating = false,
    Map<String, bool> reachedEndPerAccount = const {},
    Object? error,
  }) {
    final index = indexMerged(items);
    return UnifiedTimelineState(
      items: items,
      byId: index.byId,
      originByReceiver: index.originByReceiver,
      pending: pending,
      holdPending: holdPending,
      isPaginating: isPaginating,
      reachedEndPerAccount: reachedEndPerAccount,
      error: error,
    );
  }

  bool get reachedEnd => reachedEndPerAccount.isNotEmpty &&
      reachedEndPerAccount.values.every((v) => v);

  /// Replacing [items] re-indexes automatically so the maps can never
  /// drift from the list.
  UnifiedTimelineState copyWith({
    List<MergedTimelineItem>? items,
    List<MergedTimelineItem>? pending,
    bool? holdPending,
    bool? isPaginating,
    Map<String, bool>? reachedEndPerAccount,
    Object? error,
    bool clearError = false,
  }) {
    final index = items == null
        ? (byId: byId, originByReceiver: originByReceiver)
        : indexMerged(items);
    return UnifiedTimelineState(
      items: items ?? this.items,
      byId: index.byId,
      originByReceiver: index.originByReceiver,
      pending: pending ?? this.pending,
      holdPending: holdPending ?? this.holdPending,
      isPaginating: isPaginating ?? this.isPaginating,
      reachedEndPerAccount:
          reachedEndPerAccount ?? this.reachedEndPerAccount,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Multi-account merged timeline.
///
/// On first build:
///   1. fetch one page from each logged-in account in parallel
///   2. merge them with the merge engine
/// On stream events: buffered per window, then prepend / patch / remove
/// via the merge engine in one pass.
/// On pagination: fetch the next page from EACH account using their
/// own `untilId` tail anchor; re-merge.
class UnifiedTimelineController
    extends FamilyAsyncNotifier<UnifiedTimelineState, TimelineKind> {
  static const _pageSize = 30;
  static const _liveCap = 800;

  final _log = const Log('UnifiedTimeline');
  final _engine = const TimelineMergeEngine();

  late TimelineKind _kind;
  late List<Account> _accounts;
  late EmojiRepository _emojiRepo;
  final _channelLocalIdsByAccount = <String, String>{};

  /// accountId -> that account's userId, for mirroring `myReaction`
  /// when a patch is caused by the viewer.
  final _viewerUserIdByAccount = <String, String>{};

  /// See [TimelineController._events].
  late final _events =
      StreamEventBatcher<MisskeyStreamEvent>(onFlush: _applyBatch);

  @override
  Future<UnifiedTimelineState> build(TimelineKind kind) async {
    _kind = kind;
    _events.clear();
    ref.onDispose(_events.clear);
    final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
    _accounts = accounts;
    _viewerUserIdByAccount
      ..clear()
      ..addEntries(accounts.map((a) => MapEntry(a.id, a.userId)));
    _emojiRepo = ref.watch(emojiRepositoryProvider);
    if (accounts.isEmpty) {
      return const UnifiedTimelineState();
    }

    _attachStreams();

    // Parallel HTTP fan-out.
    final perAccount = <String, List<Note>>{};
    final futures = <Future<void>>[];
    for (final account in accounts) {
      futures.add(() async {
        try {
          final endpoints = await ref
              .watch(misskeyEndpointsProvider(account).future);
          if (endpoints == null) return;
          final notes = await _fetchOne(endpoints, kind: kind);
          perAccount[account.id] = notes;
        } catch (e, st) {
          _log.warn('initial fetch for ${account.id} failed: $e', stack: st);
        }
      }());
    }
    await Future.wait(futures);

    for (final list in perAccount.values) {
      _ingestEmoji(list);
    }
    final merged = _engine.merge(perAccount, now: Clock.system.now());
    return UnifiedTimelineState.indexed(
      items: merged,
      reachedEndPerAccount: {
        for (final a in accounts)
          a.id: (perAccount[a.id]?.length ?? 0) < _pageSize,
      },
    );
  }

  /// See [TimelineController._ingestEmoji].
  void _ingestEmoji(Iterable<Note> notes) {
    for (final n in notes) {
      MisskeyParsers.ingestEmojis(n, _emojiRepo);
    }
  }

  void _attachStreams() {
    final supervisor = ref.read(streamSupervisorProvider);

    void subscribeAccount(Account account) {
      final localId = 'unified:${account.id}:${_kind.key}';
      _channelLocalIdsByAccount[account.id] = localId;
      final conn = supervisor.connectionFor(account);
      if (conn == null) return;
      conn.subscribe(StreamSubscriptionSpec(
        localId: localId,
        channel: _channelToMisskey(_kind),
      ));
    }

    // Subscribe each account's connection to the appropriate channel.
    // Connections that aren't open yet (fresh add-account) are picked up
    // by the listen on streamConnectionProvider below.
    for (final account in _accounts) {
      subscribeAccount(account);
    }

    // Watch each per-account connection so a brand-new account's
    // websocket completes opening, this controller picks it up and
    // subscribes its unified channel without forcing a full rebuild.
    for (final account in _accounts) {
      ref.listen<StreamConnection?>(
        streamConnectionProvider(account),
        (prev, next) {
          if (prev == null && next != null) {
            subscribeAccount(account);
          }
        },
      );
    }

    // On dispose: unsubscribe each connection from the unified channel
    // (per-account subscriptions are owned by us, not by per-kind
    // controllers — those use a different localId namespace).
    final perAccountLocals = Map.of(_channelLocalIdsByAccount);
    ref.onDispose(() {
      for (final account in _accounts) {
        final conn = supervisor.connectionFor(account);
        final localId = perAccountLocals[account.id];
        if (conn != null && localId != null) conn.unsubscribe(localId);
      }
    });

    // Listen to merged events. ref.listen (no watch) — we don't want
    // build() re-running on each event.
    ref.listen<AsyncValue<MisskeyStreamEvent>>(
      mergedStreamEventsProvider,
      (_, next) {
        final event = next.valueOrNull;
        if (event != null) _onEvent(event);
      },
    );
  }

  static String _channelToMisskey(TimelineKind k) => switch (k) {
        TimelineKind.home => MisskeyChannels.homeTimeline,
        TimelineKind.local => MisskeyChannels.localTimeline,
        TimelineKind.hybrid => MisskeyChannels.hybridTimeline,
        TimelineKind.global => MisskeyChannels.globalTimeline,
      };

  void _onEvent(MisskeyStreamEvent event) {
    switch (event) {
      case NoteAdded(:final channelId):
        // Only consume events from OUR unified channels (each account's
        // per-kind channel for this controller). The account is
        // identified by parsing the localId we minted.
        if (_accountForChannel(channelId) == null) return;
        _events.add(event);
      case NoteDeleted():
        _events.add(event);
      case NoteUpdated(:final patch):
        if (patch != null) _events.add(event);
      case ConnectionStateChanged():
      case NotificationReceived():
        // Surfaced elsewhere (drawer dot, notifications).
        break;
    }
  }

  String? _accountForChannel(String channelId) {
    for (final entry in _channelLocalIdsByAccount.entries) {
      if (entry.value == channelId) return entry.key;
    }
    return null;
  }

  /// Apply one buffered window of stream events with a single state
  /// emission. Same replay semantics as
  /// [TimelineController._applyBatch]; the merge engine's batch insert
  /// handles cross-account dedupe of the new items.
  void _applyBatch(List<MisskeyStreamEvent> batch) {
    final s = state.valueOrNull;
    if (s == null) return;
    final now = Clock.system.now();

    // New items in arrival order, indexed by receiver key so patches /
    // deletes for a note still in this window resolve in place.
    final fresh = <MergedTimelineItem?>[];
    final freshIndex = <String, int>{};
    final replace = Map<MergedTimelineItem, MergedTimelineItem>.identity();
    final gone = Set<MergedTimelineItem>.identity();
    final pendingDeletes = <(String, String)>[];

    for (final event in batch) {
      switch (event) {
        case NoteAdded(:final channelId, :final note):
          final accountId = _accountForChannel(channelId);
          if (accountId == null) continue;
          final key = noteKey(note);
          if (freshIndex.containsKey(key)) continue;
          freshIndex[key] = fresh.length;
          fresh.add(MergedTimelineItem(
            accountId: accountId,
            note: note,
            receivedAt: now,
          ));
        case NoteDeleted(:final noteId, :final sourceHost):
          final key = noteKeyOf(sourceHost: sourceHost, noteId: noteId);
          final fi = freshIndex.remove(key);
          if (fi != null) {
            fresh[fi] = null;
            continue;
          }
          final origin = s.originByReceiver[key];
          final visible = origin == null ? null : s.byId[origin];
          if (visible != null) {
            gone.add(visible);
            replace.remove(visible);
          }
          if (s.pending.isNotEmpty) pendingDeletes.add((sourceHost, noteId));
        case NoteUpdated(:final noteId, :final sourceHost, :final patch):
          if (patch == null) continue;
          final key = noteKeyOf(sourceHost: sourceHost, noteId: noteId);
          final fi = freshIndex[key];
          if (fi != null) {
            final it = fresh[fi]!;
            fresh[fi] = it.withNote(ReactionPatch.apply(
              it.note,
              patch,
              viewerUserId: _viewerUserIdByAccount[it.accountId],
            ));
            continue;
          }
          // The patch arrives tagged with the receiving host; resolve to
          // the deduped (origin-keyed) row we kept.
          final origin = s.originByReceiver[key];
          final original = origin == null ? null : s.byId[origin];
          if (original == null || gone.contains(original)) continue;
          final base = replace[original] ?? original;
          final updated = ReactionPatch.apply(
            base.note,
            patch,
            viewerUserId: _viewerUserIdByAccount[base.accountId],
          );
          if (!identical(updated, base.note)) {
            replace[original] = base.withNote(updated);
          }
        case ConnectionStateChanged():
        case NotificationReceived():
          break;
      }
    }

    var items = s.items;
    var pending = s.pending;
    var dirty = false;

    if (replace.isNotEmpty || gone.isNotEmpty) {
      items = [
        for (final it in items)
          if (!gone.contains(it)) replace[it] ?? it,
      ];
      dirty = true;
    }
    for (final (sourceHost, noteId) in pendingDeletes) {
      final next =
          _engine.removeNote(pending, sourceHost: sourceHost, noteId: noteId);
      if (!identical(next, pending)) {
        pending = next;
        dirty = true;
      }
    }

    final freshItems = <MergedTimelineItem>[
      for (final it in fresh)
        if (it != null) it,
    ];
    if (freshItems.isNotEmpty) {
      _ingestEmoji(freshItems.map((it) => it.note));
      if (s.holdPending) {
        // Buffer for the new-notes banner. Use the merge engine so the
        // pending list itself stays sorted — releasing it keeps the
        // global order correct.
        pending = _capped(_engine.insertMany(pending, freshItems));
      } else {
        items = _capped(_engine.insertMany(items, freshItems));
      }
      dirty = true;
    }

    if (!dirty) return;
    state = AsyncData(s.copyWith(
      items: identical(items, s.items) ? null : items,
      pending: pending,
    ));
  }

  static List<MergedTimelineItem> _capped(List<MergedTimelineItem> list) =>
      list.length > _liveCap ? list.sublist(0, _liveCap) : list;

  void setHoldPending(bool hold) {
    final s = state.valueOrNull;
    if (s == null) return;
    if (s.holdPending == hold) return;
    if (!hold && s.pending.isNotEmpty) {
      releasePending();
      return;
    }
    state = AsyncData(s.copyWith(holdPending: hold));
  }

  void releasePending() {
    final s = state.valueOrNull;
    if (s == null) return;
    if (s.pending.isEmpty) {
      state = AsyncData(s.copyWith(holdPending: false));
      return;
    }
    // Both lists are already sorted and deduped, so one merge pass
    // (rather than a full rebuild + sort) restores global order.
    state = AsyncData(s.copyWith(
      items: _capped(_engine.insertMany(s.items, s.pending)),
      pending: const [],
      holdPending: false,
    ));
  }

  Future<List<Note>> _fetchOne(
    MisskeyEndpoints endpoints, {
    required TimelineKind kind,
    String? untilId,
  }) {
    switch (kind) {
      case TimelineKind.home:
        return endpoints.homeTimeline(limit: _pageSize, untilId: untilId);
      case TimelineKind.local:
        return endpoints.localTimeline(limit: _pageSize, untilId: untilId);
      case TimelineKind.hybrid:
        return endpoints.hybridTimeline(limit: _pageSize, untilId: untilId);
      case TimelineKind.global:
        return endpoints.globalTimeline(limit: _pageSize, untilId: untilId);
    }
  }

  Future<void> loadMore() async {
    final s = state.valueOrNull;
    if (s == null || s.isPaginating || s.reachedEnd) return;
    state = AsyncData(s.copyWith(isPaginating: true, clearError: true));

    // Per-account paging: each account contributes its own next page,
    // anchored on the oldest note we've seen FROM THAT ACCOUNT (not the
    // global tail). Without per-account anchors, accounts that lag
    // behind the global tail would never get paginated.
    final tailByAccount = <String, String>{};
    for (final item in s.items) {
      tailByAccount[item.accountId] = item.note.id;
    }

    final perAccountAdditions = <String, List<Note>>{};
    final reachedEnd = Map<String, bool>.from(s.reachedEndPerAccount);
    final futures = <Future<void>>[];
    for (final account in _accounts) {
      if (reachedEnd[account.id] == true) continue;
      futures.add(() async {
        try {
          final endpoints = await ref
              .watch(misskeyEndpointsProvider(account).future);
          if (endpoints == null) return;
          final older = await _fetchOne(
            endpoints,
            kind: _kind,
            untilId: tailByAccount[account.id],
          );
          perAccountAdditions[account.id] = older;
          if (older.length < _pageSize) reachedEnd[account.id] = true;
        } catch (e, st) {
          _log.warn('paginate ${account.id} failed: $e', stack: st);
        }
      }());
    }
    await Future.wait(futures);

    // Build on the *current* state: streamed notes may have landed
    // while the pages were in flight.
    final cur = state.valueOrNull ?? s;
    if (perAccountAdditions.isEmpty) {
      state = AsyncData(cur.copyWith(
        isPaginating: false,
        reachedEndPerAccount: reachedEnd,
      ));
      return;
    }

    for (final list in perAccountAdditions.values) {
      _ingestEmoji(list);
    }

    // Re-merge: we have to reconstruct an existing per-account map from
    // cur.items because the engine works on whole lists, not deltas.
    final reconstructed = <String, List<Note>>{};
    for (final item in cur.items) {
      reconstructed.putIfAbsent(item.accountId, () => []).add(item.note);
    }
    perAccountAdditions.forEach((acct, notes) {
      reconstructed.putIfAbsent(acct, () => []).addAll(notes);
    });
    final merged = _engine.merge(reconstructed, now: Clock.system.now());

    state = AsyncData(cur.copyWith(
      items: merged,
      isPaginating: false,
      reachedEndPerAccount: reachedEnd,
    ));
  }

  Future<void> refresh() async {
    _events.clear();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(_kind));
  }
}

final unifiedTimelineControllerProvider = AsyncNotifierProvider.family<
    UnifiedTimelineController,
    UnifiedTimelineState,
    TimelineKind>(UnifiedTimelineController.new);
