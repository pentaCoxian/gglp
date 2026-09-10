import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/misskey/models/emoji.dart';
import 'package:misskey_gglp/ui/widgets/mfm_input/mfm_emoji_ranker.dart';

CustomEmoji emoji(
  String name, {
  String host = 'misskey.io',
  List<String> aliases = const [],
  String? category,
}) =>
    CustomEmoji(
      host: host,
      name: name,
      url: 'https://$host/emoji/$name.png',
      aliases: aliases,
      category: category,
    );

void main() {
  group('rankEmoji', () {
    test('exact name beats prefix beats substring', () {
      final all = [
        emoji('parrot_long'),     // prefix
        emoji('parrot'),          // exact
        emoji('grumpy_parrot'),   // substring
      ];
      final ranked = rankEmoji(
        all: all,
        query: 'parrot',
        viewerHost: 'misskey.io',
        recents: const [],
      );
      expect(ranked.map((e) => e.name).toList(),
          ['parrot', 'parrot_long', 'grumpy_parrot']);
    });

    test('alias prefix beats name substring', () {
      final all = [
        emoji('weather_sun', aliases: const []),       // substring 'sun'
        emoji('blazing_star', aliases: const ['sun']), // alias prefix
      ];
      final ranked = rankEmoji(
        all: all,
        query: 'sun',
        viewerHost: 'misskey.io',
        recents: const [],
      );
      // alias prefix (200) < name substring (400+idx).
      expect(ranked.first.name, 'blazing_star');
    });

    test('shorter prefix-match outranks longer one (tie-breaker)', () {
      final all = [
        emoji('parrot_long'),
        emoji('par'),
      ];
      final ranked = rankEmoji(
        all: all,
        query: 'par',
        viewerHost: 'misskey.io',
        recents: const [],
      );
      // 'par' exact (0) < 'parrot_long' prefix (1 + 8 = 9).
      expect(ranked.first.name, 'par');
    });

    test('recents bump pulls a match to the top', () {
      final all = [
        emoji('parrot'),
        emoji('parrot_long'),
      ];
      final ranked = rankEmoji(
        all: all,
        query: 'parrot',
        viewerHost: 'misskey.io',
        recents: const [':parrot_long:'],
      );
      // With -50 bonus 'parrot_long' (prefix score 1+5=6, → -44) outranks
      // 'parrot' (exact = 0).
      expect(ranked.first.name, 'parrot_long');
    });

    test('no matches → empty list', () {
      final all = [emoji('parrot')];
      final ranked = rankEmoji(
        all: all,
        query: 'zzz',
        viewerHost: 'misskey.io',
        recents: const [],
      );
      expect(ranked, isEmpty);
    });

    test('cap respected', () {
      final all = List.generate(50, (i) => emoji('parrot_$i'));
      final ranked = rankEmoji(
        all: all,
        query: 'parrot',
        viewerHost: 'misskey.io',
        recents: const [],
        limit: 5,
      );
      expect(ranked.length, 5);
    });

    test('dedupes by name when same name reappears', () {
      final all = [
        emoji('parrot'),
        emoji('parrot'), // duplicate (e.g. alias collision)
      ];
      final ranked = rankEmoji(
        all: all,
        query: 'parrot',
        viewerHost: 'misskey.io',
        recents: const [],
      );
      expect(ranked.length, 1);
    });

    test('empty query → recents first, then catalog order', () {
      final all = [
        emoji('alpha'),
        emoji('beta'),
        emoji('gamma'),
      ];
      final ranked = rankEmoji(
        all: all,
        query: '',
        viewerHost: 'misskey.io',
        recents: const [':gamma:'],
      );
      expect(ranked.map((e) => e.name).toList(),
          ['gamma', 'alpha', 'beta']);
    });

    test('empty query, federated recents key resolves to right host', () {
      final all = [
        emoji('alpha', host: 'a.example'),
        emoji('alpha', host: 'b.example'),
      ];
      // Recent key encodes the b.example variant; we should surface it.
      final ranked = rankEmoji(
        all: all,
        query: '',
        viewerHost: 'a.example',
        recents: const [':alpha@b.example:'],
      );
      // First by recents (the b.example one matches the host), then by
      // catalog order — but de-dup is by name only, so the second alpha
      // is suppressed. Either way the b.example one comes first.
      expect(ranked.first.host, 'b.example');
    });
  });
}
