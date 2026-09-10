import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/mfm/parser.dart';
import 'package:misskey_gglp/mfm/renderer.dart';

void main() {
  testWidgets('top-level quote alone renders into a Container with text',
      (tester) async {
    final ast = parseMfm('> hello world');
    Object? caught;
    FlutterError.onError = (details) => caught = details.exception;
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
    expect(caught, isNull);
    expect(find.textContaining('hello world'), findsOneWidget);
  });

  testWidgets(r'quote then quote with $[tada …] — both quotes render',
      (tester) async {
    final src = '> a\n> \$[tada b]';
    final ast = parseMfm(src);
    Object? caught;
    FlutterError.onError = (details) => caught = details.exception;
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
    expect(caught, isNull);
    expect(find.textContaining('a'), findsAtLeast(1));
    expect(find.textContaining('b'), findsAtLeast(1));
  });
}
