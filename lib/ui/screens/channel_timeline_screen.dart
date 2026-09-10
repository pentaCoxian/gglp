import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/note.dart';
import '../../timeline/channel_timeline_controller.dart';
import '../plus/plus.dart';
import '../widgets/captured_note_card.dart';
import '../widgets/net_image.dart';
import 'compose_screen.dart';

/// Standalone view of a single Misskey channel's timeline.
///
/// Pushed from:
///   - the channel chip at the bottom of any note (tap-through)
///   - the AccountDrawer "Browse channels" sheet
///
/// Header pulls fresh metadata from `channels/show` so we always
/// render the canonical name/banner even if the chip was built from a
/// stale cached note.
class ChannelTimelineScreen extends ConsumerWidget {
  final Account account;
  final String channelId;

  /// Name to use until `channels/show` returns. The chip already
  /// carries it, so we avoid an extra round-trip just to fill the
  /// AppBar title on first paint.
  final String? initialName;

  const ChannelTimelineScreen({
    super.key,
    required this.account,
    required this.channelId,
    this.initialName,
  });

  static Future<void> open(
    BuildContext context, {
    required Account account,
    required String channelId,
    String? initialName,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChannelTimelineScreen(
          account: account,
          channelId: channelId,
          initialName: initialName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ChannelTimelineArgs(account: account, channelId: channelId);
    final infoAsync =
        ref.watch(_channelInfoProvider((account, channelId)));
    final title = infoAsync.maybeWhen(
      data: (info) => info?['name'] as String? ?? initialName ?? 'Channel',
      orElse: () => initialName ?? 'Channel',
    );
    final color = _parseHex(infoAsync.valueOrNull?['color'] as String?);
    final banner = infoAsync.valueOrNull?['bannerUrl'] as String?;
    final description =
        infoAsync.valueOrNull?['description'] as String? ?? '';

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: banner != null ? 200 : 110,
            backgroundColor:
                color ?? Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            title: Text(title),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () => ref
                    .read(channelTimelineControllerProvider(args).notifier)
                    .refresh(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ChannelHeader(
                title: title,
                description: description,
                bannerUrl: banner,
                accent: color,
                handle: '@${account.username}@${account.host}',
              ),
              titlePadding: EdgeInsets.zero,
            ),
          ),
        ],
        body: _ChannelTimelineList(args: args, attribution: account),
      ),
      floatingActionButton: PlusComposeDisc(
        tooltip: 'Post to channel',
        onPressed: () => ComposeScreen.open(
          context,
          account: account,
          mode: ComposeMode.channel,
          channelId: channelId,
          channelName: title,
        ),
      ),
    );
  }

  static Color? _parseHex(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final hex = raw.replaceAll('#', '');
    final padded = switch (hex.length) {
      6 => 'ff$hex',
      8 => hex,
      _ => null,
    };
    if (padded == null) return null;
    final p = int.tryParse(padded, radix: 16);
    return p == null ? null : Color(p);
  }
}

class _ChannelHeader extends StatelessWidget {
  final String title;
  final String description;
  final String? bannerUrl;
  final Color? accent;
  final String handle;
  const _ChannelHeader({
    required this.title,
    required this.description,
    required this.bannerUrl,
    required this.accent,
    required this.handle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = accent ?? theme.colorScheme.primary;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (bannerUrl != null)
          NetImage(
            url: bannerUrl!,
            fit: BoxFit.cover,
            errorWidget: Container(color: base),
          )
        else
          Container(color: base),
        // Bottom-fading overlay so the AppBar title and the
        // channel handle stay legible regardless of banner contents.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.0),
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (description.isNotEmpty)
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                'on $handle',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Body of the channel screen — animated list + scroll-position
/// driven new-notes banner. Mirrors `_TimelineList` shape exactly.
class _ChannelTimelineList extends ConsumerStatefulWidget {
  final ChannelTimelineArgs args;
  final Account attribution;
  const _ChannelTimelineList({
    required this.args,
    required this.attribution,
  });

  @override
  ConsumerState<_ChannelTimelineList> createState() =>
      _ChannelTimelineListState();
}

class _ChannelTimelineListState
    extends ConsumerState<_ChannelTimelineList> {
  final _scroll = ScrollController();

  static const _topThreshold = 32.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final notifier = ref
        .read(channelTimelineControllerProvider(widget.args).notifier);
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      notifier.loadMore();
    }
    notifier.setHoldPending(_scroll.position.pixels > _topThreshold);
  }

  void _onBannerTap() {
    ref
        .read(channelTimelineControllerProvider(widget.args).notifier)
        .releasePending();
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(channelTimelineControllerProvider(widget.args));
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorBlock(
        message: '$e',
        onRetry: () => ref
            .read(channelTimelineControllerProvider(widget.args).notifier)
            .refresh(),
      ),
      data: (s) => Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref
                .read(
                    channelTimelineControllerProvider(widget.args).notifier)
                .refresh(),
            child: ListView.builder(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: s.notes.length + 1,
              itemBuilder: (context, i) {
                if (i == s.notes.length) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: s.reachedEnd
                          ? const Text('— end —')
                          : const CircularProgressIndicator(),
                    ),
                  );
                }
                final note = s.notes[i];
                return _LiveNote(
                  args: widget.args,
                  noteSnapshot: note,
                  attribution: widget.attribution,
                );
              },
            ),
          ),
          if (s.pending.isNotEmpty)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: _ChannelNewNotesBanner(
                  count: s.pending.length,
                  onTap: _onBannerTap,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Single row that subscribes to its own live `Note` from the
/// controller, so reaction patches land here without rebuilding the
/// whole list.
class _LiveNote extends ConsumerWidget {
  final ChannelTimelineArgs args;
  final Note noteSnapshot;
  final Account attribution;
  const _LiveNote({
    required this.args,
    required this.noteSnapshot,
    required this.attribution,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // O(1) per emission (see the antenna list for why).
    final key = noteSnapshot.globalId;
    final live = ref.watch(
      channelTimelineControllerProvider(
        args,
      ).select((async) => async.valueOrNull?.byId[key]),
    );
    return CapturedNoteCard(
      key: ValueKey(noteSnapshot.globalId),
      note: live ?? noteSnapshot,
      attributionAccount: attribution,
    );
  }
}

class _ChannelNewNotesBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _ChannelNewNotesBanner({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 new note' : '$count new notes';
    // White raised rectangle hovering over the timeline — flat 2014
    // chrome, never a capsule.
    return PlusButton.raised(
      onTap: onTap,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_upward, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            PlusButton.text(
              onTap: onRetry,
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

/// Per-(account, channelId) snapshot of `channels/show`. autoDispose so
/// we don't keep the data hanging around when the screen pops.
final _channelInfoProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, (Account, String)>((ref, key) async {
  final endpoints = await ref.watch(misskeyEndpointsProvider(key.$1).future);
  if (endpoints == null) return null;
  try {
    return await endpoints.channelsShow(key.$2);
  } catch (_) {
    return null;
  }
});
