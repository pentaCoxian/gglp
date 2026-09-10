import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network image that shows each frame the instant it is decoded.
///
/// `CachedNetworkImage` fades every frame that wasn't already in the
/// in-memory cache, so even a disk-cache hit decoded in a few
/// milliseconds animates in — which reads as latency while scrolling.
/// This widget never fades: the [placeholder] is shown until the first
/// frame exists and is then replaced immediately.
///
/// Backed by [CachedNetworkImageProvider], so the disk and memory
/// caches are shared with the rest of the app. [memCacheWidth] /
/// [memCacheHeight] bound the decoded bitmap like the corresponding
/// `CachedNetworkImage` parameters.
class NetImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Map<String, String>? headers;

  /// Shown until the first frame is available.
  final Widget? placeholder;

  /// Shown when the image fails to load.
  final Widget? errorWidget;

  const NetImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.memCacheWidth,
    this.memCacheHeight,
    this.headers,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final provider = ResizeImage.resizeIfNeeded(
      memCacheWidth,
      memCacheHeight,
      CachedNetworkImageProvider(url, headers: headers),
    );
    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      // Keep showing the previous bitmap while a new URL decodes
      // (thumbnail → full-size swaps) instead of flashing empty.
      gaplessPlayback: true,
      errorBuilder:
          errorWidget == null ? null : (_, __, ___) => errorWidget!,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return placeholder ?? child;
      },
    );
  }
}
