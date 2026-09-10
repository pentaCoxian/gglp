// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserImpl _$$UserImplFromJson(Map<String, dynamic> json) => _$UserImpl(
  id: json['id'] as String,
  username: json['username'] as String,
  host: json['host'] as String?,
  name: json['name'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  avatarBlurhash: json['avatarBlurhash'] as String?,
  isBot: json['isBot'] as bool? ?? false,
  isCat: json['isCat'] as bool? ?? false,
);

Map<String, dynamic> _$$UserImplToJson(_$UserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'host': instance.host,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'avatarBlurhash': instance.avatarBlurhash,
      'isBot': instance.isBot,
      'isCat': instance.isCat,
    };
