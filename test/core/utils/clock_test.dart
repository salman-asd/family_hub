import 'package:family_hub/core/utils/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SystemClock returns a UTC instant', () {
    expect(const SystemClock().nowUtc().isUtc, isTrue);
  });

  test('FakeClock can be set and advanced', () {
    final clock = FakeClock(DateTime.utc(2026, 10, 14, 12));
    expect(clock.nowUtc(), DateTime.utc(2026, 10, 14, 12));
    clock.advance(const Duration(hours: 13));
    expect(clock.nowUtc(), DateTime.utc(2026, 10, 15, 1));
    clock.setTo(DateTime.utc(2028, 2, 29));
    expect(clock.nowUtc(), DateTime.utc(2028, 2, 29));
  });

  test('clockProvider defaults to SystemClock and can be overridden', () {
    final defaults = ProviderContainer();
    addTearDown(defaults.dispose);
    expect(defaults.read(clockProvider), isA<SystemClock>());

    final fake = FakeClock(DateTime.utc(2026, 1, 1));
    final overridden = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(fake)],
    );
    addTearDown(overridden.dispose);
    expect(overridden.read(clockProvider), same(fake));
  });
}
