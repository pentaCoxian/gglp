import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:misskey_gglp/app/providers.dart';
import 'package:misskey_gglp/app/theme/app_theme.dart';
import 'package:misskey_gglp/misskey/models/account.dart';
import 'package:misskey_gglp/misskey/models/note.dart';
import 'package:misskey_gglp/misskey/models/note_channel.dart';
import 'package:misskey_gglp/misskey/models/notification.dart';
import 'package:misskey_gglp/misskey/models/reaction.dart';
import 'package:misskey_gglp/misskey/models/user.dart';
import 'package:misskey_gglp/misskey/streaming/stream_providers.dart';
import 'package:misskey_gglp/storage/app_database.dart';
import 'package:misskey_gglp/storage/daos/emoji_dao.dart';
import 'package:misskey_gglp/timeline/note_actions_service.dart';
import 'package:misskey_gglp/timeline/notifications_controller.dart';
import 'package:misskey_gglp/ui/screens/notifications_screen.dart';
import 'package:misskey_gglp/ui/shell/activity_panel.dart';

const _account = Account(
  id: 'misskey.systems:u1',
  host: 'misskey.systems',
  userId: 'u1',
  username: 'viewer',
);

const _actor = User(
  id: 'u2',
  username: 'walkure',
  name: 'Δ :blob: *cat*',
  host: 'a-rather-long-federated-host.example.org',
);

Note _note({
  String? text,
  String? cw,
  bool sensitiveChannel = false,
  List<Reaction> reactions = const [],
}) => Note(
      id: 'n1',
      sourceHost: 'misskey.systems',
      user: _actor,
      createdAt: DateTime(2026, 9, 1),
      text: text,
      cw: cw,
      reactions: reactions,
      channel: sensitiveChannel
          ? const NoteChannel(id: 'c1', name: '下ネタの国', isSensitive: true)
          : null,
    );

NotificationsState _seed() => NotificationsState(
      items: [
        MisskeyNotification(
          id: 'a',
          kind: NotificationKind.follow,
          createdAt: DateTime(2026, 9, 1),
          rawType: 'follow',
          user: _actor,
        ),
        MisskeyNotification(
          id: 'b',
          kind: NotificationKind.reaction,
          createdAt: DateTime(2026, 9, 1),
          rawType: 'reaction',
          user: _actor,
          reaction: ':blob@.:',
          note: _note(
            text: r'hello $[x2 :blob:] https://example.org/x',
            reactions: const [
              Reaction(key: ':blob@.:', count: 2, isCustom: true),
              Reaction(key: ':remote@other.example:', count: 1, isCustom: true),
            ],
          ),
        ),
        MisskeyNotification(
          id: 'c',
          kind: NotificationKind.reply,
          createdAt: DateTime(2026, 9, 1),
          rawType: 'reply',
          user: _actor,
          note: _note(text: 'short', sensitiveChannel: true),
        ),
        MisskeyNotification(
          id: 'd',
          kind: NotificationKind.mention,
          createdAt: DateTime(2026, 9, 1),
          rawType: 'mention',
          user: _actor,
          note: _note(text: 'the secret', cw: 'spoiler'),
        ),
      ],
      reachedEnd: true,
    );

class _FakeNotifications extends NotificationsController {
  @override
  Future<NotificationsState> build(Account account) async => _seed();
}

Widget _app(AppDatabase db, Widget home) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      accountsProvider.overrideWith((_) => Stream.value(const [_account])),
      noteActionsProvider.overrideWith((_, __) async => null),
      noteCaptureManagerProvider.overrideWith((_, __) => null),
      notificationsControllerProvider.overrideWith(_FakeNotifications.new),
    ],
    child: MaterialApp(theme: AppTheme.light(), home: home),
  );
}

Future<void> _settleWithoutErrors(
  WidgetTester tester,
  Future<void> Function() body,
) async {
  final errors = <FlutterErrorDetails>[];
  final prev = FlutterError.onError;
  FlutterError.onError = errors.add;
  try {
    await body();
  } finally {
    FlutterError.onError = prev;
  }
  if (errors.isNotEmpty) {
    fail(
      'Framework errors:\n${errors.map((d) => d.toString()).join('\n\n')}',
    );
  }
}

void main() {
  late AppDatabase db;
  setUp(() async {
    // visibility_detector re-arms a 500ms timer on every paint; report
    // synchronously so nothing outlives the test.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Fresh catalog stamps keep the on-demand emoji fetch off the
    // network so no HTTP timers outlive the test.
    final dao = EmojiDao(db);
    for (final host in ['misskey.systems', 'other.example']) {
      await dao.markCatalogFetched(host, DateTime.now());
    }
  });
  tearDown(() => db.close());


  testWidgets('notifications list settles at panel width', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _settleWithoutErrors(tester, () async {
      await tester.pumpWidget(
        _app(
          db,
          Scaffold(
            body: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 310,
                child: NotificationsList(account: _account),
              ),
            ),
          ),
        ),
      );
      // A rebuild/layout loop shows up as a timeout here.
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
    });
    expect(find.textContaining('followed you'), findsOneWidget);
    expect(find.textContaining('Tap to reveal'), findsOneWidget);
    // The action row must lay out at a sane size (an ErrorWidget in
    // the row is 100000px square — that was the panel freeze).
    expect(tester.getSize(find.byTooltip('More').first).width, lessThan(80));
  });

  testWidgets('opening the activity panel from a screen settles',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _settleWithoutErrors(tester, () async {
      await tester.pumpWidget(
        _app(
          db,
          Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => ActivityPanel.open(ctx, account: _account),
                  child: const Text('bell'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('bell'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
    });
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.textContaining('reacted to your note'), findsOneWidget);
    expect(tester.getSize(find.byTooltip('More').first).width, lessThan(80));
  });
}
