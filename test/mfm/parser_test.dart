import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/mfm/ast.dart';
import 'package:misskey_gglp/mfm/parser.dart';

void main() {
  group('plain text', () {
    test('returns single MfmText for plain', () {
      final ast = parseMfm('hello world');
      expect(ast, hasLength(1));
      expect((ast.first as MfmText).text, 'hello world');
    });

    test('preserves newlines as breaks', () {
      final ast = parseMfm('a\nb');
      expect(ast.length, 3);
      expect((ast[0] as MfmText).text, 'a');
      expect(ast[1], isA<MfmBreak>());
      expect((ast[2] as MfmText).text, 'b');
    });
  });

  group('inline styles', () {
    test('bold', () {
      final ast = parseMfm('**hi**');
      expect(ast, hasLength(1));
      final b = ast.first as MfmBold;
      expect((b.children.single as MfmText).text, 'hi');
    });

    test('italic vs bold do not collide', () {
      final ast = parseMfm('*it* and **bo**');
      // Coalesced into Italic, ' and ', Bold.
      expect(ast.length, 3);
      expect(ast[0], isA<MfmItalic>());
      expect((ast[1] as MfmText).text, ' and ');
      expect(ast[2], isA<MfmBold>());
    });

    test('strike + small', () {
      final ast = parseMfm('~~bye~~ <small>q</small>');
      expect(ast[0], isA<MfmStrike>());
      // Whitespace between collapses into a single text node.
      expect(ast.last, isA<MfmSmall>());
    });

    test('inline code', () {
      final ast = parseMfm('`x.foo()`');
      expect(ast, hasLength(1));
      expect((ast.first as MfmInlineCode).code, 'x.foo()');
    });
  });

  group('blocks', () {
    test('code fence with language', () {
      final ast = parseMfm('```dart\nprint(1);\n```');
      expect(ast, hasLength(1));
      final cb = ast.first as MfmCodeBlock;
      expect(cb.language, 'dart');
      expect(cb.code, 'print(1);');
    });

    test('blockquote', () {
      final ast = parseMfm('> hello\n> world');
      expect(ast, hasLength(1));
      expect(ast.first, isA<MfmQuote>());
    });

    test('center', () {
      final ast = parseMfm('<center>hi</center>');
      expect(ast.first, isA<MfmCenter>());
    });
  });

  group('mentions / hashtags / urls / emoji', () {
    test('mention without host', () {
      final ast = parseMfm('hi @alice ok');
      final m = ast.firstWhere((n) => n is MfmMention) as MfmMention;
      expect(m.username, 'alice');
      expect(m.host, isNull);
    });

    test('mention with host', () {
      final ast = parseMfm('@bob@misskey.io ?');
      final m = ast.firstWhere((n) => n is MfmMention) as MfmMention;
      expect(m.username, 'bob');
      expect(m.host, 'misskey.io');
    });

    test('hashtag', () {
      final ast = parseMfm('see #flutter and #dart');
      final tags = ast.whereType<MfmHashtag>().toList();
      expect(tags.map((t) => t.tag).toList(), ['flutter', 'dart']);
    });

    test('bare url', () {
      final ast = parseMfm('go https://misskey.io/foo bye');
      final u = ast.firstWhere((n) => n is MfmUrl) as MfmUrl;
      expect(u.url, 'https://misskey.io/foo');
    });

    test('labeled link', () {
      final ast = parseMfm('[click](https://e.com)');
      expect(ast.first, isA<MfmLink>());
      expect((ast.first as MfmLink).url, 'https://e.com');
    });

    test('custom emoji', () {
      final ast = parseMfm(':party: woo');
      expect(ast.first, isA<MfmEmoji>());
      expect((ast.first as MfmEmoji).name, 'party');
    });
  });

  group('fn (\$[…])', () {
    test('x2 with text', () {
      final ast = parseMfm(r'$[x2 hello]');
      final fn = ast.first as MfmFn;
      expect(fn.name, 'x2');
      expect((fn.children.single as MfmText).text, 'hello');
    });

    test('shake with args', () {
      final ast = parseMfm(r'$[shake.speed=2s hi]');
      final fn = ast.first as MfmFn;
      expect(fn.name, 'shake');
      expect(fn.args['speed'], '2s');
    });

    test('fg color', () {
      final ast = parseMfm(r'$[fg.color=ff0000 red]');
      final fn = ast.first as MfmFn;
      expect(fn.args['color'], 'ff0000');
    });

    test('nested fn (recursive content, matches mfm.js)', () {
      // mfm.js parses fn content as inline nodes, so a well-formed
      // inner fn consumes its own `]` and nests.
      final ast = parseMfm(r'$[x2 $[shake hi]]');
      expect(ast.length, 1);
      final outer = ast.first as MfmFn;
      expect(outer.name, 'x2');
      final inner = outer.children.single as MfmFn;
      expect(inner.name, 'shake');
      expect((inner.children.single as MfmText).text, 'hi');
    });

    test('comma-separated args after the first dotted one', () {
      final ast = parseMfm(r'$[scale.x=8,y=0.5 wide]');
      final fn = ast.single as MfmFn;
      expect(fn.name, 'scale');
      expect(fn.args, {'x': '8', 'y': '0.5'});
    });

    test('negative, decimal and unit-suffixed arg values', () {
      final ast = parseMfm(
        r'$[position.x=-7,y=-.6 $[shake.speed=3s,delay=.5s hi]]',
      );
      final outer = ast.single as MfmFn;
      expect(outer.args, {'x': '-7', 'y': '-.6'});
      final inner = outer.children.single as MfmFn;
      expect(inner.name, 'shake');
      expect(inner.args, {'speed': '3s', 'delay': '.5s'});
    });

    test('four-level chain from the wild parses to nested fns', () {
      final ast = parseMfm(
        r'$[rainbow $[position.x=-7,y=-.6 $[rotate.deg=0 '
        r'$[scale.x=8,y=0.5 🇦🇹]]]] tail',
      );
      expect(ast.length, 2);
      var node = ast.first as MfmFn;
      final names = <String>[];
      while (true) {
        names.add(node.name);
        final next = node.children.whereType<MfmFn>().toList();
        if (next.isEmpty) break;
        node = next.single;
      }
      expect(names, ['rainbow', 'position', 'rotate', 'scale']);
      expect((ast.last as MfmText).text, ' tail');
    });

    test('unclosed outer falls back to text but the inner still parses',
        () {
      final ast = parseMfm(r'$[x2 $[shake hi]');
      expect(ast.whereType<MfmFn>().map((f) => f.name), ['shake']);
    });

    test('empty content is not an fn (matches mfm.js)', () {
      // No content after the space — must NOT parse as MfmFn.
      // Renders as plain text `$[fg.color=86b300 ` followed by literal `]`.
      final ast = parseMfm(r'$[fg.color=86b300 ]');
      expect(ast.whereType<MfmFn>().toList(), isEmpty);
    });

    test(
        'inner that fails as an fn does not nest (matches mfm.js)', () {
      // `$[bounce]` has no space+content so mfm.js parses it as text;
      // the first `]` then closes the outer and the second is literal:
      //   outer fn = bounce, content = `$[bounce`, then text `]`.
      final ast = parseMfm(r'$[bounce $[bounce]]');
      // Outer fn + a trailing `]` text node.
      expect(ast.length, 2);
      final outer = ast.first as MfmFn;
      expect(outer.name, 'bounce');
      expect(outer.children.whereType<MfmFn>(), isEmpty);
      final tail = ast.last as MfmText;
      expect(tail.text, ']');
    });

    test('inner with empty content also fails to nest', () {
      final ast = parseMfm(r'$[bounce $[bounce ]]');
      expect(ast.length, 2);
      expect((ast.first as MfmFn).name, 'bounce');
      expect((ast.last as MfmText).text, ']');
    });
  });

  group('safety', () {
    test('over-length input is truncated', () {
      final huge = 'a' * (MfmLimits.maxInputLength + 100);
      final ast = parseMfm(huge);
      expect(ast, hasLength(1));
      expect((ast.first as MfmText).text.length, MfmLimits.maxInputLength);
    });

    test('malformed input falls back to text without crashing', () {
      // Unclosed delimiters intentionally messy.
      final ast = parseMfm('**unclosed *italic ~~strike `code <small>');
      expect(ast, isNotEmpty);
      // Whatever the parser did, it must be expressible as nodes.
      for (final n in ast) {
        expect(n, isA<MfmNode>());
      }
    });

    test('deeply nested fn does not blow stack', () {
      final s = StringBuffer();
      for (var i = 0; i < 100; i++) {
        s.write(r'$[x2 ');
      }
      s.write('hi');
      for (var i = 0; i < 100; i++) {
        s.write(']');
      }
      final ast = parseMfm(s.toString());
      // Either parsed within depth budget, or text fallback. Must not
      // throw and must produce at least one node.
      expect(ast, isNotEmpty);
    });
  });
}
