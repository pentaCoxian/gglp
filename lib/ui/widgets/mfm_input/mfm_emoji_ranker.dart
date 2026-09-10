import '../../../misskey/emoji/emoji_ref.dart';
import '../../../misskey/models/emoji.dart';

/// Ranks a custom-emoji catalog against an autocomplete query.
///
/// Scoring (lower is better):
///   - exact name match                       → 0
///   - name prefix match                      → 1   + (name.length - q.length)
///   - alias prefix match                     → 200
///   - name substring match                   → 400 + indexOf(q)
///   - alias substring match                  → 600
///   - otherwise discarded
/// Then a recents bump: if the produced token (`:name:` or
/// `:name@host:`) matches a key in [recents], subtract 50 from the
/// score so recently-used emoji float up.
///
/// Empty query → recents first (decoded from their `:name:` keys),
/// then everything in [all] in catalog order, capped at [limit].
///
/// All inputs are taken as in-memory lists; no I/O or `BuildContext`.
List<CustomEmoji> rankEmoji({
  required List<CustomEmoji> all,
  required String query,
  required String viewerHost,
  required List<String> recents,
  int limit = 12,
}) {
  if (query.isEmpty) {
    return _emptyQuery(all: all, recents: recents, viewerHost: viewerHost)
        .take(limit)
        .toList(growable: false);
  }
  final q = query.toLowerCase();
  final recentsSet = recents.toSet();
  final scored = <(int, CustomEmoji)>[];
  for (final e in all) {
    final s = _score(e, q);
    if (s == _discarded) continue;
    final token = EmojiRef.tokenFor(e, viewerHost);
    final adjusted = recentsSet.contains(token) ? s - 50 : s;
    scored.add((adjusted, e));
  }
  scored.sort((a, b) => a.$1.compareTo(b.$1));
  final out = <CustomEmoji>[];
  final seen = <String>{};
  for (final (_, e) in scored) {
    if (seen.add(e.name)) out.add(e);
    if (out.length == limit) break;
  }
  return out;
}

const _discarded = 1 << 30;

int _score(CustomEmoji e, String q) {
  final name = e.name.toLowerCase();
  if (name == q) return 0;
  if (name.startsWith(q)) return 1 + (name.length - q.length);
  for (final a in e.aliases) {
    if (a.toLowerCase().startsWith(q)) return 200;
  }
  final idx = name.indexOf(q);
  if (idx >= 0) return 400 + idx;
  for (final a in e.aliases) {
    if (a.toLowerCase().contains(q)) return 600;
  }
  return _discarded;
}

/// Empty-query path: decode [recents] back into the catalog (filtering
/// to entries we actually have on file for [viewerHost]) and append the
/// rest of [all] in catalog order, deduplicating by name.
Iterable<CustomEmoji> _emptyQuery({
  required List<CustomEmoji> all,
  required List<String> recents,
  required String viewerHost,
}) sync* {
  final byName = <String, CustomEmoji>{};
  for (final e in all) {
    byName[e.name] = e;
  }
  final emitted = <String>{};
  for (final key in recents) {
    // `:name:` or `:name@host:` — strip the colons, then split.
    if (!key.startsWith(':') || !key.endsWith(':') || key.length < 3) {
      continue;
    }
    final inner = key.substring(1, key.length - 1);
    final at = inner.indexOf('@');
    final name = at < 0 ? inner : inner.substring(0, at);
    final host = at < 0 ? viewerHost : inner.substring(at + 1);
    final hit = byName[name];
    if (hit == null) continue;
    if (host != hit.host) continue;
    if (emitted.add(name)) yield hit;
  }
  for (final e in all) {
    if (emitted.add(e.name)) yield e;
  }
}
