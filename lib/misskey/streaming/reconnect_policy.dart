import 'dart:math';

/// Exponential backoff with jitter, capped at 30s .
class ReconnectPolicy {
  final List<Duration> _schedule;
  final Random _rng;
  int _attempt = 0;

  ReconnectPolicy({Random? rng})
      : _schedule = const [
          Duration(milliseconds: 500),
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 5),
          Duration(seconds: 10),
          Duration(seconds: 30),
        ],
        _rng = rng ?? Random();

  /// Reset after a successful connection.
  void reset() => _attempt = 0;

  /// Next backoff duration with up to ±20% jitter so reconnect storms
  /// don't synchronize across accounts.
  Duration nextDelay() {
    final base = _schedule[_attempt.clamp(0, _schedule.length - 1)];
    _attempt++;
    final jitter = 1.0 + (_rng.nextDouble() * 0.4 - 0.2);
    return Duration(microseconds: (base.inMicroseconds * jitter).round());
  }
}
