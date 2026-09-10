import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/note.dart';
import '../../timeline/antenna_timeline_controller.dart';
import '../plus/plus.dart';
import '../widgets/captured_note_card.dart';

/// Standalone view of a single Misskey antenna's timeline.
class AntennaTimelineScreen extends ConsumerStatefulWidget {
  final Account account;
  final String antennaId;
  final String? initialName;

  const AntennaTimelineScreen({
    super.key,
    required this.account,
    required this.antennaId,
    this.initialName,
  });

  static Future<void> open(
    BuildContext context, {
    required Account account,
    required String antennaId,
    String? initialName,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AntennaTimelineScreen(
          account: account,
          antennaId: antennaId,
          initialName: initialName,
        ),
      ),
    );
  }

  @override
  ConsumerState<AntennaTimelineScreen> createState() =>
      _AntennaTimelineScreenState();
}

class _AntennaTimelineScreenState
    extends ConsumerState<AntennaTimelineScreen> {
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
    final notifier = ref.read(antennaTimelineControllerProvider(
      AntennaTimelineArgs(
          account: widget.account, antennaId: widget.antennaId),
    ).notifier);
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      notifier.loadMore();
    }
    notifier.setHoldPending(_scroll.position.pixels > _topThreshold);
  }

  void _onBannerTap(WidgetRef ref) {
    ref
        .read(antennaTimelineControllerProvider(
          AntennaTimelineArgs(
              account: widget.account, antennaId: widget.antennaId),
        ).notifier)
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
    final args = AntennaTimelineArgs(
      account: widget.account,
      antennaId: widget.antennaId,
    );
    final infoAsync =
        ref.watch(_antennaInfoProvider((widget.account, widget.antennaId)));
    final title = infoAsync.maybeWhen(
      data: (info) => info?['name'] as String? ?? widget.initialName ?? 'Antenna',
      orElse: () => widget.initialName ?? 'Antenna',
    );
    final state = ref.watch(antennaTimelineControllerProvider(args));
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.satellite_alt_outlined, size: 18),
            const SizedBox(width: 6),
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          // Flat icon action on the brand app bar.
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: PlusIconButton(
                icon: Icons.refresh,
                tooltip: 'Refresh',
                onBrand: true,
                onTap: () => ref
                    .read(antennaTimelineControllerProvider(args).notifier)
                    .refresh(),
              ),
            ),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load: $e'),
          ),
        ),
        data: (s) => Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref
                  .read(antennaTimelineControllerProvider(args).notifier)
                  .refresh(),
              child: ListView.builder(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: s.notes.length + 1,
                itemBuilder: (_, i) {
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
                  return _LiveNote(
                    args: args,
                    snapshot: s.notes[i],
                    attribution: widget.account,
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
                  child: _PendingPill(
                    count: s.pending.length,
                    onTap: () => _onBannerTap(ref),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveNote extends ConsumerWidget {
  final AntennaTimelineArgs args;
  final Note snapshot;
  final Account attribution;
  const _LiveNote({
    required this.args,
    required this.snapshot,
    required this.attribution,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // O(1) per emission: the selector is re-run for every mounted row
    // on every state change, so a linear scan here was O(rows × notes)
    // per incoming note.
    final key = snapshot.globalId;
    final live = ref.watch(
      antennaTimelineControllerProvider(
        args,
      ).select((async) => async.valueOrNull?.byId[key]),
    );
    return CapturedNoteCard(
      key: ValueKey(snapshot.globalId),
      note: live ?? snapshot,
      attributionAccount: attribution,
    );
  }
}

class _PendingPill extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _PendingPill({required this.count, required this.onTap});

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

final _antennaInfoProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, (Account, String)>((ref, key) async {
  final endpoints = await ref.watch(misskeyEndpointsProvider(key.$1).future);
  if (endpoints == null) return null;
  try {
    return await endpoints.antennasShow(key.$2);
  } catch (_) {
    return null;
  }
});
