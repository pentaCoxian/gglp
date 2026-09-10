import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/mfm/parser.dart';
import 'package:misskey_gglp/mfm/renderer.dart';

void main() {
  testWidgets(r'nested $[bounce $[bounce ]] renders without throwing',
      (tester) async {
    final ast = parseMfm(r'$[bounce $[bounce ]]');
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
    expect(caught, isNull, reason: 'rendering nested empty effects threw');
  });

  testWidgets(r'nested $[bounce $[bounce hi]] renders text',
      (tester) async {
    final ast = parseMfm(r'$[bounce $[bounce hi]]');
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
    // Under mfm.js semantics, this input doesn't render an inner fn —
    // the outer's content is `$[bounce hi` (stops at first `]`),
    // recursive parse can't close, so the inner is text. The
    // assertion: no exception, and the literal 'hi' substring made
    // it into the rendered text somewhere.
    expect(find.textContaining('hi'), findsOneWidget);
  });
}
