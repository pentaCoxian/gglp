import 'package:freezed_annotation/freezed_annotation.dart';

part 'poll.freezed.dart';
part 'poll.g.dart';

/// One selectable option in a note poll.
@freezed
class PollChoice with _$PollChoice {
  const factory PollChoice({
    required String text,
    @Default(0) int votes,

    /// True when the viewer has voted for this choice (Misskey ships
    /// `isVoted` per choice for authenticated callers).
    @Default(false) bool isVoted,
  }) = _PollChoice;

  factory PollChoice.fromJson(Map<String, dynamic> json) =>
      _$PollChoiceFromJson(json);
}

/// A poll attached to a note.
@freezed
class Poll with _$Poll {
  const Poll._();

  const factory Poll({
    /// Null = the poll never expires.
    DateTime? expiresAt,
    @Default(false) bool multiple,
    @Default(<PollChoice>[]) List<PollChoice> choices,
  }) = _Poll;

  factory Poll.fromJson(Map<String, dynamic> json) => _$PollFromJson(json);

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  int get totalVotes => choices.fold(0, (sum, c) => sum + c.votes);

  /// Whether the viewer has cast at least one vote. For single-choice
  /// polls this means voting is over for them; multi-choice polls
  /// accept further votes on other choices.
  bool get hasVoted => choices.any((c) => c.isVoted);

  /// Voting is open for the viewer: not expired, and either they
  /// haven't voted yet or the poll allows multiple choices.
  bool get canVote => !isExpired && (!hasVoted || multiple);
}
