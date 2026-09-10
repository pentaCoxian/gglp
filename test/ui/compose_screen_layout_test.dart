import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:misskey_gglp/app/providers.dart';
import 'package:misskey_gglp/app/theme/app_theme.dart';
import 'package:misskey_gglp/misskey/models/account.dart';
import 'package:misskey_gglp/storage/app_database.dart';
import 'package:misskey_gglp/timeline/note_actions_service.dart';
import 'package:misskey_gglp/ui/plus/plus.dart';
import 'package:misskey_gglp/ui/screens/compose_screen.dart';

const _a = Account(
  id: 'misskey.example:u1',
  host: 'misskey.example',
  userId: 'u1',
  username: 'a_rather_long_username',
  displayName: 'Alice',
);
const _b = Account(
  id: 'other.example:u2',
  host: 'other.example',
  userId: 'u2',
  username: 'bob',
);

/// The composer over a stub app, with every network-backed provider
/// stubbed out so the layout can be exercised offline.
Widget _harness(AppDatabase db, {ComposeMode mode = ComposeMode.post}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      accountsProvider.overrideWith((_) => Stream.value(const [_a, _b])),
      noteActionsProvider.overrideWith((_, __) async => null),
      misskeyEndpointsProvider.overrideWith((_, __) async => null),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder:
            (ctx) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed:
                      () => ComposeScreen.open(
                        ctx,
                        account: _a,
                        mode: mode,
                        channelId: mode == ComposeMode.channel ? 'c1' : null,
                        channelName:
                            mode == ComposeMode.channel
                                ? 'a channel with a very long name indeed'
                                : null,
                      ),
                  child: const Text('open'),
                ),
              ),
            ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester) async {
  final errors = <FlutterErrorDetails>[];
  final prev = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  } finally {
    FlutterError.onError = prev;
  }
  if (errors.isNotEmpty) {
    fail(
      'Unexpected error(s) while opening the composer:\n'
      '${errors.map((d) => d.toString()).join('\n\n')}',
    );
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'narrow phone, large text, keyboard up: poll + CW + long text never overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(_harness(db));
      await _open(tester);

      expect(find.text('New note'), findsOneWidget);
      expect(find.text('Posting as'), findsOneWidget);
      expect(find.byTooltip('Post to channel'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).first,
        List.filled(60, 'lorem ipsum dolor').join(' '),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Add poll'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Add content warning'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Content warning'), findsOneWidget);

      // The toolbar scrolls on narrow phones so the visibility chip
      // stays reachable instead of overflowing.
      await tester.drag(
        find.byTooltip('Add image'),
        const Offset(-300, 0),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Public'), findsOneWidget);
    },
  );

  testWidgets('channel picker opens from the audience row and lays out',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(_harness(db));
    await _open(tester);

    // The toolbar scrolls horizontally on a 320px phone at 1.3x, so
    // bring the button fully into its viewport before tapping.
    await tester.ensureVisible(find.byTooltip('Post to channel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Post to channel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Post to channel'), findsOneWidget);
    expect(find.text('Mine'), findsOneWidget);
  });

  testWidgets('channel mode locks audience and shows the channel chip',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(db, mode: ComposeMode.channel));
    await _open(tester);

    expect(
      find.textContaining('#a channel with a very long name'),
      findsWidgets,
    );
    // Local-only is forced on for channel notes.
    expect(find.byTooltip("Channel notes don't federate"), findsOneWidget);
    // Visibility is inert and the channel can't be changed.
    expect(
      find.byTooltip('Channel notes are public within the channel'),
      findsOneWidget,
    );
    expect(find.byTooltip('Remove channel'), findsNothing);
  });

  testWidgets('desktop width centers the card and fits the bar',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(db));
    await _open(tester);
    expect(find.text('Public'), findsOneWidget);
    expect(find.byTooltip('Post to channel'), findsOneWidget);
  });

  testWidgets('status-bar inset is not re-applied inside the card',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    // A tall status bar, like the phone in the bug report.
    tester.view.padding = const FakeViewPadding(top: 48);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(db));
    await _open(tester);

    // Card top = status bar (48) + the deliberate red-bar reveal (56).
    // The header row must start right there, not another 48px lower.
    final title = tester.getTopLeft(find.text('New note'));
    expect(title.dy, lessThan(48 + PlusDims.appBarMobile + 24));
  });
}
