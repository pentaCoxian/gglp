import 'package:freezed_annotation/freezed_annotation.dart';

part 'reaction.freezed.dart';
part 'reaction.g.dart';

/// A single reaction key + count on a note. Misskey serializes reactions as
/// `{":emoji_name@host:": count}` for custom and `{"👍": count}`
/// for unicode. We split that out so the UI doesn't re-parse strings.
@freezed
class Reaction with _$Reaction {
  const factory Reaction({
    /// Raw key from Misskey (e.g. `:smile@.:`, `:custom@remote.example:`,
    /// or a unicode codepoint sequence).
    required String key,
    required int count,

    /// True when `key` starts and ends with `:` (custom emoji).
    required bool isCustom,

    /// For custom emoji, the resolved emoji metadata if known. Null until
    /// the emoji resolver finishes lookup.
    String? resolvedUrl,
  }) = _Reaction;

  factory Reaction.fromJson(Map<String, dynamic> json) =>
      _$ReactionFromJson(json);
}
