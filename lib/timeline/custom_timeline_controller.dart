import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'custom_timeline.dart';
import 'note_keys.dart';
import 'stream_event_batcher.dart';
import 'timeline_merge_engine.dart';
import 'timeline_source.dart';

/// State for a custom unified timeline driven by `List<TimelineSource>`.
///
/// Mirrors [UnifiedTimelineState] but keys `pending` / `reachedEnd`
/// per-source-fingerprint instead of per-account, so the same account
/// can contribute multiple sources (e.g. its home + a channel) without
/// the entries colliding.
class CustomTimelineState {
  final List<MergedTimelineItem> items;

  /// `originId -> item` over [items]; see [MergedIndex].
  final Map<String, MergedTimelineItem> byId;

  /// `sourceHost:noteId -> originId`; see [MergedIndex].
  final Map<String, String> originByReceiver;

  final List<MergedTimelineItem> pending;
  final bool holdPending;
  final bool isPaginating;
  final Map<String, bool> reachedEndPerSource;
  final Object? error;

  const CustomTimelineState({
    this.items = const [],
    this.byId = const {},
    this.originByReceiver = const {},
    this.pending = const [],
    this.holdPending = false,
    this.isPaginating = false,
    this.reachedEndPerSource = const {},
    this.error,
  });

  /// Build a state whose indexes match [items].
  factory CustomTimelineState.indexed({
    required List<MergedTimelineItem> items,
    List<MergedTimelineItem> pending = const [],
    bool holdPending = false,
    bool isPaginating = false,
    Map<String, bool> reachedEndPerSource = const {},
    Object? error,
  }) {
    final index = indexMerged(items);
    return CustomTimelineState(
      items: items,
      byId: index.byId,
      originByReceiver: index.originByReceiver,
      pending: pending,
      holdPending: holdPending,
      isPaginating: isPaginating,
      reachedEndPerSource: reachedEndPerSource,
      error: error,
    );
  }

  bool get reachedEnd =>
      reachedEndPerSource.isNotEmpty &&
      reachedEndPerSource.values.every((v) => v);

  /// Replacing [items] re-indexes automatically so the maps can never
  /// drift from the list.
  CustomTimelineState copyWith({
    List<MergedTimelineItem>? items,
    List<MergedTimelineItem>? pending,
    bool? holdPending,
    bool? isPaginating,
    Map<String, bool>? reachedEndPerSource,
    Object? error,
    bool clearError = false,
  }) {
    final index = items == null
        ? (byId: byId, originByReceiver: originByReceiver)
        : indexMerged(items);
    return CustomTimelineState(
      items: items ?? this.items,
      byId: index.byId,
      originByReceiver: index.originByReceiver,
      pending: pending ?? this.pending,
      holdPending: holdPending ?? this.holdPending,
      isPaginating: isPaginating ?? this.isPaginating,
      reachedEndPerSource:
          reachedEndPerSource ?? this.reachedEndPerSource,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Controller for a user-defined unified timeline.
///
/// Family key is the custom-timeline id (a UUID). Watches the DAO so
/// edits to the source list rebuild the timeline; watches each
/// referenced account's websocket so brand-new connections pick up our
/// per-source channel subscriptions without a full build re-run.
class CustomTimelineController
    extends FamilyAsyncNotifier<CustomTimelineState, String> {
  static const _pageSize = 30;
  static const _liveCap = 800;

  final _log = const Log('CustomTimeline');
  final _engine = const TimelineMergeEngine();

  late String _timelineId;
  late EmojiRepository _emojiRepo;

  /// Resolved sources for this build. Same order as the saved timeline,
  /// minus any sources whose account is no longer logged in (which we
  /// log + skip rather than crash).
  final _sources = <_ResolvedSource>[];

  /// localId -> source fingerprint, so inbound NoteAdded events from
  /// the streaming layer can be attributed back to a source.
  final _sourceByLocalId = <String, _ResolvedSource>{};

  /// accountId -> userId for `myReaction` mirroring in patches.
  final _viewerUserIdByAccount = <String, String>{};

  /// See [TimelineController._events].
  late final _events =
      StreamEventBatcher<MisskeyStreamEvent>(onFlush: _applyBatch);

  @override
  Future<CustomTimelineState> build(String timelineId) async {
    _timelineId = timelineId;
    _events.clear();
    ref.onDispose(_events.clear);
    _emojiRepo = ref.watch(emojiRepositoryProvider);

    // Watch the timeline definition so edits to its sources rebuild
    // the controller. valueOrNull is null on the very first frame
    // (Drift stream not yet emitted) so we treat that as empty.
    final timelines =
        ref.watch(customTimelinesProvider).valueOrNull ?? const [];
    final timeline = timelines
        .cast<CustomTimeline?>()
        .firstWhere((t) => t!.id == timelineId, orElse: () => null);
    if (timeline == null) {
      return const CustomTimelineState();
    }

    final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
    final accountById = {for (final a in accounts) a.id: a};

    _sources.clear();
    _sourceByLocalId.clear();
    _viewerUserIdByAccount.clear();
    for (final src in timeline.sources) {
      final account = accountById[src.accountId];
      if (account == null) {
        _log.warn(
          'source ${src.fingerprint}: account ${src.accountId} not '
          'logged in, skipping',
        );
        continue;
      }
      _sources.add(_ResolvedSource(account: account, source: src));
      _viewerUserIdByAccount[account.id] = account.userId;
    }

    if (_sources.isEmpty) {
      return const CustomTimelineState();
    }

    _attachStreams();

    // Parallel HTTP fan-out. Each source's bucket key is its
    // fingerprint (account + kind + channelId), not the account id.
    final perBucket = <String, List<Note>>{};
    final futures = <Future<void>>[];
    for (final s in _sources) {
      futures.add(() async {
        try {
          final endpoints = await ref
              .watch(misskeyEndpointsProvider(s.account).future);
          if (endpoints == null) return;
          final notes = await _fetchOne(endpoints, source: s.source);
          perBucket[s.source.fingerprint] = notes;
        } catch (e, st) {
          _log.warn(
            'initial fetch for ${s.source.fingerprint} failed: $e',
            stack: st,
          );
        }
      }());
    }
    await Future.wait(futures);

    for (final list in perBucket.values) {
      _ingestEmoji(list);
    }
    final merged = _engine.merge(perBucket, now: Clock.system.now());
    return CustomTimelineState.indexed(
      items: merged,
      reachedEndPerSource: {
        for (final s in _sources)
          s.source.fingerprint:
              (perBucket[s.source.fingerprint]?.length ?? 0) < _pageSize,
      },
    );
  }

  void _ingestEmoji(Iterable<Note> notes) {
    for (final n in notes) {
      MisskeyParsers.ingestEmojis(n, _emojiRepo);
    }
  }

  void _attachStreams() {
    final supervisor = ref.read(streamSupervisorProvider);

    void subscribeSource(_ResolvedSource s) {
      final localId =
          'custom:$_timelineId:${s.source.fingerprint.replaceAll(':', '_')}';
      _sourceByLocalId[localId] = s;
      final conn = supervisor.connectionFor(s.account);
      if (conn == null) return;
      final spec = s.source.toStreamSpec();
      conn.subscribe(StreamSubscriptionSpec(
        localId: localId,
        channel: spec.channel,
        params: spec.params,
      ));
    }

    for (final s in _sources) {
      subscribeSource(s);
    }

    // Re-subscribe when a brand-new account's websocket finishes opening.
    final byAccountId = <String, List<_ResolvedSource>>{};
    for (final s in _sources) {
      byAccountId.putIfAbsent(s.account.id, () => []).add(s);
    }
    for (final entry in byAccountId.entries) {
      final account = entry.value.first.account;
      ref.listen<StreamConnection?>(
        streamConnectionProvider(account),
        (prev, next) {
          if (prev == null && next != null) {
            for (final s in entry.value) {
              subscribeSource(s);
            }
          }
        },
      );
    }

    // Unsubscribe on dispose.
    final byLocalIdSnapshot = Map.of(_sourceByLocalId);
    ref.onDispose(() {
      for (final entry in byLocalIdSnapshot.entries) {
        final conn = supervisor.connectionFor(entry.value.account);
        conn?.unsubscribe(entry.key);
      }
    });

    ref.listen<AsyncValue<MisskeyStreamEvent>>(
      mergedStreamEventsProvider,
      (_, next) {
        final event = next.valueOrNull;
        if (event != null) _onEvent(event);
      },
    );
  }

  void _onEvent(MisskeyStreamEvent event) {
    switch (event) {
      case NoteAdded(:final channelId):
        if (!_sourceByLocalId.containsKey(channelId)) return;
        _events.add(event);
      case NoteDeleted():
        _events.add(event);
      case NoteUpdated(:final patch):
        if (patch != null) _events.add(event);
      case ConnectionStateChanged():
      case NotificationReceived():
        break;
    }
  }

  /// See [UnifiedTimelineController._applyBatch]; attribution here goes
  /// through the source that owns the channel the note arrived on.
  void _applyBatch(List<MisskeyStreamEvent> batch) {
    final st = state.valueOrNull;
    if (st == null) return;
    final now = Clock.system.now();

    final fresh = <MergedTimelineItem?>[];
    final freshIndex = <String, int>{};
    final replace = Map<MergedTimelineItem, MergedTimelineItem>.identity();
    final gone = Set<MergedTimelineItem>.identity();
    final pendingDeletes = <(String, String)>[];

    for (final event in batch) {
      switch (event) {
        case NoteAdded(:final channelId, :final note):
          final source = _sourceByLocalId[channelId];
          if (source == null) continue;
          final key = noteKey(note);
          if (freshIndex.containsKey(key)) continue;
          freshIndex[key] = fresh.length;
          fresh.add(MergedTimelineItem(
            accountId: source.account.id,
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
          final origin = st.originByReceiver[key];
          final visible = origin == null ? null : st.byId[origin];
          if (visible != null) {
            gone.add(visible);
            replace.remove(visible);
          }
          if (st.pending.isNotEmpty) pendingDeletes.add((sourceHost, noteId));
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
          final origin = st.originByReceiver[key];
          final original = origin == null ? null : st.byId[origin];
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

    var items = st.items;
    var pending = st.pending;
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
      if (st.holdPending) {
        pending = _capped(_engine.insertMany(pending, freshItems));
      } else {
        items = _capped(_engine.insertMany(items, freshItems));
      }
      dirty = true;
    }

    if (!dirty) return;
    state = AsyncData(st.copyWith(
      items: identical(items, st.items) ? null : items,
      pending: pending,
    ));
  }

  static List<MergedTimelineItem> _capped(List<MergedTimelineItem> list) =>
      list.length > _liveCap ? list.sublist(0, _liveCap) : list;

  void setHoldPending(bool hold) {
    final st = state.valueOrNull;
    if (st == null) return;
    if (st.holdPending == hold) return;
    if (!hold && st.pending.isNotEmpty) {
      releasePending();
      return;
    }
    state = AsyncData(st.copyWith(holdPending: hold));
  }

  void releasePending() {
    final st = state.valueOrNull;
    if (st == null) return;
    if (st.pending.isEmpty) {
      state = AsyncData(st.copyWith(holdPending: false));
      return;
    }
    // Both lists are already sorted and deduped; one merge pass
    // restores global order.
    state = AsyncData(st.copyWith(
      items: _capped(_engine.insertMany(st.items, st.pending)),
      pending: const [],
      holdPending: false,
    ));
  }

  Future<List<Note>> _fetchOne(
    MisskeyEndpoints endpoints, {
    required TimelineSource source,
    String? untilId,
  }) {
    switch (source.kind) {
      case TimelineSourceKind.home:
        return endpoints.homeTimeline(limit: _pageSize, untilId: untilId);
      case TimelineSourceKind.local:
        return endpoints.localTimeline(limit: _pageSize, untilId: untilId);
      case TimelineSourceKind.hybrid:
        return endpoints.hybridTimeline(limit: _pageSize, untilId: untilId);
      case TimelineSourceKind.global:
        return endpoints.globalTimeline(limit: _pageSize, untilId: untilId);
      case TimelineSourceKind.channel:
        final id = source.channelId;
        if (id == null || id.isEmpty) return Future.value(const []);
        return endpoints.channelTimeline(
            channelId: id, limit: _pageSize, untilId: untilId);
      case TimelineSourceKind.antenna:
        final id = source.antennaId;
        if (id == null || id.isEmpty) return Future.value(const []);
        return endpoints.antennasNotes(
            antennaId: id, limit: _pageSize, untilId: untilId);
    }
  }

  Future<void> loadMore() async {
    final st = state.valueOrNull;
    if (st == null || st.isPaginating || st.reachedEnd) return;
    state = AsyncData(st.copyWith(isPaginating: true, clearError: true));

    // Per-source paging: each source contributes its own next page,
    // anchored on the oldest note we've seen FROM THAT SOURCE'S
    // ACCOUNT (closest substitute we have for "from that source"
    // since item-level source-fingerprint is lost in the merge engine).
    final tailByAccount = <String, String>{};
    for (final item in st.items) {
      tailByAccount[item.accountId] = item.note.id;
    }

    final perBucketAdditions = <String, List<Note>>{};
    final reachedEnd = Map<String, bool>.from(st.reachedEndPerSource);
    final futures = <Future<void>>[];
    for (final s in _sources) {
      if (reachedEnd[s.source.fingerprint] == true) continue;
      futures.add(() async {
        try {
          final endpoints = await ref
              .watch(misskeyEndpointsProvider(s.account).future);
          if (endpoints == null) return;
          final older = await _fetchOne(
            endpoints,
            source: s.source,
            untilId: tailByAccount[s.account.id],
          );
          perBucketAdditions[s.source.fingerprint] = older;
          if (older.length < _pageSize) {
            reachedEnd[s.source.fingerprint] = true;
          }
        } catch (e, st) {
          _log.warn(
            'paginate ${s.source.fingerprint} failed: $e',
            stack: st,
          );
        }
      }());
    }
    await Future.wait(futures);

    // Build on the *current* state: streamed notes may have landed
    // while the pages were in flight.
    final cur = state.valueOrNull ?? st;
    if (perBucketAdditions.isEmpty) {
      state = AsyncData(cur.copyWith(
        isPaginating: false,
        reachedEndPerSource: reachedEnd,
      ));
      return;
    }

    for (final list in perBucketAdditions.values) {
      _ingestEmoji(list);
    }

    final reconstructed = <String, List<Note>>{};
    for (final item in cur.items) {
      reconstructed.putIfAbsent(item.accountId, () => []).add(item.note);
    }
    perBucketAdditions.forEach((bucket, notes) {
      // Bucket key is fingerprint, but the merge engine just needs a
      // unique key; using fingerprint avoids collapsing two sources
      // for the same account.
      reconstructed.putIfAbsent(bucket, () => []).addAll(notes);
    });
    final merged = _engine.merge(reconstructed, now: Clock.system.now());

    state = AsyncData(cur.copyWith(
      items: merged,
      isPaginating: false,
      reachedEndPerSource: reachedEnd,
    ));
  }

  Future<void> refresh() async {
    _events.clear();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(_timelineId));
  }
}

/// Internal: a TimelineSource paired with the live Account it
/// references. Cached at build-time so per-source code paths don't
/// have to re-resolve the account on every event.
class _ResolvedSource {
  final Account account;
  final TimelineSource source;
  const _ResolvedSource({required this.account, required this.source});
}

final customTimelineControllerProvider = AsyncNotifierProvider.family<
    CustomTimelineController, CustomTimelineState, String>(
  CustomTimelineController.new,
);
