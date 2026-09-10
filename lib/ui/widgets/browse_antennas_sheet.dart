import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../misskey/models/account.dart';
import '../plus/plus.dart';
import '../screens/antenna_timeline_screen.dart';

/// Bottom sheet listing the active account's antennas. Tapping a row
/// pushes the standalone antenna viewer.
class BrowseAntennasSheet extends ConsumerWidget {
  final Account account;
  const BrowseAntennasSheet({super.key, required this.account});

  static Future<void> show(
    BuildContext context, {
    required Account account,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BrowseAntennasSheet(account: account),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(_antennasListProvider(account));
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
                children: [
                  Flexible(
                    child: Text(
                      'Antennas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '@${account.username}@${account.host}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const PlusDivider(margin: EdgeInsets.symmetric(horizontal: 16)),
            Expanded(
              child: async.when(
                skipLoadingOnReload: true,
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Failed to load antennas: $e'),
                  ),
                ),
                data: (antennas) {
                  if (antennas.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          "You haven't created any antennas on "
                          "${account.host} yet. Create one in Misskey "
                          "web to use it here.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }
                  // Flat white rows with an ink press state; a hairline
                  // divider separates rows (2014 list styling).
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: antennas.length,
                    itemBuilder: (_, i) {
                      final a = antennas[i];
                      final id = a['id'] as String? ?? '';
                      final name = a['name'] as String? ?? id;
                      final keywords = (a['keywords'] as List?)
                              ?.expand((g) => (g as List).cast<String>())
                              .where((s) => s.isNotEmpty)
                              .join(' · ') ??
                          '';
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          AntennaTimelineScreen.open(
                            context,
                            account: account,
                            antennaId: id,
                            initialName: name,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                child: Icon(Icons.satellite_alt_outlined,
                                    size: 18, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    if (keywords.isNotEmpty)
                                      Text(
                                        keywords,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

final _antennasListProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Account>((ref, account) async {
  final endpoints =
      await ref.watch(misskeyEndpointsProvider(account).future);
  if (endpoints == null) return const [];
  return endpoints.antennasList();
});
