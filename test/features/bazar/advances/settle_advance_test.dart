import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement_builder.dart';
import 'package:family_hub/features/bazar/advances/domain/usecases/settle_advance.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_balance_calculator.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../bazar_test_helpers.dart';

const String _f = BazarFixture.familyId;

/// P2-20 / P2-23: paying a member back never touches the original expense.
void main() {
  late BazarFixture fx;
  late SettleAdvance settle;

  setUp(() {
    fx = BazarFixture();
    settle = SettleAdvance(
      advances: fx.backend,
      funds: fx.backend,
      families: fx.backend,
      clock: fx.clock,
      newId: fx.ids.call,
      dateKeys: fx.dateKeys,
    );
  });

  Money balance() =>
      FundBalanceCalculator.balance(fx.backend.fundTransactionsOf(_f));

  MemberAdvance advance(String id) => fx.backend.advances[_f]![id]!;

  Future<AppFailure?> settleIt(
    int paisa, {
    String expenseId = 'e1',
    String actor = 'alice',
    DateKey? date,
    String? settlementId,
  }) async {
    final result = await settle(
      actorUid: actor,
      familyId: _f,
      expenseId: expenseId,
      amount: Money.paisa(paisa),
      date: date,
      settlementId: settlementId,
    );
    return result.failureOrNull;
  }

  test('a partial then a full settlement move pending -> partial -> settled', () async {
    fx.putAdvance(expenseId: 'e1', memberId: 'cara', amount: const Money.paisa(10000));

    expect(await settleIt(4000, settlementId: 's1'), isNull);
    expect(advance('e1').status, AdvanceStatus.partial);
    expect(advance('e1').settled, const Money.paisa(4000));
    expect(balance(), const Money.paisa(-4000));

    expect(await settleIt(6000, settlementId: 's2'), isNull);
    expect(advance('e1').status, AdvanceStatus.settled);
    expect(advance('e1').remaining, Money.zero);
    expect(balance(), const Money.paisa(-10000));
    expect(fx.backend.settlements[_f]!.keys, <String>['s1', 's2']);
  });

  test('an overpayment is refused and writes nothing', () async {
    fx.putAdvance(expenseId: 'e1', amount: const Money.paisa(5000));
    expect(await settleIt(5001), const Conflict(code: 'overpayment'));
    expect(fx.backend.writes, 0);
    expect(balance(), Money.zero);
  });

  test('a second settlement sees the first (fresh state inside the write)', () async {
    fx.putAdvance(expenseId: 'e1', amount: const Money.paisa(5000));
    await settleIt(3000, settlementId: 's1');
    expect(await settleIt(3000, settlementId: 's2'), const Conflict(code: 'overpayment'));
    expect(advance('e1').settled, const Money.paisa(3000));
  });

  test('a voided advance and a missing one are refused', () async {
    fx.putAdvance(
      expenseId: 'e1',
      amount: const Money.paisa(5000),
      status: AdvanceStatus.voided,
    );
    expect(await settleIt(100), const Conflict(code: 'advance_voided'));
    expect(await settleIt(100, expenseId: 'nope'), isA<NotFound>());
  });

  test('the original expense is never edited', () async {
    final expense = fx.putExpense(
      id: 'e1',
      funding: FundingSource.member,
      paidByMemberId: 'cara',
      reimbursable: true,
      total: const Money.paisa(12000),
    );
    fx.putAdvance(expenseId: 'e1', memberId: 'cara', amount: expense.total);
    final before = fx.backend.expenses[_f]!['e1'];

    await settleIt(12000);

    expect(fx.backend.expenses[_f]!['e1'], before);
    // Paying back lowers the fund but is not a new expense.
    expect(fx.backend.expensesOf(_f), hasLength(1));
  });

  test('a locked month, a future date and a plain member are refused', () async {
    fx.putAdvance(expenseId: 'e1', amount: const Money.paisa(5000));
    expect(
      await settleIt(100, date: DateKey(2026, 10, 19)),
      const Validation('dateKey', 'future_date'),
    );
    fx.putClosing(monthKey: MonthKey(2026, 10));
    expect(await settleIt(100), const Conflict(code: 'month_locked'));
    expect(await settleIt(100, actor: 'cara'), isA<PermissionDenied>());
  });

  test('the plan builder is pure and checks the current amount', () {
    final current = fx.putAdvance(expenseId: 'e1', amount: const Money.paisa(5000));
    final plan = buildSettlementPlan(
      current: current,
      amount: const Money.paisa(2000),
      date: fx.dateKeys.today(),
      at: fx.clock.nowUtc(),
      actorUid: 'alice',
      settlementId: 's9',
    ).valueOrNull!;

    expect(plan.settlement.fundTxId, 'stl_s9');
    expect(plan.reimbursement.id, 'stl_s9');
    expect(plan.reimbursement.type, FundTxType.reimbursement);
    expect(plan.reimbursement.amount, const Money.paisa(-2000));
    expect(plan.advanceAfter.status, AdvanceStatus.partial);
  });
}
