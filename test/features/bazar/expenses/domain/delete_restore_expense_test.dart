import 'package:family_hub/core/errors/app_failure.dart';
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

  void seedFundExpense() {
    f.putExpense(id: 'e1');
    f.putFundTransaction(
      FundTransaction.forExpense(
        expenseId: 'e1',
        total: const Money.paisa(10000),
        dateKey: f.dateKeys.today(),
        createdBy: 'alice',
        createdAt: f.clock.nowUtc(),
      ),
    );
  }

  test('soft delete reverses a fund expense and keeps a revision', () async {
    seedFundExpense();
    final result = await f.softDeleteExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      eventId: 'ev-del',
    );

    expect(result.valueOrNull?.isDeleted, isTrue);
    final rows = f.backend.fundTransactionsOf(BazarFixture.familyId);
    expect(rows.length, 2);
    expect(
      rows.singleWhere((row) => row.id == 'adj_ev-del_del').amount,
      const Money.paisa(10000),
    );
    expect(FundBalanceCalculator.ledgerFor(rows, 'e1'), Money.zero);
    final revision = f.backend.revisionsOf(BazarFixture.familyId, 'e1').single;
    expect(revision.changedFields, <String>['deletedAt', 'deletedBy']);
    expect(revision.before['deletedAt'], isNull);
    final original = rows.singleWhere((row) => row.id == 'exp_e1');
    expect(original.amount, const Money.paisa(-10000));
    expect(original.type, FundTxType.expense);
  });

  test('retrying the same delete event keeps one adjustment', () async {
    seedFundExpense();
    for (var i = 0; i < 2; i++) {
      final result = await f.softDeleteExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        expenseId: 'e1',
        eventId: 'ev-del',
      );
      expect(result.isSuccess, isTrue);
    }

    final adjustments = f.backend
        .fundTransactionsOf(BazarFixture.familyId)
        .where((row) => row.id.startsWith('adj_ev-del'));
    expect(adjustments.length, 1);
  });

  test(
    'soft delete voids a pending member advance but writes no fund row',
    () async {
      f.putExpense(
        id: 'e1',
        funding: FundingSource.member,
        paidByMemberId: 'bob',
        reimbursable: true,
      );
      f.putAdvance(expenseId: 'e1', memberId: 'bob');

      final result = await f.softDeleteExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        expenseId: 'e1',
        eventId: 'ev-del',
      );

      expect(result.isSuccess, isTrue);
      expect(f.backend.fundTransactionsOf(BazarFixture.familyId), isEmpty);
      expect(
        f.backend.advancesOf(BazarFixture.familyId).single.status,
        AdvanceStatus.voided,
      );
    },
  );

  test('a settled advance blocks the delete', () async {
    f.putExpense(
      id: 'e1',
      funding: FundingSource.member,
      paidByMemberId: 'bob',
      reimbursable: true,
    );
    f.putAdvance(
      expenseId: 'e1',
      memberId: 'bob',
      settled: const Money.paisa(10000),
    );

    final result = await f.softDeleteExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      eventId: 'ev-del',
    );

    expect(result.failureOrNull, const Conflict(code: 'advance_settled'));
    expect(
      f.backend.expensesOf(BazarFixture.familyId).single.isDeleted,
      isFalse,
    );
  });

  test('restore re-applies the fund row and clears deletedAt', () async {
    seedFundExpense();
    await f.softDeleteExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      eventId: 'ev-del',
    );

    final result = await f.restoreExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      eventId: 'ev-res',
    );

    expect(result.valueOrNull?.isDeleted, isFalse);
    final rows = f.backend.fundTransactionsOf(BazarFixture.familyId);
    expect(rows.length, 3);
    expect(
      rows.singleWhere((row) => row.id == 'adj_ev-res_res').amount,
      const Money.paisa(-10000),
    );
    expect(
      FundBalanceCalculator.ledgerFor(rows, 'e1'),
      const Money.paisa(-10000),
    );
  });

  test('restore turns a voided advance back into pending', () async {
    f.putExpense(
      id: 'e1',
      funding: FundingSource.member,
      paidByMemberId: 'bob',
      reimbursable: true,
    );
    f.putAdvance(expenseId: 'e1', memberId: 'bob');
    await f.softDeleteExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      eventId: 'ev-del',
    );

    final result = await f.restoreExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      eventId: 'ev-res',
    );

    expect(result.isSuccess, isTrue);
    expect(
      f.backend.advancesOf(BazarFixture.familyId).single.status,
      AdvanceStatus.pending,
    );
  });

  test('restoring a live expense is a conflict', () async {
    f.putExpense(id: 'e1');
    final result = await f.restoreExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      eventId: 'ev-res',
    );
    expect(result.failureOrNull, const Conflict(code: 'expense_not_deleted'));
  });

  test('a closed month blocks delete and restore', () async {
    seedFundExpense();
    f.putClosing(monthKey: f.dateKeys.today().monthKey);

    final deleted = await f.softDeleteExpense(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      eventId: 'ev-del',
    );
    expect(deleted.failureOrNull, const Conflict(code: 'month_locked'));
  });

  test('a plain member may not delete another member\'s expense', () async {
    seedFundExpense();
    final result = await f.softDeleteExpense(
      actorUid: 'cara',
      familyId: BazarFixture.familyId,
      expenseId: 'e1',
      eventId: 'ev-del',
    );
    expect(result.failureOrNull, const PermissionDenied());
  });
}
