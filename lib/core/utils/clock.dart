/// Source of "now". Domain code receives a [Clock] and never calls
/// DateTime.now() itself, so tests stay deterministic.
abstract interface class Clock {
  /// Current instant, always in UTC.
  DateTime nowUtc();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// Settable clock for tests.
final class FakeClock implements Clock {
  FakeClock(DateTime initial) : _now = initial.toUtc();

  DateTime _now;

  @override
  DateTime nowUtc() => _now;

  void setTo(DateTime value) => _now = value.toUtc();

  void advance(Duration duration) => _now = _now.add(duration);
}
