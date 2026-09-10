import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../misskey/models/note_file.dart';
import '../widgets/net_image.dart';

/// Full-screen multi-image viewer.
///
/// Features:
///   - swipe between attachments (PageView)
///   - pinch + double-tap zoom (InteractiveViewer per page)
///   - position counter ("2 / 4")
///   - copy URL / open in browser via overflow menu
///   - tap-to-dismiss on the backdrop
///
/// Non-image attachments (video, audio) render a placeholder card —
/// inline playback is a follow-up.
class MediaViewerScreen extends StatefulWidget {
  final List<NoteFile> files;
  final int initialIndex;

  const MediaViewerScreen({
    super.key,
    required this.files,
    required this.initialIndex,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late final PageController _pages;
  late int _index;

  @override
  void initState() {
    super.initState();
    // clamp() throws when the upper bound is below the lower one, so
    // an empty attachment list must short-circuit.
    _index = widget.files.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.files.length - 1);
    _pages = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.files.isEmpty) {
      // Nothing to show: keep the route dismissable rather than
      // indexing into an empty list.
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ),
      );
    }
    final file = widget.files[_index];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Tap-to-dismiss backdrop. Wrapped in IgnorePointer once a
            // child is being interacted with so InteractiveViewer
            // gestures don't fight the dismiss tap.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            PageView.builder(
              controller: _pages,
              itemCount: widget.files.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final f = widget.files[i];
                if (f.isVideo) return _VideoPage(file: f);
                return _ZoomablePage(file: f);
              },
            ),
            // Top bar: counter + close + overflow.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                index: _index,
                total: widget.files.length,
                file: file,
                onClose: () => Navigator.of(context).maybePop(),
              ),
            ),
            // Optional comment / alt-text strip at the bottom.
            if ((file.comment ?? '').isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _Caption(text: file.comment!),
              ),
          ],
        ),
      ),
    );
  }
}

/// One page of the viewer: a single zoomable image with double-tap to
/// reset / zoom in.
class _ZoomablePage extends StatefulWidget {
  final NoteFile file;
  const _ZoomablePage({required this.file});

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage>
    with SingleTickerProviderStateMixin {
  final _viewer = TransformationController();
  late final AnimationController _anim;
  Animation<Matrix4>? _resetAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(() {
        final v = _resetAnim?.value;
        if (v != null) _viewer.value = v;
      });
  }

  @override
  void dispose() {
    _viewer.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _onDoubleTap(TapDownDetails d) {
    final current = _viewer.value;
    final isZoomed = current.getMaxScaleOnAxis() > 1.01;
    final Matrix4 target;
    if (isZoomed) {
      target = Matrix4.identity();
    } else {
      // Zoom into the tap location, scale 2.5x.
      const scale = 2.5;
      final pos = d.localPosition;
      target = Matrix4.identity()
        ..translate(-pos.dx * (scale - 1), -pos.dy * (scale - 1))
        ..scale(scale);
    }
    _resetAnim = Matrix4Tween(begin: current, end: target).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
    _anim
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.file;
    if (!f.isImage) {
      // Video lands in [_VideoPage] one level up; we only get
      // here for audio / generic-attachment files.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                f.isAudio ? Icons.audiotrack : Icons.attachment,
                size: 64,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              Text(
                f.name ?? f.type,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 4),
              const Text(
                'Inline playback for this file type isn\'t available yet.',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      onDoubleTapDown: _onDoubleTap,
      // GestureDetector swallows the parent's tap-to-dismiss; let
      // single taps fall through to the backdrop by NOT defining onTap.
      child: InteractiveViewer(
        transformationController: _viewer,
        minScale: 1.0,
        maxScale: 6.0,
        clipBehavior: Clip.none,
        child: Center(
          child: NetImage(
            url: f.url,
            fit: BoxFit.contain,
            placeholder: const Center(child: CircularProgressIndicator()),
            errorWidget: const Icon(Icons.broken_image, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Inline video playback page.
///
/// Loads on `initState`, auto-plays once ready, and shows a tap-toggle
/// play/pause overlay plus a scrubbable progress bar. We don't reuse
/// `chewie` or similar wrappers since they bring a full custom UI; the
/// raw `video_player` plugin is enough for an in-app preview.
class _VideoPage extends StatefulWidget {
  final NoteFile file;
  const _VideoPage({required this.file});

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  VideoPlayerController? _controller;
  bool _showOverlay = true;
  Object? _initError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.file.url));
      _controller = c;
      await c.initialize();
      // Loop short clips like Misskey's web client does. Long videos
      // still loop — that's a feature for memes.
      await c.setLooping(true);
      await c.play();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _initError = e);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
      } else {
        c.play();
      }
      _showOverlay = !c.value.isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: Colors.white70),
              const SizedBox(height: 12),
              Text(
                'Failed to load video',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                '$_initError',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: () {
        // Toggle overlay first, then play state on the same tap so a
        // single tap shows controls and another tap dismisses or
        // toggles playback.
        if (_showOverlay) {
          _togglePlay();
        } else {
          setState(() => _showOverlay = true);
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: c.value.aspectRatio,
              child: VideoPlayer(c),
            ),
          ),
          AnimatedOpacity(
            opacity: _showOverlay || !c.value.isPlaying ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 180),
            child: Container(
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 24),
                // Dense chrome: cap text scaling like Material's own
                // bars do, so the time readout can't push the scrubber
                // off a narrow screen at accessibility sizes.
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 2.0,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          c.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 40,
                        ),
                        onPressed: _togglePlay,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: VideoProgressIndicator(
                          c,
                          allowScrubbing: true,
                          colors: VideoProgressColors(
                            playedColor: Colors.white,
                            bufferedColor:
                                Colors.white.withValues(alpha: 0.4),
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatDuration(c.value.position)} '
                        '/ ${_formatDuration(c.value.duration)}',
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          // Fixed-width digits keep the scrubber from
                          // jittering as the position ticks.
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }
}

class _TopBar extends StatelessWidget {
  final int index;
  final int total;
  final NoteFile file;
  final VoidCallback onClose;

  const _TopBar({
    required this.index,
    required this.total,
    required this.file,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onClose,
            ),
            const Spacer(),
            if (total > 1)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${index + 1} / $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (v) async {
                switch (v) {
                  case 'copy':
                    await Clipboard.setData(ClipboardData(text: file.url));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Image URL copied')),
                      );
                    }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'copy',
                  child: Text('Copy image URL'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  final String text;
  const _Caption({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.65),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
