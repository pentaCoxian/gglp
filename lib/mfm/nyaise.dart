/// Transform plain text the way Misskey does for cat users:
/// every `na` (case-insensitive) becomes `nya` (with the case of the
/// original `n` preserved).
///
/// Examples:
///   - "na"     -> "nya"
///   - "Na"     -> "Nya"
///   - "NA"     -> "NYA"
///   - "banana" -> "banyanya"
///   - "snack"  -> "snyack"
///
/// The transform only runs on MfmText nodes — code blocks, mentions,
/// URLs, hashtags, custom emoji names, and fn args are NOT affected.
/// That matches Misskey's behavior (cat users don't accidentally break
/// links by nyaa-ing them).
String nyaise(String input) {
  if (input.isEmpty) return input;
  final buf = StringBuffer();
  final src = input;
  for (var i = 0; i < src.length; i++) {
    final ch = src[i];
    final next = i + 1 < src.length ? src[i + 1] : '';
    final isN = ch == 'n' || ch == 'N';
    final isA = next == 'a' || next == 'A';
    if (isN && isA) {
      // Insert 'y' between, preserving the case of the n.
      buf.write(ch); // n / N
      buf.write(ch == 'N' && next == 'A' ? 'Y' : 'y');
      buf.write(next);
      i++;
    } else {
      buf.write(ch);
    }
  }
  return buf.toString();
}
