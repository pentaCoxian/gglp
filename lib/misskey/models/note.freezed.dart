// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Note _$NoteFromJson(Map<String, dynamic> json) {
  return _Note.fromJson(json);
}

/// @nodoc
mixin _$Note {
  String get id => throw _privateConstructorUsedError;
  String get sourceHost => throw _privateConstructorUsedError;
  User get user => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  String? get text => throw _privateConstructorUsedError;
  String? get cw => throw _privateConstructorUsedError;
  NoteVisibility get visibility => throw _privateConstructorUsedError;
  String? get replyId => throw _privateConstructorUsedError;
  String? get renoteId => throw _privateConstructorUsedError;

  /// The full renoted note when one is embedded. Misskey ships the
  /// renoted note alongside the renote envelope so we can render a
  /// quote / boost without an extra fetch. Null on plain notes.
  Note? get renote => throw _privateConstructorUsedError;

  /// Drive files attached to the note. Empty for text-only notes.
  List<NoteFile> get files => throw _privateConstructorUsedError;

  /// Channel this note belongs to, if any. Misskey channels are
  /// server-side topic groups — when present we render a chip in
  /// the header so the user can see which channel the note came
  /// from.
  NoteChannel? get channel => throw _privateConstructorUsedError;

  /// Poll attached to the note, if any. Choice vote counts and the
  /// viewer's `isVoted` flags come straight from the note JSON.
  Poll? get poll => throw _privateConstructorUsedError;

  /// True when the author posted with the "local-only" flag set.
  /// Misskey calls these "non-federated" notes. We surface this as
  /// a small badge in the metadata row alongside the visibility
  /// icon, since federated viewers should never see them.
  bool get localOnly => throw _privateConstructorUsedError;

  /// The viewer's own reaction key, if any. Misskey ships this as
  /// `myReaction` in the note JSON when there's an authenticated
  /// caller. The reaction chip uses it to toggle: tapping a chip
  /// whose key matches `myReaction` un-reacts; tapping any other
  /// chip is a no-op for now (re-reacting requires removing the
  /// previous reaction first, which is friction we surface via the
  /// "+ React" button instead).
  String? get myReaction => throw _privateConstructorUsedError;
  List<Reaction> get reactions => throw _privateConstructorUsedError;
  int get repliesCount => throw _privateConstructorUsedError;
  int get renoteCount => throw _privateConstructorUsedError;

  /// ActivityPub URI for federated notes. Populated by Misskey only
  /// when the note's author is on a different server from `sourceHost`.
  /// Stable across all receiving servers — this is the ONLY identity
  /// that lets us dedup the same federated note across our accounts.
  String? get uri => throw _privateConstructorUsedError;

  /// Compact per-note extras retained from the wire payload. Today
  /// this holds only the flattened inline emoji map under `emojis`
  /// (see `MisskeyParsers._extrasFromJson`); the full decoded JSON
  /// is deliberately NOT kept — it was several times the size of the
  /// parsed model for every note in memory. Model new fields
  /// explicitly rather than reading them back from here.
  Map<String, dynamic>? get rawExtras => throw _privateConstructorUsedError;

  /// Serializes this Note to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NoteCopyWith<Note> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteCopyWith<$Res> {
  factory $NoteCopyWith(Note value, $Res Function(Note) then) =
      _$NoteCopyWithImpl<$Res, Note>;
  @useResult
  $Res call({
    String id,
    String sourceHost,
    User user,
    DateTime createdAt,
    DateTime? updatedAt,
    String? text,
    String? cw,
    NoteVisibility visibility,
    String? replyId,
    String? renoteId,
    Note? renote,
    List<NoteFile> files,
    NoteChannel? channel,
    Poll? poll,
    bool localOnly,
    String? myReaction,
    List<Reaction> reactions,
    int repliesCount,
    int renoteCount,
    String? uri,
    Map<String, dynamic>? rawExtras,
  });

  $UserCopyWith<$Res> get user;
  $NoteCopyWith<$Res>? get renote;
  $NoteChannelCopyWith<$Res>? get channel;
  $PollCopyWith<$Res>? get poll;
}

/// @nodoc
class _$NoteCopyWithImpl<$Res, $Val extends Note>
    implements $NoteCopyWith<$Res> {
  _$NoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceHost = null,
    Object? user = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? text = freezed,
    Object? cw = freezed,
    Object? visibility = null,
    Object? replyId = freezed,
    Object? renoteId = freezed,
    Object? renote = freezed,
    Object? files = null,
    Object? channel = freezed,
    Object? poll = freezed,
    Object? localOnly = null,
    Object? myReaction = freezed,
    Object? reactions = null,
    Object? repliesCount = null,
    Object? renoteCount = null,
    Object? uri = freezed,
    Object? rawExtras = freezed,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            sourceHost:
                null == sourceHost
                    ? _value.sourceHost
                    : sourceHost // ignore: cast_nullable_to_non_nullable
                        as String,
            user:
                null == user
                    ? _value.user
                    : user // ignore: cast_nullable_to_non_nullable
                        as User,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            updatedAt:
                freezed == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime?,
            text:
                freezed == text
                    ? _value.text
                    : text // ignore: cast_nullable_to_non_nullable
                        as String?,
            cw:
                freezed == cw
                    ? _value.cw
                    : cw // ignore: cast_nullable_to_non_nullable
                        as String?,
            visibility:
                null == visibility
                    ? _value.visibility
                    : visibility // ignore: cast_nullable_to_non_nullable
                        as NoteVisibility,
            replyId:
                freezed == replyId
                    ? _value.replyId
                    : replyId // ignore: cast_nullable_to_non_nullable
                        as String?,
            renoteId:
                freezed == renoteId
                    ? _value.renoteId
                    : renoteId // ignore: cast_nullable_to_non_nullable
                        as String?,
            renote:
                freezed == renote
                    ? _value.renote
                    : renote // ignore: cast_nullable_to_non_nullable
                        as Note?,
            files:
                null == files
                    ? _value.files
                    : files // ignore: cast_nullable_to_non_nullable
                        as List<NoteFile>,
            channel:
                freezed == channel
                    ? _value.channel
                    : channel // ignore: cast_nullable_to_non_nullable
                        as NoteChannel?,
            poll:
                freezed == poll
                    ? _value.poll
                    : poll // ignore: cast_nullable_to_non_nullable
                        as Poll?,
            localOnly:
                null == localOnly
                    ? _value.localOnly
                    : localOnly // ignore: cast_nullable_to_non_nullable
                        as bool,
            myReaction:
                freezed == myReaction
                    ? _value.myReaction
                    : myReaction // ignore: cast_nullable_to_non_nullable
                        as String?,
            reactions:
                null == reactions
                    ? _value.reactions
                    : reactions // ignore: cast_nullable_to_non_nullable
                        as List<Reaction>,
            repliesCount:
                null == repliesCount
                    ? _value.repliesCount
                    : repliesCount // ignore: cast_nullable_to_non_nullable
                        as int,
            renoteCount:
                null == renoteCount
                    ? _value.renoteCount
                    : renoteCount // ignore: cast_nullable_to_non_nullable
                        as int,
            uri:
                freezed == uri
                    ? _value.uri
                    : uri // ignore: cast_nullable_to_non_nullable
                        as String?,
            rawExtras:
                freezed == rawExtras
                    ? _value.rawExtras
                    : rawExtras // ignore: cast_nullable_to_non_nullable
                        as Map<String, dynamic>?,
          )
          as $Val,
    );
  }

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get user {
    return $UserCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NoteCopyWith<$Res>? get renote {
    if (_value.renote == null) {
      return null;
    }

    return $NoteCopyWith<$Res>(_value.renote!, (value) {
      return _then(_value.copyWith(renote: value) as $Val);
    });
  }

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NoteChannelCopyWith<$Res>? get channel {
    if (_value.channel == null) {
      return null;
    }

    return $NoteChannelCopyWith<$Res>(_value.channel!, (value) {
      return _then(_value.copyWith(channel: value) as $Val);
    });
  }

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PollCopyWith<$Res>? get poll {
    if (_value.poll == null) {
      return null;
    }

    return $PollCopyWith<$Res>(_value.poll!, (value) {
      return _then(_value.copyWith(poll: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NoteImplCopyWith<$Res> implements $NoteCopyWith<$Res> {
  factory _$$NoteImplCopyWith(
    _$NoteImpl value,
    $Res Function(_$NoteImpl) then,
  ) = __$$NoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String sourceHost,
    User user,
    DateTime createdAt,
    DateTime? updatedAt,
    String? text,
    String? cw,
    NoteVisibility visibility,
    String? replyId,
    String? renoteId,
    Note? renote,
    List<NoteFile> files,
    NoteChannel? channel,
    Poll? poll,
    bool localOnly,
    String? myReaction,
    List<Reaction> reactions,
    int repliesCount,
    int renoteCount,
    String? uri,
    Map<String, dynamic>? rawExtras,
  });

  @override
  $UserCopyWith<$Res> get user;
  @override
  $NoteCopyWith<$Res>? get renote;
  @override
  $NoteChannelCopyWith<$Res>? get channel;
  @override
  $PollCopyWith<$Res>? get poll;
}

/// @nodoc
class __$$NoteImplCopyWithImpl<$Res>
    extends _$NoteCopyWithImpl<$Res, _$NoteImpl>
    implements _$$NoteImplCopyWith<$Res> {
  __$$NoteImplCopyWithImpl(_$NoteImpl _value, $Res Function(_$NoteImpl) _then)
    : super(_value, _then);

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceHost = null,
    Object? user = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? text = freezed,
    Object? cw = freezed,
    Object? visibility = null,
    Object? replyId = freezed,
    Object? renoteId = freezed,
    Object? renote = freezed,
    Object? files = null,
    Object? channel = freezed,
    Object? poll = freezed,
    Object? localOnly = null,
    Object? myReaction = freezed,
    Object? reactions = null,
    Object? repliesCount = null,
    Object? renoteCount = null,
    Object? uri = freezed,
    Object? rawExtras = freezed,
  }) {
    return _then(
      _$NoteImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        sourceHost:
            null == sourceHost
                ? _value.sourceHost
                : sourceHost // ignore: cast_nullable_to_non_nullable
                    as String,
        user:
            null == user
                ? _value.user
                : user // ignore: cast_nullable_to_non_nullable
                    as User,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        updatedAt:
            freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime?,
        text:
            freezed == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                    as String?,
        cw:
            freezed == cw
                ? _value.cw
                : cw // ignore: cast_nullable_to_non_nullable
                    as String?,
        visibility:
            null == visibility
                ? _value.visibility
                : visibility // ignore: cast_nullable_to_non_nullable
                    as NoteVisibility,
        replyId:
            freezed == replyId
                ? _value.replyId
                : replyId // ignore: cast_nullable_to_non_nullable
                    as String?,
        renoteId:
            freezed == renoteId
                ? _value.renoteId
                : renoteId // ignore: cast_nullable_to_non_nullable
                    as String?,
        renote:
            freezed == renote
                ? _value.renote
                : renote // ignore: cast_nullable_to_non_nullable
                    as Note?,
        files:
            null == files
                ? _value._files
                : files // ignore: cast_nullable_to_non_nullable
                    as List<NoteFile>,
        channel:
            freezed == channel
                ? _value.channel
                : channel // ignore: cast_nullable_to_non_nullable
                    as NoteChannel?,
        poll:
            freezed == poll
                ? _value.poll
                : poll // ignore: cast_nullable_to_non_nullable
                    as Poll?,
        localOnly:
            null == localOnly
                ? _value.localOnly
                : localOnly // ignore: cast_nullable_to_non_nullable
                    as bool,
        myReaction:
            freezed == myReaction
                ? _value.myReaction
                : myReaction // ignore: cast_nullable_to_non_nullable
                    as String?,
        reactions:
            null == reactions
                ? _value._reactions
                : reactions // ignore: cast_nullable_to_non_nullable
                    as List<Reaction>,
        repliesCount:
            null == repliesCount
                ? _value.repliesCount
                : repliesCount // ignore: cast_nullable_to_non_nullable
                    as int,
        renoteCount:
            null == renoteCount
                ? _value.renoteCount
                : renoteCount // ignore: cast_nullable_to_non_nullable
                    as int,
        uri:
            freezed == uri
                ? _value.uri
                : uri // ignore: cast_nullable_to_non_nullable
                    as String?,
        rawExtras:
            freezed == rawExtras
                ? _value._rawExtras
                : rawExtras // ignore: cast_nullable_to_non_nullable
                    as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$NoteImpl extends _Note {
  const _$NoteImpl({
    required this.id,
    required this.sourceHost,
    required this.user,
    required this.createdAt,
    this.updatedAt,
    this.text,
    this.cw,
    this.visibility = NoteVisibility.public,
    this.replyId,
    this.renoteId,
    this.renote,
    final List<NoteFile> files = const <NoteFile>[],
    this.channel,
    this.poll,
    this.localOnly = false,
    this.myReaction,
    final List<Reaction> reactions = const <Reaction>[],
    this.repliesCount = 0,
    this.renoteCount = 0,
    this.uri,
    final Map<String, dynamic>? rawExtras,
  }) : _files = files,
       _reactions = reactions,
       _rawExtras = rawExtras,
       super._();

  factory _$NoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$NoteImplFromJson(json);

  @override
  final String id;
  @override
  final String sourceHost;
  @override
  final User user;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final String? text;
  @override
  final String? cw;
  @override
  @JsonKey()
  final NoteVisibility visibility;
  @override
  final String? replyId;
  @override
  final String? renoteId;

  /// The full renoted note when one is embedded. Misskey ships the
  /// renoted note alongside the renote envelope so we can render a
  /// quote / boost without an extra fetch. Null on plain notes.
  @override
  final Note? renote;

  /// Drive files attached to the note. Empty for text-only notes.
  final List<NoteFile> _files;

  /// Drive files attached to the note. Empty for text-only notes.
  @override
  @JsonKey()
  List<NoteFile> get files {
    if (_files is EqualUnmodifiableListView) return _files;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_files);
  }

  /// Channel this note belongs to, if any. Misskey channels are
  /// server-side topic groups — when present we render a chip in
  /// the header so the user can see which channel the note came
  /// from.
  @override
  final NoteChannel? channel;

  /// Poll attached to the note, if any. Choice vote counts and the
  /// viewer's `isVoted` flags come straight from the note JSON.
  @override
  final Poll? poll;

  /// True when the author posted with the "local-only" flag set.
  /// Misskey calls these "non-federated" notes. We surface this as
  /// a small badge in the metadata row alongside the visibility
  /// icon, since federated viewers should never see them.
  @override
  @JsonKey()
  final bool localOnly;

  /// The viewer's own reaction key, if any. Misskey ships this as
  /// `myReaction` in the note JSON when there's an authenticated
  /// caller. The reaction chip uses it to toggle: tapping a chip
  /// whose key matches `myReaction` un-reacts; tapping any other
  /// chip is a no-op for now (re-reacting requires removing the
  /// previous reaction first, which is friction we surface via the
  /// "+ React" button instead).
  @override
  final String? myReaction;
  final List<Reaction> _reactions;
  @override
  @JsonKey()
  List<Reaction> get reactions {
    if (_reactions is EqualUnmodifiableListView) return _reactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reactions);
  }

  @override
  @JsonKey()
  final int repliesCount;
  @override
  @JsonKey()
  final int renoteCount;

  /// ActivityPub URI for federated notes. Populated by Misskey only
  /// when the note's author is on a different server from `sourceHost`.
  /// Stable across all receiving servers — this is the ONLY identity
  /// that lets us dedup the same federated note across our accounts.
  @override
  final String? uri;

  /// Compact per-note extras retained from the wire payload. Today
  /// this holds only the flattened inline emoji map under `emojis`
  /// (see `MisskeyParsers._extrasFromJson`); the full decoded JSON
  /// is deliberately NOT kept — it was several times the size of the
  /// parsed model for every note in memory. Model new fields
  /// explicitly rather than reading them back from here.
  final Map<String, dynamic>? _rawExtras;

  /// Compact per-note extras retained from the wire payload. Today
  /// this holds only the flattened inline emoji map under `emojis`
  /// (see `MisskeyParsers._extrasFromJson`); the full decoded JSON
  /// is deliberately NOT kept — it was several times the size of the
  /// parsed model for every note in memory. Model new fields
  /// explicitly rather than reading them back from here.
  @override
  Map<String, dynamic>? get rawExtras {
    final value = _rawExtras;
    if (value == null) return null;
    if (_rawExtras is EqualUnmodifiableMapView) return _rawExtras;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'Note(id: $id, sourceHost: $sourceHost, user: $user, createdAt: $createdAt, updatedAt: $updatedAt, text: $text, cw: $cw, visibility: $visibility, replyId: $replyId, renoteId: $renoteId, renote: $renote, files: $files, channel: $channel, poll: $poll, localOnly: $localOnly, myReaction: $myReaction, reactions: $reactions, repliesCount: $repliesCount, renoteCount: $renoteCount, uri: $uri, rawExtras: $rawExtras)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sourceHost, sourceHost) ||
                other.sourceHost == sourceHost) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.cw, cw) || other.cw == cw) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.replyId, replyId) || other.replyId == replyId) &&
            (identical(other.renoteId, renoteId) ||
                other.renoteId == renoteId) &&
            (identical(other.renote, renote) || other.renote == renote) &&
            const DeepCollectionEquality().equals(other._files, _files) &&
            (identical(other.channel, channel) || other.channel == channel) &&
            (identical(other.poll, poll) || other.poll == poll) &&
            (identical(other.localOnly, localOnly) ||
                other.localOnly == localOnly) &&
            (identical(other.myReaction, myReaction) ||
                other.myReaction == myReaction) &&
            const DeepCollectionEquality().equals(
              other._reactions,
              _reactions,
            ) &&
            (identical(other.repliesCount, repliesCount) ||
                other.repliesCount == repliesCount) &&
            (identical(other.renoteCount, renoteCount) ||
                other.renoteCount == renoteCount) &&
            (identical(other.uri, uri) || other.uri == uri) &&
            const DeepCollectionEquality().equals(
              other._rawExtras,
              _rawExtras,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    sourceHost,
    user,
    createdAt,
    updatedAt,
    text,
    cw,
    visibility,
    replyId,
    renoteId,
    renote,
    const DeepCollectionEquality().hash(_files),
    channel,
    poll,
    localOnly,
    myReaction,
    const DeepCollectionEquality().hash(_reactions),
    repliesCount,
    renoteCount,
    uri,
    const DeepCollectionEquality().hash(_rawExtras),
  ]);

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteImplCopyWith<_$NoteImpl> get copyWith =>
      __$$NoteImplCopyWithImpl<_$NoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NoteImplToJson(this);
  }
}

abstract class _Note extends Note {
  const factory _Note({
    required final String id,
    required final String sourceHost,
    required final User user,
    required final DateTime createdAt,
    final DateTime? updatedAt,
    final String? text,
    final String? cw,
    final NoteVisibility visibility,
    final String? replyId,
    final String? renoteId,
    final Note? renote,
    final List<NoteFile> files,
    final NoteChannel? channel,
    final Poll? poll,
    final bool localOnly,
    final String? myReaction,
    final List<Reaction> reactions,
    final int repliesCount,
    final int renoteCount,
    final String? uri,
    final Map<String, dynamic>? rawExtras,
  }) = _$NoteImpl;
  const _Note._() : super._();

  factory _Note.fromJson(Map<String, dynamic> json) = _$NoteImpl.fromJson;

  @override
  String get id;
  @override
  String get sourceHost;
  @override
  User get user;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  String? get text;
  @override
  String? get cw;
  @override
  NoteVisibility get visibility;
  @override
  String? get replyId;
  @override
  String? get renoteId;

  /// The full renoted note when one is embedded. Misskey ships the
  /// renoted note alongside the renote envelope so we can render a
  /// quote / boost without an extra fetch. Null on plain notes.
  @override
  Note? get renote;

  /// Drive files attached to the note. Empty for text-only notes.
  @override
  List<NoteFile> get files;

  /// Channel this note belongs to, if any. Misskey channels are
  /// server-side topic groups — when present we render a chip in
  /// the header so the user can see which channel the note came
  /// from.
  @override
  NoteChannel? get channel;

  /// Poll attached to the note, if any. Choice vote counts and the
  /// viewer's `isVoted` flags come straight from the note JSON.
  @override
  Poll? get poll;

  /// True when the author posted with the "local-only" flag set.
  /// Misskey calls these "non-federated" notes. We surface this as
  /// a small badge in the metadata row alongside the visibility
  /// icon, since federated viewers should never see them.
  @override
  bool get localOnly;

  /// The viewer's own reaction key, if any. Misskey ships this as
  /// `myReaction` in the note JSON when there's an authenticated
  /// caller. The reaction chip uses it to toggle: tapping a chip
  /// whose key matches `myReaction` un-reacts; tapping any other
  /// chip is a no-op for now (re-reacting requires removing the
  /// previous reaction first, which is friction we surface via the
  /// "+ React" button instead).
  @override
  String? get myReaction;
  @override
  List<Reaction> get reactions;
  @override
  int get repliesCount;
  @override
  int get renoteCount;

  /// ActivityPub URI for federated notes. Populated by Misskey only
  /// when the note's author is on a different server from `sourceHost`.
  /// Stable across all receiving servers — this is the ONLY identity
  /// that lets us dedup the same federated note across our accounts.
  @override
  String? get uri;

  /// Compact per-note extras retained from the wire payload. Today
  /// this holds only the flattened inline emoji map under `emojis`
  /// (see `MisskeyParsers._extrasFromJson`); the full decoded JSON
  /// is deliberately NOT kept — it was several times the size of the
  /// parsed model for every note in memory. Model new fields
  /// explicitly rather than reading them back from here.
  @override
  Map<String, dynamic>? get rawExtras;

  /// Create a copy of Note
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoteImplCopyWith<_$NoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
