import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/reports/domain/period_comparison.dart';
import 'package:family_hub/features/bazar/reports/domain/report_data.dart';
import 'package:family_hub/features/bazar/reports/domain/report_query.dart';
import 'package:flutter_test/flutter_test.dart';

/// P2-24: query resolution and the integer percentage helpers.
void main() {
  final today = DateKey(2026, 10, 18);

  group('ReportQuery', () {
    test('thisMonth resolves to the whole month of today', () {
      final query = ReportQuery.thisMonth(today);
      expect(query.preset, RangePreset.thisMonth);
      expect(query.resolvedRange, monthRange(MonthKey(2026, 10)));
    });

    test('resolve honours the family week start', () {
      final saturday = ReportQuery.resolve(
        preset: RangePreset.thisWeek,
        today: today,
        weekStartDay: DateTime.saturday,
      );
      expect(saturday.resolvedRange.start, DateKey(2026, 10, 17));

      final monday = ReportQuery.resolve(
        preset: RangePreset.thisWeek,
        today: today,
        weekStartDay: DateTime.monday,
      );
      expect(monday.resolvedRange.start, DateKey(2026, 10, 12));
    });

    test('withRange keeps every filter', () {
      final query = ReportQuery(
        preset: RangePreset.custom,
        range: monthRange(MonthKey(2026, 10)),
        categoryId: 'cat_food',
        itemId: 'i1',
        memberId: 'cara',
        funding: FundingSource.member,
      );
      final previous = query.withRange(monthRange(MonthKey(2026, 9)));
      expect(previous.resolvedRange, monthRange(MonthKey(2026, 9)));
      expect(previous.categoryId, 'cat_food');
      expect(previous.itemId, 'i1');
      expect(previous.memberId, 'cara');
      expect(previous.funding, FundingSource.member);
      expect(previous.preset, RangePreset.custom);
    });

    test('equality compares every field', () {
      const a = ReportQuery(
        preset: RangePreset.thisMonth,
        range: DateKeyRange(DateKey(2026, 10, 1), DateKey(2026, 10, 31)),
      );
      const b = ReportQuery(
        preset: RangePreset.thisMonth,
        range: DateKeyRange(DateKey(2026, 10, 1), DateKey(2026, 10, 31)),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == a.withRange(monthRange(MonthKey(2026, 9))), isFalse);
    });
  });

  group('halfUpRatioBp', () {
    test('rounds half away from zero and keeps the sign', () {
      expect(halfUpRatioBp(delta: const Money.paisa(50), base: const Money.paisa(200)), 2500);
      expect(halfUpRatioBp(delta: const Money.paisa(-50), base: const Money.paisa(200)), -2500);
      expect(halfUpRatioBp(delta: const Money.paisa(1), base: const Money.paisa(3)), 3333);
      expect(halfUpRatioBp(delta: const Money.paisa(2), base: const Money.paisa(3)), 6667);
    });
  });

  group('PeriodComparison', () {
    test('equal totals are flat with zero basis points', () {
      final comparison = PeriodComparison.of(
        current: const Money.paisa(5000),
        previous: const Money.paisa(5000),
      );
      expect(comparison.isFlat, isTrue);
      expect(comparison.deltaBp, 0);
    });

    test('a drop is negative and not "up"', () {
      final comparison = PeriodComparison.of(
        current: const Money.paisa(4000),
        previous: const Money.paisa(5000),
      );
      expect(comparison.delta, const Money.paisa(-1000));
      expect(comparison.deltaBp, -2000);
      expect(comparison.isUp, isFalse);
    });

    test('a zero previous total has no percentage', () {
      final comparison = PeriodComparison.of(
        current: const Money.paisa(4000),
        previous: Money.zero,
      );
      expect(comparison.deltaBp, isNull);
    });
  });

  test('averageMoney is exact on paisa', () {
    expect(averageMoney(const Money.paisa(1000), 3), const Money.paisa(333));
    expect(averageMoney(const Money.paisa(1001), 3), const Money.paisa(334));
    expect(averageMoney(Money.zero, 31), Money.zero);
  });
}
