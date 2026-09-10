import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../core/logger.dart';
import '../misskey/emoji/emoji_providers.dart';
import '../misskey/emoji/emoji_repository.dart';
import '../misskey/http/endpoint_registry.dart';
import '../misskey/models/account.dart';
import '../misskey/models/note.dart';
import '../misskey/models/notification.dart';
import '../misskey/models/parsers.dart';
import '../misskey/streaming/stream_messages.dart';
import '../misskey/streaming/stream_providers.dart';

/// Snapshot of the notifications inbox for one account.
class NotificationsState {
  final List<MisskeyNotification> items;
  final bool isPaginating;
  final bool reachedEnd;
  final Object? error;

  const NotificationsState({
    this.items = const [],
    this.isPaginating = false,
    this.reachedEnd = false,
    this.error,
  });

  NotificationsState copyWith({
    List<MisskeyNotification>? items,
    bool? isPaginating,
    bool? reachedEnd,
    Object? error,
    bool clearError = false,
  }) =>
      NotificationsState(
        items: items ?? this.items,
        isPaginating: isPaginating ?? this.isPaginating,
        reachedEnd: reachedEnd ?? this.reachedEnd,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Per-account notifications controller.
///
/// Hits `i/notifications` for the initial page + paging, and listens
/// to the live `main` channel's `notification` events (already routed
/// through the stream layer as `NotificationReceived`) for new arrivals.
class NotificationsController
    extends FamilyAsyncNotifier<NotificationsState, Account> {
  static const _pageSize = 30;
  static const _liveCap = 200;

  final _log = const Log('Notifications');

  late MisskeyEndpoints _endpoints;
  late EmojiRepository _emojiRepo;
  late Account _account;

  @override
  Future<NotificationsState> build(Account account) async {
    _account = account;
    final endpoints =
        await ref.watch(misskeyEndpointsProvider(account).future);
    if (endpoints == null) {
      throw StateError('No HTTP client for ${account.id}');
    }
    _endpoints = endpoints;
    _emojiRepo = ref.watch(emojiRepositoryProvider);

    // Subscribe to the supervisor's merged event stream and filter for
    // notifications attributable to this account. The underlying
    // `main` channel subscribe is owned by the supervisor's per-account
    // connection (notifications come over the always-on `main`
    // channel rather than a per-screen subscription), so we don't need
    // to register one ourselves.
    ref.listen<AsyncValue<MisskeyStreamEvent>>(
      streamEventsProvider(account),
      (_, next) {
        final ev = next.valueOrNull;
        if (ev is NotificationReceived) {
          _onLiveNotification(ev);
        }
      },
    );

    final initial = await _endpoints.notificationsParsed(limit: _pageSize);
    _ingestEmoji(initial);
    return NotificationsState(
      items: initial,
      reachedEnd: initial.length < _pageSize,
    );
  }

  void _onLiveNotification(NotificationReceived event) {
    // The stream layer doesn't pre-parse notifications (we kept that
    // surface narrow because the screen is the only consumer); parse
    // here using the same code path as the HTTP page.
    if (event.type != 'notification') {
      // `mention` / `reply` / `renote` etc. arrive via the same channel
      // when the user has opted in. We only render them inside the
      // notifications screen if they match our known kinds.
      return;
    }
    try {
      final parsed = MisskeyParsers.notificationFromJson(
        event.body,
        viewerHost: _account.host,
      );
      _ingestEmoji([parsed]);
      final s = state.valueOrNull;
      if (s == null) return;
      if (s.items.any((n) => n.id == parsed.id)) return;
      final combined = [parsed, ...s.items];
      final trimmed = combined.length > _liveCap
          ? combined.sublist(0, _liveCap)
          : combined;
      state = AsyncData(s.copyWith(items: trimmed));
    } catch (e, st) {
      _log.warn('failed to parse live notification: $e', stack: st);
    }
  }

  void _ingestEmoji(Iterable<MisskeyNotification> items) {
    for (final n in items) {
      final note = n.note;
      if (note != null) {
        MisskeyParsers.ingestEmojis(note, _emojiRepo);
      }
    }
  }

  Future<void> loadMore() async {
    final s = state.valueOrNull;
    if (s == null || s.isPaginating || s.reachedEnd || s.items.isEmpty) {
      return;
    }
    state = AsyncData(s.copyWith(isPaginating: true, clearError: true));
    try {
      final older = await _endpoints.notificationsParsed(
        untilId: s.items.last.id,
        limit: _pageSize,
      );
      _ingestEmoji(older);
      state = AsyncData(s.copyWith(
        items: [...s.items, ...older],
        isPaginating: false,
        reachedEnd: older.length < _pageSize,
      ));
    } catch (e, st) {
      _log.warn('paginate notifications failed: $e', stack: st);
      state = AsyncData(s.copyWith(isPaginating: false, error: e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(_account));
  }

  Future<void> markAllRead() async {
    try {
      await _endpoints.notificationsMarkAllAsRead();
    } catch (e, st) {
      _log.warn('markAllAsRead failed: $e', stack: st);
    }
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(
      items: s.items
          .map((n) => n.isRead ? n : n.copyWith(isRead: true))
          .toList(growable: false),
    ));
  }
}

final notificationsControllerProvider = AsyncNotifierProvider.family<
    NotificationsController,
    NotificationsState,
    Account>(NotificationsController.new);

/// Helper: pulls the most recent note out of a notification, used by
/// the screen rows when they need to render the originating note
/// inline (replies, mentions, quotes).
Note? notificationNote(MisskeyNotification n) => n.note;
