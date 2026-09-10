// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MisskeyNotificationImpl _$$MisskeyNotificationImplFromJson(
  Map<String, dynamic> json,
) => _$MisskeyNotificationImpl(
  id: json['id'] as String,
  kind: $enumDecode(_$NotificationKindEnumMap, json['kind']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  rawType: json['rawType'] as String,
  user:
      json['user'] == null
          ? null
          : User.fromJson(json['user'] as Map<String, dynamic>),
  note:
      json['note'] == null
          ? null
          : Note.fromJson(json['note'] as Map<String, dynamic>),
  reaction: json['reaction'] as String?,
  isRead: json['isRead'] as bool? ?? false,
);

Map<String, dynamic> _$$MisskeyNotificationImplToJson(
  _$MisskeyNotificationImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'kind': _$NotificationKindEnumMap[instance.kind]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'rawType': instance.rawType,
  'user': instance.user,
  'note': instance.note,
  'reaction': instance.reaction,
  'isRead': instance.isRead,
};

const _$NotificationKindEnumMap = {
  NotificationKind.follow: 'follow',
  NotificationKind.unfollow: 'unfollow',
  NotificationKind.followRequest: 'followRequest',
  NotificationKind.followRequestAccepted: 'followRequestAccepted',
  NotificationKind.mention: 'mention',
  NotificationKind.reply: 'reply',
  NotificationKind.renote: 'renote',
  NotificationKind.quote: 'quote',
  NotificationKind.reaction: 'reaction',
  NotificationKind.reactionGrouped: 'reactionGrouped',
  NotificationKind.renoteGrouped: 'renoteGrouped',
  NotificationKind.achievementEarned: 'achievementEarned',
  NotificationKind.pollEnded: 'pollEnded',
  NotificationKind.other: 'other',
};
