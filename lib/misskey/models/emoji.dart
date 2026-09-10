import 'package:freezed_annotation/freezed_annotation.dart';

part 'emoji.freezed.dart';
part 'emoji.g.dart';

/// Custom emoji metadata.
///
/// custom emoji are server-scoped: the same `name` may
/// resolve to different images on different hosts. Always carry `host`.
@freezed
class CustomEmoji with _$CustomEmoji {
  const factory CustomEmoji({
    required String host,
    required String name,
    required String url,
    @Default(<String>[]) List<String> aliases,
    String? category,
    @Default(false) bool sensitive,
    DateTime? fetchedAt,
  }) = _CustomEmoji;

  factory CustomEmoji.fromJson(Map<String, dynamic> json) =>
      _$CustomEmojiFromJson(json);
}
