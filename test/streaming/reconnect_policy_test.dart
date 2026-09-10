import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/misskey/streaming/reconnect_policy.dart';

void main() {
  test('schedule grows then caps at 30s', () {
    final p = ReconnectPolicy(rng: Random(0));
    final delays = List.generate(8, (_) => p.nextDelay());

    // Base schedule: 0.5s, 1s, 2s, 5s, 10s, 30s.
    final bases = [500, 1000, 2000, 5000, 10000, 30000, 30000, 30000];
    for (var i = 0; i < delays.length; i++) {
      final ms = delays[i].inMilliseconds;
      // Allow ±20% jitter window with a small slack for rounding.
      expect(ms, greaterThanOrEqualTo((bases[i] * 0.79).round()));
      expect(ms, lessThanOrEqualTo((bases[i] * 1.21).round()));
    }
  });

  test('reset rewinds to first slot', () {
    final p = ReconnectPolicy(rng: Random(0));
    p.nextDelay();
    p.nextDelay();
    p.nextDelay();
    p.reset();
    final after = p.nextDelay().inMilliseconds;
    expect(after, lessThanOrEqualTo(700)); // back to ~500ms ±jitter
  });
}
