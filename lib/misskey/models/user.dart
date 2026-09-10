import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// A Misskey user as observed from a particular `viewerHost`.
///
/// `host` is the user's home host (null when local to the viewer's host —
/// Misskey omits it for local users in API responses, so we keep null).
@freezed
class User with _$User {
  const factory User({
    required String id,
    required String username,
    String? host,
    String? name,
    String? avatarUrl,
    String? avatarBlurhash,
    @Default(false) bool isBot,
    @Default(false) bool isCat,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
