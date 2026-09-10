import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../misskey/models/note_file.dart';
import '../screens/media_viewer_screen.dart';
import 'net_image.dart';
import 'sensitive_veil.dart';

/// Image / video / audio attachments for a note.
///
/// Layout:
///   1 file  -> single tile, aspect-ratio bounded (max 16:9 / min 1:1)
///   2 files -> two tiles side by side
///   3 files -> one large left, two stacked right
///   4 files -> 2x2 grid
///   5+      -> 2x2 grid of the first four with a "+N" overlay on the
///              fourth tile
///
/// Sensitive files are rendered as a blacked-out tap-to-reveal box. We
/// don't decode blurhash here to avoid pulling another package; the
/// placeholder is a solid color while the image fetches.
class NoteMediaGrid extends StatelessWidget {
  final List<NoteFile> files;
  const NoteMediaGrid({super.key, required this.files});

  /// 4.4.0 value, agreed on by riviera_album_image_padding,
  /// album_photo_grid_spacing, and story_element_picker_photo_grid_spacing.
  static const _gap = 2.0;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();
    // Hard-edged media panel: images run square and flush to the card
    // edges on every form factor, exactly like the 2014 stream cards.
    return ClipRect(
      child: AspectRatio(
        aspectRatio: _gridAspect(),
        child: _layoutFor(files),
      ),
    );
  }

  double _gridAspect() {
    switch (files.length) {
      case 1:
        final r = files.first.aspectRatio;
        // Clamp very-tall and very-wide images so a single attachment
        // never dominates the timeline.
        return r.clamp(0.75, 16 / 9);
      case 2:
        return 16 / 9;
      default:
        return 4 / 3;
    }
  }

  Widget _layoutFor(List<NoteFile> f) {
    // Each tile gets the whole file list + its own index so tap-through
    // can open a swipeable multi-image viewer instead of a single
    // image. The viewer pre-loads the index that was tapped.
    Widget tile(int i, {int moreCount = 0}) =>
        _Tile(allFiles: f, index: i, moreCount: moreCount);
    switch (f.length) {
      case 1:
        return tile(0);
      case 2:
        return Row(children: [
          Expanded(child: tile(0)),
          const SizedBox(width: _gap),
          Expanded(child: tile(1)),
        ]);
      case 3:
        return Row(children: [
          Expanded(child: tile(0)),
          const SizedBox(width: _gap),
          Expanded(
            child: Column(children: [
              Expanded(child: tile(1)),
              const SizedBox(height: _gap),
              Expanded(child: tile(2)),
            ]),
          ),
        ]);
      default:
        final extra = f.length - 4;
        return Column(children: [
          Expanded(
            child: Row(children: [
              Expanded(child: tile(0)),
              const SizedBox(width: _gap),
              Expanded(child: tile(1)),
            ]),
          ),
          const SizedBox(height: _gap),
          Expanded(
            child: Row(children: [
              Expanded(child: tile(2)),
              const SizedBox(width: _gap),
              Expanded(child: tile(3, moreCount: extra)),
            ]),
          ),
        ]);
    }
  }
}

class _Tile extends StatefulWidget {
  final List<NoteFile> allFiles;
  final int index;
  final int moreCount;
  const _Tile({
    required this.allFiles,
    required this.index,
    this.moreCount = 0,
  });

  NoteFile get file => allFiles[index];

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.file;
    final inner = _buildContent(context, f);
    return GestureDetector(
      onTap: () => _onTap(context, f),
      child: Stack(
        fit: StackFit.expand,
        children: [
          inner,
          if (widget.moreCount > 0)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: Text(
                  '+${widget.moreCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, NoteFile f) {
    if (f.isSensitive && !_revealed) {
      setState(() => _revealed = true);
      return;
    }
    if (f.isImage || f.isVideo) {
      // Open the full-screen viewer pre-paged to this tile's index.
      // Both images and videos route here; audio + generic
      // attachments still no-op for now.
      Navigator.of(context).push(
        PageRouteBuilder<void>(
          opaque: false,
          barrierColor: Colors.black,
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (_, __, ___) => MediaViewerScreen(
            files: widget.allFiles,
            initialIndex: widget.index,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context, NoteFile f) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(color: scheme.surfaceContainerHighest);
    Widget content;
    if (f.isImage) {
      content = _imageTile(context, f, placeholder);
    } else if (f.isVideo) {
      // Inline playback comes with the media viewer in . For now,
      // surface the thumbnail (Misskey populates one for videos) with a
      // play icon so the user knows it's playable on tap-through.
      content = Stack(
        fit: StackFit.expand,
        children: [
          if (f.thumbnailUrl != null)
            NetImage(
              url: f.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: placeholder,
              errorWidget: placeholder,
            )
          else
            placeholder,
          const Center(
            child: Icon(Icons.play_circle_fill,
                color: Colors.white, size: 56),
          ),
        ],
      );
    } else if (f.isAudio) {
      content = Container(
        color: scheme.surfaceContainerHigh,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.audiotrack, color: scheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                f.name ?? 'Audio',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    } else {
      content = Container(
        color: scheme.surfaceContainerHigh,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.attachment, color: scheme.outline),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                f.name ?? f.type,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    if (f.isSensitive && !_revealed) {
      // The image stays mounted underneath so revealing is instant
      // (no re-fetch). A slight dark scrim keeps the pill legible
      // against bright photos.
      content = SensitiveVeil(
        expand: true,
        sigma: 16,
        scrim: Colors.black.withValues(alpha: 0.18),
        label: 'Sensitive · Tap to view',
        onReveal: () => setState(() => _revealed = true),
        child: content,
      );
    }
    return content;
  }

  /// Widest decode we ask the engine for, in physical pixels per axis.
  /// Bounds memory on very wide tiles (tablet, desktop window): a
  /// 4000px photo decoded at 2048px is ~16MB RGBA instead of ~64MB.
  static const _maxDecodePx = 2048;

  /// Decode targets are rounded up to this granularity so a rotation
  /// or window resize doesn't mint a fresh image-cache key (and a
  /// fresh decode) for every few pixels of width.
  static const _decodeBucket = 128;

  /// Image tile: the full-resolution `url`, decoded down-sampled to the
  /// tile's physical pixel size, with the server thumbnail (~500px —
  /// blurry on a 3x phone, but instant from cache) underneath while the
  /// full image fetches.
  ///
  /// While a sensitive tile is still blurred only the thumbnail is
  /// loaded: no point pulling megabytes for an image the user hasn't
  /// asked to see, and the blur hides the resolution anyway. Revealing
  /// swaps in the full image with the (already cached) thumbnail as its
  /// placeholder, so the swap is seamless.
  Widget _imageTile(BuildContext context, NoteFile f, Widget placeholder) {
    final scheme = Theme.of(context).colorScheme;
    final thumb = f.thumbnailUrl;
    final hasThumb = thumb != null && thumb.isNotEmpty && thumb != f.url;
    final broken = Container(
      color: scheme.errorContainer,
      alignment: Alignment.center,
      child: Icon(Icons.broken_image, color: scheme.onErrorContainer),
    );
    Widget thumbnail({required Widget onError}) => NetImage(
          url: thumb!,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          placeholder: placeholder,
          errorWidget: onError,
        );
    if (hasThumb && f.isSensitive && !_revealed) {
      return thumbnail(onError: placeholder);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        int? target(double logical) {
          if (!logical.isFinite || logical <= 0) return null;
          final px = (logical * dpr).ceil();
          final bucketed = (px + _decodeBucket - 1) ~/ _decodeBucket * _decodeBucket;
          return math.min(bucketed, _maxDecodePx);
        }

        final tileW = constraints.hasBoundedWidth ? constraints.maxWidth : 0.0;
        final tileH =
            constraints.hasBoundedHeight ? constraints.maxHeight : 0.0;
        // `BoxFit.cover` scales the image by whichever axis needs more
        // magnification. Decoding to the tile *width* alone leaves a
        // landscape photo in a portrait tile (the tall left tile of the
        // 3-up layout, say) upscaled and soft, so when the file's
        // dimensions are known pick the binding axis; width otherwise.
        final dimsKnown =
            f.width != null && f.height != null && f.width! > 0 && f.height! > 0;
        final heightBinds = dimsKnown &&
            tileW > 0 &&
            tileH > 0 &&
            f.aspectRatio > tileW / tileH;
        // Null (= decode at native size) only when the tile is
        // unbounded or zero-sized, which doesn't happen inside the grid.
        final memCacheWidth = heightBinds ? null : target(tileW);
        final memCacheHeight = heightBinds ? target(tileH) : null;
        return NetImage(
          url: f.url,
          memCacheWidth: memCacheWidth,
          memCacheHeight: memCacheHeight,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          placeholder:
              hasThumb ? thumbnail(onError: placeholder) : placeholder,
          // If the original is gone but the proxied thumbnail survives,
          // show that rather than a broken-image box.
          errorWidget: hasThumb ? thumbnail(onError: broken) : broken,
        );
      },
    );
  }
}
