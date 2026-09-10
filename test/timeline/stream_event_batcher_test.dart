import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/timeline/stream_event_batcher.dart';

// `testWidgets` runs the body under the test binding's fake clock, so
// `tester.pump(duration)` advances the batcher's Timer deterministically
// without pulling `fake_async` in as a direct dependency.
void main() {
  testWidgets('delivers one batch per window, in arrival order',
      (tester) async {
    final flushes = <List<int>>[];
    final b = StreamEventBatcher<int>(
      onFlush: flushes.add,
      delay: const Duration(milliseconds: 250),
      maxSize: 50,
    );
    b.add(1);
    b.add(2);
    await tester.pump(const Duration(milliseconds: 100));
    b.add(3);
    expect(flushes, isEmpty, reason: 'window still open');
    await tester.pump(const Duration(milliseconds: 200));
    expect(flushes, [
      [1, 2, 3]
    ]);
    // A later arrival starts a fresh window.
    b.add(4);
    await tester.pump(const Duration(milliseconds: 250));
    expect(flushes, [
      [1, 2, 3],
      [4]
    ]);
  });

  testWidgets('flushes immediately once the buffer reaches maxSize',
      (tester) async {
    final flushes = <List<int>>[];
    final b = StreamEventBatcher<int>(
      onFlush: flushes.add,
      delay: const Duration(seconds: 1),
      maxSize: 3,
    );
    b.add(1);
    b.add(2);
    expect(flushes, isEmpty);
    b.add(3);
    expect(flushes, [
      [1, 2, 3]
    ], reason: 'no timer needed');
    // The timer from the first add must not fire an empty flush.
    await tester.pump(const Duration(seconds: 2));
    expect(flushes, hasLength(1));
  });

  testWidgets('clear drops buffered events and cancels the timer',
      (tester) async {
    final flushes = <List<int>>[];
    final b = StreamEventBatcher<int>(onFlush: flushes.add);
    b.add(1);
    b.clear();
    await tester.pump(const Duration(seconds: 1));
    expect(flushes, isEmpty);
    // Still usable afterwards.
    b.add(2);
    await tester.pump(const Duration(seconds: 1));
    expect(flushes, [
      [2]
    ]);
  });

  testWidgets('dispose ignores later adds', (tester) async {
    final flushes = <List<int>>[];
    final b = StreamEventBatcher<int>(onFlush: flushes.add);
    b.add(1);
    b.dispose();
    b.add(2);
    await tester.pump(const Duration(seconds: 1));
    expect(flushes, isEmpty);
  });

  testWidgets('events added during a flush go to the next batch',
      (tester) async {
    final flushes = <List<int>>[];
    late StreamEventBatcher<int> b;
    b = StreamEventBatcher<int>(
      onFlush: (batch) {
        flushes.add(batch);
        if (batch.contains(1)) b.add(99);
      },
    );
    b.add(1);
    await tester.pump(const Duration(milliseconds: 250));
    expect(flushes, [
      [1]
    ]);
    await tester.pump(const Duration(milliseconds: 250));
    expect(flushes, [
      [1],
      [99]
    ]);
  });
}
