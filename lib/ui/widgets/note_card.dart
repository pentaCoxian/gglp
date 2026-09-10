import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/settings/settings_controller.dart';
import '../../mfm/ast.dart';
import '../../mfm/parser.dart';
import '../../mfm/renderer.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/note.dart';
import '../../misskey/models/note_channel.dart';
import '../../misskey/models/reaction.dart';
import '../../timeline/note_actions_service.dart';
import '../plus/plus.dart';
import 'sensitive_veil.dart';
import '../screens/channel_timeline_screen.dart';
import '../screens/search_screen.dart';
import '../screens/user_profile_screen.dart';
import 'emoji_image.dart';
import 'link_preview_card.dart';
import 'note_actions_row.dart';
import 'note_media_grid.dart';
import 'poll_view.dart';
import 'user_avatar.dart';
import 'user_display_name.dart';

class NoteCard extends ConsumerWidget {
  final Note note;
  final Account? attributionAccount;

  /// Dense-stream mode: render flat and full-width directly on the
  /// canvas instead of as a card — the hosting list is expected to
  /// draw a [PlusDivider] hairline between rows.
  final bool stream;

  const NoteCard({
    super.key,
    required this.note,
    this.attributionAccount,
    this.stream = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pure renote (boost without commentary): show a small renoter
    // header and let the inner note take over as the visible card.
    if (note.isPureRenote) {
      return _PureRenoteCard(
        outer: note,
        inner: note.renote!,
        attributionAccount: attributionAccount,
        stream: stream,
      );
    }
    final body = _NoteBody(
      note: note,
      isQuoteEmbed: false,
      attributionAccount: attributionAccount,
      stream: stream,
    );
    // Wrap in Semantics so screen readers announce a single
    // navigable item per note. `container: true` collapses the
    // descendant subtree into one a11y node up to the action row,
    // which keeps its own (icon + tooltip) semantics.
    // Horizontal insets live inside _NoteBody so media can bleed to
    // the card edges in both card and stream presentation.
    return Semantics(
      container: true,
      label: _accessibleLabel(note),
      child: stream
          ? Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
              child: body,
            )
          : PlusCard(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: body,
            ),
    );
  }

  /// Build a human-readable summary of a note for screen readers:
  /// `<author display name> @user@host posted <relative time>: <body>`.
  /// CW notes prepend the warning.
  static String _accessibleLabel(Note note) {
    final user = note.user;
    final displayName = user.name ?? user.username;
    final host = user.host ?? note.sourceHost;
    final handle = '@${user.username}@$host';
    final body = (note.text ?? '').trim();
    final cw = (note.cw ?? '').trim();
    final attachments = note.files.length;
    final parts = <String>[
      '$displayName $handle',
      if (cw.isNotEmpty) 'content warning: $cw',
      if (body.isNotEmpty) body,
      if (attachments > 0)
        '$attachments attachment${attachments == 1 ? '' : 's'}',
      if (note.reactions.isNotEmpty)
        '${note.reactions.length} reaction'
            '${note.reactions.length == 1 ? '' : 's'}',
    ];
    return parts.join('. ');
  }
}

/// The inner content of a note. Used both at the top level (inside a
/// Card) and embedded inside another note as a quote box.
class _NoteBody extends ConsumerStatefulWidget {
  final Note note;
  final bool isQuoteEmbed;
  final Account? attributionAccount;

  /// Dense-stream host (see [NoteCard.stream]): the action row skips
  /// its internal groove so the between-note groove stays the only
  /// separator.
  final bool stream;

  const _NoteBody({
    required this.note,
    required this.isQuoteEmbed,
    this.attributionAccount,
    this.stream = false,
  });

  @override
  ConsumerState<_NoteBody> createState() => _NoteBodyState();
}

class _NoteBodyState extends ConsumerState<_NoteBody> {
  /// Per-note CW reveal. Resets when the row is recycled (matches
  /// Misskey web's behavior — the CW is the user's own decision and
  /// shouldn't auto-leak across sessions).
  bool _cwOpen = false;

  /// Per-note "I've revealed the sensitive-channel blur" toggle. Same
  /// recycling semantics as [_cwOpen] — tapping through doesn't leak
  /// across scroll-back.
  bool _sensitiveRevealed = false;

  /// Parsed MFM for `note.text` (plus the link-preview URL found in
  /// it) and for `note.cw`, memoized per source string. Rebuilds
  /// triggered by settings changes, the CW toggle, reaction patches
  /// etc. reuse the AST; only an actual text change (edit, streaming
  /// update) re-runs the parser — see [didUpdateWidget].
  ({List<MfmNode> ast, String? firstUrl})? _parsedBody;
  List<MfmNode>? _parsedCw;

  /// The renderer owns the tap recognizers it creates for links,
  /// mentions and hashtags; keep the current one so it can be
  /// disposed on the next build and on unmount.
  MfmRenderer? _renderer;

  @override
  void dispose() {
    _renderer?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_NoteBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.text != widget.note.text) _parsedBody = null;
    if (oldWidget.note.cw != widget.note.cw) _parsedCw = null;
  }

  static ({List<MfmNode> ast, String? firstUrl}) _parseBody(String text) {
    final ast = parseMfm(text);
    return (ast: ast, firstUrl: _firstUrl(ast));
  }

  /// First URL in the rendered body — the link-preview candidate.
  /// Walks container nodes but deliberately skips code spans (a URL
  /// in a code sample isn't a share).
  static String? _firstUrl(List<MfmNode> nodes) {
    for (final n in nodes) {
      switch (n) {
        case MfmUrl(:final url):
          return url;
        case MfmLink(:final url):
          return url;
        case MfmBold(:final children):
        case MfmItalic(:final children):
        case MfmStrike(:final children):
        case MfmSmall(:final children):
        case MfmCenter(:final children):
        case MfmQuote(:final children):
        case MfmFn(:final children):
          final hit = _firstUrl(children);
          if (hit != null) return hit;
        default:
          break;
      }
    }
    return null;
  }

  /// Pre-tap summary of what's behind the CW. Helps the user decide
  /// whether to reveal — e.g. they can tell at a glance that the note
  /// has 3 attachments and a quote even before opening it.
  static String _cwHiddenSummary(Note note) {
    final body = (note.text ?? '').trim();
    final parts = <String>[];
    if (body.isNotEmpty) {
      // Stripped char-count rather than the body text itself, so the
      // CW actually hides the note instead of leaking it.
      parts.add(body.length == 1 ? '1 character' : '${body.length} characters');
    }
    if (note.files.isNotEmpty) {
      parts.add('${note.files.length} '
          '${note.files.length == 1 ? 'attachment' : 'attachments'}');
    }
    if (note.isQuoteRenote) parts.add('quote');
    if (parts.isEmpty) return 'Show contents';
    return 'Show contents · ${parts.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;
    final isQuoteEmbed = widget.isQuoteEmbed;
    final attributionAccount = widget.attributionAccount;
    final theme = Theme.of(context);
    final user = note.user;
    final displayName = user.name ?? user.username;
    final userHost = user.host ?? note.sourceHost;
    final isFederated = user.host != null && user.host != note.sourceHost;
    final handle = '@${user.username}@$userHost';

    final animate = EffectSettings.shouldAnimate(context, ref);
    final emojiSize = (theme.textTheme.bodyMedium?.fontSize ?? 14) * 1.4;
    _renderer?.dispose();
    final renderer = _renderer = MfmRenderer(
      context: context,
      animateEffects: animate,
      nyaiseText: user.isCat,
      callbacks: MfmCallbacks(
        onUrlTap: (url) async {
          final uri = Uri.tryParse(url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        onMentionTap: (mention) {
          final viewer = attributionAccount;
          if (viewer == null) return;
          UserProfileScreen.openByHandle(
            context,
            viewerAccount: viewer,
            username: mention.username,
            userHost: mention.host,
          );
        },
        onHashtagTap: (tag) {
          final viewer = attributionAccount;
          if (viewer == null) return;
          SearchScreen.open(context, account: viewer, initialTag: tag);
        },
        resolveEmoji: (rawName) => EmojiImage(
          rawName: rawName,
          viewerHost: note.sourceHost,
          size: emojiSize,
        ),
      ),
    );

    Widget? body;
    String? firstUrl;
    if (note.text != null && note.text!.isNotEmpty) {
      final parsed = _parsedBody ??= _parseBody(note.text!);
      body = renderer.render(parsed.ast);
      firstUrl = parsed.firstUrl;
    }
    Widget? cw;
    if (note.cw != null && note.cw!.isNotEmpty) {
      cw = renderer.render(_parsedCw ??= parseMfm(note.cw!));
    }
    // Link preview: progressive enhancement on the first URL in the
    // body. Skipped inside quote embeds (space) and on quote renotes
    // (the embedded note is already the preview).
    final showPreview = firstUrl != null &&
        !isQuoteEmbed &&
        !note.isQuoteRenote &&
        attributionAccount != null;

    // (avatar_dimension); quote embeds stay compact.
    final avatarRadius = isQuoteEmbed ? 12.0 : PlusDims.noteAvatar / 2;
    // Text content keeps the 16px card inset; media bleeds full-width.
    // Quote embeds sit inside their own padded box, so no extra inset.
    final hPad = isQuoteEmbed ? 0.0 : PlusDims.cardPadding;
    final inset = EdgeInsets.symmetric(horizontal: hPad);
    Widget pad(Widget w) => Padding(padding: inset, child: w);
    void openAuthorProfile() {
      final viewer = attributionAccount;
      if (viewer == null) return;
      // Open by handle so federated authors resolve correctly: the
      // note's `user.id` is local to `note.sourceHost` (the delivering
      // server), but the profile screen runs against [viewer]'s home
      // server, where that same id may not be valid. Handle-based
      // lookup goes through `users/show?username=...&host=...` which
      // Misskey resolves via WebFinger.
      UserProfileScreen.openByHandle(
        context,
        viewerAccount: viewer,
        username: user.username,
        userHost: user.host,
      );
    }
    final settings = ref.watch(settingsProvider);
    final isSensitiveChannel =
        note.channel?.isSensitive == true && !isQuoteEmbed;
    final shouldBlur = isSensitiveChannel &&
        settings.blurSensitiveChannels &&
        !_sensitiveRevealed;

    final children = <Widget>[
      Padding(
        padding: inset,
        child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: openAuthorProfile,
            child: UserAvatar(
              url: user.avatarUrl,
              seed: displayName,
              radius: avatarRadius,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: openAuthorProfile,
              // The header column is width-bounded by the Expanded; the
              // LayoutBuilder hands that width down so each row's
              // trailing, non-flexible item (federation tag, metadata
              // cluster) is capped instead of overflowing. Two loose
              // Flexibles would split a row 50/50 and needlessly
              // ellipsize the name/handle whenever the trailing item is
              // short, so the cap goes on the trailing item and the
              // leading Flexible keeps whatever is left.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final rowWidth = constraints.hasBoundedWidth
                      ? constraints.maxWidth
                      : double.infinity;
                  // Federation tag: at most ~60% of the row, so a very
                  // long remote host can't push the name out entirely.
                  final tagMax = rowWidth.isFinite
                      ? math.max(0.0, rowWidth * 0.6)
                      : double.infinity;
                  // Metadata cluster: up to the full row minus the gap;
                  // the handle shrinks into whatever remains.
                  final metaMax = rowWidth.isFinite
                      ? math.max(0.0, rowWidth - 6)
                      : double.infinity;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: UserDisplayName(
                              name: displayName,
                              viewerHost: note.sourceHost,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          if (isFederated) ...[
                            const SizedBox(width: 6),
                            // Remote-instance marker: rectangular context
                            // tag with the purple federation edge.
                            // Capped so a long host ellipsizes inside
                            // the tag (its label is Flexible) rather
                            // than pushing the display name to zero.
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: tagMax),
                              child: PlusContextTag(
                                label: 'via ${note.sourceHost}',
                                accent: PlusTheme.of(context).remote,
                                tooltip: 'Federated note received via '
                                    '${note.sourceHost}',
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Metadata sits under the name, the app layout
                      // ("Public · 9 hours ago" in the 2014 stream cards):
                      // handle, then visibility + time.
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              handle,
                              style: PlusTheme.of(context).metadata,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: metaMax),
                            child: _NoteMetadata(
                              visibility: note.visibility,
                              localOnly: note.localOnly,
                              createdAt: note.createdAt,
                              updatedAt: note.updatedAt,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
        ),
      ),
      // Content-warning aware body section.
      //
      // When the note has a CW, the body / media / quote stay collapsed
      // behind a "Show contents" pill until tapped. The CW text itself
      // is always visible (it's the warning, not the secret).
      //
      // Sensitive-channel blur layers on top: if the note is in a
      // channel flagged sensitive AND the user hasn't tapped to reveal,
      // the whole content block (CW pill included) is wrapped in a
      // [_SensitiveBlurOverlay]. The author header and channel chip
      // stay un-blurred so the user can tell *what* is being hidden.
      _SensitiveBlurOverlay(
        active: shouldBlur,
        onReveal: () => setState(() => _sensitiveRevealed = true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cw != null) ...[
              const SizedBox(height: 8),
              pad(cw),
              const SizedBox(height: 6),
              pad(_CwToggle(
                open: _cwOpen,
                hiddenSummary: _cwHiddenSummary(note),
                onToggle: () => setState(() => _cwOpen = !_cwOpen),
              )),
              if (_cwOpen) ...[
                const SizedBox(height: 6),
                const PlusDivider(),
                if (body != null) ...[
                  const SizedBox(height: 8),
                  pad(body),
                ],
                if (note.poll != null) ...[
                  const SizedBox(height: 8),
                  pad(PollView(
                    note: note,
                    attributionAccount: attributionAccount,
                  )),
                ],
                if (note.files.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // Media bleeds to the card edges.
                  NoteMediaGrid(files: note.files),
                ],
                if (note.isQuoteRenote) ...[
                  const SizedBox(height: 8),
                  pad(_QuoteBox(inner: note.renote!)),
                ],
                if (showPreview) ...[
                  const SizedBox(height: 8),
                  pad(LinkPreviewCard(
                    url: firstUrl,
                    account: attributionAccount,
                  )),
                ],
              ],
            ] else ...[
              if (body != null) ...[
                const SizedBox(height: 8),
                pad(body),
              ],
              if (note.poll != null) ...[
                const SizedBox(height: 8),
                pad(PollView(
                  note: note,
                  attributionAccount: attributionAccount,
                )),
              ],
              if (note.files.isNotEmpty) ...[
                const SizedBox(height: 8),
                // Media bleeds to the card edges.
                NoteMediaGrid(files: note.files),
              ],
              // Quote: this note has its own text/files AND embeds another
              // note. Render the embedded note as a bordered preview.
              if (note.isQuoteRenote) ...[
                const SizedBox(height: 8),
                pad(_QuoteBox(inner: note.renote!)),
              ],
              if (showPreview) ...[
                const SizedBox(height: 8),
                pad(LinkPreviewCard(
                  url: firstUrl,
                  account: attributionAccount,
                )),
              ],
            ],
          ],
        ),
      ),
      if (note.reactions.isNotEmpty) ...[
        const SizedBox(height: 8),
        pad(Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final r in note.reactions)
              _ReactionChip(
                note: note,
                reaction: r,
                emojiSize: emojiSize,
                attributionAccount: attributionAccount,
              ),
          ],
        )),
      ],
      // Channel attribution: rendered after the body/media/quote/
      // reactions but before the action row, so the channel reads as
      // a "from" line wrapping up the note's content. Sitting above
      // the action row keeps the channel chip thumb-tied to the note
      // it belongs to rather than floating below the action buttons.
      if (note.channel != null) ...[
        const SizedBox(height: 6),
        pad(_ChannelChip(
          channel: note.channel!,
          attributionAccount: attributionAccount,
        )),
      ],
      // Action row: only on top-level notes, not inside a quote
      // embed (where actions belong to the outer note).
      if (!isQuoteEmbed && attributionAccount != null)
        NoteActionsRow(
          note: note,
          attributionAccount: attributionAccount,
          showDivider: !widget.stream,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// Veil for notes posted in a channel marked `isSensitive` server-side.
/// Blurs the body / media / quote (whatever the [child] contains) and
/// shows a tap-to-reveal pill; on reveal the parent flips a flag and
/// the unblurred [child] renders on the next rebuild.
///
/// When [active] is false the child is returned verbatim — no image
/// filter is added to the tree, so non-sensitive notes pay zero
/// rendering cost.
class _SensitiveBlurOverlay extends StatelessWidget {
  final bool active;
  final Widget child;
  final VoidCallback onReveal;
  const _SensitiveBlurOverlay({
    required this.active,
    required this.child,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return SensitiveVeil(
      label: 'Sensitive channel · Tap to reveal',
      onReveal: onReveal,
      child: child,
    );
  }
}

/// Tappable pill that toggles the CW-gated content area.
///
/// Open state shows "Hide contents", closed shows the
/// `hiddenSummary` (e.g. "Show contents · 312 characters · 2
/// attachments") so the user can decide whether to reveal without
/// leaking the body text.
class _CwToggle extends StatelessWidget {
  final bool open;
  final String hiddenSummary;
  final VoidCallback onToggle;
  const _CwToggle({
    required this.open,
    required this.hiddenSummary,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    // Flat rectangular chip; the amber eye marks it as a warning gate
    //. Never a capsule.
    return Align(
      alignment: Alignment.centerLeft,
      child: PlusChip(
        onTap: onToggle,
        selected: false,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              open ? Icons.visibility_off : Icons.visibility,
              size: 14,
              color: plus.warning,
            ),
            const SizedBox(width: 6),
            // The summary ("Show contents · 312 characters · 2
            // attachments") is arbitrary-length; it must yield to the
            // card width rather than push past it.
            Flexible(
              child: Text(
                open ? 'Hide contents' : hiddenSummary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: plus.textPrimary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteBox extends StatelessWidget {
  final Note inner;
  const _QuoteBox({required this.inner});

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    // Flat bordered box on the subtle surface — the quoted note reads
    // as an inset document, square-cornered like everything else.
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: plus.surfaceSubtle,
        borderRadius: BorderRadius.circular(PlusRadii.card),
        border: Border.all(color: plus.border),
      ),
      child: _NoteBody(note: inner, isQuoteEmbed: true),
    );
  }
}

class _PureRenoteCard extends StatelessWidget {
  final Note outer;
  final Note inner;
  final Account? attributionAccount;
  final bool stream;
  const _PureRenoteCard({
    required this.outer,
    required this.inner,
    this.attributionAccount,
    this.stream = false,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final renoter = outer.user;
    final renoterName = renoter.name ?? renoter.username;
    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                PlusDims.cardPadding, 0, PlusDims.cardPadding, 6),
            child: Row(
              children: [
                // Renotes are green.
                Icon(Icons.repeat, size: 16, color: plus.renote),
                const SizedBox(width: 6),
                Flexible(
                  child: UserDisplayName(
                    name: '$renoterName renoted',
                    viewerHost: outer.sourceHost,
                    style: plus.metadata,
                  ),
                ),
              ],
            ),
          ),
          _NoteBody(
            note: inner,
            isQuoteEmbed: false,
            attributionAccount: attributionAccount,
            stream: stream,
          ),
        ],
      );
    return stream
        ? Padding(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
            child: content,
          )
        : PlusCard(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: content,
          );
  }
}

String _relative(DateTime t) {
  final delta = DateTime.now().difference(t);
  if (delta.inSeconds < 60) return '${delta.inSeconds}s';
  if (delta.inMinutes < 60) return '${delta.inMinutes}m';
  if (delta.inHours < 24) return '${delta.inHours}h';
  return '${delta.inDays}d';
}

/// Compact metadata cluster on the right side of the note header:
/// `[non-federated badge?] [visibility icon] [relative time]`.
///
/// Visibility maps:
///   public    -> globe                  (everyone, federated)
///   home      -> house                  (home timeline only)
///   followers -> lock                   (followers-only)
///   specified -> @ symbol               (DM)
///
/// `localOnly` (Misskey's "non-federated" flag) is rendered as a small
/// `public_off` icon in front of the visibility icon, since a public
/// note marked local-only is materially different from a regular public
/// note — it never leaves the home server.
///
/// Must be given a bounded width (the header wraps it in a
/// [ConstrainedBox]): the relative-time text is [Flexible] so the
/// cluster ellipsizes instead of overflowing on narrow rows / large
/// text scales.
class _NoteMetadata extends StatelessWidget {
  final NoteVisibility visibility;
  final bool localOnly;
  final DateTime createdAt;

  /// Non-null when the author edited the note after posting. Rendered
  /// as a small pencil badge so silent edits are visible.
  final DateTime? updatedAt;

  const _NoteMetadata({
    required this.visibility,
    required this.localOnly,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final outline = plus.textSecondary;
    // Non-federated notes are local-only no matter what their
    // visibility is, so the `public_off` icon supersedes the regular
    // visibility icon. Showing both was redundant — a "public +
    // local-only" note is functionally a different beast and the
    // user only needs one symbol communicating that.
    //
    // Exception: 'specified' (DM) and 'followers' visibility carry
    // independent semantic weight even when local-only, so we render
    // those alongside `public_off`.
    final showVisibilityIcon = !localOnly ||
        visibility == NoteVisibility.specified ||
        visibility == NoteVisibility.followers;
    final (icon, label) = switch (visibility) {
      NoteVisibility.public => (Icons.public, 'Public'),
      NoteVisibility.home => (Icons.home_outlined, 'Home timeline only'),
      NoteVisibility.followers => (Icons.lock_outline, 'Followers only'),
      NoteVisibility.specified => (Icons.alternate_email, 'Direct'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (updatedAt != null) ...[
          Tooltip(
            message: 'Edited ${_relative(updatedAt!)} ago',
            child: Icon(Icons.edit_outlined, size: 12, color: outline),
          ),
          const SizedBox(width: 4),
        ],
        if (localOnly) ...[
          Tooltip(
            message: 'Local-only — not federated',
            child: Icon(
              Icons.public_off,
              size: 14,
              // Amber marks local-only state.
              color: plus.localOnly,
            ),
          ),
          const SizedBox(width: 4),
        ],
        if (showVisibilityIcon) ...[
          Tooltip(
            message: label,
            child: Icon(icon, size: 14, color: outline),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            _relative(createdAt),
            style: plus.metadata,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Rounded, color-tinted chip identifying a Misskey channel. Uses the
/// channel's own `color` when the server publishes one (e.g. `#4f46e5`)
/// and falls back to the theme accent.
class _ChannelChip extends StatelessWidget {
  final NoteChannel channel;

  /// Account whose websocket delivered this note. Tap opens the
  /// channel timeline scoped to this account (channel ids are
  /// account-server-local). Null when the note is rendered in a
  /// detached context (e.g. a quote embed) — in that case the chip
  /// stays informational-only.
  final Account? attributionAccount;

  const _ChannelChip({
    required this.channel,
    required this.attributionAccount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _parseHexColor(channel.color) ?? theme.colorScheme.primary;
    final account = attributionAccount;
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(PlusRadii.chip),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tag, size: 12, color: accent),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              channel.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (channel.isSensitive) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: 'Sensitive channel',
              child: Icon(
                Icons.warning_amber_outlined,
                size: 12,
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: account == null
          ? body
          : InkWell(
              borderRadius: BorderRadius.circular(PlusRadii.chip),
              onTap: () => ChannelTimelineScreen.open(
                context,
                account: account,
                channelId: channel.id,
                initialName: channel.name,
              ),
              child: body,
            ),
    );
  }

  /// `#rrggbb` / `#aarrggbb` -> Color, null on malformed input. Used so
  /// channel-published colors don't crash the renderer if the server
  /// ships something unexpected.
  static Color? _parseHexColor(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final hex = raw.replaceAll('#', '');
    final padded = switch (hex.length) {
      6 => 'ff$hex',
      8 => hex,
      _ => null,
    };
    if (padded == null) return null;
    final parsed = int.tryParse(padded, radix: 16);
    return parsed == null ? null : Color(parsed);
  }
}

/// One reaction chip in the note card's reaction wrap.
///
/// Tap behavior:
///   - if this is the viewer's own reaction (`note.myReaction == r.key`)
///     → call `notes/reactions/delete` to un-react
///   - otherwise → call `notes/reactions/create` with this reaction's
///     key, so tapping someone else's chip joins it. Misskey rejects a
///     second create when you already have a reaction; we surface that
///     error via SnackBar (the user can use the more-menu to clear
///     theirs first).
///   - a chip the reacting account *cannot* send — a remote instance's
///     custom emoji (`:name@host:`), or a local custom emoji when the
///     account lives on a different server than the note — is not
///     tappable at all (Misskey only accepts unicode or the reacting
///     user's own server's emoji; the web client disables these chips
///     too). It renders dimmed with an explanatory tooltip. The
///     viewer's own reaction is always tappable so it can be removed.
///
/// Visual: a flat rectangular [PlusChip]; the viewer's own reaction
/// gets the brand-soft fill and 1px brand border.
class _ReactionChip extends ConsumerWidget {
  final Note note;
  final Reaction reaction;
  final double emojiSize;
  final Account? attributionAccount;
  const _ReactionChip({
    required this.note,
    required this.reaction,
    required this.emojiSize,
    required this.attributionAccount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    final viewer = attributionAccount;
    final key = reaction.key;
    final isMine = note.myReaction != null &&
        _normalizeKey(note.myReaction!) == _normalizeKey(key);
    // Sendable iff unicode, or a custom emoji local to the note's server
    // while the reacting account is on that same server. The viewer's
    // own reaction stays tappable regardless so it can be removed.
    final sendable = isMine ||
        !reaction.isCustom ||
        (_isLocalCustom(key) &&
            viewer != null &&
            viewer.host == note.sourceHost);
    final fg = isMine
        ? plus.brand
        : sendable
            ? plus.textSecondary
            : plus.textTertiary;
    final accountAsync =
        viewer == null ? null : ref.watch(noteActionsProvider(viewer));
    final actions = accountAsync?.valueOrNull;
    final disabled = actions == null || !sendable;
    final tooltip = sendable
        ? null
        : "Remote emoji — can't react from "
            '${viewer == null ? 'this account' : '@${viewer.username}@${viewer.host}'}';

    Future<void> onTap() async {
      if (actions == null) return;
      try {
        if (isMine) {
          await actions.unreact(note);
        } else {
          // Strip the leading-`:` markers Misskey sometimes returns in
          // its `reaction` keys to match the format `notes/reactions/
          // create` expects (`:name@host:` for federated, `:name:`
          // local — both already correct here, so we pass through).
          await actions.react(note: note, reaction: reaction.key);
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reaction failed: $e')),
        );
      }
    }

    return PlusChip(
      onTap: disabled ? null : onTap,
      selected: isMine,
      tooltip: tooltip,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flexible so the emoji slot can shrink: an unresolved custom
          // emoji falls back to its `:name@host:` text, which at a
          // large text scale is wider than a phone-width chip. The
          // chip sits in a width-bounded Wrap, so the flex is legal.
          Flexible(
            child: reaction.isCustom
                ? EmojiImage(
                    rawName: _innerName(key),
                    viewerHost: note.sourceHost,
                    size: emojiSize,
                  )
                : Text(
                    key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg),
                  ),
          ),
          const SizedBox(width: 4),
          Text(
            '${reaction.count}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: isMine ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Local custom-emoji keys can arrive as either `:name:` or
  /// `:name@.:` depending on the Misskey version + path. Normalize the
  /// `@.` suffix away so the viewer's-own check still matches both.
  static String _normalizeKey(String key) {
    if (key.length < 2 || !key.startsWith(':') || !key.endsWith(':')) {
      return key;
    }
    final inner = key.substring(1, key.length - 1);
    final atDot = inner.endsWith('@.');
    return atDot ? ':${inner.substring(0, inner.length - 2)}:' : key;
  }

  /// `:name:` / `:name@host:` -> `name` / `name@host`. Tolerates a
  /// malformed key shorter than two colons instead of throwing.
  static String _innerName(String key) =>
      key.length >= 2 ? key.substring(1, key.length - 1) : key;

  /// True for a custom-emoji key naming an emoji on the note's own
  /// server: `:name:` or `:name@.:`. A remote `:name@host:` (host
  /// neither empty nor `.`) and anything malformed return false.
  static bool _isLocalCustom(String key) {
    if (key.length < 3 || !key.startsWith(':') || !key.endsWith(':')) {
      return false;
    }
    final inner = key.substring(1, key.length - 1);
    final at = inner.indexOf('@');
    if (at < 0) return true;
    if (at == 0) return false;
    final host = inner.substring(at + 1);
    return host.isEmpty || host == '.';
  }
}
