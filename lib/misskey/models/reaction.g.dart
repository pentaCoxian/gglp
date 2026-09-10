// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReactionImpl _$$ReactionImplFromJson(Map<String, dynamic> json) =>
    _$ReactionImpl(
      key: json['key'] as String,
      count: (json['count'] as num).toInt(),
      isCustom: json['isCustom'] as bool,
      resolvedUrl: json['resolvedUrl'] as String?,
    );

Map<String, dynamic> _$$ReactionImplToJson(_$ReactionImpl instance) =>
    <String, dynamic>{
      'key': instance.key,
      'count': instance.count,
      'isCustom': instance.isCustom,
      'resolvedUrl': instance.resolvedUrl,
    };
