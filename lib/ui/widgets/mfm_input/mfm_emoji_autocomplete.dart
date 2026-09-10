import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../misskey/emoji/emoji_providers.dart';
import '../../../misskey/emoji/emoji_ref.dart';
import '../../../misskey/models/account.dart';
import '../../../misskey/models/emoji.dart';
import '../../plus/plus.dart';
import '../emoji_image.dart';
import 'mfm_editing.dart';
import 'mfm_emoji_ranker.dart';

/// Wraps a TextField in a ranked emoji-suggestion popup.
///
/// Triggers when the user types `:` followed by zero or more word chars,
/// per [currentEmojiPartialRange] semantics. Suggestions are scored
/// against the active account's host catalog ([EmojiRepository.allForHost])
/// with a recents bump from [ReactionRecentDao.recent]. Picking a row
/// (or pressing Enter on the highlighted entry) replaces the partial
/// in-place via [replaceCurrentEmojiToken].
///
/// The popup anchors **below** the wrapped field via
/// [CompositedTransformTarget] / [CompositedTransformFollower]. Anchoring
/// to the field rather than the caret keeps the placement stable as the
/// user types (no jitter line-by-line) and avoids the TextPainter
/// line-metrics dance — the trade-off is the panel sits at a fixed
/// vertical offset rather than tracking the cursor mid-paragraph. For
/// compose / page-block sized inputs that's an acceptable simplification.
class MfmEmojiAutocomplete extends ConsumerStatefulWidget {
  final Account account;
  final TextEditingController controller;
  final FocusNode focusNode;
  final Widget child;

  const MfmEmojiAutocomplete({
    super.key,
    required this.account,
    required this.controller,
    required this.focusNode,
    required this.child,
  });

  @override
  ConsumerState<MfmEmojiAutocomplete> createState() =>
      _MfmEmojiAutocompleteState();
}

class _MfmEmojiAutocompleteState
    extends ConsumerState<MfmEmojiAutocomplete> {
  final _layerLink = LayerLink();
  final _portal = OverlayPortalController();
  String? _activeQuery;
  List<String> _recents = const [];
  int _lastTextLength = 0;

  @override
  void initState() {
    super.initState();
    _lastTextLength = widget.controller.text.length;
    widget.controller.addListener(_handleControllerChange);
    widget.focusNode.addListener(_handleFocusChange);
    _refreshRecents();
  }

  @override
  void didUpdateWidget(covariant MfmEmojiAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      widget.controller.addListener(_handleControllerChange);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
    }
    if (oldWidget.account.id != widget.account.id) {
      _refreshRecents();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  Future<void> _refreshRecents() async {
    try {
      final dao = ref.read(reactionRecentDaoProvider);
      final list = await dao.recent(accountId: widget.account.id);
      if (!mounted) return;
      setState(() => _recents = list);
    } catch (_) {
      // Recents are advisory; failures fall back to no-recents state.
    }
  }

  void _handleFocusChange() {
    if (!widget.focusNode.hasFocus) {
      _hide();
    }
  }

  void _handleControllerChange() {
    // Controller notifications can arrive during teardown (a commit
    // that pops the route); never setState on a defunct element.
    if (!mounted) return;
    final v = widget.controller.value;
    final delta = (v.text.length - _lastTextLength).abs();
    _lastTextLength = v.text.length;

    // Paste / programmatic mass insertion: dismiss; the user's next
    // keystroke will re-evaluate.
    if (delta > 1) {
      _hide();
      return;
    }
    // NOTE: no gate on `v.composing` here. Android IMEs (Gboard et
    // al.) keep even plain ASCII words in an active composing region
    // while the user types, so hiding during composition suppressed
    // the popup entirely on Android. It's safe to evaluate anyway:
    // emoji partials only match ASCII `[A-Za-z0-9_]` after `:`
    // (see [currentEmojiPartial]), so CJK conversion text never forms
    // a trigger, and committing a pick clears the composing region
    // via [replaceCurrentEmojiToken].
    if (isInsideCodeContext(v)) {
      _hide();
      return;
    }
    final partial = currentEmojiPartial(v);
    if (partial == null) {
      _hide();
      return;
    }
    if (partial != _activeQuery) {
      setState(() => _activeQuery = partial);
    }
    _show();
  }

  void _show() {
    if (!_portal.isShowing) {
      _portal.show();
    }
  }

  void _hide() {
    if (_portal.isShowing) {
      _portal.hide();
      _activeQuery = null;
    }
  }

  void _commit(CustomEmoji emoji) {
    final token = EmojiRef.tokenFor(emoji, widget.account.host);
    widget.controller.value = replaceCurrentEmojiToken(
      widget.controller.value,
      token,
    );
    // Bump async; UI doesn't wait.
    ref.read(reactionRecentDaoProvider).bump(
          accountId: widget.account.id,
          reactionKey: token,
        );
    _hide();
    // After insert, refresh recents so the next opening reflects it.
    _refreshRecents();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the catalog tick so the popup picks up a freshly-loaded
    // catalog without needing a re-open.
    ref.watch(emojiCatalogTickProvider);
    final repo = ref.watch(emojiRepositoryProvider);
    final all = repo.allForHost(widget.account.host);
    final query = _activeQuery ?? '';
    final ranked = rankEmoji(
      all: all,
      query: query,
      viewerHost: widget.account.host,
      recents: _recents,
    );
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (overlayContext) => Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: _SuggestionPanel(
              query: query,
              account: widget.account,
              emoji: ranked,
              catalogEmpty: all.isEmpty,
              onPick: _commit,
              onDismiss: _hide,
            ),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  final String query;
  final Account account;
  final List<CustomEmoji> emoji;
  final bool catalogEmpty;
  final void Function(CustomEmoji) onPick;
  final VoidCallback onDismiss;

  const _SuggestionPanel({
    required this.query,
    required this.account,
    required this.emoji,
    required this.catalogEmpty,
    required this.onPick,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    final emojiSize =
        (theme.textTheme.bodyMedium?.fontSize ?? 14) * 1.4;
    final maxWidth =
        MediaQuery.of(context).size.width.clamp(0, 320).toDouble();
    // Floating panel: flat white menu surface with the menu drop
    // shadow (a 1px border in dark mode). The inner transparent
    // Material keeps the rows' InkWell ripples working; Clip.antiAlias
    // keeps the list inside the near-square face.
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: plus.surface,
        borderRadius: BorderRadius.circular(PlusRadii.menu),
        border: plus.isDark ? Border.all(color: plus.border) : null,
        boxShadow: plus.isDark ? null : plus.shadowMenu,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 240,
          maxWidth: maxWidth,
          minWidth: 220,
        ),
        child: emoji.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  catalogEmpty
                      ? 'Loading custom emoji from ${account.host}…'
                      : 'No emoji match ":$query".',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: emoji.length,
                itemBuilder: (_, i) {
                  final e = emoji[i];
                  final tokenForRender = e.host == account.host
                      ? ':${e.name}:'
                      : ':${e.name}@${e.host}:';
                  return Semantics(
                    button: true,
                    label: 'Insert $tokenForRender emoji',
                    child: InkWell(
                      onTap: () => onPick(e),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: emojiSize,
                              height: emojiSize,
                              child: EmojiImage(
                                rawName: e.host == account.host
                                    ? e.name
                                    : '${e.name}@${e.host}',
                                viewerHost: account.host,
                                size: emojiSize,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ':${e.name}:',
                                    style: theme.textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (e.category != null ||
                                      e.host != account.host)
                                    Text(
                                      e.host != account.host
                                          ? '@${e.host}'
                                          : (e.category ?? ''),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        ),
      ),
    );
  }
}
