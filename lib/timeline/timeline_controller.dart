import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/logger.dart';
import '../misskey/emoji/emoji_providers.dart';
import '../misskey/emoji/emoji_repository.dart';
import '../misskey/http/endpoint_registry.dart';
import '../misskey/models/account.dart';
import '../misskey/models/note.dart';
import '../misskey/models/parsers.dart';
import '../misskey/streaming/stream_connection.dart';
import '../misskey/streaming/stream_messages.dart';
import '../misskey/streaming/stream_providers.dart';
import '../misskey/streaming/stream_subscription_spec.dart';
import 'note_keys.dart';
import 'note_list_ops.dart';
import 'stream_event_batcher.dart';
import 'timeline_kind.dart';

/// Per-account, per-kind timeline state.
///
/// introduced HTTP-only loading; adds the live websocket stream:
///   - the websocket is opened lazily when the first listener appears
///   - new notes are prepended to [notes]
///   - on reconnect, a gap-fill HTTP page is fetched using `sinceId` of
///     the head note so we don't lose anything that arrived offline
///   - [connectionPhase] is exposed so the UI can show a banner when
///     the socket is reconnecting/failed.
class TimelineState {
  final List<Note> notes;

  /// `globalId -> Note` index over [notes]. Rows watch
  /// `byId[key]` through a Riverpod `select` — an O(1) lookup with no
  /// allocation — instead of scanning [notes] on every emission. Always
  /// kept in lockstep with [notes]; [copyWith] re-indexes automatically
  /// when [notes] is replaced without an explicit index.
  final Map<String, Note> byId;

  /// Streamed notes held back because the viewport isn't anchored at
  /// the top — surfacing them as a "X new notes" banner instead of a
  /// scroll jump. Released into [notes] on banner tap or scroll-to-top.
  final List<Note> pending;

  /// When true, freshly-streamed notes are diverted to [pending] instead
  /// of [notes]. The UI flips this based on scroll position.
  final bool holdPending;

  final bool isInitialLoading;
  final bool isPaginating;
  final bool reachedEnd;
  final ConnectionPhase connectionPhase;
  final Object? error;

  const TimelineState({
    this.notes = const [],
    this.byId = const {},
    this.pending = const [],
    this.holdPending = false,
    this.isInitialLoading = false,
    this.isPaginating = false,
    this.reachedEnd = false,
    this.connectionPhase = ConnectionPhase.disconnected,
    this.error,
  });

  TimelineState copyWith({
    List<Note>? notes,
    Map<String, Note>? byId,
    List<Note>? pending,
    bool? holdPending,
    bool? isInitialLoading,
    bool? isPaginating,
    bool? reachedEnd,
    ConnectionPhase? connectionPhase,
    Object? error,
    bool clearError = false,
  }) =>
      TimelineState(
        notes: notes ?? this.notes,
        byId: byId ?? (notes == null ? this.byId : indexNotes(notes)),
        pending: pending ?? this.pending,
        holdPending: holdPending ?? this.holdPending,
        isInitialLoading: isInitialLoading ?? this.isInitialLoading,
        isPaginating: isPaginating ?? this.isPaginating,
        reachedEnd: reachedEnd ?? this.reachedEnd,
        connectionPhase: connectionPhase ?? this.connectionPhase,
        error: clearError ? null : (error ?? this.error),
      );
}

class TimelineController
    extends FamilyAsyncNotifier<TimelineState, TimelineArgs> {
  static const _pageSize = 30;
  /// Hard cap on the in-memory timeline. Streaming bursts trim from the
  /// tail; old notes can be re-fetched via pagination.
  static const _liveCap = 500;

  final _log = const Log('Timeline');
  static const _ops = NoteListOps(cap: _liveCap);

  late MisskeyEndpoints _endpoints;
  late EmojiRepository _emojiRepo;
  late TimelineKind _kind;
  late TimelineArgs _args;
  late String _channelLocalId;
  ConnectionPhase _previousPhase = ConnectionPhase.disconnected;

  /// Note-level stream events (add / patch / delete) are buffered here
  /// and applied in one pass per window so a busy timeline costs one
  /// list copy and one emission per ~250ms instead of per note.
  late final _events =
      StreamEventBatcher<MisskeyStreamEvent>(onFlush: _applyBatch);

  /// Re-entrancy guard: a flapping socket can emit several `connected`
  /// transitions before the first gap-fill page returns.
  bool _gapFilling = false;

  @override
  Future<TimelineState> build(TimelineArgs args) async {
    _args = args;
    _kind = args.kind;
    // Riverpod runs onDispose before every rebuild as well as on final
    // teardown; clearing (not disposing) keeps the batcher reusable by
    // this same notifier instance while guaranteeing no timer fires
    // into a torn-down provider.
    _events.clear();
    ref.onDispose(_events.clear);
    final endpoints =
        await ref.watch(misskeyEndpointsProvider(args.account).future);
    if (endpoints == null) {
      throw StateError('No HTTP client for ${args.account.id}');
    }
    _endpoints = endpoints;
    _emojiRepo = ref.watch(emojiRepositoryProvider);

    // Subscribe to the live stream for this account. The connection
    // is shared across all timelines for the account; we identify our
    // channel by a per-(account,kind) localId.
    _channelLocalId = 'tl:${args.account.id}:${args.kind.key}';
    _attachStream();

    final initial = await _fetch();
    _ingestEmoji(initial);
    return TimelineState(
      notes: initial,
      byId: indexNotes(initial),
      isInitialLoading: false,
      connectionPhase: _previousPhase,
    );
  }

  /// Ingest embedded emoji blocks from each note into the per-host
  /// catalog (free, no fetch). Then for any *new* host that we haven't
  /// fetched a catalog for in this session, kick off a token-less
  /// `/api/emojis` fetch in the background — that gives the reaction
  /// picker browseable access to the remote host's full catalog,
  /// which the inline ingest alone can't provide. The repository
  /// rate-limits and dedupes those fetches app-wide; the local set
  /// just avoids re-asking for the same host on every batch.
  void _ingestEmoji(Iterable<Note> notes) {
    for (final n in notes) {
      MisskeyParsers.ingestEmojis(n, _emojiRepo);
    }
  }

  void _attachStream() {
    // Initial connection check — may be null right after add-account
    // because the supervisor's reconcile() is async. We bind subscribe
    // immediately if we have one, and *also* listen to future changes
    // so when the supervisor finishes opening the websocket, we go
    // back and subscribe our per-kind channel. Without that listen,
    // a brand-new account would never see streamed notes.
    void bind(StreamConnection? conn) {
      if (conn == null) return;
      conn.subscribe(StreamSubscriptionSpec(
        localId: _channelLocalId,
        channel: _channelToMisskey(_kind),
      ));
      _previousPhase = conn.phase;
      // Mirror the live phase into TimelineState so the connection
      // banner clears the moment we're connected (without waiting for
      // the next ConnectionStateChanged broadcast).
      final s = state.valueOrNull;
      if (s != null && s.connectionPhase != conn.phase) {
        state = AsyncData(s.copyWith(connectionPhase: conn.phase));
      }
    }

    // Use ref.read for the snapshot — ref.watch here would cause
    // build() to re-run on every supervisor mutation, including
    // unrelated accounts.
    final initial = ref.read(streamConnectionProvider(_args.account));
    bind(initial);
    if (initial != null) {
      // Capture once; onDispose can't ref.read while disposing.
      ref.onDispose(() => initial.unsubscribe(_channelLocalId));
    }

    // Listen for the connection appearing later (the add-account
    // reconcile lands asynchronously). On transition null -> non-null
    // we subscribe + register the unsub-on-dispose.
    ref.listen<StreamConnection?>(
      streamConnectionProvider(_args.account),
      (prev, next) {
        if (prev == null && next != null) {
          bind(next);
          ref.onDispose(() => next.unsubscribe(_channelLocalId));
        }
      },
    );

    // Subscribe to events with ref.listen ONLY. ref.watch here would
    // cause build() to re-run on every emitted event — re-firing the
    // initial HTTP page and putting the timeline into AsyncLoading on
    // every new streamed note.
    ref.listen<AsyncValue<MisskeyStreamEvent>>(
      streamEventsProvider(_args.account),
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
        if (channelId != _channelLocalId) return;
        _events.add(event);
      case NoteDeleted():
        _events.add(event);
      case NoteUpdated(:final patch):
        if (patch != null) _events.add(event);
      case ConnectionStateChanged(:final phase):
        // Not buffered: the phase drives the banner and the gap-fill,
        // both of which should react promptly.
        _onConnectionPhase(phase);
      case NotificationReceived():
        // Routed to the in-app notifications surface in .
        break;
    }
  }

  /// Apply one buffered window of stream events with a single state
  /// emission. See [NoteListOps.applyEvents] for the replay semantics.
  void _applyBatch(List<MisskeyStreamEvent> batch) {
    final s = state.valueOrNull;
    if (s == null) return;
    final r = _ops.applyEvents(
      notes: s.notes,
      byId: s.byId,
      pending: s.pending,
      holdPending: s.holdPending,
      viewerUserId: _args.account.userId,
      batch: batch,
      accepts: (e) => e.channelId == _channelLocalId,
    );
    if (r == null) return;
    _ingestEmoji(r.added);
    state = AsyncData(s.copyWith(
      notes: r.notes,
      byId: r.byId,
      pending: r.pending,
    ));
  }

  /// Toggle the pending-hold mode. The timeline UI calls this with
  /// `true` whenever the user has scrolled away from the head, and
  /// `false` when they return — flipping `false` automatically drains
  /// any buffered notes via [releasePending].
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

  /// Move pending notes into the visible list. Called when the user
  /// taps the "X new notes" banner.
  void releasePending() {
    final s = state.valueOrNull;
    if (s == null) return;
    if (s.pending.isEmpty) {
      state = AsyncData(s.copyWith(holdPending: false));
      return;
    }
    final result = _ops.prependVisible(s.pending, s.notes, s.byId);
    state = AsyncData(s.copyWith(
      notes: result.notes,
      byId: result.byId,
      pending: const [],
      holdPending: false,
    ));
  }

  Future<void> _onConnectionPhase(ConnectionPhase phase) async {
    final s = state.valueOrNull;
    if (s == null) {
      _previousPhase = phase;
      return;
    }
    state = AsyncData(s.copyWith(connectionPhase: phase));

    // On a fresh re-connect, gap-fill anything that arrived while the
    // socket was down. Skip if we don't yet have a head note to anchor.
    final wasDown = _previousPhase != ConnectionPhase.connected;
    _previousPhase = phase;
    if (phase == ConnectionPhase.connected && wasDown && s.notes.isNotEmpty) {
      await _gapFill(sinceId: s.notes.first.id);
    }
  }

  Future<void> _gapFill({required String sinceId}) async {
    if (_gapFilling) return;
    _gapFilling = true;
    try {
      final fresh = await _fetch(sinceId: sinceId, limit: _pageSize);
      if (fresh.isEmpty) return;
      // Re-read: streamed notes may have landed while the page was in
      // flight, and the index is what we dedupe against.
      final s = state.valueOrNull;
      if (s == null) return;
      final dedup =
          fresh.where((n) => !s.byId.containsKey(noteKey(n))).toList();
      if (dedup.isEmpty) return;
      _ingestEmoji(dedup);
      final result = _ops.prependVisible(dedup, s.notes, s.byId);
      state = AsyncData(s.copyWith(notes: result.notes, byId: result.byId));
      _log.info('gap-fill prepended ${dedup.length} notes');
    } catch (e, st) {
      _log.warn('gap-fill failed: $e', stack: st);
    } finally {
      _gapFilling = false;
    }
  }

  Future<List<Note>> _fetch({
    String? untilId,
    String? sinceId,
    int limit = _pageSize,
  }) {
    switch (_kind) {
      case TimelineKind.home:
        return _endpoints.homeTimeline(
            limit: limit, untilId: untilId, sinceId: sinceId);
      case TimelineKind.local:
        return _endpoints.localTimeline(
            limit: limit, untilId: untilId, sinceId: sinceId);
      case TimelineKind.hybrid:
        return _endpoints.hybridTimeline(
            limit: limit, untilId: untilId, sinceId: sinceId);
      case TimelineKind.global:
        return _endpoints.globalTimeline(
            limit: limit, untilId: untilId, sinceId: sinceId);
    }
  }

  /// Fetch older notes. No-op when already paginating or end reached.
  Future<void> loadMore() async {
    final s = state.valueOrNull;
    if (s == null || s.isPaginating || s.reachedEnd || s.notes.isEmpty) return;
    state = AsyncData(s.copyWith(isPaginating: true, clearError: true));
    try {
      final older = await _fetch(untilId: s.notes.last.id);
      _ingestEmoji(older);
      // Append to the *current* list — streamed notes may have been
      // prepended while the page was in flight, and building on the
      // pre-await snapshot would silently drop them.
      final cur = state.valueOrNull ?? s;
      final additions =
          older.where((n) => !cur.byId.containsKey(noteKey(n))).toList();
      state = AsyncData(cur.copyWith(
        notes: [...cur.notes, ...additions],
        byId: Map.of(cur.byId)..addAll(indexNotes(additions)),
        isPaginating: false,
        reachedEnd: older.length < _pageSize,
      ));
    } catch (e, st) {
      _log.warn('loadMore failed: $e', stack: st);
      final cur = state.valueOrNull ?? s;
      state = AsyncData(cur.copyWith(isPaginating: false, error: e));
    }
  }

  /// Pull-to-refresh. Drops the in-memory list and re-fetches from the
  /// top. Streaming continues feeding new notes from there.
  Future<void> refresh() async {
    // Anything buffered belongs to the list we're about to discard.
    _events.clear();
    state = const AsyncLoading();
    try {
      final fresh = await _fetch();
      _ingestEmoji(fresh);
      state = AsyncData(TimelineState(
        notes: fresh,
        byId: indexNotes(fresh),
        connectionPhase: _previousPhase,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

class TimelineArgs {
  final Account account;
  final TimelineKind kind;
  const TimelineArgs(this.account, this.kind);

  @override
  bool operator ==(Object other) =>
      other is TimelineArgs &&
      other.account.id == account.id &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(account.id, kind);
}

final timelineControllerProvider = AsyncNotifierProvider.family<
    TimelineController, TimelineState, TimelineArgs>(TimelineController.new);
