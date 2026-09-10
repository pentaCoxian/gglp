import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/misskey/models/account.dart';
import 'package:misskey_gglp/ui/widgets/mfm_input/mfm_toolbar.dart';

const _account = Account(
  id: 'misskey.io:abc',
  host: 'misskey.io',
  userId: 'abc',
  username: 'tester',
);

Widget _harness(TextEditingController controller) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          TextField(controller: controller),
          MfmToolbar(controller: controller, account: _account),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('Bold button inserts `****` and places caret between',
      (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(_harness(controller));

    await tester.tap(find.byTooltip('Bold (**…**)'));
    await tester.pumpAndSettle();

    expect(controller.text, '****');
    expect(controller.selection.baseOffset, 2);
  });

  testWidgets('Italic button inserts `**` with caret between',
      (tester) async {
    final controller = TextEditingController(text: 'hi ');
    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pumpWidget(_harness(controller));

    await tester.tap(find.byTooltip('Italic (*…*)'));
    await tester.pumpAndSettle();

    expect(controller.text, 'hi **');
    expect(controller.selection.baseOffset, 4);
  });

  testWidgets('Quote button toggles `> ` on the current line',
      (tester) async {
    final controller = TextEditingController(text: 'one\ntwo');
    controller.selection = const TextSelection.collapsed(offset: 7);
    await tester.pumpWidget(_harness(controller));

    await tester.tap(find.byTooltip('Blockquote (> …)'));
    await tester.pumpAndSettle();

    expect(controller.text, 'one\n> two');
  });
}
