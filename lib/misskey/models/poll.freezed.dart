// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poll.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PollChoice _$PollChoiceFromJson(Map<String, dynamic> json) {
  return _PollChoice.fromJson(json);
}

/// @nodoc
mixin _$PollChoice {
  String get text => throw _privateConstructorUsedError;
  int get votes => throw _privateConstructorUsedError;

  /// True when the viewer has voted for this choice (Misskey ships
  /// `isVoted` per choice for authenticated callers).
  bool get isVoted => throw _privateConstructorUsedError;

  /// Serializes this PollChoice to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PollChoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PollChoiceCopyWith<PollChoice> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PollChoiceCopyWith<$Res> {
  factory $PollChoiceCopyWith(
    PollChoice value,
    $Res Function(PollChoice) then,
  ) = _$PollChoiceCopyWithImpl<$Res, PollChoice>;
  @useResult
  $Res call({String text, int votes, bool isVoted});
}

/// @nodoc
class _$PollChoiceCopyWithImpl<$Res, $Val extends PollChoice>
    implements $PollChoiceCopyWith<$Res> {
  _$PollChoiceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PollChoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? votes = null,
    Object? isVoted = null,
  }) {
    return _then(
      _value.copyWith(
            text:
                null == text
                    ? _value.text
                    : text // ignore: cast_nullable_to_non_nullable
                        as String,
            votes:
                null == votes
                    ? _value.votes
                    : votes // ignore: cast_nullable_to_non_nullable
                        as int,
            isVoted:
                null == isVoted
                    ? _value.isVoted
                    : isVoted // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PollChoiceImplCopyWith<$Res>
    implements $PollChoiceCopyWith<$Res> {
  factory _$$PollChoiceImplCopyWith(
    _$PollChoiceImpl value,
    $Res Function(_$PollChoiceImpl) then,
  ) = __$$PollChoiceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String text, int votes, bool isVoted});
}

/// @nodoc
class __$$PollChoiceImplCopyWithImpl<$Res>
    extends _$PollChoiceCopyWithImpl<$Res, _$PollChoiceImpl>
    implements _$$PollChoiceImplCopyWith<$Res> {
  __$$PollChoiceImplCopyWithImpl(
    _$PollChoiceImpl _value,
    $Res Function(_$PollChoiceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PollChoice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? votes = null,
    Object? isVoted = null,
  }) {
    return _then(
      _$PollChoiceImpl(
        text:
            null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                    as String,
        votes:
            null == votes
                ? _value.votes
                : votes // ignore: cast_nullable_to_non_nullable
                    as int,
        isVoted:
            null == isVoted
                ? _value.isVoted
                : isVoted // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PollChoiceImpl implements _PollChoice {
  const _$PollChoiceImpl({
    required this.text,
    this.votes = 0,
    this.isVoted = false,
  });

  factory _$PollChoiceImpl.fromJson(Map<String, dynamic> json) =>
      _$$PollChoiceImplFromJson(json);

  @override
  final String text;
  @override
  @JsonKey()
  final int votes;

  /// True when the viewer has voted for this choice (Misskey ships
  /// `isVoted` per choice for authenticated callers).
  @override
  @JsonKey()
  final bool isVoted;

  @override
  String toString() {
    return 'PollChoice(text: $text, votes: $votes, isVoted: $isVoted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PollChoiceImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.votes, votes) || other.votes == votes) &&
            (identical(other.isVoted, isVoted) || other.isVoted == isVoted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, text, votes, isVoted);

  /// Create a copy of PollChoice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PollChoiceImplCopyWith<_$PollChoiceImpl> get copyWith =>
      __$$PollChoiceImplCopyWithImpl<_$PollChoiceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PollChoiceImplToJson(this);
  }
}

abstract class _PollChoice implements PollChoice {
  const factory _PollChoice({
    required final String text,
    final int votes,
    final bool isVoted,
  }) = _$PollChoiceImpl;

  factory _PollChoice.fromJson(Map<String, dynamic> json) =
      _$PollChoiceImpl.fromJson;

  @override
  String get text;
  @override
  int get votes;

  /// True when the viewer has voted for this choice (Misskey ships
  /// `isVoted` per choice for authenticated callers).
  @override
  bool get isVoted;

  /// Create a copy of PollChoice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PollChoiceImplCopyWith<_$PollChoiceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Poll _$PollFromJson(Map<String, dynamic> json) {
  return _Poll.fromJson(json);
}

/// @nodoc
mixin _$Poll {
  /// Null = the poll never expires.
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  bool get multiple => throw _privateConstructorUsedError;
  List<PollChoice> get choices => throw _privateConstructorUsedError;

  /// Serializes this Poll to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Poll
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PollCopyWith<Poll> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PollCopyWith<$Res> {
  factory $PollCopyWith(Poll value, $Res Function(Poll) then) =
      _$PollCopyWithImpl<$Res, Poll>;
  @useResult
  $Res call({DateTime? expiresAt, bool multiple, List<PollChoice> choices});
}

/// @nodoc
class _$PollCopyWithImpl<$Res, $Val extends Poll>
    implements $PollCopyWith<$Res> {
  _$PollCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Poll
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? expiresAt = freezed,
    Object? multiple = null,
    Object? choices = null,
  }) {
    return _then(
      _value.copyWith(
            expiresAt:
                freezed == expiresAt
                    ? _value.expiresAt
                    : expiresAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            multiple:
                null == multiple
                    ? _value.multiple
                    : multiple // ignore: cast_nullable_to_non_nullable
                        as bool,
            choices:
                null == choices
                    ? _value.choices
                    : choices // ignore: cast_nullable_to_non_nullable
                        as List<PollChoice>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PollImplCopyWith<$Res> implements $PollCopyWith<$Res> {
  factory _$$PollImplCopyWith(
    _$PollImpl value,
    $Res Function(_$PollImpl) then,
  ) = __$$PollImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime? expiresAt, bool multiple, List<PollChoice> choices});
}

/// @nodoc
class __$$PollImplCopyWithImpl<$Res>
    extends _$PollCopyWithImpl<$Res, _$PollImpl>
    implements _$$PollImplCopyWith<$Res> {
  __$$PollImplCopyWithImpl(_$PollImpl _value, $Res Function(_$PollImpl) _then)
    : super(_value, _then);

  /// Create a copy of Poll
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? expiresAt = freezed,
    Object? multiple = null,
    Object? choices = null,
  }) {
    return _then(
      _$PollImpl(
        expiresAt:
            freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        multiple:
            null == multiple
                ? _value.multiple
                : multiple // ignore: cast_nullable_to_non_nullable
                    as bool,
        choices:
            null == choices
                ? _value._choices
                : choices // ignore: cast_nullable_to_non_nullable
                    as List<PollChoice>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PollImpl extends _Poll {
  const _$PollImpl({
    this.expiresAt,
    this.multiple = false,
    final List<PollChoice> choices = const <PollChoice>[],
  }) : _choices = choices,
       super._();

  factory _$PollImpl.fromJson(Map<String, dynamic> json) =>
      _$$PollImplFromJson(json);

  /// Null = the poll never expires.
  @override
  final DateTime? expiresAt;
  @override
  @JsonKey()
  final bool multiple;
  final List<PollChoice> _choices;
  @override
  @JsonKey()
  List<PollChoice> get choices {
    if (_choices is EqualUnmodifiableListView) return _choices;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_choices);
  }

  @override
  String toString() {
    return 'Poll(expiresAt: $expiresAt, multiple: $multiple, choices: $choices)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PollImpl &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.multiple, multiple) ||
                other.multiple == multiple) &&
            const DeepCollectionEquality().equals(other._choices, _choices));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    expiresAt,
    multiple,
    const DeepCollectionEquality().hash(_choices),
  );

  /// Create a copy of Poll
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PollImplCopyWith<_$PollImpl> get copyWith =>
      __$$PollImplCopyWithImpl<_$PollImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PollImplToJson(this);
  }
}

abstract class _Poll extends Poll {
  const factory _Poll({
    final DateTime? expiresAt,
    final bool multiple,
    final List<PollChoice> choices,
  }) = _$PollImpl;
  const _Poll._() : super._();

  factory _Poll.fromJson(Map<String, dynamic> json) = _$PollImpl.fromJson;

  /// Null = the poll never expires.
  @override
  DateTime? get expiresAt;
  @override
  bool get multiple;
  @override
  List<PollChoice> get choices;

  /// Create a copy of Poll
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PollImplCopyWith<_$PollImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
