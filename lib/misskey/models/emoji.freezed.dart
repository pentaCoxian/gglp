// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'emoji.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CustomEmoji _$CustomEmojiFromJson(Map<String, dynamic> json) {
  return _CustomEmoji.fromJson(json);
}

/// @nodoc
mixin _$CustomEmoji {
  String get host => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  List<String> get aliases => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  bool get sensitive => throw _privateConstructorUsedError;
  DateTime? get fetchedAt => throw _privateConstructorUsedError;

  /// Serializes this CustomEmoji to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CustomEmoji
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CustomEmojiCopyWith<CustomEmoji> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomEmojiCopyWith<$Res> {
  factory $CustomEmojiCopyWith(
    CustomEmoji value,
    $Res Function(CustomEmoji) then,
  ) = _$CustomEmojiCopyWithImpl<$Res, CustomEmoji>;
  @useResult
  $Res call({
    String host,
    String name,
    String url,
    List<String> aliases,
    String? category,
    bool sensitive,
    DateTime? fetchedAt,
  });
}

/// @nodoc
class _$CustomEmojiCopyWithImpl<$Res, $Val extends CustomEmoji>
    implements $CustomEmojiCopyWith<$Res> {
  _$CustomEmojiCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CustomEmoji
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? host = null,
    Object? name = null,
    Object? url = null,
    Object? aliases = null,
    Object? category = freezed,
    Object? sensitive = null,
    Object? fetchedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            host:
                null == host
                    ? _value.host
                    : host // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            url:
                null == url
                    ? _value.url
                    : url // ignore: cast_nullable_to_non_nullable
                        as String,
            aliases:
                null == aliases
                    ? _value.aliases
                    : aliases // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            category:
                freezed == category
                    ? _value.category
                    : category // ignore: cast_nullable_to_non_nullable
                        as String?,
            sensitive:
                null == sensitive
                    ? _value.sensitive
                    : sensitive // ignore: cast_nullable_to_non_nullable
                        as bool,
            fetchedAt:
                freezed == fetchedAt
                    ? _value.fetchedAt
                    : fetchedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CustomEmojiImplCopyWith<$Res>
    implements $CustomEmojiCopyWith<$Res> {
  factory _$$CustomEmojiImplCopyWith(
    _$CustomEmojiImpl value,
    $Res Function(_$CustomEmojiImpl) then,
  ) = __$$CustomEmojiImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String host,
    String name,
    String url,
    List<String> aliases,
    String? category,
    bool sensitive,
    DateTime? fetchedAt,
  });
}

/// @nodoc
class __$$CustomEmojiImplCopyWithImpl<$Res>
    extends _$CustomEmojiCopyWithImpl<$Res, _$CustomEmojiImpl>
    implements _$$CustomEmojiImplCopyWith<$Res> {
  __$$CustomEmojiImplCopyWithImpl(
    _$CustomEmojiImpl _value,
    $Res Function(_$CustomEmojiImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CustomEmoji
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? host = null,
    Object? name = null,
    Object? url = null,
    Object? aliases = null,
    Object? category = freezed,
    Object? sensitive = null,
    Object? fetchedAt = freezed,
  }) {
    return _then(
      _$CustomEmojiImpl(
        host:
            null == host
                ? _value.host
                : host // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        url:
            null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                    as String,
        aliases:
            null == aliases
                ? _value._aliases
                : aliases // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        category:
            freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                    as String?,
        sensitive:
            null == sensitive
                ? _value.sensitive
                : sensitive // ignore: cast_nullable_to_non_nullable
                    as bool,
        fetchedAt:
            freezed == fetchedAt
                ? _value.fetchedAt
                : fetchedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CustomEmojiImpl implements _CustomEmoji {
  const _$CustomEmojiImpl({
    required this.host,
    required this.name,
    required this.url,
    final List<String> aliases = const <String>[],
    this.category,
    this.sensitive = false,
    this.fetchedAt,
  }) : _aliases = aliases;

  factory _$CustomEmojiImpl.fromJson(Map<String, dynamic> json) =>
      _$$CustomEmojiImplFromJson(json);

  @override
  final String host;
  @override
  final String name;
  @override
  final String url;
  final List<String> _aliases;
  @override
  @JsonKey()
  List<String> get aliases {
    if (_aliases is EqualUnmodifiableListView) return _aliases;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_aliases);
  }

  @override
  final String? category;
  @override
  @JsonKey()
  final bool sensitive;
  @override
  final DateTime? fetchedAt;

  @override
  String toString() {
    return 'CustomEmoji(host: $host, name: $name, url: $url, aliases: $aliases, category: $category, sensitive: $sensitive, fetchedAt: $fetchedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CustomEmojiImpl &&
            (identical(other.host, host) || other.host == host) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.url, url) || other.url == url) &&
            const DeepCollectionEquality().equals(other._aliases, _aliases) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.sensitive, sensitive) ||
                other.sensitive == sensitive) &&
            (identical(other.fetchedAt, fetchedAt) ||
                other.fetchedAt == fetchedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    host,
    name,
    url,
    const DeepCollectionEquality().hash(_aliases),
    category,
    sensitive,
    fetchedAt,
  );

  /// Create a copy of CustomEmoji
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CustomEmojiImplCopyWith<_$CustomEmojiImpl> get copyWith =>
      __$$CustomEmojiImplCopyWithImpl<_$CustomEmojiImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CustomEmojiImplToJson(this);
  }
}

abstract class _CustomEmoji implements CustomEmoji {
  const factory _CustomEmoji({
    required final String host,
    required final String name,
    required final String url,
    final List<String> aliases,
    final String? category,
    final bool sensitive,
    final DateTime? fetchedAt,
  }) = _$CustomEmojiImpl;

  factory _CustomEmoji.fromJson(Map<String, dynamic> json) =
      _$CustomEmojiImpl.fromJson;

  @override
  String get host;
  @override
  String get name;
  @override
  String get url;
  @override
  List<String> get aliases;
  @override
  String? get category;
  @override
  bool get sensitive;
  @override
  DateTime? get fetchedAt;

  /// Create a copy of CustomEmoji
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CustomEmojiImplCopyWith<_$CustomEmojiImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
