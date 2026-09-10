import 'dart:async';

/// Cooperative cancellation token. Use in long-running tasks (HTTP retries,
/// gap-fill on reconnect) instead of fighting with `Completer<void>`.
class CancellationToken {
  final _completer = Completer<void>();
  bool _cancelled = false;

  bool get isCancelled => _cancelled;
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _completer.complete();
  }

  void throwIfCancelled() {
    if (_cancelled) throw const CancelledException();
  }
}

class CancelledException implements Exception {
  const CancelledException();
  @override
  String toString() => 'CancelledException';
}
