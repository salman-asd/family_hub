import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_plan_generator.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_status.dart';
import 'package:flutter_test/flutter_test.dart';

final MonthKey _oct = MonthKey(2026, 10);

Contribution _c(
  String id,
  String member,
  int paisa, {
  ContributionApproval status = ContributionApproval.approved,
  DateTime? voidedAt,
}) => Contribution(
  id: id,
  memberId: member,
  monthKey: _oct,
  dateKey: DateKey(2026, 10, 5),
  amount: Money.paisa(paisa),
  status: status,
  requestedBy: member,
  createdAt: DateTime.utc(2026, 10, 5),
  voidedAt: voidedAt,
);

ContributionPlan _plan(String member, int paisa) =>
    ContributionPlan(month: _oct, memberId: member, expected: Money.paisa(paisa));

void main() {
  group('generateEqualSplit', () {
    test('5,000 taka among 3 gives the remainder paisa to the first', () {
      final plans = generateEqualSplit(
        month: _oct,
        target: const Money.paisa(500000),
        activeMemberIds: <String>['a', 'b', 'c'],
      );
      expect(plans.map((p) => p.expected.paisa), <int>[166667, 166667, 166666]);
      expect(
        plans.fold<int>(0, (sum, p) => sum + p.expected.paisa),
        500000,
      );
      expect(plans.first.id, '2026-10_a');
    });

    test('an empty roster yields nothing', () {
      expect(
        generateEqualSplit(
          month: _oct,
          target: const Money.paisa(100),
          activeMemberIds: const <String>[],
        ),
        isEmpty,
      );
    });
  });

  group('ContributionStatusCalculator', () {
    List<MemberContributionStatus> run(
      List<ContributionPlan> plans,
      List<Contribution> cs, [
      List<String> active = const <String>['a', 'b'],
    ]) => ContributionStatusCalculator.compute(
      plans: plans,
      contributions: cs,
      activeMemberIds: active,
    );

    test('nobody paid', () {
      final rows = run(<ContributionPlan>[_plan('a', 1000), _plan('b', 1000)], []);
      expect(rows.map((r) => r.remaining.paisa), <int>[1000, 1000]);
      expect(ContributionStatusCalculator.totalReceived(rows), Money.zero);
      expect(
        ContributionStatusCalculator.totalExpected(rows).paisa,
        2000,
      );
    });

    test('partial, exact and over (credit)', () {
      final rows = run(
        <ContributionPlan>[_plan('a', 1000), _plan('b', 1000)],
        <Contribution>[_c('1', 'a', 400), _c('2', 'a', 100), _c('3', 'b', 1500)],
      );
      expect(rows[0].received.paisa, 500);
      expect(rows[0].remaining.paisa, 500);
      expect(rows[0].credit, Money.zero);
      expect(rows[1].remaining, Money.zero);
      expect(rows[1].credit.paisa, 500);
    });

    test('a member without a plan: every payment is credit', () {
      final rows = run(<ContributionPlan>[], <Contribution>[_c('1', 'a', 300)]);
      expect(rows[0].expected, Money.zero);
      expect(rows[0].credit.paisa, 300);
    });

    test('voided, pending and rejected never count as received', () {
      final rows = run(
        <ContributionPlan>[_plan('a', 1000)],
        <Contribution>[
          _c('1', 'a', 100, voidedAt: DateTime.utc(2026, 10, 6)),
          _c('2', 'a', 200, status: ContributionApproval.pending),
          _c('3', 'a', 300, status: ContributionApproval.rejected),
          _c('4', 'a', 50),
        ],
      );
      expect(rows[0].received.paisa, 50);
      expect(rows[0].pendingTotal.paisa, 200);
      expect(rows[0].remaining.paisa, 950);
    });

    test('a non-active member with money still appears, after the roster', () {
      final rows = run(
        <ContributionPlan>[],
        <Contribution>[_c('1', 'zed', 100)],
      );
      expect(rows.map((r) => r.memberId), <String>['a', 'b', 'zed']);
    });
  });

  group('Contribution', () {
    test('copyWith moves the month with the date and clears flags', () {
      final c = _c('1', 'a', 100).copyWith(
        dateKey: DateKey(2026, 11, 2),
        pendingChange: ContributionChange(
          amount: const Money.paisa(1),
          date: DateKey(2026, 11, 2),
          requestedAt: DateTime.utc(2026, 10, 6),
        ),
      );
      expect(c.monthKey, MonthKey(2026, 11));
      expect(c.copyWith(clearPendingChange: true).pendingChange, isNull);
    });
  });
}
