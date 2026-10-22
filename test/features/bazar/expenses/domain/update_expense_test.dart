import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_balance_calculator.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';

void main() {
  late BazarFixture f;

  setUp(() => f = BazarFixture());

  void seedFundExpense({int total = 10000}) {
    f.putExpense(id: 'e1', total: Money.paisa(total));
    f.putFundTransaction(
      FundTransaction.forExpense(
        expenseId: 'e1',
        total: Money.paisa(total),
        dateKey: f.dateKeys.today(),
        createdBy: 'alice',
        createdAt: f.clock.nowUtc(),
      ),
    );
  }

  test('a same-month amount change writes one compensating row', () async {
    seedFundExpense();
    final result = await f.updateExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      draft: f.draft(typedTotal: const Money.paisa(15000)),
      eventId: 'ev1',
    );

    expect(result.valueOrNull?.total, const Money.paisa(15000));
    final rows = f.backend.fundTransactionsOf(BazarFixture.familyId);
    expect(rows.length, 2);
    final adjustment = rows.singleWhere((row) => row.id == 'adj_ev1_a');
    expect(adjustment.amount, const Money.paisa(-5000));
    expect(
      FundBalanceCalculator.ledgerFor(rows, 'e1'),
      const Money.paisa(-15000),
    );
  });

  test('moving a fund expense to another month writes two rows', () async {
    seedFundExpense();
    final result = await f.updateExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      draft: f.draft(date: DateTime.utc(2026, 9, 15, 9)),
      eventId: 'ev1',
    );

    expect(result.isSuccess, isTrue);
    final rows = f.backend.fundTransactionsOf(BazarFixture.familyId);
    expect(rows.length, 3);
    final oldMonth = rows.singleWhere((row) => row.id == 'adj_ev1_a');
    final newMonth = rows.singleWhere((row) => row.id == 'adj_ev1_b');
    expect(oldMonth.amount, const Money.paisa(10000));
    expect(oldMonth.monthKey.toString(), '2026-10');
    expect(newMonth.amount, const Money.paisa(-10000));
    expect(newMonth.monthKey.toString(), '2026-09');
    expect(
      FundBalanceCalculator.ledgerFor(rows, 'e1'),
      const Money.paisa(-10000),
    );
  });

  test(
    'fund to reimbursable member creates an advance and refunds the fund',
    () async {
      seedFundExpense();
      final result = await f.updateExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        expenseId: 'e1',
        draft: f.draft(
          funding: FundingSource.member,
          paidByMemberId: 'bob',
          reimbursable: true,
        ),
        eventId: 'ev1',
      );

      expect(result.isSuccess, isTrue);
      final rows = f.backend.fundTransactionsOf(BazarFixture.familyId);
      expect(
        rows.singleWhere((row) => row.id == 'adj_ev1_a').amount,
        const Money.paisa(10000),
      );
      expect(FundBalanceCalculator.ledgerFor(rows, 'e1'), Money.zero);
      final advance = f.backend.advancesOf(BazarFixture.familyId).single;
      expect(advance.memberId, 'bob');
      expect(advance.status, AdvanceStatus.pending);
    },
  );

  test('member to fund voids the advance and charges the fund', () async {
    f.putExpense(
      id: 'e1',
      funding: FundingSource.member,
      paidByMemberId: 'bob',
      reimbursable: true,
    );
    f.putAdvance(expenseId: 'e1', memberId: 'bob');

    final result = await f.updateExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      draft: f.draft(),
      eventId: 'ev1',
    );

    expect(result.isSuccess, isTrue);
    final rows = f.backend.fundTransactionsOf(BazarFixture.familyId);
    expect(rows.single.amount, const Money.paisa(-10000));
    expect(
      f.backend.advancesOf(BazarFixture.familyId).single.status,
      AdvanceStatus.voided,
    );
  });

  test(
    'a text-only edit writes no ledger rows and records a revision',
    () async {
      seedFundExpense();
      final result = await f.updateExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        expenseId: 'e1',
        draft: f.draft(shop: 'New shop'),
        eventId: 'ev1',
      );

      expect(result.isSuccess, isTrue);
      expect(f.backend.fundTransactionsOf(BazarFixture.familyId).length, 1);
      final revision = f.backend
          .revisionsOf(BazarFixture.familyId, 'e1')
          .single;
      expect(revision.id, 'ev1');
      expect(revision.before['shop'], isNull);
      expect(revision.changedFields, contains('shop'));
      expect(
        f.backend.events
            .where((event) => event.type == AuditEventType.bazarExpenseUpdated)
            .length,
        1,
      );
    },
  );

  test('refuses to change a partly settled advance', () async {
    f.putExpense(
      id: 'e1',
      funding: FundingSource.member,
      paidByMemberId: 'bob',
      reimbursable: true,
    );
    f.putAdvance(
      expenseId: 'e1',
      memberId: 'bob',
      amount: const Money.paisa(10000),
      settled: const Money.paisa(5000),
    );

    final result = await f.updateExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      draft: f.draft(
        funding: FundingSource.member,
        paidByMemberId: 'bob',
        reimbursable: true,
        typedTotal: const Money.paisa(15000),
      ),
      eventId: 'ev1',
    );

    expect(result.failureOrNull, const Conflict(code: 'advance_settled'));
    expect(
      f.backend.expensesOf(BazarFixture.familyId).single.total,
      const Money.paisa(10000),
    );
  });

  test('a plain member may not edit somebody else\'s expense', () async {
    seedFundExpense();
    final result = await f.updateExpense(
      actorUid: 'cara',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      draft: f.draft(shop: 'New shop'),
      eventId: 'ev1',
    );

    expect(result.failureOrNull, const PermissionDenied());
  });

  test('a moderator may edit somebody else\'s expense', () async {
    seedFundExpense();
    final result = await f.updateExpense(
      actorUid: 'bob',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      draft: f.draft(shop: 'Moderated shop'),
      eventId: 'ev1',
    );

    expect(result.valueOrNull?.shop, 'Moderated shop');
  });

  test('a locked destination month blocks an edit', () async {
    seedFundExpense();
    f.putClosing(monthKey: MonthKey(2026, 9));

    final result = await f.updateExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      draft: f.draft(date: DateTime.utc(2026, 9, 15, 9)),
      eventId: 'ev1',
    );

    expect(result.failureOrNull, const Conflict(code: 'month_locked'));
    expect(
      f.backend.expensesOf(BazarFixture.familyId).single.dateKey,
      f.dateKeys.today(),
    );
  });

  test('retrying the same edit event keeps one adjustment', () async {
    seedFundExpense();
    for (var i = 0; i < 2; i++) {
      final result = await f.updateExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        expenseId: 'e1',
        draft: f.draft(typedTotal: const Money.paisa(15000)),
        eventId: 'ev1',
      );
      expect(result.isSuccess, isTrue);
    }

    final adjustments = f.backend
        .fundTransactionsOf(BazarFixture.familyId)
        .where((row) => row.id.startsWith('adj_ev1'));
    expect(adjustments.length, 1);
    expect(
      FundBalanceCalculator.ledgerFor(
        f.backend.fundTransactionsOf(BazarFixture.familyId),
        'e1',
      ),
      const Money.paisa(-15000),
    );
  });

  test('a closed month blocks the edit before any write', () async {
    seedFundExpense();
    f.putClosing(monthKey: f.dateKeys.today().monthKey);

    final result = await f.updateExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      draft: f.draft(shop: 'New shop'),
      eventId: 'ev1',
    );

    expect(result.failureOrNull, const Conflict(code: 'month_locked'));
    expect(f.backend.expensesOf(BazarFixture.familyId).single.shop, isNull);
  });
}
