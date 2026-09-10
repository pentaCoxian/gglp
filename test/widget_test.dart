import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:misskey_gglp/app/app.dart';
import 'package:misskey_gglp/app/providers.dart';
import 'package:misskey_gglp/app/settings/settings_controller.dart';
import 'package:misskey_gglp/misskey/emoji/emoji_providers.dart';
import 'package:misskey_gglp/misskey/models/account.dart';
import 'package:misskey_gglp/timeline/custom_timeline.dart';

/// Settings notifier that bypasses Drift so widget tests don't leave a
/// pending disk-read timer when the widget tree disposes.
class _StubSettingsController extends SettingsController {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  testWidgets('M1: empty state when accounts list is empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsProvider
              .overrideWith((_) => Stream<List<Account>>.value(const [])),
          // The custom-timeline drawer entry watches a live Drift
          // stream by default; stub it to a one-shot empty list so
          // there's no pending timer when the widget tree disposes.
          customTimelinesProvider.overrideWith(
              (_) => Stream<List<CustomTimeline>>.value(const [])),
          // The real SettingsController kicks off a Drift read on
          // build via Future.microtask; stub it out so the test
          // teardown has no pending timers.
          settingsProvider
              .overrideWith(_StubSettingsController.new),
          // Bootstrap provider triggers HTTP/timer activity if the
          // accounts list changes — stub it out for unit tests.
          emojiCatalogBootstrapProvider.overrideWithValue(null),
        ],
        child: const MisskeyGglpApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('GGLP'), findsOneWidget);
    expect(find.text('No accounts yet.'), findsOneWidget);
  });
}
