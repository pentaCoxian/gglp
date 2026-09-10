import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../misskey/models/account.dart';
import '../plus/plus.dart';
import '../screens/page_editor_screen.dart';
import '../screens/page_viewer_screen.dart';

/// Bottom sheet listing the active account's authored pages plus a
/// "New page" affordance.
class MyPagesSheet extends ConsumerWidget {
  final Account account;
  const MyPagesSheet({super.key, required this.account});

  static Future<void> show(
    BuildContext context, {
    required Account account,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MyPagesSheet(account: account),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(_iPagesProvider(account));
    // Size from the viewport left once the keyboard is up (the Column
    // below doesn't scroll); `minimum` keeps the sheet above it.
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final height = (MediaQuery.sizeOf(context).height - insets) * 0.7;
    return SafeArea(
      minimum: EdgeInsets.only(bottom: insets),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                // Title left, button right; both shrink with an
                // ellipsis rather than overflow at large text scale.
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Pages',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'New page',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        PageEditorScreen.openNew(context, account: account);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const PlusDivider(),
            Expanded(
              child: async.when(
                skipLoadingOnReload: true,
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Failed to load pages: $e'),
                  ),
                ),
                data: (pages) {
                  if (pages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No pages yet. Tap "New page" to write one.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: pages.length,
                    separatorBuilder: (_, __) => const PlusDivider(),
                    itemBuilder: (_, i) {
                      final p = pages[i];
                      final id = p['id'] as String? ?? '';
                      final title = p['title'] as String? ??
                          p['name'] as String? ??
                          '(untitled)';
                      final summary = p['summary'] as String? ?? '';
                      return ListTile(
                        leading: const Icon(Icons.article_outlined),
                        title: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: summary.isEmpty
                            ? null
                            : Text(
                                summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        onTap: () {
                          Navigator.of(context).pop();
                          PageViewerScreen.openById(
                            context,
                            viewerAccount: account,
                            pageId: id,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _iPagesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Account>((ref, account) async {
  final endpoints = await ref.watch(misskeyEndpointsProvider(account).future);
  if (endpoints == null) return const [];
  return endpoints.iPages();
});
