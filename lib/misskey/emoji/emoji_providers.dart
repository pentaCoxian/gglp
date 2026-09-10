import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../models/account.dart';
import 'emoji_repository.dart';

/// App-lifetime singleton.
final emojiRepositoryProvider = Provider<EmojiRepository>((ref) {
  final repo = EmojiRepository(dao: ref.watch(emojiDaoProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

/// Tick-stream of host-name sets whose catalogs just changed (already
/// coalesced by the repository). Surfaces that browse *every* host —
/// the reaction picker, the emoji autocomplete — watch this and
/// rebuild so emoji that were previously text fallbacks can become
/// images.
///
/// Per-emoji widgets should watch [emojiHostTickProvider] for their
/// own host instead: every widget watching this provider rebuilds
/// whenever *any* host changes, which on a busy federated timeline
/// means every emoji on screen rebuilding for a catalog it never uses.
final emojiCatalogTickProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(emojiRepositoryProvider).updates;
});

/// Per-host tick: only notifies when [host]'s catalog changed. The
/// value is a monotonically increasing counter so each change is a
/// distinct state (a `Set` filtered to one host would compare equal
/// tick to tick and be swallowed).
///
/// `autoDispose` so hosts that scroll off screen don't keep a stream
/// subscription for the app lifetime — federated hosts are unbounded.
final emojiHostTickProvider =
    StreamProvider.autoDispose.family<int, String>((ref, host) {
  var n = 0;
  return ref
      .watch(emojiRepositoryProvider)
      .updates
      .where((hosts) => hosts.contains(host))
      .map((_) => ++n);
});

/// App-lifetime bootstrap. Watches the accounts list and fires a
/// background `/emojis` fetch the first time we see each host.
/// Rendering doesn't depend on this completing — lookups fall back to
/// text until the catalog arrives — but it keeps reaction picker UX
/// instantaneous for newly added accounts.
///
/// `Provider` instead of `Provider.autoDispose` so it stays alive for
/// the whole app session.
final emojiCatalogBootstrapProvider = Provider<void>((ref) {
  final repo = ref.watch(emojiRepositoryProvider);
  final seen = <String>{};
  ref.listen<AsyncValue<List<Account>>>(
    accountsProvider,
    (_, next) async {
      final accounts = next.valueOrNull ?? const [];
      for (final a in accounts) {
        if (!seen.add(a.host)) continue;
        try {
          final client = await ref
              .read(accountRepositoryProvider)
              .clientFor(a);
          if (client == null) continue;
          // Fire and forget; failures are logged inside the repo.
          unawaited(repo.ensureFetched(client: client));
        } catch (_) {
          /* logged inside repo */
        }
      }
    },
    fireImmediately: true,
  );
});
