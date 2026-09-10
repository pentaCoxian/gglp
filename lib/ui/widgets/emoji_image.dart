import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../misskey/emoji/emoji_providers.dart';
import '../../misskey/emoji/emoji_ref.dart';
import 'net_image.dart';

/// Inline emoji widget. Resolves `:name:` / `:name@host:` against the
/// repository on every build; if not yet cached, renders a text
/// fallback `:name:`. Listens to the catalog tick stream so a future
/// fetch upgrades the visible widget without touching the renderer.
class EmojiImage extends ConsumerWidget {
  final String rawName;
  final String viewerHost;
  final double size;

  const EmojiImage({
    super.key,
    required this.rawName,
    required this.viewerHost,
    required this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribe to *this host's* tick so the widget rebuilds when the
    // referenced catalog lands — and not when any other host's does.
    final eref = EmojiRef.parse(rawName, viewerHost: viewerHost);
    ref.watch(emojiHostTickProvider(eref.host));
    final repo = ref.watch(emojiRepositoryProvider);
    final emoji = repo.lookup(host: eref.host, name: eref.name);
    if (emoji == null) {
      // Unresolved — fall back to literal `:name:` so the user sees
      // the source. Single-line + ellipsis so a long `:name@host:`
      // can't overflow a bounded host (reaction chip, filter chip).
      return Text(
        ':$rawName:',
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: size * 0.7,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    // Height-locked and aspect-preserving (wide emoji stay wide), but
    // width-capped so a banner-shaped or malformed image can't blow out
    // the line it sits in. Placeholder and error fallback are both a
    // `size` square, so the surrounding text doesn't reflow while the
    // image is in flight or if it fails.
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: size,
        maxHeight: size,
        maxWidth: size * 2.5,
      ),
      child: NetImage(
        url: emoji.url,
        fit: BoxFit.contain,
        placeholder: SizedBox.square(dimension: size),
        errorWidget: SizedBox.square(
          dimension: size,
          child: Tooltip(
            message: ':$rawName:',
            child: Icon(
              Icons.broken_image_outlined,
              size: size * 0.8,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }
}
