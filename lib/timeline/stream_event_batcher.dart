import 'dart:async';

/// Coalesces a high-frequency event stream into batches.
///
/// A busy global timeline can deliver tens of notes per second. Applying
/// each one individually meant one list copy, one dedupe scan and one
/// Riverpod emission per note — and every emission re-ran every mounted
/// row's selector. Buffering arrivals and applying them in one pass
/// collapses that to (at most) one emission per [delay] window.
///
/// Flushes early when the buffer reaches [maxSize] so a burst can't
/// pile up an unbounded amount of work behind a single timer tick.
/// Arrival order is preserved inside a batch so consumers can replay
/// adds / patches / deletes with the same semantics as immediate
/// application.
class StreamEventBatcher<T> {
  StreamEventBatcher({
    required this.onFlush,
    this.delay = const Duration(milliseconds: 250),
    this.maxSize = 50,
  });

  final void Function(List<T> batch) onFlush;
  final Duration delay;
  final int maxSize;

  final _buffer = <T>[];
  Timer? _timer;
  bool _disposed = false;

  /// Number of events waiting for the next flush.
  int get length => _buffer.length;

  void add(T event) {
    if (_disposed) return;
    _buffer.add(event);
    if (_buffer.length >= maxSize) {
      flush();
      return;
    }
    _timer ??= Timer(delay, flush);
  }

  /// Drop buffered events without delivering them. Used when the
  /// consumer is about to discard its state anyway (pull-to-refresh).
  void clear() {
    _timer?.cancel();
    _timer = null;
    _buffer.clear();
  }

  /// Deliver everything buffered so far in one call. Safe to call when
  /// nothing is buffered; safe to call re-entrantly from [onFlush]
  /// (events added during a flush go to the next batch).
  void flush() {
    _timer?.cancel();
    _timer = null;
    if (_buffer.isEmpty || _disposed) return;
    final batch = List<T>.of(_buffer, growable: false);
    _buffer.clear();
    onFlush(batch);
  }

  /// Cancel the pending timer and discard buffered events. Call from
  /// the owner's dispose hook so a timer can't fire into a disposed
  /// notifier.
  void dispose() {
    _disposed = true;
    clear();
  }
}
