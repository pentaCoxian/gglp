import 'package:flutter/material.dart';

import '../../app/active_account.dart';
import '../../misskey/models/account.dart';
import '../widgets/user_avatar.dart';
import '../widgets/user_display_name.dart';

/// Bottom-sheet account chooser shared by every "act as which
/// account?" flow (search, notifications, channels, antennas,
/// time machine, drawer-style rows).
Future<Account?> pickAccountFor(
  BuildContext context, {
  required List<Account> accounts,
  required String title,
}) {
  return showModalBottomSheet<Account>(
    context: context,
    builder:
        (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ),
              // The sheet hugs its content while it fits and scrolls
              // once the account list outgrows the sheet's max height
              // (many accounts, large text scale).
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    for (final a in accounts)
                      ListTile(
                        leading: UserAvatar(
                          url: a.avatarUrl,
                          seed: a.displayName ?? a.username,
                          radius: 18,
                        ),
                        title: UserDisplayName(
                          name: a.displayName ?? a.username,
                          viewerHost: a.host,
                        ),
                        subtitle: Text('@${a.username}@${a.host}'),
                        onTap: () => Navigator.of(sheetContext).pop(a),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
  );
}

/// Resolve which account an action should target:
/// single account → it; selection pins one → that one; otherwise ask.
/// Returns null when the user cancels or no accounts exist.
Future<Account?> resolveAccountFor(
  BuildContext context, {
  required List<Account> accounts,
  required TimelineSelection selection,
  required String title,
}) async {
  if (accounts.isEmpty) return null;
  if (accounts.length == 1) return accounts.first;
  if (selection is SingleAccount) return selection.account;
  return pickAccountFor(context, accounts: accounts, title: title);
}
