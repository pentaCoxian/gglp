import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:misskey_gglp/app/theme/app_theme.dart';
import 'package:misskey_gglp/mfm/parser.dart';
import 'package:misskey_gglp/mfm/renderer.dart';
import 'package:misskey_gglp/ui/widgets/user_display_name.dart';

// Inspect the styles that reach Flutter's render objects, including inherited
// span properties. Widget tests use test fonts, so this verifies shaping inputs
// rather than pretending to compare the Android system's actual kanji glyphs.
Iterable<(String, TextStyle)> _textRuns(
  InlineSpan span, [
  TextStyle inherited = const TextStyle(),
]) sync* {
  if (span is! TextSpan) return;
  final effective = inherited.merge(span.style);
  if (span.text case final String text when text.isNotEmpty) {
    yield (text, effective);
  }
  for (final child in span.children ?? const <InlineSpan>[]) {
    yield* _textRuns(child, effective);
  }
}

class _MfmSample extends StatefulWidget {
  const _MfmSample();

  @override
  State<_MfmSample> createState() => _MfmSampleState();
}

class _MfmSampleState extends State<_MfmSample> {
  MfmRenderer? _renderer;

  @override
  Widget build(BuildContext context) {
    _renderer?.dispose();
    final renderer =
        _renderer = MfmRenderer(context: context, animateEffects: false);
    return renderer.render(
      parseMfm(
        '通常の文章 **太字の直感** `行内の置換`\n'
        '```dart\nコードの骨組\n```',
      ),
    );
  }

  @override
  void dispose() {
    _renderer?.dispose();
    super.dispose();
  }
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'Android ${brightness.name} uses Japanese shaping in text, names, '
      'editing and MFM while the interface stays English',
      (tester) async {
        final controller = TextEditingController(text: '入力の文字');
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode:
                  brightness == Brightness.dark
                      ? ThemeMode.dark
                      : ThemeMode.light,
              home: Scaffold(
                appBar: AppBar(title: const Text('画面の題名')),
                body: Column(
                  children: [
                    const Text('本文の直線'),
                    const UserDisplayName(
                      name: '名前の骨格',
                      viewerHost: 'example.invalid',
                    ),
                    TextField(controller: controller),
                    const ListTile(
                      title: Text('一覧の見出し'),
                      subtitle: Text('補足の情報'),
                    ),
                    const Chip(label: Text('分類の標識')),
                    const _MfmSample(),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final context = tester.element(find.byType(_MfmSample));
        expect(Localizations.localeOf(context).languageCode, 'en');
        expect(MaterialLocalizations.of(context).copyButtonLabel, 'Copy');

        final runs = <(String, TextStyle)>[
          for (final paragraph in tester.renderObjectList<RenderParagraph>(
            find.byType(RichText),
          ))
            ..._textRuns(paragraph.text),
          for (final editable in tester.stateList<EditableTextState>(
            find.byType(EditableText),
          ))
            if (editable.renderEditable.text case final InlineSpan text)
              ..._textRuns(text),
        ];

        TextStyle styleFor(String text) {
          final matches = runs.where((run) => run.$1.contains(text)).toList();
          expect(matches, hasLength(1), reason: 'Rendered text: $text');
          return matches.single.$2;
        }

        for (final text in [
          '画面の題名',
          '本文の直線',
          '名前の骨格',
          '入力の文字',
          '一覧の見出し',
          '補足の情報',
          '分類の標識',
          '通常の文章',
          '太字の直感',
          '行内の置換',
          'コードの骨組',
        ]) {
          expect(styleFor(text).locale, const Locale('ja'), reason: text);
        }
        for (final text in ['本文の直線', '名前の骨格', '入力の文字', '通常の文章', '太字の直感']) {
          expect(styleFor(text).fontFamily, 'Roboto', reason: text);
          expect(styleFor(text).fontFamilyFallback, ['NotoColorEmoji']);
        }
        expect(styleFor('太字の直感').fontWeight, FontWeight.w700);
        for (final text in ['行内の置換', 'コードの骨組']) {
          expect(styleFor(text).fontFamily, 'monospace', reason: text);
          expect(styleFor(text).fontFamilyFallback, [
            'Menlo',
            'Consolas',
            'monospace',
          ]);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }
}
