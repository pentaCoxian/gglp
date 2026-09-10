/// Pure transformations on [TextEditingValue].
///
/// These are the single source of truth for every MFM editing affordance
/// (toolbar buttons, keyboard shortcuts, autocomplete commit). They take
/// a value, return a new value, and never touch a controller, build a
/// widget, or read a [BuildContext]. The hosting widget is responsible
/// for assigning the result back to the controller.
///
/// Behaviour summary:
///   - [insertWrapping] — insert-then-type model: `**|**` at the cursor
///     with caret between the markers. Selection (if any) collapses to
///     its end first; we never wrap selected text in v1.
///   - [insertBlockquoteLine], [insertCodeBlock], [insertAtCursor] —
///     other inserts.
///   - [currentEmojiPartial] / [replaceCurrentEmojiToken] — autocomplete
///     trigger detection and commit.
///   - [isInsideCodeContext] — suppress autocomplete inside `…` and
///     ``` … ```.
library;

import 'package:flutter/services.dart';

/// Word-character set for emoji-token detection. Misskey emoji names
/// allow `[A-Za-z0-9_]` (parser at `mfm/parser.dart`).
final RegExp _wordChar = RegExp(r'[A-Za-z0-9_]');

/// The character before the leading `:` of an emoji token must be
/// start-of-text or one of these — otherwise we're mid-word and the
/// `:` is something else (e.g. URL scheme, time literal `12:30`).
final RegExp _allowedTriggerPrefix = RegExp(r'[\s\(\)\{\}\[\],]');

/// Insert a marker pair at the caret and place the caret between them.
///
/// If [v] has a non-empty selection, the selection is collapsed to its
/// end first — we don't wrap selected text. This matches the
/// "tap toolbar button → markers appear → user types content" flow
/// confirmed for v1.
TextEditingValue insertWrapping(
  TextEditingValue v,
  String prefix,
  String suffix,
) {
  final at = v.selection.isValid
      ? (v.selection.isCollapsed
          ? v.selection.baseOffset
          : v.selection.end)
      : v.text.length;
  final inserted = '$prefix$suffix';
  final newText = v.text.replaceRange(at, at, inserted);
  return TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: at + prefix.length),
    composing: TextRange.empty,
  );
}

/// Insert plain [text] at the caret, collapsing any selection to its
/// end first. The caret lands at the end of the inserted text.
TextEditingValue insertAtCursor(TextEditingValue v, String text) {
  final at = v.selection.isValid
      ? (v.selection.isCollapsed
          ? v.selection.baseOffset
          : v.selection.end)
      : v.text.length;
  final newText = v.text.replaceRange(at, at, text);
  return TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: at + text.length),
    composing: TextRange.empty,
  );
}

/// Toggle a `> ` blockquote prefix on the line containing the caret.
///
/// If the line already starts with `> `, strip it; otherwise prepend
/// it. This is the one operation v1 *does* toggle (insert vs strip is
/// the only sensible interaction for blockquote — adding `> > ` would
/// nest, which is a separate intent).
TextEditingValue insertBlockquoteLine(TextEditingValue v) {
  final at = v.selection.isValid
      ? (v.selection.isCollapsed
          ? v.selection.baseOffset
          : v.selection.start)
      : v.text.length;
  final lineStart = _lineStart(v.text, at);
  final lineEnd = _lineEnd(v.text, at);
  final line = v.text.substring(lineStart, lineEnd);
  String newLine;
  int caretDelta;
  if (line.startsWith('> ')) {
    newLine = line.substring(2);
    caretDelta = -2;
  } else {
    newLine = '> $line';
    caretDelta = 2;
  }
  final newText =
      v.text.replaceRange(lineStart, lineEnd, newLine);
  final newOffset = (at + caretDelta).clamp(0, newText.length);
  return TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: newOffset),
    composing: TextRange.empty,
  );
}

/// Insert a fenced ``` … ``` block. The caret lands on the inner blank
/// line so the user can immediately start typing the code body.
///
/// If the caret isn't already at the start of a line, a leading
/// newline is added so the ``` opener stands alone.
TextEditingValue insertCodeBlock(TextEditingValue v) {
  final at = v.selection.isValid
      ? (v.selection.isCollapsed
          ? v.selection.baseOffset
          : v.selection.end)
      : v.text.length;
  final atLineStart = at == 0 || v.text[at - 1] == '\n';
  final lead = atLineStart ? '' : '\n';
  // ```\n│\n```\n  — caret on the empty middle line.
  final body = '$lead```\n\n```\n';
  final newText = v.text.replaceRange(at, at, body);
  // Caret at the empty middle line → after the leading newline + ```\n.
  final caret = at + lead.length + 4; // '```\n' = 4 chars
  return TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: caret),
    composing: TextRange.empty,
  );
}

/// Returns the active emoji partial — the run of word-chars after a
/// `:` immediately preceding the caret — or null if no autocomplete
/// trigger is active.
///
/// Triggers when:
///   - the caret has 0+ word chars to its left, then a `:`, then either
///     start-of-text, whitespace, or one of `(){}[],` (so `:foo:bar`
///     does not retrigger after the second colon).
///   - the caret is at end-of-text, or the next char is not a word char
///     (no triggering inside `:foo|bar`).
///
/// IME composition is deliberately NOT a gate: partials are ASCII-only,
/// so CJK conversion text can't trigger, and Android IMEs keep ASCII
/// words composing while typing — gating on it would (and previously
/// did) disable autocomplete entirely on Android.
String? currentEmojiPartial(TextEditingValue v) {
  final r = currentEmojiPartialRange(v);
  if (r == null) return null;
  // `start` is the index of the leading `:`; partial begins at `start+1`.
  return v.text.substring(r.start + 1, r.end);
}

/// Range covering the partial token including the leading `:` —
/// `[colon-index, caret)`. Used by [replaceCurrentEmojiToken] to know
/// what to delete on commit.
({int start, int end})? currentEmojiPartialRange(TextEditingValue v) {
  if (!v.selection.isValid || !v.selection.isCollapsed) return null;
  final caret = v.selection.baseOffset;
  if (caret < 1) return null;
  // Walk backwards over word chars.
  var i = caret;
  while (i > 0 && _wordChar.hasMatch(v.text[i - 1])) {
    i--;
  }
  // The char at i-1 must be `:` (the trigger).
  if (i == 0 || v.text[i - 1] != ':') return null;
  // The char before the `:` (if any) must be start-of-text or in the
  // allowed prefix set.
  if (i - 2 >= 0) {
    final pre = v.text[i - 2];
    if (!_allowedTriggerPrefix.hasMatch(pre)) return null;
  }
  // The char at the caret (if any) must not be a word char — never
  // trigger mid-word.
  if (caret < v.text.length && _wordChar.hasMatch(v.text[caret])) {
    return null;
  }
  return (start: i - 1, end: caret);
}

/// Replace the active partial (including the leading `:`) with [token].
/// [token] should already include both surrounding colons — i.e.
/// `:parrot:` or `:parrot@host:`.
///
/// If no partial is active, returns [v] unchanged.
TextEditingValue replaceCurrentEmojiToken(
  TextEditingValue v,
  String token,
) {
  final r = currentEmojiPartialRange(v);
  if (r == null) return v;
  final newText = v.text.replaceRange(r.start, r.end, token);
  final caret = r.start + token.length;
  return TextEditingValue(
    text: newText,
    selection: TextSelection.collapsed(offset: caret),
    composing: TextRange.empty,
  );
}

/// Cheap heuristic: is the caret inside an inline `…` or fenced
/// ``` … ``` code span?
///
///   - **Inline:** count unescaped backticks on the current line before
///     the caret. Odd ⇒ inside an inline-code run.
///   - **Block:** count occurrences of "```" on whole lines (i.e. lines
///     that consist of just ``` optionally followed by a language tag)
///     before the caret. Odd ⇒ inside a fenced block.
///
/// Both checks are intentionally simple — they suppress autocomplete
/// in the common case (user typing a code snippet) without trying to
/// model every parser edge case.
bool isInsideCodeContext(TextEditingValue v) {
  if (!v.selection.isValid || !v.selection.isCollapsed) return false;
  final caret = v.selection.baseOffset.clamp(0, v.text.length);
  final upTo = v.text.substring(0, caret);

  // Block check: count fences on standalone lines.
  var fenceCount = 0;
  for (final line in upTo.split('\n')) {
    final t = line.trimRight();
    if (t == '```') {
      fenceCount++;
    } else if (t.startsWith('```') && !t.substring(3).contains('`')) {
      // ```dart, ```js, etc. Open fence with a language tag.
      fenceCount++;
    }
  }
  if (fenceCount.isOdd) return true;

  // Inline check: count backticks on the current line, ignoring those
  // inside an already-closed pair would require running pairs — but
  // odd-count is the standard inline-code-open signal.
  final lineStart = _lineStart(v.text, caret);
  final lineUpTo = v.text.substring(lineStart, caret);
  var backticks = 0;
  for (var i = 0; i < lineUpTo.length; i++) {
    if (lineUpTo[i] == '`') backticks++;
  }
  return backticks.isOdd;
}

int _lineStart(String text, int at) {
  if (at <= 0) return 0;
  final i = text.lastIndexOf('\n', at - 1);
  return i < 0 ? 0 : i + 1;
}

int _lineEnd(String text, int at) {
  final i = text.indexOf('\n', at);
  return i < 0 ? text.length : i;
}
