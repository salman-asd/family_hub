import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/domain/advance_grouping.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/fund/domain/month_choices.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:flutter_test/flutter_test.dart';

final DateKey _day = DateKey(2026, 10, 18);

MemberAdvance _advance(
  String id, {
  String member = 'cara',
  int amount = 10000,
  int settled = 0,
  AdvanceStatus? status,
}) => MemberAdvance(
  expenseId: id,
  memberId: member,
  amount: Money.paisa(amount),
  settled: Money.paisa(settled),
  status: status ?? MemberAdvance.statusFor(Money.paisa(amount), Money.paisa(settled)),
  dateKey: _day,
  monthKey: _day.monthKey,
);

void main() {
  group('groupAdvances', () {
    test('groups by member, keeping the first-seen order', () {
      final groups = groupAdvances(<MemberAdvance>[
        _advance('a', member: 'cara'),
        _advance('b', member: 'alice'),
        _advance('c', member: 'cara'),
      ]);

      expect(groups.map((g) => g.memberId), <String>['cara', 'alice']);
      expect(groups.first.rows.map((r) => r.expenseId), <String>['a', 'c']);
      expect(groups.first.totalOwed, const Money.paisa(20000));
    });

    test('voided advances are dropped; settled ones only when asked', () {
      final rows = <MemberAdvance>[
        _advance('v', status: AdvanceStatus.voided),
        _advance('p', amount: 5000, settled: 5000),
        _advance('o', amount: 4000, settled: 1000),
      ];

      final open = groupAdvances(rows);
      expect(open.single.rows.map((r) => r.expenseId), <String>['o']);
      expect(open.single.totalOwed, const Money.paisa(3000));

      final all = groupAdvances(rows, includeSettled: true);
      expect(all.single.rows.map((r) => r.expenseId), <String>['p', 'o']);
    });

    test('an empty list yields no groups', () {
      expect(groupAdvances(const <MemberAdvance>[]), isEmpty);
    });
  });

  group('monthChoices / closingOf', () {
    final thisMonth = MonthKey(2026, 10);

    test('offers this month and the previous eleven', () {
      final months = monthChoices(thisMonth, const <MonthClosing>[]);
      expect(months.first, thisMonth);
      expect(months, hasLength(12));
      expect(months.last, MonthKey(2025, 11));
    });

    test('an older closed month is still offered', () {
      final months = monthChoices(thisMonth, <MonthClosing>[
        const MonthClosing(monthKey: MonthKey(2025, 1), status: MonthStatus.closed),
      ]);
      expect(months.last, MonthKey(2025, 1));
    });

    test('closingOf returns the closing of exactly that month', () {
      final closings = <MonthClosing>[
        const MonthClosing(monthKey: MonthKey(2026, 9), status: MonthStatus.closed),
      ];
      expect(closingOf(closings, MonthKey(2026, 9))!.status, MonthStatus.closed);
      expect(closingOf(closings, MonthKey(2026, 10)), isNull);
    });
  });
}
