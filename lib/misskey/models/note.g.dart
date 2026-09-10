// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NoteImpl _$$NoteImplFromJson(Map<String, dynamic> json) => _$NoteImpl(
  id: json['id'] as String,
  sourceHost: json['sourceHost'] as String,
  user: User.fromJson(json['user'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
  text: json['text'] as String?,
  cw: json['cw'] as String?,
  visibility:
      $enumDecodeNullable(_$NoteVisibilityEnumMap, json['visibility']) ??
      NoteVisibility.public,
  replyId: json['replyId'] as String?,
  renoteId: json['renoteId'] as String?,
  renote:
      json['renote'] == null
          ? null
          : Note.fromJson(json['renote'] as Map<String, dynamic>),
  files:
      (json['files'] as List<dynamic>?)
          ?.map((e) => NoteFile.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <NoteFile>[],
  channel:
      json['channel'] == null
          ? null
          : NoteChannel.fromJson(json['channel'] as Map<String, dynamic>),
  poll:
      json['poll'] == null
          ? null
          : Poll.fromJson(json['poll'] as Map<String, dynamic>),
  localOnly: json['localOnly'] as bool? ?? false,
  myReaction: json['myReaction'] as String?,
  reactions:
      (json['reactions'] as List<dynamic>?)
          ?.map((e) => Reaction.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Reaction>[],
  repliesCount: (json['repliesCount'] as num?)?.toInt() ?? 0,
  renoteCount: (json['renoteCount'] as num?)?.toInt() ?? 0,
  uri: json['uri'] as String?,
  rawExtras: json['rawExtras'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$$NoteImplToJson(_$NoteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sourceHost': instance.sourceHost,
      'user': instance.user,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'text': instance.text,
      'cw': instance.cw,
      'visibility': _$NoteVisibilityEnumMap[instance.visibility]!,
      'replyId': instance.replyId,
      'renoteId': instance.renoteId,
      'renote': instance.renote,
      'files': instance.files,
      'channel': instance.channel,
      'poll': instance.poll,
      'localOnly': instance.localOnly,
      'myReaction': instance.myReaction,
      'reactions': instance.reactions,
      'repliesCount': instance.repliesCount,
      'renoteCount': instance.renoteCount,
      'uri': instance.uri,
      'rawExtras': instance.rawExtras,
    };

const _$NoteVisibilityEnumMap = {
  NoteVisibility.public: 'public',
  NoteVisibility.home: 'home',
  NoteVisibility.followers: 'followers',
  NoteVisibility.specified: 'specified',
};
