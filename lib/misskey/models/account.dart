import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';
part 'account.g.dart';

/// A logged-in Misskey account. Identity is `{host, userId}` per the design
/// doc — the same `userId` on different hosts is a different account.
///
/// Tokens live in secure storage (NOT in this model) keyed by `id`.
@freezed
class Account with _$Account {
  const Account._();

  const factory Account({
    /// `host:userId` — the stable key used everywhere (DB rows, secure
    /// storage entries, Riverpod families, stream supervisor).
    required String id,
    required String host,
    required String userId,
    required String username,
    String? displayName,
    String? avatarUrl,
    @Default(false) bool isCat,
    @Default(false) bool isAdmin,
    DateTime? addedAt,
    DateTime? lastUsedAt,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  static String makeId({required String host, required String userId}) =>
      '$host:$userId';
}
