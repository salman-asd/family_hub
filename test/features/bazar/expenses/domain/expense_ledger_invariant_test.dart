import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_balance_calculator.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';

void main() {
  test(
    'every edit sequence leaves ledger == -sum(live expense totals)',
    () async {
      final f = BazarFixture();

      Future<void> check() async {
        final rows = f.backend.fundTransactionsOf(BazarFixture.familyId);
        final live = f.backend
            .expensesOf(BazarFixture.familyId)
            .where((expense) => !expense.isDeleted);
        var expectedBalance = Money.zero;
        for (final expense in live) {
          final funded = expense.funding == FundingSource.fund;
          final expected = funded ? -expense.total : Money.zero;
          if (funded) expectedBalance -= expense.total;
          expect(
            FundBalanceCalculator.ledgerFor(rows, expense.id),
            expected,
            reason: 'ledger mismatch for ${expense.id}',
          );
        }
        expect(FundBalanceCalculator.balance(rows), expectedBalance);
      }

      await f.addExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        draft: f.draft(),
        id: 'e1',
        eventId: 'ev-add',
      );
      await check();

      await f.updateExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        expenseId: 'e1',
        draft: f.draft(typedTotal: const Money.paisa(15000)),
        eventId: 'ev-up-1',
      );
      await check();
      final original = f.backend
          .fundTransactionsOf(BazarFixture.familyId)
          .singleWhere((row) => row.id == 'exp_e1');
      expect(original.amount, const Money.paisa(-10000));
      expect(original.type, FundTxType.expense);

      await f.updateExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        expenseId: 'e1',
        draft: f.draft(
          date: DateTime.utc(2026, 9, 15, 9),
          typedTotal: const Money.paisa(15000),
        ),
        eventId: 'ev-up-2',
      );
      await check();

      await f.updateExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        expenseId: 'e1',
        draft: f.draft(
          date: DateTime.utc(2026, 9, 15, 9),
          funding: FundingSource.member,
          paidByMemberId: 'bob',
          typedTotal: const Money.paisa(15000),
        ),
        eventId: 'ev-up-3',
      );
      await check();

      await f.updateExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        expenseId: 'e1',
        draft: f.draft(
          date: DateTime.utc(2026, 9, 15, 9),
          typedTotal: const Money.paisa(15000),
        ),
        eventId: 'ev-up-4',
      );
      await check();

      await f.softDeleteExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        expenseId: 'e1',
        eventId: 'ev-del',
      );
      await check();

      await f.restoreExpense(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        expenseId: 'e1',
        eventId: 'ev-res',
      );
      await check();
    },
  );
}
