import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../misskey/models/account.dart';
import '../../misskey/models/note.dart';
import '../../misskey/streaming/stream_providers.dart';
import 'height_recorder.dart';
import 'note_card.dart';

/// `NoteCard` wrapped with viewport-aware capture (subNote/unsubNote)
/// for the account that delivered the note.
///
/// `attributionAccount` is the account whose websocket delivered this
/// note (may differ from the note's `sourceHost` for federated copies).
/// Capture frames are scoped to that account's connection.
class CapturedNoteCard extends ConsumerWidget {
  final Note note;
  final Account attributionAccount;

  /// Dense-stream rendering (see [NoteCard.stream]). Also namespaces
  /// the height-cache bucket, since stream rows lay out shorter than
  /// carded ones and stale card heights would cause scroll jitter.
  final bool stream;

  const CapturedNoteCard({
    super.key,
    required this.note,
    required this.attributionAccount,
    this.stream = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(noteCaptureManagerProvider(attributionAccount));
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final scale = mediaQuery.textScaler.scale(1.0);
    final brightness = Theme.of(context).brightness;
    return VisibilityDetector(
      // visibility_detector requires a globally-unique key. Combine
      // attribution account id with the note's globalId so two cards
      // for the same federated note in different timelines get
      // distinct keys.
      key: Key('cap:${attributionAccount.id}:${note.globalId}'),
      onVisibilityChanged: (info) {
        if (manager == null) return;
        // Threshold: card is "visible" once at least 10% of its
        // pixels are on-screen. Lower means we capture too eagerly
        // when the timeline scrolls fast.
        if (info.visibleFraction > 0.1) {
          manager.onVisible(note.id);
        } else {
          manager.onHidden(note.id);
        }
      },
      // After the card lays out, write the actual height into the
      // height cache so future cold-starts have warm data.
      child: HeightRecorder(
        note: note,
        width: width,
        textScale: scale,
        themeId: stream ? '${brightness.name}-stream' : brightness.name,
        cwExpanded: false,
        mfmSettingsHash: 'v1',
        child: NoteCard(
          note: note,
          attributionAccount: attributionAccount,
          stream: stream,
        ),
      ),
    );
  }
}
