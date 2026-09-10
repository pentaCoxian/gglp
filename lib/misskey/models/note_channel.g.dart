// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NoteChannelImpl _$$NoteChannelImplFromJson(Map<String, dynamic> json) =>
    _$NoteChannelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
      isSensitive: json['isSensitive'] as bool? ?? false,
    );

Map<String, dynamic> _$$NoteChannelImplToJson(_$NoteChannelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
      'isSensitive': instance.isSensitive,
    };
