// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NoteFileImpl _$$NoteFileImplFromJson(Map<String, dynamic> json) =>
    _$NoteFileImpl(
      id: json['id'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      name: json['name'] as String?,
      comment: json['comment'] as String?,
      blurhash: json['blurhash'] as String?,
      isSensitive: json['isSensitive'] as bool? ?? false,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$NoteFileImplToJson(_$NoteFileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'url': instance.url,
      'thumbnailUrl': instance.thumbnailUrl,
      'name': instance.name,
      'comment': instance.comment,
      'blurhash': instance.blurhash,
      'isSensitive': instance.isSensitive,
      'width': instance.width,
      'height': instance.height,
    };
