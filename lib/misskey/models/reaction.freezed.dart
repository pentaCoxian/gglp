// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Reaction _$ReactionFromJson(Map<String, dynamic> json) {
  return _Reaction.fromJson(json);
}

/// @nodoc
mixin _$Reaction {
  /// Raw key from Misskey (e.g. `:smile@.:`, `:custom@remote.example:`,
  /// or a unicode codepoint sequence).
  String get key => throw _privateConstructorUsedError;
  int get count => throw _privateConstructorUsedError;

  /// True when `key` starts and ends with `:` (custom emoji).
  bool get isCustom => throw _privateConstructorUsedError;

  /// For custom emoji, the resolved emoji metadata if known. Null until
  /// the emoji resolver finishes lookup.
  String? get resolvedUrl => throw _privateConstructorUsedError;

  /// Serializes this Reaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReactionCopyWith<Reaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReactionCopyWith<$Res> {
  factory $ReactionCopyWith(Reaction value, $Res Function(Reaction) then) =
      _$ReactionCopyWithImpl<$Res, Reaction>;
  @useResult
  $Res call({String key, int count, bool isCustom, String? resolvedUrl});
}

/// @nodoc
class _$ReactionCopyWithImpl<$Res, $Val extends Reaction>
    implements $ReactionCopyWith<$Res> {
  _$ReactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? count = null,
    Object? isCustom = null,
    Object? resolvedUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            key:
                null == key
                    ? _value.key
                    : key // ignore: cast_nullable_to_non_nullable
                        as String,
            count:
                null == count
                    ? _value.count
                    : count // ignore: cast_nullable_to_non_nullable
                        as int,
            isCustom:
                null == isCustom
                    ? _value.isCustom
                    : isCustom // ignore: cast_nullable_to_non_nullable
                        as bool,
            resolvedUrl:
                freezed == resolvedUrl
                    ? _value.resolvedUrl
                    : resolvedUrl // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReactionImplCopyWith<$Res>
    implements $ReactionCopyWith<$Res> {
  factory _$$ReactionImplCopyWith(
    _$ReactionImpl value,
    $Res Function(_$ReactionImpl) then,
  ) = __$$ReactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String key, int count, bool isCustom, String? resolvedUrl});
}

/// @nodoc
class __$$ReactionImplCopyWithImpl<$Res>
    extends _$ReactionCopyWithImpl<$Res, _$ReactionImpl>
    implements _$$ReactionImplCopyWith<$Res> {
  __$$ReactionImplCopyWithImpl(
    _$ReactionImpl _value,
    $Res Function(_$ReactionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? key = null,
    Object? count = null,
    Object? isCustom = null,
    Object? resolvedUrl = freezed,
  }) {
    return _then(
      _$ReactionImpl(
        key:
            null == key
                ? _value.key
                : key // ignore: cast_nullable_to_non_nullable
                    as String,
        count:
            null == count
                ? _value.count
                : count // ignore: cast_nullable_to_non_nullable
                    as int,
        isCustom:
            null == isCustom
                ? _value.isCustom
                : isCustom // ignore: cast_nullable_to_non_nullable
                    as bool,
        resolvedUrl:
            freezed == resolvedUrl
                ? _value.resolvedUrl
                : resolvedUrl // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReactionImpl implements _Reaction {
  const _$ReactionImpl({
    required this.key,
    required this.count,
    required this.isCustom,
    this.resolvedUrl,
  });

  factory _$ReactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReactionImplFromJson(json);

  /// Raw key from Misskey (e.g. `:smile@.:`, `:custom@remote.example:`,
  /// or a unicode codepoint sequence).
  @override
  final String key;
  @override
  final int count;

  /// True when `key` starts and ends with `:` (custom emoji).
  @override
  final bool isCustom;

  /// For custom emoji, the resolved emoji metadata if known. Null until
  /// the emoji resolver finishes lookup.
  @override
  final String? resolvedUrl;

  @override
  String toString() {
    return 'Reaction(key: $key, count: $count, isCustom: $isCustom, resolvedUrl: $resolvedUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReactionImpl &&
            (identical(other.key, key) || other.key == key) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.isCustom, isCustom) ||
                other.isCustom == isCustom) &&
            (identical(other.resolvedUrl, resolvedUrl) ||
                other.resolvedUrl == resolvedUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, key, count, isCustom, resolvedUrl);

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReactionImplCopyWith<_$ReactionImpl> get copyWith =>
      __$$ReactionImplCopyWithImpl<_$ReactionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReactionImplToJson(this);
  }
}

abstract class _Reaction implements Reaction {
  const factory _Reaction({
    required final String key,
    required final int count,
    required final bool isCustom,
    final String? resolvedUrl,
  }) = _$ReactionImpl;

  factory _Reaction.fromJson(Map<String, dynamic> json) =
      _$ReactionImpl.fromJson;

  /// Raw key from Misskey (e.g. `:smile@.:`, `:custom@remote.example:`,
  /// or a unicode codepoint sequence).
  @override
  String get key;
  @override
  int get count;

  /// True when `key` starts and ends with `:` (custom emoji).
  @override
  bool get isCustom;

  /// For custom emoji, the resolved emoji metadata if known. Null until
  /// the emoji resolver finishes lookup.
  @override
  String? get resolvedUrl;

  /// Create a copy of Reaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReactionImplCopyWith<_$ReactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
