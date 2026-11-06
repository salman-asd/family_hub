enum Greeting { morning, afternoon, evening }

abstract final class GreetingForTime {
  static Greeting atMinutes(int minutesOfDay) {
    if (minutesOfDay < 0 || minutesOfDay >= 24 * 60) {
      throw RangeError.range(minutesOfDay, 0, 24 * 60 - 1, 'minutesOfDay');
    }
    if (minutesOfDay < 12 * 60) return Greeting.morning;
    if (minutesOfDay < 18 * 60) return Greeting.afternoon;
    return Greeting.evening;
  }
}
