import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dhaka midnight: 18:00 UTC is already the next day', () {
    final keys = FamilyDateKeys(
      clock: FakeClock(DateTime.utc(2026, 10, 14, 18)),
    );
    expect(keys.today().toString(), '2026-10-15');
    expect(keys.thisMonth().toString(), '2026-10');
  });

  test('17:59 UTC is still the same Dhaka day', () {
    final keys = FamilyDateKeys(
      clock: FakeClock(DateTime.utc(2026, 10, 14, 17, 59)),
    );
    expect(keys.today().toString(), '2026-10-14');
  });

  test('month boundary: 31 Oct evening UTC is 1 Nov in Dhaka', () {
    final keys = FamilyDateKeys(
      clock: FakeClock(DateTime.utc(2026, 10, 31, 19)),
    );
    expect(
      keys.dateKeyOf(DateTime.utc(2026, 10, 31, 19)).toString(),
      '2026-11-01',
    );
    expect(
      keys.monthKeyOf(DateTime.utc(2026, 10, 31, 19)).toString(),
      '2026-11',
    );
  });

  test('leap day and month range', () {
    final keys = FamilyDateKeys(clock: FakeClock(DateTime.utc(2028, 2, 29, 6)));
    expect(keys.today().toString(), '2028-02-29');
    final range = keys.monthRangeOf(MonthKey(2028, 2));
    expect(range.end.toString(), '2028-02-29');
    expect(keys.monthRangeOf(MonthKey(2027, 2)).end.toString(), '2027-02-28');
  });

  test(
    'a family that changes time zone gets different keys from the same instant',
    () {
      final instant = DateTime.utc(2026, 10, 14, 20);
      final dhaka = FamilyDateKeys(clock: FakeClock(instant));
      final london = dhaka.withTimezone('Europe/London');
      expect(dhaka.dateKeyOf(instant).toString(), '2026-10-15');
      expect(london.dateKeyOf(instant).toString(), '2026-10-14');
    },
  );
}
