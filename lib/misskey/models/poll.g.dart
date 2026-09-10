// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poll.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PollChoiceImpl _$$PollChoiceImplFromJson(Map<String, dynamic> json) =>
    _$PollChoiceImpl(
      text: json['text'] as String,
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      isVoted: json['isVoted'] as bool? ?? false,
    );

Map<String, dynamic> _$$PollChoiceImplToJson(_$PollChoiceImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'votes': instance.votes,
      'isVoted': instance.isVoted,
    };

_$PollImpl _$$PollImplFromJson(Map<String, dynamic> json) => _$PollImpl(
  expiresAt:
      json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
  multiple: json['multiple'] as bool? ?? false,
  choices:
      (json['choices'] as List<dynamic>?)
          ?.map((e) => PollChoice.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PollChoice>[],
);

Map<String, dynamic> _$$PollImplToJson(_$PollImpl instance) =>
    <String, dynamic>{
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'multiple': instance.multiple,
      'choices': instance.choices,
    };
