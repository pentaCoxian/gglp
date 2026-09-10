import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../misskey/models/account.dart';
import '../../misskey/models/note.dart';
import '../../misskey/models/poll.dart';
import '../../timeline/note_actions_service.dart';
import '../plus/plus.dart';

/// Renders the poll attached to a note: one flat bordered result bar
/// per choice plus a footer summarizing turnout and expiry.
///
/// Callers only mount this when `note.poll != null`.
///
/// Voting: when the poll is open for the viewer ([Poll.canVote]) and an
/// [attributionAccount] is available, tapping a choice casts a vote via
/// `notes/polls/vote` and the result is applied optimistically to a
/// local [Poll] override — so a single-choice poll immediately locks
/// into its "voted" informational state without waiting for a timeline
/// refresh. When voting isn't possible (expired poll, already voted on
/// a single-choice poll, no account) the bars are informational only.
class PollView extends ConsumerStatefulWidget {
  final Note note;

  /// Account used to cast votes. Null renders the poll read-only
  /// (e.g. detached contexts with no authenticated viewer).
  final Account? attributionAccount;

  const PollView({
    super.key,
    required this.note,
    required this.attributionAccount,
  });

  @override
  ConsumerState<PollView> createState() => _PollViewState();
}

class _PollViewState extends ConsumerState<PollView> {
  /// Optimistic local copy of the poll after a successful vote. Kept
  /// in state (rather than mutating the Note) so re-taps and
  /// expired/voted handling read the updated counts immediately.
  Poll? _override;

  /// Guards against double-submitting while a vote is in flight.
  bool _voting = false;

  Poll get _poll => _override ?? widget.note.poll!;

  @override
  void didUpdateWidget(covariant PollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh poll from the server supersedes the optimistic copy.
    if (oldWidget.note.poll != widget.note.poll) _override = null;
  }

  Future<void> _vote(int index) async {
    final account = widget.attributionAccount;
    if (account == null || _voting) return;
    final poll = _poll;
    if (!poll.canVote || poll.choices[index].isVoted) return;
    setState(() => _voting = true);
    try {
      final actions = await ref.read(noteActionsProvider(account).future);
      if (actions == null) {
        throw StateError('No client for ${account.host}');
      }
      await actions.vote(note: widget.note, choice: index);
      if (!mounted) return;
      setState(() {
        _override = poll.copyWith(
          choices: [
            for (var i = 0; i < poll.choices.length; i++)
              if (i == index)
                poll.choices[i].copyWith(
                  votes: poll.choices[i].votes + 1,
                  isVoted: true,
                )
              else
                poll.choices[i],
          ],
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  String _expiryLabel(Poll poll) {
    final at = poll.expiresAt;
    if (at == null) return 'no expiry';
    if (poll.isExpired) return 'ended';
    final d = at.difference(DateTime.now());
    if (d.inDays >= 1) return 'ends in ${d.inDays}d';
    if (d.inHours >= 1) return 'ends in ${d.inHours}h';
    if (d.inMinutes >= 1) return 'ends in ${d.inMinutes}m';
    return 'ends in ${d.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final poll = _poll;
    final total = poll.totalVotes;
    final canVote = poll.canVote && widget.attributionAccount != null;
    final footer = [
      '$total vote${total == 1 ? '' : 's'}',
      _expiryLabel(poll),
      if (poll.multiple) 'multiple choice',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < poll.choices.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _ChoiceBar(
            choice: poll.choices[i],
            fraction: total == 0 ? 0.0 : poll.choices[i].votes / total,
            showPercent: total > 0,
            onTap: canVote && !_voting && !poll.choices[i].isVoted
                ? () => _vote(i)
                : null,
          ),
        ],
        const SizedBox(height: 6),
        Text(
          footer,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// One full-width poll choice: a flat bordered rect whose fill is a
/// result bar proportional to the choice's share of the vote, with the
/// choice text and count/percentage layered on top. The viewer's own
/// voted choice is marked with a check and primary-colored text.
class _ChoiceBar extends StatelessWidget {
  final PollChoice choice;

  /// This choice's share of the total vote, 0..1. Zero when the poll
  /// has no votes yet.
  final double fraction;

  /// Percentages only make sense once someone has voted; before that
  /// the raw (zero) count is shown instead.
  final bool showPercent;

  /// Non-null makes the bar tappable to cast a vote.
  final VoidCallback? onTap;

  const _ChoiceBar({
    required this.choice,
    required this.fraction,
    required this.showPercent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plus = PlusTheme.of(context);
    final voted = choice.isVoted;

    final bar = Container(
      decoration: BoxDecoration(
        color: plus.surfaceSubtle,
        borderRadius: BorderRadius.circular(PlusRadii.card),
        border: Border.all(color: plus.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PlusRadii.card),
        child: Stack(
          children: [
            // Result fill behind the label — grows with vote share.
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction.clamp(0.0, 1.0),
                child: Container(
                  color: scheme.primary.withValues(alpha: 0.18),
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (voted) ...[
                    Icon(Icons.check_circle, size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      choice.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: voted ? scheme.primary : scheme.onSurface,
                        fontWeight: voted ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    showPercent
                        ? '${(fraction * 100).round()}%'
                        : '${choice.votes}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: voted ? scheme.primary : scheme.outline,
                      fontWeight: voted ? FontWeight.w700 : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return bar;
    return Semantics(
      button: true,
      label: 'Vote for ${choice.text}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: bar,
        ),
      ),
    );
  }
}
