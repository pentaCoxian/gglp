// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_channel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

NoteChannel _$NoteChannelFromJson(Map<String, dynamic> json) {
  return _NoteChannel.fromJson(json);
}

/// @nodoc
mixin _$NoteChannel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  /// Hex `#rrggbb` colour the channel publishes for itself; null when
  /// the server didn't pick one. We treat null as "use the default
  /// theme accent" at render time.
  String? get color => throw _privateConstructorUsedError;
  bool get isSensitive => throw _privateConstructorUsedError;

  /// Serializes this NoteChannel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NoteChannel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NoteChannelCopyWith<NoteChannel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteChannelCopyWith<$Res> {
  factory $NoteChannelCopyWith(
    NoteChannel value,
    $Res Function(NoteChannel) then,
  ) = _$NoteChannelCopyWithImpl<$Res, NoteChannel>;
  @useResult
  $Res call({String id, String name, String? color, bool isSensitive});
}

/// @nodoc
class _$NoteChannelCopyWithImpl<$Res, $Val extends NoteChannel>
    implements $NoteChannelCopyWith<$Res> {
  _$NoteChannelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NoteChannel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? color = freezed,
    Object? isSensitive = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            color:
                freezed == color
                    ? _value.color
                    : color // ignore: cast_nullable_to_non_nullable
                        as String?,
            isSensitive:
                null == isSensitive
                    ? _value.isSensitive
                    : isSensitive // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$NoteChannelImplCopyWith<$Res>
    implements $NoteChannelCopyWith<$Res> {
  factory _$$NoteChannelImplCopyWith(
    _$NoteChannelImpl value,
    $Res Function(_$NoteChannelImpl) then,
  ) = __$$NoteChannelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? color, bool isSensitive});
}

/// @nodoc
class __$$NoteChannelImplCopyWithImpl<$Res>
    extends _$NoteChannelCopyWithImpl<$Res, _$NoteChannelImpl>
    implements _$$NoteChannelImplCopyWith<$Res> {
  __$$NoteChannelImplCopyWithImpl(
    _$NoteChannelImpl _value,
    $Res Function(_$NoteChannelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteChannel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? color = freezed,
    Object? isSensitive = null,
  }) {
    return _then(
      _$NoteChannelImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        color:
            freezed == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                    as String?,
        isSensitive:
            null == isSensitive
                ? _value.isSensitive
                : isSensitive // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NoteChannelImpl implements _NoteChannel {
  const _$NoteChannelImpl({
    required this.id,
    required this.name,
    this.color,
    this.isSensitive = false,
  });

  factory _$NoteChannelImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoteChannelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;

  /// Hex `#rrggbb` colour the channel publishes for itself; null when
  /// the server didn't pick one. We treat null as "use the default
  /// theme accent" at render time.
  @override
  final String? color;
  @override
  @JsonKey()
  final bool isSensitive;

  @override
  String toString() {
    return 'NoteChannel(id: $id, name: $name, color: $color, isSensitive: $isSensitive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteChannelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.isSensitive, isSensitive) ||
                other.isSensitive == isSensitive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, color, isSensitive);

  /// Create a copy of NoteChannel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteChannelImplCopyWith<_$NoteChannelImpl> get copyWith =>
      __$$NoteChannelImplCopyWithImpl<_$NoteChannelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NoteChannelImplToJson(this);
  }
}

abstract class _NoteChannel implements NoteChannel {
  const factory _NoteChannel({
    required final String id,
    required final String name,
    final String? color,
    final bool isSensitive,
  }) = _$NoteChannelImpl;

  factory _NoteChannel.fromJson(Map<String, dynamic> json) =
      _$NoteChannelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;

  /// Hex `#rrggbb` colour the channel publishes for itself; null when
  /// the server didn't pick one. We treat null as "use the default
  /// theme accent" at render time.
  @override
  String? get color;
  @override
  bool get isSensitive;

  /// Create a copy of NoteChannel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoteChannelImplCopyWith<_$NoteChannelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
