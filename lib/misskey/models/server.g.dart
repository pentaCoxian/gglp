// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ServerImpl _$$ServerImplFromJson(Map<String, dynamic> json) => _$ServerImpl(
  host: json['host'] as String,
  name: json['name'] as String?,
  description: json['description'] as String?,
  softwareName: json['softwareName'] as String?,
  softwareVersion: json['softwareVersion'] as String?,
  iconUrl: json['iconUrl'] as String?,
  bannerUrl: json['bannerUrl'] as String?,
  metaFetchedAt:
      json['metaFetchedAt'] == null
          ? null
          : DateTime.parse(json['metaFetchedAt'] as String),
);

Map<String, dynamic> _$$ServerImplToJson(_$ServerImpl instance) =>
    <String, dynamic>{
      'host': instance.host,
      'name': instance.name,
      'description': instance.description,
      'softwareName': instance.softwareName,
      'softwareVersion': instance.softwareVersion,
      'iconUrl': instance.iconUrl,
      'bannerUrl': instance.bannerUrl,
      'metaFetchedAt': instance.metaFetchedAt?.toIso8601String(),
    };
