import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:misskey_gglp/app/providers.dart';
import 'package:misskey_gglp/app/theme/app_theme.dart';
import 'package:misskey_gglp/misskey/models/account.dart';
import 'package:misskey_gglp/misskey/models/note.dart';
import 'package:misskey_gglp/misskey/models/note_channel.dart';
import 'package:misskey_gglp/misskey/models/user.dart';
import 'package:misskey_gglp/storage/app_database.dart';
import 'package:misskey_gglp/timeline/note_actions_service.dart';
import 'package:misskey_gglp/ui/widgets/note_card.dart';

const _account = Account(
  id: 'misskey.example:u1',
  host: 'misskey.example',
  userId: 'u1',
  username: 'viewer',
);

Note _note({String? cw, String? text}) => Note(
      id: 'n1',
      sourceHost: 'misskey.example',
      user: const User(id: 'u2', username: 'poster'),
      createdAt: DateTime(2026, 1, 1),
      cw: cw,
      text: text,
      channel: const NoteChannel(
        id: 'c1',
        name: 'spicy',
        isSensitive: true,
      ),
    );

Widget _harness(AppDatabase db, Note note) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      noteActionsProvider.overrideWith((_, __) async => null),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: ListView(
          children: [NoteCard(note: note, attributionAccount: _account)],
        ),
      ),
    ),
  );
}

/// Captures every framework error raised during [body] and fails with
/// the full report (including the "relevant error-causing widget"
/// line), so overflow regressions point at the culprit.
Future<void> _expectNoLayoutError(
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
      'Unexpected layout error(s):\n'
      '${errors.map((d) => d.toString()).join('\n\n')}',
    );
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'sensitive-channel blur over CW-hidden content fits ($width px)',
      (tester) async {
        tester.view.physicalSize = Size(width, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _expectNoLayoutError(tester, () async {
          await tester.pumpWidget(
            _harness(db, _note(cw: 'spoilers', text: 'the secret')),
          );
          await tester.pump(const Duration(milliseconds: 100));
        });
        expect(find.textContaining('Tap to reveal'), findsOneWidget);
      },
    );

    testWidgets(
      'sensitive-channel blur over a one-line note fits ($width px)',
      (tester) async {
        tester.view.physicalSize = Size(width, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await _expectNoLayoutError(tester, () async {
          await tester.pumpWidget(_harness(db, _note(text: 'hi')));
          await tester.pump(const Duration(milliseconds: 100));
        });
        expect(find.textContaining('Tap to reveal'), findsOneWidget);
      },
    );
  }

  testWidgets('large text scale: blur affordance still fits', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await _expectNoLayoutError(tester, () async {
      await tester.pumpWidget(_harness(db, _note(cw: 'cw', text: 'x')));
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
