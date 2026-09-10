import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../misskey/models/account.dart';
import 'providers.dart';

/// What's currently shown in the timeline area. Either:
///   - a specific account, or
///   - the unified multi-account view, or
///   - nothing (no accounts yet).
sealed class TimelineSelection {
  const TimelineSelection();
}

class SingleAccount extends TimelineSelection {
  final Account account;
  const SingleAccount(this.account);
}

class UnifiedAccounts extends TimelineSelection {
  const UnifiedAccounts();
}

/// A user-defined custom unified timeline, identified by id. The full
/// definition (sources, name, etc.) is fetched from
/// `customTimelinesProvider` at render time so a delete or edit
/// elsewhere immediately propagates here.
class CustomTimelineSelected extends TimelineSelection {
  final String timelineId;
  const CustomTimelineSelected(this.timelineId);
}

class NoSelection extends TimelineSelection {
  const NoSelection();
}

class ActiveAccountController extends Notifier<TimelineSelection> {
  @override
  TimelineSelection build() {
    // React to changes in the accounts list to keep `state` consistent.
    ref.listen<AsyncValue<List<Account>>>(accountsProvider, (_, next) {
      final accounts = next.valueOrNull ?? const [];
      final cur = state;
      switch (cur) {
        case NoSelection():
          if (accounts.isNotEmpty) state = SingleAccount(accounts.first);
        case SingleAccount(:final account):
          if (!accounts.any((a) => a.id == account.id)) {
            state = accounts.isEmpty
                ? const NoSelection()
                : SingleAccount(accounts.first);
          }
        case UnifiedAccounts():
          if (accounts.isEmpty) state = const NoSelection();
        case CustomTimelineSelected():
          // The custom timeline itself may be invalid (account
          // dropped, sources empty) but we leave the *selection*
          // alone — the controller renders an empty state when its
          // sources resolve to nothing, and re-add-account would
          // restore it. Falling back to NoSelection only when there
          // are zero accounts at all.
          if (accounts.isEmpty) state = const NoSelection();
      }
    });

    final initial = ref.read(accountsProvider).valueOrNull ?? const [];
    return initial.isEmpty
        ? const NoSelection()
        : SingleAccount(initial.first);
  }

  void selectAccount(Account a) => state = SingleAccount(a);
  void selectUnified() => state = const UnifiedAccounts();
  void selectCustom(String timelineId) =>
      state = CustomTimelineSelected(timelineId);
}

final activeAccountProvider =
    NotifierProvider<ActiveAccountController, TimelineSelection>(
  ActiveAccountController.new,
);
