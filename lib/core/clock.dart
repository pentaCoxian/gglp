/// Indirection over `DateTime.now()` so streaming reconnect logic, height
/// cache TTLs, and tests are deterministic.
abstract class Clock {
  DateTime now();

  static Clock system = const SystemClock();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

class FakeClock implements Clock {
  DateTime _now;
  FakeClock(this._now);

  @override
  DateTime now() => _now;

  void advance(Duration d) => _now = _now.add(d);
  void setTo(DateTime t) => _now = t;
}
