import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/mfm/parser.dart';
import 'package:misskey_gglp/mfm/renderer.dart';

void main() {
  testWidgets('multi-line quote with MFM renders both lines',
      (tester) async {
    final src =
        '> 引用ブロックのnaize\n> \$[tada 引用ブロック内のMFMのnaize]';
    final ast = parseMfm(src);
    Object? caught;
    FlutterError.onError = (details) => caught = details.exception;

    await _pump(tester, ast, (e) => caught = e);
    expect(caught, isNull);
    expect(find.textContaining('引用ブロックのnaize'), findsOneWidget);
    expect(find.textContaining('引用ブロック内のMFMのnaize'), findsOneWidget);
  });

  testWidgets('mixed code fence + plain quote (the screenshot case)',
      (tester) async {
    // The user's actual input: a code fence enclosing a quote sample,
    // followed by `// 原文ママ` and the same content rendered as live
    // MFM (plain quote + tada fn).
    final src = [
      '```',
      '> 引用ブロックのnaize',
      r'> $[tada 引用ブロック内のMFMのnaize]',
      '```',
      '// 原文ママ',
      '> 引用ブロックのnaize',
      r'> $[tada 引用ブロック内のMFMのnaize]',
    ].join('\n');

    final ast = parseMfm(src);

    // Sanity: a code block, a text/break run with `// 原文ママ`, and a quote.
    final hasCode = ast.any((n) => n.runtimeType.toString() == 'MfmCodeBlock');
    final hasQuote = ast.any((n) => n.runtimeType.toString() == 'MfmQuote');
    expect(hasCode, isTrue, reason: 'code fence should produce MfmCodeBlock');
    expect(hasQuote, isTrue, reason: 'plain quote should produce MfmQuote');

    Object? caught;
    FlutterError.onError = (details) => caught = details.exception;

    await _pump(tester, ast, (e) => caught = e);
    expect(caught, isNull);

    // Each instance of the long string appears: once inside the code
    // block, once inside the live quote.
    expect(find.textContaining('引用ブロックのnaize'), findsAtLeast(1));
    expect(find.textContaining('引用ブロック内のMFMのnaize'), findsAtLeast(1));
    expect(find.textContaining('// 原文ママ'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, ast, void Function(Object) onErr) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              final renderer = MfmRenderer(
                context: ctx,
                animateEffects: false,
              );
              return renderer.render(ast);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}
