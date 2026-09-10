import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/mfm/ast.dart';
import 'package:misskey_gglp/mfm/parser.dart';

void main() {
  test('plain quote', () {
    final ast = parseMfm('> hello');
    expect(ast, hasLength(1));
    final q = ast.first as MfmQuote;
    expect(q.children.whereType<MfmText>().map((t) => t.text).join(),
        'hello');
  });

  test('multi-line quote', () {
    final ast = parseMfm('> a\n> b');
    expect(ast, hasLength(1));
    expect(ast.first, isA<MfmQuote>());
    final q = ast.first as MfmQuote;
    final flat = _flatten(q.children);
    expect(flat, contains('a'));
    expect(flat, contains('b'));
  });

  test('CJK content inside quote', () {
    final ast = parseMfm('> 引用ブロックのnaize');
    expect(ast, hasLength(1));
    final q = ast.first as MfmQuote;
    final flat = _flatten(q.children);
    expect(flat, contains('引用ブロックのnaize'));
  });

  test(r'MFM inside quote: $[tada …] is parsed as MfmFn', () {
    final ast = parseMfm(r'> $[tada hello]');
    expect(ast.first, isA<MfmQuote>());
    final q = ast.first as MfmQuote;
    final fns = q.children.whereType<MfmFn>().toList();
    expect(fns, hasLength(1),
        reason: 'fn inside a blockquote must still parse');
    expect(fns.first.name, 'tada');
  });

  test('multi-line quote with MFM line', () {
    final ast =
        parseMfm('> 引用ブロックのnaize\n> \$[tada 引用ブロック内のMFMのnaize]');
    expect(ast, hasLength(1));
    expect(ast.first, isA<MfmQuote>());
    final q = ast.first as MfmQuote;
    final fns = q.children.whereType<MfmFn>().toList();
    expect(fns, hasLength(1));
    expect(fns.first.name, 'tada');
  });

  test('code fence containing a quote stays a code block', () {
    final src =
        '```\n> 引用ブロックのnaize\n> \$[tada 引用ブロック内のMFMのnaize]\n```';
    final ast = parseMfm(src);
    expect(ast, hasLength(1));
    expect(ast.first, isA<MfmCodeBlock>());
  });
}

String _flatten(List<MfmNode> ns) {
  final buf = StringBuffer();
  for (final n in ns) {
    if (n is MfmText) buf.write(n.text);
    if (n is MfmBreak) buf.write('\n');
    if (n is MfmFn) buf.write(_flatten(n.children));
    if (n is MfmQuote) buf.write(_flatten(n.children));
  }
  return buf.toString();
}
