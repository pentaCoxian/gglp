import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/note.dart';
import '../../timeline/note_actions_service.dart';
import '../plus/plus.dart';
import '../widgets/note_card.dart';

/// Thread / conversation view for a single note.
///
/// Layout (one scrollable):
///   - ancestor chain as flat stream rows (oldest first), each
///     separated by a [PlusDivider] hairline — the same dense-stream
///     convention as the timeline
///   - the FOCAL note as a white card (default [NoteCard] mode) so it
///     pops out of the flat stream
///   - a "Replies" section of stream rows (direct children)
///
/// Every non-focal row is tappable and re-opens [ThreadScreen] for
/// that note, so arbitrarily deep threads are walked by plain
/// navigation.
///
/// Federation: `notes/conversation` / `notes/children` expect a note
/// id local to [account]'s server. When the note was delivered by a
/// different server we re-anchor it via
/// [NoteActionsService.resolveOnThisAccount] first; if that fails the
/// screen degrades to showing the passed-in note alone with a notice.
class ThreadScreen extends ConsumerStatefulWidget {
  final Account account;
  final Note note;

  const ThreadScreen({
    super.key,
    required this.account,
    required this.note,
  });

  static Future<void> open(
    BuildContext context, {
    required Account account,
    required Note note,
  }) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ThreadScreen(account: account, note: note),
      ));

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen> {
  /// The note the thread is anchored on, with an id valid on
  /// [ThreadScreen.account]'s server. Null until the first load
  /// completes (or fails).
  Note? _focal;

  /// Ancestor chain, oldest first (`notes/conversation` returns
  /// nearest-first; we reverse for display).
  List<Note> _ancestors = const [];

  /// Direct replies (and quote-renotes) to the focal note.
  List<Note> _replies = const [];

  bool _loading = true;
  Object? _error;

  /// True when the note couldn't be re-anchored onto the account's
  /// server — we show the passed-in note alone plus a small notice.
  bool _conversationUnavailable = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var focal = widget.note;

      // Re-anchor a federated note so its id is valid on the
      // account's server. `resolveOnThisAccount` short-circuits when
      // the hosts already match, but we guard anyway to skip the
      // provider read in the common local case.
      var reanchorFailed = false;
      if (widget.note.sourceHost != widget.account.host) {
        try {
          final actions =
              await ref.read(noteActionsProvider(widget.account).future);
          final resolved = actions == null
              ? null
              : await actions.resolveOnThisAccount(widget.note);
          if (resolved == null) {
            reanchorFailed = true;
          } else {
            focal = resolved;
          }
        } catch (_) {
          reanchorFailed = true;
        }
      }
      if (reanchorFailed) {
        if (!mounted) return;
        setState(() {
          _focal = widget.note;
          _ancestors = const [];
          _replies = const [];
          _conversationUnavailable = true;
          _loading = false;
        });
        return;
      }

      final endpoints =
          await ref.read(misskeyEndpointsProvider(widget.account).future);
      if (endpoints == null) {
        throw StateError('No API client for ${widget.account.host}');
      }
      final results = await Future.wait([
        endpoints.notesConversation(noteId: focal.id),
        endpoints.notesChildren(noteId: focal.id),
      ]);
      if (!mounted) return;
      setState(() {
        _focal = focal;
        _ancestors = results[0].reversed.toList(growable: false);
        _replies = results[1];
        _conversationUnavailable = false;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (_focal != null) {
        // Refresh failure with content already on screen: keep the
        // stale thread visible and surface the error transiently.
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refresh failed: $e')),
        );
      } else {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thread')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final focal = _focal;
    if (focal == null) {
      if (!_loading && _error != null) return _errorView(context);
      return const Center(child: CircularProgressIndicator());
    }
    final theme = Theme.of(context);
    final replyCount = _replies.length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_conversationUnavailable)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The conversation couldn’t be fetched from '
                      '${widget.account.host}.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Ancestor context, oldest first, as flat stream rows with a
          // hairline rule between consecutive rows.
          for (var i = 0; i < _ancestors.length; i++) ...[
            if (i > 0) const PlusDivider(),
            _threadRow(_ancestors[i]),
          ],
          // Focal note: white card so it pops out of the stream.
          // Deliberately NOT tappable — it's the note being viewed.
          NoteCard(
            note: focal,
            attributionAccount: widget.account,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Text(
              replyCount > 0 ? 'Replies · $replyCount' : 'Replies',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_replies.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Text(
                'No replies yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var i = 0; i < _replies.length; i++) ...[
              if (i > 0) const PlusDivider(),
              _threadRow(_replies[i]),
            ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// A tappable flat stream row. Tapping re-opens the thread anchored
  /// on [note], so ancestors and replies are walkable to any depth.
  ///
  /// The [GestureDetector] carries its own semantics tap action;
  /// [NoteCard] provides the row's Semantics label, so screen readers
  /// announce the note and can activate it. Inner controls (avatar,
  /// action row, reaction pills) keep their own recognizers and win
  /// the gesture arena over the row tap.
  Widget _threadRow(Note note) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ThreadScreen.open(
        context,
        account: widget.account,
        note: note,
      ),
      child: NoteCard(
        key: ValueKey('thread:${note.globalId}'),
        note: note,
        attributionAccount: widget.account,
        stream: true,
      ),
    );
  }

  Widget _errorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            PlusButton.text(
              onTap: _load,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Retry'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
