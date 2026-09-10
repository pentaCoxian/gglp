import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../mfm/parser.dart';
import '../../mfm/renderer.dart';
import '../../misskey/emoji/emoji_providers.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/note_file.dart';
import '../../misskey/models/page_block.dart';
import '../../misskey/models/parsers.dart';
import '../plus/plus.dart';
import '../widgets/captured_note_card.dart';
import '../widgets/emoji_image.dart';
import '../widgets/net_image.dart';
import 'media_viewer_screen.dart';
import 'page_editor_screen.dart';

/// Viewer for a Misskey Page.
///
/// Pulls metadata + content blocks via `pages/show` and renders the
/// title, eye-catch, summary, and the supported block types. The
/// editor button is shown only when the active account owns the page.
class PageViewerScreen extends ConsumerWidget {
  final Account viewerAccount;
  final String? pageId;

  /// Alternative lookup path: `pages/show` accepts `username + name`
  /// so a page link can be opened without a numeric id.
  final String? pageName;
  final String? authorUsername;

  const PageViewerScreen({
    super.key,
    required this.viewerAccount,
    this.pageId,
    this.pageName,
    this.authorUsername,
  })  : assert(pageId != null || (pageName != null && authorUsername != null),
            'pass pageId or (pageName + authorUsername)');

  static Future<void> openById(
    BuildContext context, {
    required Account viewerAccount,
    required String pageId,
  }) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PageViewerScreen(
            viewerAccount: viewerAccount,
            pageId: pageId,
          ),
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(_pageProvider((
      viewerAccount,
      pageId,
      pageName,
      authorUsername,
    )));
    return Scaffold(
      appBar: AppBar(),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load page: $e'),
          ),
        ),
        data: (raw) {
          if (raw == null) {
            return const Center(child: Text('Page not found.'));
          }
          // Ingest emoji blocks from the page user (Misskey returns
          // user.emojis on author objects).
          final user = raw['user'];
          if (user is Map<String, dynamic>) {
            MisskeyParsers.ingestUserEmojis(
              user,
              viewerHost: viewerAccount.host,
              repo: ref.read(emojiRepositoryProvider),
            );
          }
          ref.watch(emojiCatalogTickProvider);

          final title = raw['title'] as String? ??
              raw['name'] as String? ??
              'Untitled';
          final summary = raw['summary'] as String?;
          final eyecatchUrl =
              raw['eyeCatchingImage']?['url'] as String?;
          final blocksJson = (raw['content'] as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();
          final blocks = blocksJson
              .map(PageBlock.fromJson)
              .toList(growable: false);
          final ownerId = raw['userId'] as String?;
          final isOwner =
              ownerId != null && ownerId == viewerAccount.userId;

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
            children: [
              if (eyecatchUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: NetImage(
                    url: eyecatchUrl,
                    fit: BoxFit.cover,
                    errorWidget: Container(color: theme.colorScheme.primary),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (summary != null && summary.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _MfmText(
                    text: summary,
                    viewerHost: viewerAccount.host,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              if (isOwner)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit page'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PageEditorScreen(
                            account: viewerAccount,
                            existingPageRaw: raw,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              for (final b in blocks)
                PageBlockView(
                  block: b,
                  viewerAccount: viewerAccount,
                ),
            ],
          );
        },
      ),
    );
  }
}

class PageBlockView extends StatelessWidget {
  final PageBlock block;
  final Account viewerAccount;
  const PageBlockView({
    super.key,
    required this.block,
    required this.viewerAccount,
  });

  @override
  Widget build(BuildContext context) {
    switch (block) {
      case PageBlockText(:final text):
        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          child: _MfmText(
            text: text,
            viewerHost: viewerAccount.host,
          ),
        );
      case PageBlockSection(:final title, :final children):
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              for (final c in children)
                PageBlockView(block: c, viewerAccount: viewerAccount),
            ],
          ),
        );
      case PageBlockImage(:final fileId):
        return _PageImageBlock(account: viewerAccount, fileId: fileId);
      case PageBlockNote(:final noteId, :final detailed):
        return _PageNoteEmbed(
          account: viewerAccount,
          noteId: noteId,
          detailed: detailed,
        );
      case PageBlockOther(:final raw):
        // Flat bordered notice rect replacing the old recessed well.
        return Container(
          margin: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: PlusTheme.of(context).surfaceSubtle,
            borderRadius: BorderRadius.circular(PlusRadii.card),
            border: Border.all(color: PlusTheme.of(context).border),
          ),
          child: Row(
            children: [
              const Icon(Icons.help_outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Block type "${raw['type']}" not yet supported in '
                  'this viewer.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// Inline MFM text used for both summary + text blocks. Renders custom
/// emoji against the active account's host. Tier-3 effects respect the
/// global animated-MFM toggle the same way notes do.
class _MfmText extends ConsumerStatefulWidget {
  final String text;
  final String viewerHost;
  final TextStyle? style;
  const _MfmText({
    required this.text,
    required this.viewerHost,
    this.style,
  });

  @override
  ConsumerState<_MfmText> createState() => _MfmTextState();
}

class _MfmTextState extends ConsumerState<_MfmText> {
  /// Owns the tap recognizers the renderer creates; disposed on
  /// rebuild and unmount.
  MfmRenderer? _renderer;

  @override
  void dispose() {
    _renderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.style;
    final emojiSize =
        ((style ?? theme.textTheme.bodyMedium)?.fontSize ?? 14) * 1.4;
    _renderer?.dispose();
    final renderer = _renderer = MfmRenderer(
      context: context,
      animateEffects: EffectSettings.shouldAnimate(context, ref),
      callbacks: MfmCallbacks(
        resolveEmoji: (raw) => EmojiImage(
          rawName: raw,
          viewerHost: widget.viewerHost,
          size: emojiSize,
        ),
      ),
    );
    if (style == null) return renderer.render(parseMfm(widget.text));
    return DefaultTextStyle.merge(
      style: style,
      child: renderer.render(parseMfm(widget.text)),
    );
  }
}

/// Resolves a drive file id into a usable URL via `drive/files/show`.
/// Tapping opens the existing media viewer with a single-image carousel
/// so pinch-zoom + copy-URL work the same as in note attachments.
class _PageImageBlock extends ConsumerWidget {
  final Account account;
  final String? fileId;
  const _PageImageBlock({required this.account, required this.fileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    if (fileId == null) {
      return const SizedBox.shrink();
    }

    // Flat bordered rect used for the loading / error / missing states.
    Widget notice(Widget child) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: plus.surfaceSubtle,
            borderRadius: BorderRadius.circular(PlusRadii.card),
            border: Border.all(color: plus.border),
          ),
          child: child,
        );

    final async = ref.watch(pageDriveFileProvider((account, fileId!)));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: async.when(
        loading: () => AspectRatio(
          aspectRatio: 16 / 9,
          child: notice(
            const Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (e, _) => notice(
          Text('Failed to load image: $e',
              style: theme.textTheme.bodySmall),
        ),
        data: (file) {
          if (file == null) {
            return notice(
              Text('Image (drive file $fileId) not accessible.',
                  style: theme.textTheme.bodySmall),
            );
          }
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MediaViewerScreen(
                  files: [file],
                  initialIndex: 0,
                ),
                fullscreenDialog: true,
              ));
            },
            // Flat white card frame around the picture — square
            // corners, hairline card shadow.
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: plus.surface,
                borderRadius: BorderRadius.circular(PlusRadii.media),
                boxShadow: plus.shadowCard,
              ),
              child: AspectRatio(
                aspectRatio: file.aspectRatio,
                child: NetImage(
                  url: file.url,
                  fit: BoxFit.cover,
                  placeholder: Container(
                    color: theme.colorScheme.surfaceContainerHigh,
                  ),
                  errorWidget: Container(
                    color: theme.colorScheme.errorContainer,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Drive-file resolver shared by the viewer + editor preview. Cached
/// per (account, fileId) to avoid re-fetching while the page is open.
/// autoDispose so a closed page releases the cache.
final pageDriveFileProvider = FutureProvider.autoDispose
    .family<NoteFile?, (Account, String)>((ref, key) async {
  final endpoints = await ref.watch(misskeyEndpointsProvider(key.$1).future);
  if (endpoints == null) return null;
  try {
    return await endpoints.driveFilesShow(key.$2);
  } catch (_) {
    return null;
  }
});

class _PageNoteEmbed extends ConsumerWidget {
  final Account account;
  final String? noteId;
  final bool detailed;
  const _PageNoteEmbed({
    required this.account,
    required this.noteId,
    required this.detailed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (noteId == null) {
      return const SizedBox.shrink();
    }
    final async = ref.watch(_pageNoteProvider((account, noteId!)));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Failed to load embedded note: $e'),
      ),
      data: (note) => note == null
          ? const SizedBox.shrink()
          : CapturedNoteCard(
              note: note,
              attributionAccount: account,
            ),
    );
  }
}

final _pageProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, (Account, String?, String?, String?)>(
        (ref, key) async {
  final endpoints = await ref.watch(misskeyEndpointsProvider(key.$1).future);
  if (endpoints == null) return null;
  try {
    return await endpoints.pagesShow(
      pageId: key.$2,
      name: key.$3,
      username: key.$4,
    );
  } catch (_) {
    return null;
  }
});

/// One-off note resolver for `note` page blocks. autoDispose so we
/// don't keep these around once the page is closed.
final _pageNoteProvider =
    FutureProvider.autoDispose.family((ref, (Account, String) key) async {
  final endpoints = await ref.watch(misskeyEndpointsProvider(key.$1).future);
  if (endpoints == null) return null;
  try {
    return await endpoints.notesShow(key.$2);
  } catch (_) {
    return null;
  }
});
