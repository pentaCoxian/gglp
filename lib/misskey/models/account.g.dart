// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AccountImpl _$$AccountImplFromJson(Map<String, dynamic> json) =>
    _$AccountImpl(
      id: json['id'] as String,
      host: json['host'] as String,
      userId: json['userId'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isCat: json['isCat'] as bool? ?? false,
      isAdmin: json['isAdmin'] as bool? ?? false,
      addedAt:
          json['addedAt'] == null
              ? null
              : DateTime.parse(json['addedAt'] as String),
      lastUsedAt:
          json['lastUsedAt'] == null
              ? null
              : DateTime.parse(json['lastUsedAt'] as String),
    );

Map<String, dynamic> _$$AccountImplToJson(_$AccountImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'host': instance.host,
      'userId': instance.userId,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarUrl': instance.avatarUrl,
      'isCat': instance.isCat,
      'isAdmin': instance.isAdmin,
      'addedAt': instance.addedAt?.toIso8601String(),
      'lastUsedAt': instance.lastUsedAt?.toIso8601String(),
    };
