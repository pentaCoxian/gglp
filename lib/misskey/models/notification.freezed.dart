// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MisskeyNotification _$MisskeyNotificationFromJson(Map<String, dynamic> json) {
  return _MisskeyNotification.fromJson(json);
}

/// @nodoc
mixin _$MisskeyNotification {
  String get id => throw _privateConstructorUsedError;
  NotificationKind get kind => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// `type` exactly as it came over the wire — useful when [kind]
  /// is [NotificationKind.other] and the UI wants to surface
  /// something less generic than "notification".
  String get rawType => throw _privateConstructorUsedError;
  User? get user => throw _privateConstructorUsedError;

  /// The note the notification refers to (e.g. the note that was
  /// reacted to, replied to, mentioned in). Null for `follow` etc.
  Note? get note => throw _privateConstructorUsedError;

  /// Reaction key for `reaction`-type notifications (`:wave_anim@.:`
  /// or a unicode codepoint).
  String? get reaction => throw _privateConstructorUsedError;

  /// Unread state on the server. We don't drive UI off this yet
  /// (read-marker requires `notifications/markAllAsRead`); kept so
  /// the next iteration can use it.
  bool get isRead => throw _privateConstructorUsedError;

  /// Serializes this MisskeyNotification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MisskeyNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MisskeyNotificationCopyWith<MisskeyNotification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MisskeyNotificationCopyWith<$Res> {
  factory $MisskeyNotificationCopyWith(
    MisskeyNotification value,
    $Res Function(MisskeyNotification) then,
  ) = _$MisskeyNotificationCopyWithImpl<$Res, MisskeyNotification>;
  @useResult
  $Res call({
    String id,
    NotificationKind kind,
    DateTime createdAt,
    String rawType,
    User? user,
    Note? note,
    String? reaction,
    bool isRead,
  });

  $UserCopyWith<$Res>? get user;
  $NoteCopyWith<$Res>? get note;
}

/// @nodoc
class _$MisskeyNotificationCopyWithImpl<$Res, $Val extends MisskeyNotification>
    implements $MisskeyNotificationCopyWith<$Res> {
  _$MisskeyNotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MisskeyNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? createdAt = null,
    Object? rawType = null,
    Object? user = freezed,
    Object? note = freezed,
    Object? reaction = freezed,
    Object? isRead = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            kind:
                null == kind
                    ? _value.kind
                    : kind // ignore: cast_nullable_to_non_nullable
                        as NotificationKind,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            rawType:
                null == rawType
                    ? _value.rawType
                    : rawType // ignore: cast_nullable_to_non_nullable
                        as String,
            user:
                freezed == user
                    ? _value.user
                    : user // ignore: cast_nullable_to_non_nullable
                        as User?,
            note:
                freezed == note
                    ? _value.note
                    : note // ignore: cast_nullable_to_non_nullable
                        as Note?,
            reaction:
                freezed == reaction
                    ? _value.reaction
                    : reaction // ignore: cast_nullable_to_non_nullable
                        as String?,
            isRead:
                null == isRead
                    ? _value.isRead
                    : isRead // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of MisskeyNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res>? get user {
    if (_value.user == null) {
      return null;
    }

    return $UserCopyWith<$Res>(_value.user!, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }

  /// Create a copy of MisskeyNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NoteCopyWith<$Res>? get note {
    if (_value.note == null) {
      return null;
    }

    return $NoteCopyWith<$Res>(_value.note!, (value) {
      return _then(_value.copyWith(note: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MisskeyNotificationImplCopyWith<$Res>
    implements $MisskeyNotificationCopyWith<$Res> {
  factory _$$MisskeyNotificationImplCopyWith(
    _$MisskeyNotificationImpl value,
    $Res Function(_$MisskeyNotificationImpl) then,
  ) = __$$MisskeyNotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    NotificationKind kind,
    DateTime createdAt,
    String rawType,
    User? user,
    Note? note,
    String? reaction,
    bool isRead,
  });

  @override
  $UserCopyWith<$Res>? get user;
  @override
  $NoteCopyWith<$Res>? get note;
}

/// @nodoc
class __$$MisskeyNotificationImplCopyWithImpl<$Res>
    extends _$MisskeyNotificationCopyWithImpl<$Res, _$MisskeyNotificationImpl>
    implements _$$MisskeyNotificationImplCopyWith<$Res> {
  __$$MisskeyNotificationImplCopyWithImpl(
    _$MisskeyNotificationImpl _value,
    $Res Function(_$MisskeyNotificationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MisskeyNotification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? createdAt = null,
    Object? rawType = null,
    Object? user = freezed,
    Object? note = freezed,
    Object? reaction = freezed,
    Object? isRead = null,
  }) {
    return _then(
      _$MisskeyNotificationImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        kind:
            null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                    as NotificationKind,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        rawType:
            null == rawType
                ? _value.rawType
                : rawType // ignore: cast_nullable_to_non_nullable
                    as String,
        user:
            freezed == user
                ? _value.user
                : user // ignore: cast_nullable_to_non_nullable
                    as User?,
        note:
            freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                    as Note?,
        reaction:
            freezed == reaction
                ? _value.reaction
                : reaction // ignore: cast_nullable_to_non_nullable
                    as String?,
        isRead:
            null == isRead
                ? _value.isRead
                : isRead // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MisskeyNotificationImpl implements _MisskeyNotification {
  const _$MisskeyNotificationImpl({
    required this.id,
    required this.kind,
    required this.createdAt,
    required this.rawType,
    this.user,
    this.note,
    this.reaction,
    this.isRead = false,
  });

  factory _$MisskeyNotificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$MisskeyNotificationImplFromJson(json);

  @override
  final String id;
  @override
  final NotificationKind kind;
  @override
  final DateTime createdAt;

  /// `type` exactly as it came over the wire — useful when [kind]
  /// is [NotificationKind.other] and the UI wants to surface
  /// something less generic than "notification".
  @override
  final String rawType;
  @override
  final User? user;

  /// The note the notification refers to (e.g. the note that was
  /// reacted to, replied to, mentioned in). Null for `follow` etc.
  @override
  final Note? note;

  /// Reaction key for `reaction`-type notifications (`:wave_anim@.:`
  /// or a unicode codepoint).
  @override
  final String? reaction;

  /// Unread state on the server. We don't drive UI off this yet
  /// (read-marker requires `notifications/markAllAsRead`); kept so
  /// the next iteration can use it.
  @override
  @JsonKey()
  final bool isRead;

  @override
  String toString() {
    return 'MisskeyNotification(id: $id, kind: $kind, createdAt: $createdAt, rawType: $rawType, user: $user, note: $note, reaction: $reaction, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MisskeyNotificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.rawType, rawType) || other.rawType == rawType) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.reaction, reaction) ||
                other.reaction == reaction) &&
            (identical(other.isRead, isRead) || other.isRead == isRead));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    kind,
    createdAt,
    rawType,
    user,
    note,
    reaction,
    isRead,
  );

  /// Create a copy of MisskeyNotification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MisskeyNotificationImplCopyWith<_$MisskeyNotificationImpl> get copyWith =>
      __$$MisskeyNotificationImplCopyWithImpl<_$MisskeyNotificationImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MisskeyNotificationImplToJson(this);
  }
}

abstract class _MisskeyNotification implements MisskeyNotification {
  const factory _MisskeyNotification({
    required final String id,
    required final NotificationKind kind,
    required final DateTime createdAt,
    required final String rawType,
    final User? user,
    final Note? note,
    final String? reaction,
    final bool isRead,
  }) = _$MisskeyNotificationImpl;

  factory _MisskeyNotification.fromJson(Map<String, dynamic> json) =
      _$MisskeyNotificationImpl.fromJson;

  @override
  String get id;
  @override
  NotificationKind get kind;
  @override
  DateTime get createdAt;

  /// `type` exactly as it came over the wire — useful when [kind]
  /// is [NotificationKind.other] and the UI wants to surface
  /// something less generic than "notification".
  @override
  String get rawType;
  @override
  User? get user;

  /// The note the notification refers to (e.g. the note that was
  /// reacted to, replied to, mentioned in). Null for `follow` etc.
  @override
  Note? get note;

  /// Reaction key for `reaction`-type notifications (`:wave_anim@.:`
  /// or a unicode codepoint).
  @override
  String? get reaction;

  /// Unread state on the server. We don't drive UI off this yet
  /// (read-marker requires `notifications/markAllAsRead`); kept so
  /// the next iteration can use it.
  @override
  bool get isRead;

  /// Create a copy of MisskeyNotification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MisskeyNotificationImplCopyWith<_$MisskeyNotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
