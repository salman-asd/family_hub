import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MonthClosing closing(MonthKey month, MonthStatus status) => MonthClosing(
    monthKey: month,
    status: status,
    closingBalance: status == MonthStatus.closed
        ? const Money.paisa(100000)
        : null,
  );

  test('only a closed month is locked', () {
    final closings = <MonthKey, MonthClosing>{
      MonthKey(2026, 8): closing(MonthKey(2026, 8), MonthStatus.closed),
      MonthKey(2026, 9): closing(MonthKey(2026, 9), MonthStatus.open),
    };

    expect(MonthLocks.isLocked(MonthKey(2026, 8), closings), isTrue);
    expect(MonthLocks.isLocked(MonthKey(2026, 9), closings), isFalse);
    expect(MonthLocks.isLocked(MonthKey(2026, 10), closings), isFalse);
  });

  test('no closings and no start month means no fund window', () {
    expect(
      MonthLocks.fundWindowStart(const <MonthKey, MonthClosing>{}, null),
      isNull,
    );
  });

  test('no closings falls back to the configured start month', () {
    final start = MonthKey(2026, 1);

    expect(
      MonthLocks.fundWindowStart(const <MonthKey, MonthClosing>{}, start),
      start,
    );
  });

  test('the window starts after the latest closed month', () {
    final closings = <MonthKey, MonthClosing>{
      MonthKey(2026, 8): closing(MonthKey(2026, 8), MonthStatus.closed),
      MonthKey(2026, 9): closing(MonthKey(2026, 9), MonthStatus.closed),
      MonthKey(2026, 7): closing(MonthKey(2026, 7), MonthStatus.closed),
    };

    expect(
      MonthLocks.fundWindowStart(closings, MonthKey(2026, 1)),
      MonthKey(2026, 10),
    );
  });

  test('a reopened month no longer moves the window', () {
    final closings = <MonthKey, MonthClosing>{
      MonthKey(2026, 8): closing(MonthKey(2026, 8), MonthStatus.closed),
      MonthKey(2026, 9): closing(MonthKey(2026, 9), MonthStatus.open),
      MonthKey(2026, 7): closing(MonthKey(2026, 7), MonthStatus.closed),
    };

    expect(
      MonthLocks.fundWindowStart(closings, MonthKey(2026, 1)),
      MonthKey(2026, 9),
    );
  });

  test('the window crosses a year boundary', () {
    final closings = <MonthKey, MonthClosing>{
      MonthKey(2026, 12): closing(MonthKey(2026, 12), MonthStatus.closed),
    };

    expect(
      MonthLocks.fundWindowStart(closings, MonthKey(2026, 1)),
      MonthKey(2027, 1),
    );
  });
}
