import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/mfm/ast.dart';
import 'package:misskey_gglp/mfm/parser.dart';
import 'package:misskey_gglp/mfm/renderer.dart';

void main() {
  // Synthetic regression: a quote followed by a blank line and a code
  // fence containing the same quoted MFM syntax.
  const src =
      '> 引用ブロックの例\n'
      r'> $[tada 引用ブロック内のMFM例]'
      '\n\n'
      '```\n'
      '// コードの例\n'
      '> 引用ブロックの例\n'
      r'> $[tada 引用ブロック内のMFM例]'
      '\n```';

  test('parses without throwing and produces nodes', () {
    final ast = parseMfm(src);
    expect(ast, isNotEmpty);
  });

  test('contains a quote and a code block at the top level', () {
    final ast = parseMfm(src);
    expect(ast.whereType<MfmQuote>(), isNotEmpty,
        reason: 'top quote must parse');
    expect(ast.whereType<MfmCodeBlock>(), isNotEmpty,
        reason: 'code fence must parse');
  });

  testWidgets('renders without throwing and shows visible text',
      (tester) async {
    final ast = parseMfm(src);
    Object? caught;
    FlutterError.onError = (details) => caught = details.exception;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Builder(
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
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(caught, isNull);
    expect(find.textContaining('引用ブロックの例'), findsAtLeast(1));
    expect(find.textContaining('// コードの例'), findsOneWidget);
  });
}
