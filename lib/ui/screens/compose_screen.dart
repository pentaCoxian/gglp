import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/note.dart';
import '../../misskey/models/note_channel.dart';
import '../../misskey/models/note_file.dart';
import '../../storage/app_database.dart';
import '../../storage/daos/draft_dao.dart';
import '../../timeline/note_actions_service.dart';
import '../plus/plus.dart';
import '../widgets/browse_channels_sheet.dart';
import '../widgets/compose_poll_editor.dart';
import '../widgets/mfm_input/mfm_emoji_autocomplete.dart';
import '../widgets/mfm_input/mfm_keyboard_shortcuts.dart';
import '../widgets/mfm_input/mfm_toolbar.dart';
import '../widgets/reactions/reaction_picker_sheet.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_display_name.dart';

/// Mode of the compose screen.
enum ComposeMode { post, reply, quote, channel }

/// Visibility option metadata for the picker menu.
class _VisibilityOption {
  final String value;
  final IconData icon;
  final String label;
  final String description;
  const _VisibilityOption(this.value, this.icon, this.label, this.description);
}

const _visibilities = <_VisibilityOption>[
  _VisibilityOption('public', Icons.public, 'Public', 'Visible to everyone'),
  _VisibilityOption(
    'home',
    Icons.home_outlined,
    'Home',
    'Only on the home timeline',
  ),
  _VisibilityOption(
    'followers',
    Icons.lock_outline,
    'Followers',
    'Only visible to your followers',
  ),
  _VisibilityOption(
    'specified',
    Icons.alternate_email,
    'Direct',
    'Only mentioned users',
  ),
];

/// One-screen compose surface.
///
/// Handles four flows (new post / reply / quote-renote / channel), with:
///   - account selector in the header (switch which account posts)
///   - channel picker in the toolbar (post mode), or a fixed channel
///     when opened from a channel timeline / replying to a channel note
///   - drafts panel (save / resume / delete) backed by Drift
///   - polished visibility menu, character counter, attachment grid
class ComposeScreen extends ConsumerStatefulWidget {
  final Account account;
  final ComposeMode mode;
  final Note? inReplyTo;
  final Note? renoteSource;

  /// Channel context for `ComposeMode.channel`. Both required when in
  /// channel mode so the post can be attributed to that channel and
  /// the screen can show its name in the context header. Channel ids
  /// are local to `account.host`, so the account is implicitly fixed
  /// in this mode.
  final String? channelId;
  final String? channelName;

  /// When set, the screen seeds itself from this draft and reuses its
  /// id on save so subsequent saves overwrite the same row.
  final String? draftId;

  const ComposeScreen({
    super.key,
    required this.account,
    this.mode = ComposeMode.post,
    this.inReplyTo,
    this.renoteSource,
    this.channelId,
    this.channelName,
    this.draftId,
  });

  /// Presents the composer as a white card layered over the current
  /// screen behind a 32% scrim — context is preserved, not
  /// navigated away from. Scale/translate enter per ; reduced
  /// motion degrades to a fade. Every call site (disc, reply, quote,
  /// channel, drafts) shares this route.
  static Future<bool?> open(
    BuildContext context, {
    required Account account,
    ComposeMode mode = ComposeMode.post,
    Note? inReplyTo,
    Note? renoteSource,
    String? channelId,
    String? channelName,
    String? draftId,
  }) {
    final plus = PlusTheme.of(context);
    return showGeneralDialog<bool>(
      context: context,
      useRootNavigator: true,
      // Dismissal must route through the discard-draft check, so the
      // barrier itself doesn't pop.
      barrierDismissible: false,
      barrierLabel: 'Compose',
      barrierColor: plus.scrimLight,
      transitionDuration: PlusMotion.dialog,
      pageBuilder:
          (_, __, ___) => _ComposeOverlayContainer(
            child: ComposeScreen(
              account: account,
              mode: mode,
              inReplyTo: inReplyTo,
              renoteSource: renoteSource,
              channelId: channelId,
              channelName: channelName,
              draftId: draftId,
            ),
          ),
      transitionBuilder: (ctx, animation, _, child) {
        if (MediaQuery.disableAnimationsOf(ctx)) {
          return FadeTransition(opacity: animation, child: child);
        }
        final t = CurvedAnimation(
          parent: animation,
          curve: PlusMotion.easeEnter,
          reverseCurve: PlusMotion.easeExit,
        );
        // Transform origin: the compose disc's corner on phones,
        // center when opened on a wide layout.
        final wide =
            MediaQuery.sizeOf(ctx).width >=
            PlusDims.composerMaxWidth + 2 * PlusSpacing.x4;
        return FadeTransition(
          opacity: t,
          child: AnimatedBuilder(
            animation: t,
            builder:
                (_, inner) => Transform.translate(
                  offset: Offset(0, PlusMotion.distSm * (1 - t.value)),
                  child: inner,
                ),
            child: ScaleTransition(
              scale: Tween(begin: PlusMotion.scaleEnter, end: 1.0).animate(t),
              alignment: wide ? Alignment.center : Alignment.bottomRight,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

/// Sizes and positions the composer card: 10px side margins on
/// phones with a near-full-height card that leaves the red bar
/// visible; centered with a 600px cap on wide layouts. This container
/// owns the keyboard inset (AnimatedPadding) and zeroes the inner
/// insets so the card's own Scaffold doesn't double-apply them.
class _ComposeOverlayContainer extends StatelessWidget {
  final Widget child;
  const _ComposeOverlayContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final plus = PlusTheme.of(context);
    final wide =
        mq.size.width >= PlusDims.composerMaxWidth + 2 * PlusSpacing.x4;
    final keyboardUp = mq.viewInsets.bottom > 0;
    return AnimatedPadding(
      duration: PlusMotion.control,
      curve: PlusMotion.easeStandard,
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            wide ? PlusSpacing.x4 : 10,
            // Keep the red application bar visible behind the scrim
            // — only a sliver of it while the keyboard
            // is up, when vertical space is the scarce resource.
            keyboardUp ? PlusSpacing.x3 : PlusDims.appBarMobile,
            wide ? PlusSpacing.x4 : 10,
            keyboardUp ? 0 : 10,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: PlusDims.composerMaxWidth,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PlusRadii.dialog),
                  boxShadow: plus.isDark ? null : plus.shadowDialog,
                  border: plus.isDark ? Border.all(color: plus.border) : null,
                ),
                clipBehavior: Clip.antiAlias,
                // The card already sits inside SafeArea, so the status
                // bar / notch padding must not leak into it: the inner
                // AppBar would otherwise add a second status-bar-high
                // blank band above "New note".
                child: MediaQuery(
                  data: mq.copyWith(
                    viewInsets: EdgeInsets.zero,
                    padding: EdgeInsets.zero,
                    viewPadding: EdgeInsets.zero,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  static const _maxNoteLength = 3000;

  final _text = TextEditingController();
  final _cw = TextEditingController();
  final _textFocus = FocusNode(debugLabel: 'compose-body');
  final _cwFocus = FocusNode(debugLabel: 'compose-cw');
  final _scroll = ScrollController();

  /// Snackbars stay inside the card: the app-level messenger would
  /// also show them on the timeline scaffold behind the scrim.
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  late Account _account;
  late String _draftId;
  bool _hasCw = false;
  String _visibility = 'public';
  bool _localOnly = false;
  bool _posting = false;
  bool _resolvingSource = false;

  /// Target channel, or null for the account's regular timelines.
  NoteChannel? _channel;

  /// True when the channel can't be changed here: opened from a
  /// channel timeline, or replying to / quoting a channel note (the
  /// server forces those into the source note's channel anyway).
  bool _channelLocked = false;

  /// Audience the user had picked before a channel was attached, so
  /// removing the channel restores it. Misskey forces channel notes
  /// to `public` + `localOnly`, so those two are inert while a channel
  /// is attached.
  String _preChannelVisibility = 'public';
  bool _preChannelLocalOnly = false;

  /// In-progress poll, or null when no poll is attached. Not persisted
  /// to drafts in v1.
  PollDraft? _poll;

  /// Live source-note state. These hold whichever Note is currently
  /// anchored to [_account]'s server — re-resolved on account switch
  /// and on draft resume.
  Note? _inReplyTo;
  Note? _renoteSource;

  /// Pending uploads. Each entry holds the local file path and the
  /// drive file id once the upload succeeds. Notes are posted using
  /// only the rows that have a server-side id.
  final List<_Attachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _draftId = widget.draftId ?? const Uuid().v4();
    _inReplyTo = widget.inReplyTo;
    _renoteSource = widget.renoteSource;
    final reply = _inReplyTo;
    if (reply != null) {
      _visibility = reply.visibility.name;
      // Pre-populate a `@user` mention so the reply is hooked up by
      // the recipient's mention list. Misskey itself does this on web.
      final author = reply.user;
      final handle =
          author.host == null
              ? '@${author.username}'
              : '@${author.username}@${author.host}';
      _text.text = '$handle ';
      _text.selection = TextSelection.collapsed(offset: _text.text.length);
    }
    if (widget.mode == ComposeMode.channel && widget.channelId != null) {
      _setChannel(
        NoteChannel(id: widget.channelId!, name: widget.channelName ?? ''),
        locked: true,
      );
    } else {
      // Replies and quotes inherit the source note's channel: Misskey
      // coerces cross-channel replies/renotes into the source's
      // channel server-side, so surface that instead of hiding it.
      final inherited = (_inReplyTo ?? _renoteSource)?.channel;
      if (inherited != null) _setChannel(inherited, locked: true);
    }
    if (widget.draftId != null) {
      _seedFromDraft(widget.draftId!);
    }
    _text.addListener(_onEdited);
    _cw.addListener(_onEdited);
    _textFocus.addListener(_onFocusChanged);
    _cwFocus.addListener(_onFocusChanged);
    // If we were opened with a source note already-anchored to a
    // *different* account (e.g. switched accounts before opening
    // compose), re-anchor it to the active account. Same code path
    // re-runs after an in-screen account switch.
    _ensureSourceAnchored();
  }

  @override
  void dispose() {
    _text.removeListener(_onEdited);
    _cw.removeListener(_onEdited);
    _textFocus.removeListener(_onFocusChanged);
    _cwFocus.removeListener(_onFocusChanged);
    _text.dispose();
    _cw.dispose();
    _textFocus.dispose();
    _cwFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Counter and publish state derive from controller text; one
  /// rebuild per change keeps them honest for programmatic edits
  /// (toolbar inserts, draft loads) too.
  void _onEdited() {
    if (mounted) setState(() {});
  }

  /// The formatting bar docks at the card's bottom edge while either
  /// field has the caret, targeting whichever one that is.
  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  /// Glue between the MFM toolbar's "emoji" button (and Ctrl/Cmd-J)
  /// and the existing reaction picker sheet. The picker returns either
  /// a unicode codepoint or a `:name:` / `:name@host:` string; either
  /// is valid as MFM body text. Inserts at the focused field's caret.
  Future<void> _openEmojiPickerForCompose({
    required TextEditingController target,
    required FocusNode focus,
  }) async {
    final key = await ReactionPickerSheet.show(context, account: _account);
    if (key == null || !mounted) return;
    final v = target.value;
    final at =
        v.selection.isValid && v.selection.isCollapsed
            ? v.selection.baseOffset
            : v.text.length;
    target.value = TextEditingValue(
      text: v.text.replaceRange(at, at, key),
      selection: TextSelection.collapsed(offset: at + key.length),
    );
    focus.requestFocus();
  }

  // ---------------------------------------------------------------
  // Channel
  // ---------------------------------------------------------------

  void _setChannel(NoteChannel? channel, {bool locked = false}) {
    if (channel != null && _channel == null) {
      _preChannelVisibility = _visibility;
      _preChannelLocalOnly = _localOnly;
    }
    _channel = channel;
    _channelLocked = channel != null && locked;
    if (channel != null) {
      // Channel notes are public within the channel and never
      // federate; the server enforces both, so show the truth.
      _visibility = 'public';
      _localOnly = true;
    } else {
      _visibility = _preChannelVisibility;
      _localOnly = _preChannelLocalOnly;
    }
  }

  Future<void> _pickChannel() async {
    if (_channelLocked || _posting) return;
    final picked = await BrowseChannelsSheet.pick(
      context,
      account: _account,
      selectedChannelId: _channel?.id,
    );
    if (picked == null || !mounted) return;
    setState(() => _setChannel(picked));
  }

  /// Toolbar `#` button: opens the picker when no channel is set,
  /// otherwise a change / remove menu anchored to the button.
  Future<void> _channelButtonTapped(BuildContext anchor) async {
    if (_channelLocked || _posting) return;
    if (_channel == null) {
      await _pickChannel();
      return;
    }
    final action = await showPlusMenu<String>(
      context: context,
      position: plusMenuPosition(anchor),
      items: [
        PlusMenuItem(
          label: 'Change channel…',
          value: 'change',
          icon: Icons.swap_horiz,
        ),
        PlusMenuItem(
          label: 'Remove channel',
          value: 'clear',
          icon: Icons.close,
          destructive: true,
        ),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case 'change':
        await _pickChannel();
      case 'clear':
        setState(() => _setChannel(null));
    }
  }

  // ---------------------------------------------------------------
  // Drafts
  // ---------------------------------------------------------------

  Future<void> _seedFromDraft(String id) async {
    final dao = ref.read(draftDaoProvider);
    final row = await dao.get(id);
    if (row == null || !mounted) return;
    setState(() => _applyDraft(row));
    await _restoreSourceFromDraft(row);
  }

  /// Copies a stored draft into the editor. Shared by the `draftId`
  /// entry point and the drafts sheet so both restore the same set of
  /// fields (text, CW, audience, channel, uploaded attachments).
  void _applyDraft(DraftRow row) {
    _draftId = row.id;
    _text.text = row.body ?? '';
    _cw.text = row.cw ?? '';
    _hasCw = row.cw != null && row.cw!.isNotEmpty;
    _visibility = row.visibility;
    _localOnly = row.localOnly;
    // Clear stale source-note objects in case the previous draft
    // was a reply but this one is a top-level post (or vice versa).
    _inReplyTo = null;
    _renoteSource = null;
    if (!_channelLocked) {
      _channel = null;
      final channelId = row.channelId;
      if (channelId != null && channelId.isNotEmpty) {
        _setChannel(NoteChannel(id: channelId, name: row.channelName ?? ''));
      }
    }
    // Pre-existing drive file ids from the draft come back as
    // already-uploaded chips with no preview path.
    _attachments
      ..clear()
      ..addAll(
        DraftDao.decodeFileIds(
          row.fileIdsJson,
        ).map((id) => _Attachment.fromExisting(driveId: id)),
      );
  }

  /// Re-fetch the reply/quote source note that this draft is linked
  /// to, so the context header reappears and a subsequent post still
  /// targets the right note. Uses ap/show when the draft was authored
  /// from a different account, falling back to notes/show for the
  /// same-server case.
  Future<void> _restoreSourceFromDraft(DraftRow row) async {
    final replyId = row.replyId;
    final renoteId = row.renoteId;
    final hasReply = replyId != null && replyId.isNotEmpty;
    final hasRenote = renoteId != null && renoteId.isNotEmpty;
    if (!hasReply && !hasRenote) return;

    setState(() => _resolvingSource = true);
    try {
      final actions = await ref.read(noteActionsProvider(_account).future);
      if (actions == null) return;
      Note? resolved;
      // Same-account fast path: the stored id is local to us.
      if (row.sourceHost != null && row.sourceHost == _account.host) {
        final id = hasReply ? replyId : renoteId!;
        resolved = await actions.notesShow(id);
      } else if (row.sourceNoteUri != null) {
        // Cross-account or unknown — re-resolve via ActivityPub.
        try {
          resolved = await actions.resolveByUri(row.sourceNoteUri!);
        } catch (_) {
          resolved = null;
        }
      }

      if (!mounted) return;
      if (resolved == null) {
        _toast('Source note no longer available; reply/quote link cleared.');
        return;
      }
      setState(() {
        if (hasReply) {
          _inReplyTo = resolved;
        } else {
          _renoteSource = resolved;
        }
      });
    } finally {
      if (mounted) setState(() => _resolvingSource = false);
    }
  }

  bool get _canSubmit {
    if (_posting) return false;
    final hasText = _text.text.trim().isNotEmpty;
    final hasMedia = _attachments.any((a) => a.driveId != null);
    final isPureRenote = _renoteSource != null && !hasText && !hasMedia;
    // A pure renote with no commentary IS valid (the picker uses
    // ComposeMode.quote when that's intended).
    if (_renoteSource != null && widget.mode != ComposeMode.quote) {
      return true;
    }
    if (isPureRenote && widget.mode == ComposeMode.quote) return false;
    return hasText || hasMedia;
  }

  /// Account switching is allowed in every mode, but in reply/quote it
  /// triggers a source-note re-resolution against the new account
  /// before the switch is committed.
  /// Channel ids are local to a server, so switching accounts with a
  /// channel attached would silently lose the binding: lock the
  /// account while a channel is set (remove the channel first).
  bool get _canSwitchAccount =>
      !_posting && !_resolvingSource && _channel == null;

  /// On open / resume / account-switch, ensure the in-reply-to /
  /// renote source note is keyed against the active account's server.
  /// If it isn't, call ap/show to re-anchor it. Drops the link with a
  /// warning if the new account can't see the note (federation
  /// blocked, instance offline, etc.).
  Future<void> _ensureSourceAnchored() async {
    final source = _inReplyTo ?? _renoteSource;
    if (source == null) return;
    if (source.sourceHost == _account.host) return;
    setState(() => _resolvingSource = true);
    try {
      final actions = await ref.read(noteActionsProvider(_account).future);
      if (actions == null) {
        _toast('No client for ${_account.host}');
        return;
      }
      final resolved = await actions.resolveOnThisAccount(source);
      if (!mounted) return;
      if (resolved == null) {
        // The new account can't resolve the source — drop the link
        // gracefully so the user can still post without crashing.
        setState(() {
          _inReplyTo = null;
          _renoteSource = null;
        });
        _toast(
          "${_account.host} can't see this note. Reply/quote link removed.",
        );
        return;
      }
      setState(() {
        if (_inReplyTo != null) _inReplyTo = resolved;
        if (_renoteSource != null) _renoteSource = resolved;
      });
    } catch (e) {
      _toast('Could not re-anchor source note: $e');
    } finally {
      if (mounted) setState(() => _resolvingSource = false);
    }
  }

  bool get _hasAnyContent =>
      _text.text.trim().isNotEmpty ||
      _cw.text.trim().isNotEmpty ||
      _attachments.isNotEmpty ||
      _poll != null;

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    final title = switch (widget.mode) {
      ComposeMode.post => 'New note',
      ComposeMode.reply => 'Reply',
      ComposeMode.quote => 'Quote',
      ComposeMode.channel =>
        widget.channelName == null || widget.channelName!.isEmpty
            ? 'New channel note'
            : 'Post to #${widget.channelName}',
    };
    final remaining = _maxNoteLength - _text.text.length;
    final cwActive = _hasCw && _cwFocus.hasFocus;
    // System back / Esc route through the discard-draft check instead
    // of silently dropping in-progress text.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_posting) _maybeAbandon();
      },
      child: ScaffoldMessenger(
        key: _messenger,
        child: Scaffold(
          // The composer is one white card — its header belongs
          // to the card, not to the global red chrome.
          appBar: AppBar(
            backgroundColor: plus.surface,
            foregroundColor: plus.textPrimary,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: plus.textSecondary),
            actionsIconTheme: IconThemeData(color: plus.textSecondary),
            titleTextStyle: theme.textTheme.titleLarge,
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: _posting ? null : _maybeAbandon,
            ),
            actions: [
              if (widget.mode == ComposeMode.post)
                IconButton(
                  tooltip: 'Drafts',
                  icon: const Icon(Icons.drafts_outlined),
                  onPressed: _posting ? null : _showDrafts,
                ),
              IconButton(
                tooltip: 'Save draft',
                icon: const Icon(Icons.save_outlined),
                onPressed: _posting || !_hasAnyContent ? null : _saveDraft,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                // Publish CTA: gray while invalid, share-green
                // when publishable. Centered because AppBar stretches
                // its action row.
                child: Center(
                  child: PlusButton.publish(
                    onTap: _canSubmit ? _submit : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    tooltip: 'Post',
                    semanticLabel: 'Post',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_posting)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(Icons.send, size: 16),
                        const SizedBox(width: 6),
                        const Text('Post'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _AccountChip(
                account: _account,
                enabled: _canSwitchAccount,
                onTap: _canSwitchAccount ? _pickAccount : null,
              ),
              const PlusDivider(),
              Expanded(child: _buildBody(theme)),
              const PlusDivider(),
              _Toolbar(
                visibility: _visibility,
                localOnly: _localOnly,
                hasCw: _hasCw,
                hasPoll: _poll != null,
                channel: _channel,
                channelLocked: _channelLocked,
                remainingChars: remaining,
                onPickImage: _posting ? null : _pickImage,
                onToggleCw: _posting ? null : _toggleCw,
                onTogglePoll: _posting ? null : _togglePoll,
                onChannelTap:
                    _posting || _channelLocked ? null : _channelButtonTapped,
                // Visibility + local-only are inert while a channel is
                // attached — channel notes are inherently public and
                // never federate (the server enforces both).
                onChangeVisibility:
                    _posting || _channel != null
                        ? null
                        : (v) => setState(() => _visibility = v),
                onToggleLocalOnly:
                    _posting || _channel != null
                        ? null
                        : () => setState(() => _localOnly = !_localOnly),
              ),
              // MFM formatting bar, docked at the card's bottom edge (so
              // it sits flush against the keyboard) while a field has
              // the caret. Living inside the card — rather than as a
              // root-overlay entry — keeps it from covering the toolbar
              // above it and from floating at the window bottom on
              // desktop, detached from the composer.
              AnimatedSize(
                duration: PlusMotion.control,
                curve: PlusMotion.easeStandard,
                alignment: Alignment.topCenter,
                child:
                    !(_textFocus.hasFocus || (_hasCw && _cwFocus.hasFocus))
                        ? const SizedBox(width: double.infinity)
                        : MfmToolbar(
                          controller: cwActive ? _cw : _text,
                          account: _account,
                          // CW is a single line — drop block-level
                          // actions (code-block, blockquote) which would
                          // push content onto a new line.
                          actions:
                              cwActive
                                  ? kInlineMfmToolbarActions
                                  : kAllMfmToolbarActions,
                          dense: cwActive,
                          onOpenEmojiPicker:
                              () => _openEmojiPickerForCompose(
                                target: cwActive ? _cw : _text,
                                focus: cwActive ? _cwFocus : _textFocus,
                              ),
                          // Re-focus before mutating so the keyboard
                          // stays up.
                          onBeforeAction:
                              (cwActive ? _cwFocus : _textFocus).requestFocus,
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Editor region. Looks like the original expanding field, but the
  /// text field grows with its content inside a scroll view: a poll
  /// editor and attachment strip below it then flow with the text
  /// instead of squeezing the body to zero (or overflowing) when the
  /// keyboard is up. The empty area below still focuses the body.
  Widget _buildBody(ThemeData theme) {
    final hint = switch (widget.mode) {
      ComposeMode.reply => "What's your reply?",
      ComposeMode.quote => 'Add commentary…',
      ComposeMode.post =>
        _channel == null
            ? "What's on your mind?"
            : "What's happening in #${_channel!.name}?",
      ComposeMode.channel =>
        widget.channelName == null || widget.channelName!.isEmpty
            ? 'Post to channel…'
            : "What's happening in #${widget.channelName}?",
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        const pad = EdgeInsets.fromLTRB(16, 12, 16, 8);
        final minHeight = (constraints.maxHeight - pad.vertical).clamp(
          0.0,
          double.infinity,
        );
        return SingleChildScrollView(
          controller: _scroll,
          padding: pad,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _posting ? null : _textFocus.requestFocus,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_channel != null)
                    _ChannelBanner(
                      channel: _channel!,
                      locked: _channelLocked,
                      onTap:
                          _channelLocked || _posting
                              ? null
                              : (anchor) => _channelButtonTapped(anchor),
                      onRemove:
                          _channelLocked || _posting
                              ? null
                              : () => setState(() => _setChannel(null)),
                    ),
                  _ContextHeader(
                    mode: widget.mode,
                    inReplyTo: _inReplyTo,
                    renoteSource: _renoteSource,
                    resolving: _resolvingSource,
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child:
                        _hasCw
                            ? Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: MfmKeyboardShortcuts(
                                controller: _cw,
                                onOpenEmojiPicker:
                                    () => _openEmojiPickerForCompose(
                                      target: _cw,
                                      focus: _cwFocus,
                                    ),
                                child: MfmEmojiAutocomplete(
                                  account: _account,
                                  controller: _cw,
                                  focusNode: _cwFocus,
                                  // Underline field; the amber warning
                                  // icon carries the CW accent.
                                  child: TextField(
                                    controller: _cw,
                                    focusNode: _cwFocus,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      prefixIcon: Icon(
                                        Icons.warning_amber_outlined,
                                        color: PlusTheme.of(context).warning,
                                      ),
                                      hintText: 'Content warning',
                                    ),
                                    maxLines: 1,
                                    enabled: !_posting,
                                    textInputAction: TextInputAction.next,
                                    onSubmitted:
                                        (_) => _textFocus.requestFocus(),
                                  ),
                                ),
                              ),
                            )
                            : const SizedBox.shrink(),
                  ),
                  MfmKeyboardShortcuts(
                    controller: _text,
                    onOpenEmojiPicker:
                        () => _openEmojiPickerForCompose(
                          target: _text,
                          focus: _textFocus,
                        ),
                    child: MfmEmojiAutocomplete(
                      account: _account,
                      controller: _text,
                      focusNode: _textFocus,
                      // Bare body field on the white card (
                      // "Write something…" sits directly on the
                      // composer surface, no framed well).
                      child: TextField(
                        controller: _text,
                        focusNode: _textFocus,
                        decoration: InputDecoration(
                          hintText: hint,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        style: theme.textTheme.bodyLarge,
                        minLines: 3,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        enabled: !_posting,
                        autofocus: widget.mode != ComposeMode.post,
                      ),
                    ),
                  ),
                  if (_poll != null) ...[
                    const SizedBox(height: 12),
                    ComposePollEditor(
                      draft: _poll!,
                      onChanged: () => setState(() {}),
                      onRemove: () => setState(() => _poll = null),
                    ),
                  ],
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _AttachmentRow(
                      attachments: _attachments,
                      onRemove: _removeAttachment,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleCw() {
    setState(() {
      _hasCw = !_hasCw;
      if (_hasCw) {
        _cwFocus.requestFocus();
      } else if (_cwFocus.hasFocus) {
        // Don't leave focus on a field that's about to unmount.
        _textFocus.requestFocus();
      }
    });
  }

  void _togglePoll() {
    setState(() {
      _poll =
          _poll == null
              ? PollDraft(
                choices: ['', ''],
                multiple: false,
                expiresAfter: null,
              )
              : null;
    });
  }

  Future<void> _pickAccount() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? const [];
    if (accounts.length <= 1) {
      _toast('Only one account is logged in — add another from the menu.');
      return;
    }
    final picked = await showModalBottomSheet<Account>(
      context: context,
      showDragHandle: true,
      builder:
          (_) => _AccountPickerSheet(accounts: accounts, current: _account),
    );
    if (picked != null && picked.id != _account.id && mounted) {
      setState(() {
        _account = picked;
        // A new account means a new draft id (drafts are per-account).
        _draftId = const Uuid().v4();
      });
      // Re-anchor the in-reply-to / quote source onto the new account's
      // server. This is the whole reason cross-account compose works.
      await _ensureSourceAnchored();
    }
  }

  Future<void> _maybeAbandon() async {
    if (!_hasAnyContent) {
      Navigator.of(context).pop(false);
      return;
    }
    final action = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Discard or save?'),
            content: const Text('Your in-progress note has unsaved changes.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('cancel'),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('discard'),
                child: const Text('Discard'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('save'),
                child: const Text('Save draft'),
              ),
            ],
          ),
    );
    if (!mounted) return;
    if (action == null || action == 'cancel') return;
    if (action == 'save') {
      await _saveDraft(announce: false);
    }
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<void> _saveDraft({bool announce = true}) async {
    final dao = ref.read(draftDaoProvider);
    final fileIds = _attachments
        .map((a) => a.driveId)
        .whereType<String>()
        .toList(growable: false);
    final source = _inReplyTo ?? _renoteSource;
    await dao.upsert(
      id: _draftId,
      accountId: _account.id,
      text: _text.text.trim().isEmpty ? null : _text.text,
      cw: _hasCw && _cw.text.trim().isNotEmpty ? _cw.text : null,
      visibility: _visibility,
      localOnly: _localOnly,
      replyId: _inReplyTo?.id,
      renoteId: _renoteSource?.id,
      // Persist the canonical AP URI + the host the ids were issued
      // from so a future resume on a different account can re-resolve
      // the source note via ap/show.
      sourceNoteUri: source?.originId,
      sourceHost: source?.sourceHost,
      fileIds: fileIds.isEmpty ? null : fileIds,
      channelId: _channel?.id,
      channelName: _channel?.name,
    );
    if (announce && mounted) _toast('Draft saved');
  }

  Future<void> _showDrafts() async {
    final picked = await showModalBottomSheet<DraftRow>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _DraftsSheet(accountId: _account.id),
    );
    if (picked == null || !mounted) return;
    setState(() => _applyDraft(picked));
    // Re-fetch the linked source note (if any) so the context header
    // reappears and the post correctly threads as a reply or quote.
    await _restoreSourceFromDraft(picked);
  }

  /// Open the platform's native file selector. Multi-select; filters
  /// to common media MIME types but the user can fall back to any
  /// file (Misskey accepts any drive file).
  ///
  /// Uses Storage Access Framework on Android (no runtime permission
  /// needed regardless of API level), the system file browser on
  /// iOS/macOS, and the native file dialog on desktop.
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: true,
        // We read the bytes ourselves before uploading; turning this
        // off saves memory because file_picker would otherwise keep
        // an in-memory copy too.
        withData: false,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final newAttachments = <_Attachment>[];
      for (final f in result.files) {
        final path = f.path;
        if (path == null) continue;
        newAttachments.add(_Attachment(path: path, name: f.name));
      }
      if (newAttachments.isEmpty) return;
      setState(() => _attachments.addAll(newAttachments));
      // Upload concurrently — drive uploads dominate compose latency.
      await Future.wait(newAttachments.map(_uploadAttachment));
    } catch (e) {
      _toast('Pick failed: $e');
    }
  }

  Future<void> _uploadAttachment(_Attachment att) async {
    final actions = await ref.read(noteActionsProvider(_account).future);
    if (!mounted) return;
    if (actions == null) {
      _toast('No client for ${_account.host}');
      // Don't leave a chip spinning forever with nothing behind it.
      setState(() => _attachments.remove(att));
      return;
    }
    try {
      final bytes = await File(att.path!).readAsBytes();
      final result = await actions.uploadFile(
        bytes: bytes,
        filename: att.name ?? 'upload',
        contentType: _guessMime(att.name ?? ''),
      );
      if (!mounted) return;
      setState(() {
        att.driveId = result.id;
        att.driveFile = result;
      });
    } catch (e) {
      _toast('Upload failed: $e');
      if (mounted) setState(() => _attachments.remove(att));
    }
  }

  void _removeAttachment(int i) {
    setState(() => _attachments.removeAt(i));
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (_poll != null && !_poll!.isValid) {
      _toast('Poll needs at least 2 choices.');
      return;
    }
    setState(() => _posting = true);
    try {
      final actions = await ref.read(noteActionsProvider(_account).future);
      if (actions == null) {
        _toast('No client for ${_account.host}');
        return;
      }
      final fileIds = _attachments
          .map((a) => a.driveId)
          .whereType<String>()
          .toList(growable: false);
      await actions.create(
        text: _text.text.trim().isEmpty ? null : _text.text.trim(),
        cw: _hasCw && _cw.text.trim().isNotEmpty ? _cw.text.trim() : null,
        visibility: _visibility,
        localOnly: _localOnly,
        // Always the *re-anchored* ids: after an account switch or a
        // draft resume the widget's originals point at another server.
        replyId: _inReplyTo?.id,
        renoteId: _renoteSource?.id,
        channelId: _channel?.id,
        fileIds: fileIds.isEmpty ? null : fileIds,
        poll: _poll != null && _poll!.isValid ? _poll!.toParams() : null,
      );
      // Posted successfully — drop the draft if we had one.
      await ref.read(draftDaoProvider).removeById(_draftId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _toast('Post failed: $e');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    _messenger.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  static String? _guessMime(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return null;
  }
}

class _Attachment {
  final String? path;
  final String? name;
  String? driveId;
  NoteFile? driveFile;
  _Attachment({required this.path, required this.name});
  _Attachment.fromExisting({required this.driveId}) : path = null, name = null;
}

// -------------------------------------------------------------------
// Identity strip
// -------------------------------------------------------------------

class _AccountChip extends StatelessWidget {
  final Account account;
  final bool enabled;
  final VoidCallback? onTap;
  const _AccountChip({
    required this.account,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = Row(
      children: [
        UserAvatar(
          url: account.avatarUrl,
          seed: account.displayName ?? account.username,
          radius: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Posting as',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              UserDisplayName(
                name: account.displayName ?? account.username,
                viewerHost: account.host,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                '@${account.username}@${account.host}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (enabled) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.swap_horiz,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
    // Flat identity strip: tappable (ink) while the account can be
    // switched, inert when locked (channel attached / posting).
    const chipPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    final body = Padding(padding: chipPadding, child: row);
    return onTap == null
        ? body
        : Material(
          type: MaterialType.transparency,
          child: Semantics(
            label: 'Switch posting account',
            button: true,
            child: InkWell(onTap: onTap, child: body),
          ),
        );
  }
}

// -------------------------------------------------------------------
// Sheets
// -------------------------------------------------------------------

class _AccountPickerSheet extends StatelessWidget {
  final List<Account> accounts;
  final Account current;
  const _AccountPickerSheet({required this.accounts, required this.current});

  @override
  Widget build(BuildContext context) {
    final free =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: free * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Switch poster',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            // Scrolls once the account list outgrows the sheet.
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: accounts.length,
                itemBuilder: (_, i) {
                  final a = accounts[i];
                  return ListTile(
                    leading: UserAvatar(
                      url: a.avatarUrl,
                      seed: a.displayName ?? a.username,
                      radius: 18,
                    ),
                    title: UserDisplayName(
                      name: a.displayName ?? a.username,
                      viewerHost: a.host,
                    ),
                    subtitle: Text(
                      '@${a.username}@${a.host}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing:
                        a.id == current.id
                            ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                            : null,
                    onTap: () => Navigator.of(context).pop(a),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DraftsSheet extends ConsumerWidget {
  final String accountId;
  const _DraftsSheet({required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(draftDaoProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder:
          (_, scroll) => StreamBuilder<List<DraftRow>>(
            stream: dao.watchForAccount(accountId),
            builder: (context, snap) {
              final rows = snap.data ?? const [];
              // Every branch must consume the sheet's scroll controller
              // — otherwise the sheet can't be dragged and a fixed
              // empty state overflows on short phones.
              Widget filler(Widget child) => LayoutBuilder(
                builder:
                    (_, c) => SingleChildScrollView(
                      controller: scroll,
                      child: SizedBox(
                        height: c.maxHeight,
                        child: Center(child: child),
                      ),
                    ),
              );
              if (snap.connectionState == ConnectionState.waiting) {
                return filler(const CircularProgressIndicator());
              }
              if (rows.isEmpty) {
                return filler(
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.drafts_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No drafts yet.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hit save while composing to keep a note for later.',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${rows.length} draft${rows.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      controller: scroll,
                      itemCount: rows.length,
                      separatorBuilder:
                          (_, __) => const PlusDivider(
                            margin: EdgeInsets.symmetric(horizontal: 16),
                          ),
                      itemBuilder: (_, i) {
                        final row = rows[i];
                        return _DraftTile(
                          row: row,
                          onTap: () => Navigator.of(context).pop(row),
                          onDelete: () => dao.removeById(row.id),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }
}

class _DraftTile extends StatelessWidget {
  final DraftRow row;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _DraftTile({
    required this.row,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    final preview = (row.body ?? '').trim();
    final cw = (row.cw ?? '').trim();
    final channelName = (row.channelName ?? '').trim();
    final hasChannel = (row.channelId ?? '').isNotEmpty;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        hasChannel ? Icons.tag : _iconForVisibility(row.visibility),
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        preview.isEmpty ? '(empty)' : preview,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style:
            preview.isEmpty
                ? theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                )
                : theme.textTheme.bodyMedium,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cw.isNotEmpty)
            Text(
              'CW: $cw',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: plus.warning),
            ),
          Text(
            hasChannel
                ? '${_relative(row.updatedAt)} · '
                    '#${channelName.isEmpty ? 'channel' : channelName}'
                : _relative(row.updatedAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: PlusIconButton(
        icon: Icons.delete_outline,
        tooltip: 'Delete draft',
        onTap: onDelete,
      ),
    );
  }

  static IconData _iconForVisibility(String v) {
    return _visibilities
        .firstWhere((o) => o.value == v, orElse: () => _visibilities.first)
        .icon;
  }

  static String _relative(DateTime t) {
    final delta = DateTime.now().difference(t);
    if (delta.inSeconds < 60) return 'just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes}m ago';
    if (delta.inHours < 24) return '${delta.inHours}h ago';
    if (delta.inDays < 7) return '${delta.inDays}d ago';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
}

// -------------------------------------------------------------------
// Attachments
// -------------------------------------------------------------------

class _AttachmentRow extends StatelessWidget {
  final List<_Attachment> attachments;
  final void Function(int) onRemove;
  const _AttachmentRow({required this.attachments, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder:
            (_, i) => _AttachmentChip(
              attachment: attachments[i],
              onRemove: () => onRemove(i),
            ),
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final _Attachment attachment;
  final VoidCallback onRemove;
  const _AttachmentChip({required this.attachment, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = attachment.driveId != null;
    final hasLocal = attachment.path != null;
    final placeholder = Container(
      width: 80,
      height: 80,
      color: theme.colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        // Everything stays inside the 80px tile, so the horizontal
        // list's viewport never clips the remove button.
        clipBehavior: Clip.hardEdge,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(PlusRadii.media),
            child:
                hasLocal
                    ? Image.file(
                      File(attachment.path!),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => placeholder,
                    )
                    : placeholder,
          ),
          if (!ready)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onRemove,
                child: const Tooltip(
                  message: 'Remove attachment',
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// Context banners
// -------------------------------------------------------------------

/// Recessed tag-style banner (accent lives in the icon/text, not a
/// tinted fill) telling the user their post goes into a specific
/// channel and not their main timeline. Tap to change, `×` to remove;
/// both are absent when the channel is fixed.
class _ChannelBanner extends StatelessWidget {
  final NoteChannel channel;
  final bool locked;
  final void Function(BuildContext anchor)? onTap;
  final VoidCallback? onRemove;
  const _ChannelBanner({
    required this.channel,
    required this.locked,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    final accent = parseChannelColor(channel.color) ?? theme.colorScheme.primary;
    final name = channel.name.isEmpty ? 'channel' : channel.name;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: plus.surfaceSubtle,
        borderRadius: BorderRadius.circular(PlusRadii.card),
        border: Border.all(color: plus.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Builder(
          builder:
              (anchor) => InkWell(
                onTap: onTap == null ? null : () => onTap!(anchor),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 10, onRemove == null ? 12 : 4, 10),
                  child: Row(
                    children: [
                      Icon(Icons.tag, size: 14, color: accent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Posting to #$name',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (locked)
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: plus.textTertiary,
                        )
                      else if (onRemove != null)
                        PlusIconButton(
                          icon: Icons.close,
                          size: 16,
                          tooltip: 'Remove channel',
                          onTap: onRemove,
                        ),
                    ],
                  ),
                ),
              ),
        ),
      ),
    );
  }
}

class _ContextHeader extends StatelessWidget {
  final ComposeMode mode;
  final Note? inReplyTo;
  final Note? renoteSource;

  /// True while the source note is being re-anchored on the active
  /// account (after a switch or draft resume). Surfaces a small
  /// banner so the user understands why the link's gone momentarily.
  final bool resolving;

  const _ContextHeader({
    required this.mode,
    this.inReplyTo,
    this.renoteSource,
    this.resolving = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    final isReply = inReplyTo != null || mode == ComposeMode.reply;
    // Reply context is blue, quote context is renote-green.
    final accent = isReply ? theme.colorScheme.primary : plus.renote;
    final decoration = BoxDecoration(
      color: plus.surfaceSubtle,
      borderRadius: BorderRadius.circular(PlusRadii.card),
      border: Border.all(color: plus.border),
    );

    // While we're resolving and don't have a Note object yet, render
    // a placeholder strip in the same chrome so the layout doesn't
    // jump around when the resolve completes.
    if (resolving && inReplyTo == null && renoteSource == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: decoration,
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: accent),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Re-anchoring source note…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: accent),
              ),
            ),
          ],
        ),
      );
    }

    final note = inReplyTo ?? renoteSource;
    if (note == null) return const SizedBox.shrink();
    final author = note.user;
    final handle =
        author.host == null
            ? '@${author.username}'
            : '@${author.username}@${author.host}';
    final preview = note.text ?? '';
    // Flat bordered context box — the reply/quote source reads as an
    // inset document, with the accent on icon and text.
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isReply ? Icons.reply : Icons.format_quote,
                size: 14,
                color: accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isReply ? 'Replying to $handle' : 'Quoting $handle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (resolving)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: accent,
                  ),
                ),
            ],
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// Bottom toolbar
// -------------------------------------------------------------------

class _Toolbar extends StatelessWidget {
  final String visibility;
  final bool localOnly;
  final bool hasCw;
  final bool hasPoll;
  final NoteChannel? channel;
  final bool channelLocked;
  final int remainingChars;
  final VoidCallback? onPickImage;
  final VoidCallback? onToggleCw;
  final VoidCallback? onTogglePoll;
  final VoidCallback? onToggleLocalOnly;
  final void Function(BuildContext anchor)? onChannelTap;
  final ValueChanged<String>? onChangeVisibility;

  const _Toolbar({
    required this.visibility,
    required this.localOnly,
    required this.hasCw,
    required this.hasPoll,
    required this.channel,
    required this.channelLocked,
    required this.remainingChars,
    required this.onPickImage,
    required this.onToggleCw,
    required this.onTogglePoll,
    required this.onToggleLocalOnly,
    required this.onChannelTap,
    required this.onChangeVisibility,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    final option = _visibilities.firstWhere(
      (o) => o.value == visibility,
      orElse: () => _visibilities.first,
    );
    final overLimit = remainingChars < 0;
    final nearLimit = !overLimit && remainingChars < 100;
    final counterColor =
        overLimit
            ? plus.danger
            : nearLimit
            ? plus.warning
            : plus.textTertiary;
    final hasChannel = channel != null;
    final channelAccent =
        hasChannel
            ? (parseChannelColor(channel!.color) ?? plus.selected)
            : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Row(
        children: [
          // Actions + visibility scroll as one group on narrow phones
          // (five 48px targets plus the visibility chip don't fit in
          // 320px); the counter stays pinned at the right edge.
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlusIconButton(
                    icon: Icons.image_outlined,
                    tooltip: 'Add image',
                    onTap: onPickImage,
                  ),
                  // Poll toggle: blue while a poll is attached.
                  PlusIconButton(
                    icon: Icons.poll_outlined,
                    tooltip: hasPoll ? 'Remove poll' : 'Add poll',
                    selected: hasPoll,
                    onTap: onTogglePoll,
                  ),
                  // CW toggle: amber while a content warning is attached.
                  PlusIconButton(
                    icon:
                        hasCw
                            ? Icons.warning_amber
                            : Icons.warning_amber_outlined,
                    tooltip:
                        hasCw ? 'Remove content warning' : 'Add content warning',
                    selected: hasCw,
                    selectedColor: plus.warning,
                    onTap: onToggleCw,
                  ),
                  // Local-only flag: amber while federation is off.
                  // Forced on (and inert) while a channel is attached.
                  PlusIconButton(
                    icon: localOnly ? Icons.public_off : Icons.public,
                    tooltip:
                        hasChannel
                            ? "Channel notes don't federate"
                            : localOnly
                            ? "Local-only on (won't federate)"
                            : 'Allow federation',
                    selected: localOnly,
                    selectedColor: plus.localOnly,
                    color: hasChannel ? plus.localOnly : null,
                    onTap: onToggleLocalOnly,
                  ),
                  // Channel picker: tinted with the channel colour while
                  // one is attached; a lock stands in when it's fixed.
                  Builder(
                    builder:
                        (anchor) => PlusIconButton(
                          icon: hasChannel ? Icons.tag : Icons.tag,
                          tooltip:
                              !hasChannel
                                  ? 'Post to channel'
                                  : channelLocked
                                  ? 'Channel fixed: #${channel!.name}'
                                  : 'Change or remove channel',
                          selected: hasChannel,
                          selectedColor: channelAccent,
                          color: hasChannel ? channelAccent : null,
                          onTap:
                              onChannelTap == null
                                  ? null
                                  : () => onChannelTap!(anchor),
                        ),
                  ),
                  const SizedBox(width: 4),
                  // Visibility is expressed as icon + text, opening
                  // the standard anchored menu. Inert while a channel is
                  // attached (channel notes are always public).
                  PopupMenuButton<String>(
                    tooltip:
                        hasChannel
                            ? 'Channel notes are public within the channel'
                            : 'Visibility',
                    enabled: onChangeVisibility != null,
                    onSelected: onChangeVisibility,
                    itemBuilder:
                        (_) => [
                          for (final opt in _visibilities)
                            PopupMenuItem(
                              value: opt.value,
                              child: Row(
                                children: [
                                  Icon(
                                    opt.icon,
                                    size: 18,
                                    color: plus.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          opt.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          opt.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: plus.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (opt.value == visibility)
                                    Icon(
                                      Icons.check,
                                      size: 16,
                                      color: plus.selected,
                                    ),
                                ],
                              ),
                            ),
                        ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: plus.surfaceSubtle,
                        borderRadius: BorderRadius.circular(PlusRadii.chip),
                        border: Border.all(color: plus.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            option.icon,
                            size: 16,
                            color:
                                onChangeVisibility == null
                                    ? plus.textTertiary
                                    : plus.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            option.label,
                            maxLines: 1,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color:
                                  onChangeVisibility == null
                                      ? plus.textTertiary
                                      : plus.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color:
                                onChangeVisibility == null
                                    ? plus.textTertiary
                                    : plus.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Character counter.
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 4),
            child: Text(
              '$remainingChars',
              style: theme.textTheme.labelMedium?.copyWith(
                color: counterColor,
                fontFeatures: const [FontFeature.tabularFigures()],
                fontWeight: nearLimit || overLimit ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
