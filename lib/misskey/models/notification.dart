import 'package:freezed_annotation/freezed_annotation.dart';

import 'note.dart';
import 'user.dart';

part 'notification.freezed.dart';
part 'notification.g.dart';

/// Misskey notification kinds we render. The on-the-wire `type` may
/// also be `pollEnded`, `groupInvited`, etc.; we map those to
/// [NotificationKind.other] and let the UI fall back to a generic row.
enum NotificationKind {
  follow,
  unfollow,
  followRequest,
  followRequestAccepted,
  mention,
  reply,
  renote,
  quote,
  reaction,
  reactionGrouped,
  renoteGrouped,
  achievementEarned,
  pollEnded,
  other,
}

@freezed
class MisskeyNotification with _$MisskeyNotification {
  const factory MisskeyNotification({
    required String id,
    required NotificationKind kind,
    required DateTime createdAt,

    /// `type` exactly as it came over the wire — useful when [kind]
    /// is [NotificationKind.other] and the UI wants to surface
    /// something less generic than "notification".
    required String rawType,

    User? user,

    /// The note the notification refers to (e.g. the note that was
    /// reacted to, replied to, mentioned in). Null for `follow` etc.
    Note? note,

    /// Reaction key for `reaction`-type notifications (`:wave_anim@.:`
    /// or a unicode codepoint).
    String? reaction,

    /// Unread state on the server. We don't drive UI off this yet
    /// (read-marker requires `notifications/markAllAsRead`); kept so
    /// the next iteration can use it.
    @Default(false) bool isRead,
  }) = _MisskeyNotification;

  factory MisskeyNotification.fromJson(Map<String, dynamic> json) =>
      _$MisskeyNotificationFromJson(json);
}
