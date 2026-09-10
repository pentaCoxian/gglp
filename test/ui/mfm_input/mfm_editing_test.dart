import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/ui/widgets/mfm_input/mfm_editing.dart';

TextEditingValue val(String text, [int? caret]) => TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: caret ?? text.length),
    );

void main() {
  group('insertWrapping', () {
    test('empty field → markers inserted, caret between them', () {
      final v = insertWrapping(val(''), '**', '**');
      expect(v.text, '****');
      expect(v.selection.baseOffset, 2);
    });

    test('with text and caret at end → markers appended, caret between',
        () {
      final v = insertWrapping(val('hello'), '**', '**');
      expect(v.text, 'hello****');
      expect(v.selection.baseOffset, 7);
    });

    test('with caret in middle → markers inserted at caret', () {
      final v = insertWrapping(val('hello', 2), '**', '**');
      expect(v.text, 'he****llo');
      expect(v.selection.baseOffset, 4);
    });

    test('with selection → collapses to end, then inserts (no wrap)', () {
      final v = insertWrapping(
        const TextEditingValue(
          text: 'hello',
          selection: TextSelection(baseOffset: 1, extentOffset: 4),
        ),
        '**',
        '**',
      );
      // Selection collapses to its end (4); markers inserted there.
      expect(v.text, 'hell****o');
      expect(v.selection.baseOffset, 6);
    });

    test('asymmetric prefix/suffix (e.g. link)', () {
      final v = insertWrapping(val(''), '[', '](url)');
      expect(v.text, '[](url)');
      expect(v.selection.baseOffset, 1);
    });
  });

  group('insertAtCursor', () {
    test('plain insert at end', () {
      final v = insertAtCursor(val('foo '), ':parrot:');
      expect(v.text, 'foo :parrot:');
      expect(v.selection.baseOffset, 12);
    });

    test('insert at offset', () {
      final v = insertAtCursor(val('foo bar', 4), 'X');
      expect(v.text, 'foo Xbar');
      expect(v.selection.baseOffset, 5);
    });
  });

  group('insertBlockquoteLine', () {
    test('adds `> ` to bare line', () {
      final v = insertBlockquoteLine(val('hello'));
      expect(v.text, '> hello');
      expect(v.selection.baseOffset, 7); // caret stays at end of line
    });

    test('strips `> ` if already present', () {
      final v = insertBlockquoteLine(val('> hello'));
      expect(v.text, 'hello');
      expect(v.selection.baseOffset, 5);
    });

    test('only affects current line, not others', () {
      // Caret on line 2.
      final v = insertBlockquoteLine(val('one\ntwo', 7));
      expect(v.text, 'one\n> two');
    });
  });

  group('insertCodeBlock', () {
    test('inserts fenced block at start of empty field', () {
      final v = insertCodeBlock(val(''));
      // ```\n\n```\n  — caret at the empty middle line, after "```\n".
      expect(v.text, '```\n\n```\n');
      expect(v.selection.baseOffset, 4);
    });

    test('mid-paragraph adds leading newline so opener is on its own line',
        () {
      final v = insertCodeBlock(val('hello'));
      expect(v.text, 'hello\n```\n\n```\n');
      // caret = 5 (after 'hello') + 1 (leading '\n') + 4 ('```\n') = 10.
      expect(v.selection.baseOffset, 10);
    });
  });

  group('currentEmojiPartial / Range', () {
    test('detects partial after `:` at start of text', () {
      expect(currentEmojiPartial(val(':par')), 'par');
    });

    test('detects partial after `:` after whitespace', () {
      expect(currentEmojiPartial(val('hi :par')), 'par');
    });

    test('detects empty partial (just typed `:`)', () {
      expect(currentEmojiPartial(val('hi :')), '');
    });

    test('returns null when `:` is mid-word (e.g. URL scheme)', () {
      expect(currentEmojiPartial(val('https:')), isNull);
      expect(currentEmojiPartial(val('foo:bar')), isNull);
    });

    test('returns null when caret is mid-word (no triggering inside)', () {
      // text "...:foobar" with caret between "foo" and "bar"
      expect(currentEmojiPartial(val(':foobar', 4)), isNull);
    });

    test('returns null after closing `:` (no retrigger on :foo:)', () {
      expect(currentEmojiPartial(val(':foo:')), isNull);
    });

    test('range covers leading colon through caret', () {
      final r = currentEmojiPartialRange(val('hi :par'));
      expect(r, isNotNull);
      expect(r!.start, 3);
      expect(r.end, 7);
    });
  });

  group('replaceCurrentEmojiToken', () {
    test('replaces partial including the `:`', () {
      final v = replaceCurrentEmojiToken(val('hi :par'), ':parrot:');
      expect(v.text, 'hi :parrot:');
      expect(v.selection.baseOffset, 11);
    });

    test('no partial → returns input unchanged', () {
      final input = val('foo bar');
      final v = replaceCurrentEmojiToken(input, ':x:');
      expect(v.text, 'foo bar');
      expect(v.selection.baseOffset, input.selection.baseOffset);
    });

    test('federated token form replaces correctly', () {
      final v =
          replaceCurrentEmojiToken(val('hi :par'), ':parrot@misskey.io:');
      expect(v.text, 'hi :parrot@misskey.io:');
    });
  });

  group('isInsideCodeContext', () {
    test('plain text → false', () {
      expect(isInsideCodeContext(val('hello world')), isFalse);
    });

    test('inside inline code (odd backticks on line) → true', () {
      expect(isInsideCodeContext(val('foo `code')), isTrue);
    });

    test('after closed inline code → false', () {
      expect(isInsideCodeContext(val('foo `code` bar')), isFalse);
    });

    test('inside fenced block → true', () {
      expect(isInsideCodeContext(val('```\nbody')), isTrue);
    });

    test('after closed fenced block → false', () {
      expect(isInsideCodeContext(val('```\nbody\n```\nafter')), isFalse);
    });

    test('inside fenced block with language tag → true', () {
      expect(isInsideCodeContext(val('```dart\nvar x = ')), isTrue);
    });
  });
}
