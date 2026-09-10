// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emoji.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomEmojiImpl _$$CustomEmojiImplFromJson(Map<String, dynamic> json) =>
    _$CustomEmojiImpl(
      host: json['host'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      aliases:
          (json['aliases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      category: json['category'] as String?,
      sensitive: json['sensitive'] as bool? ?? false,
      fetchedAt:
          json['fetchedAt'] == null
              ? null
              : DateTime.parse(json['fetchedAt'] as String),
    );

Map<String, dynamic> _$$CustomEmojiImplToJson(_$CustomEmojiImpl instance) =>
    <String, dynamic>{
      'host': instance.host,
      'name': instance.name,
      'url': instance.url,
      'aliases': instance.aliases,
      'category': instance.category,
      'sensitive': instance.sensitive,
      'fetchedAt': instance.fetchedAt?.toIso8601String(),
    };
