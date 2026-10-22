import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateKey(2026, 9, 15);
  final at = DateTime.utc(2026, 9, 15, 9);
  const creator = 'u1';

  test('forExpense writes exp_<id> as a negative expense row', () {
    final tx = FundTransaction.forExpense(
      expenseId: 'e1',
      total: const Money.paisa(12500),
      dateKey: date,
      createdBy: creator,
      createdAt: at,
      note: 'rice',
    );

    expect(tx.id, 'exp_e1');
    expect(tx.type, FundTxType.expense);
    expect(tx.amount, const Money.paisa(-12500));
    expect(tx.dateKey, date);
    expect(tx.monthKey, MonthKey(2026, 9));
    expect(tx.refType, FundRefType.expense);
    expect(tx.refId, 'e1');
    expect(tx.createdBy, creator);
    expect(tx.createdAt, at);
    expect(tx.note, 'rice');
  });

  test('forContribution writes con_<id> as a positive contribution row', () {
    final tx = FundTransaction.forContribution(
      contributionId: 'c1',
      amount: const Money.paisa(500000),
      dateKey: date,
      createdBy: creator,
      createdAt: at,
    );

    expect(tx.id, 'con_c1');
    expect(tx.type, FundTxType.contribution);
    expect(tx.amount, const Money.paisa(500000));
    expect(tx.refType, FundRefType.contribution);
    expect(tx.refId, 'c1');
  });

  test('forReimbursement writes stl_<id> as a negative reimbursement row', () {
    final tx = FundTransaction.forReimbursement(
      settlementId: 's1',
      amount: const Money.paisa(7500),
      dateKey: date,
      createdBy: creator,
      createdAt: at,
    );

    expect(tx.id, 'stl_s1');
    expect(tx.type, FundTxType.reimbursement);
    expect(tx.amount, const Money.paisa(-7500));
    expect(tx.refType, FundRefType.settlement);
    expect(tx.refId, 's1');
  });

  test('opening writes open_<yyyy-MM> on the first day of the month', () {
    final tx = FundTransaction.opening(
      monthKey: MonthKey(2026, 10),
      amount: const Money.paisa(250000),
      createdBy: creator,
      createdAt: at,
    );

    expect(tx.id, 'open_2026-10');
    expect(tx.type, FundTxType.opening);
    expect(tx.amount, const Money.paisa(250000));
    expect(tx.dateKey, DateKey(2026, 10, 1));
    expect(tx.monthKey, MonthKey(2026, 10));
    expect(tx.refType, FundRefType.month);
    expect(tx.refId, '2026-10');
  });

  test('adjustment writes adj_<eventId>_<suffix> and keeps its ref', () {
    final tx = FundTransaction.adjustment(
      eventId: 'ev1',
      suffix: 'A',
      amount: const Money.paisa(-100),
      dateKey: date,
      refType: FundRefType.contribution,
      refId: 'c1',
      createdBy: creator,
      createdAt: at,
    );

    expect(tx.id, 'adj_ev1_A');
    expect(tx.type, FundTxType.adjustment);
    expect(tx.amount, const Money.paisa(-100));
    expect(tx.refType, FundRefType.contribution);
    expect(tx.refId, 'c1');
  });

  test('an empty adjustment suffix is omitted', () {
    final tx = FundTransaction.adjustment(
      eventId: 'ev2',
      suffix: '  ',
      amount: const Money.paisa(100),
      dateKey: date,
      refType: FundRefType.manual,
      refId: 'manual',
      createdBy: creator,
      createdAt: at,
    );

    expect(tx.id, 'adj_ev2');
  });

  test('every factory rejects a zero or wrong-signed amount', () {
    expect(
      () => FundTransaction.forExpense(
        expenseId: 'e1',
        total: Money.zero,
        dateKey: date,
        createdBy: creator,
        createdAt: at,
      ),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => FundTransaction.forContribution(
        contributionId: 'c1',
        amount: const Money.paisa(-1),
        dateKey: date,
        createdBy: creator,
        createdAt: at,
      ),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => FundTransaction.forReimbursement(
        settlementId: 's1',
        amount: Money.zero,
        dateKey: date,
        createdBy: creator,
        createdAt: at,
      ),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => FundTransaction.opening(
        monthKey: MonthKey(2026, 10),
        amount: Money.zero,
        createdBy: creator,
        createdAt: at,
      ),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => FundTransaction.adjustment(
        eventId: 'ev1',
        amount: Money.zero,
        dateKey: date,
        refType: FundRefType.manual,
        refId: 'manual',
        createdBy: creator,
        createdAt: at,
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('the public constructor still enforces the sign rule', () {
    FundTransaction build(FundTxType type, Money amount) => FundTransaction(
      id: 'x',
      type: type,
      amount: amount,
      dateKey: date,
      monthKey: MonthKey(2026, 9),
      refType: FundRefType.manual,
      refId: 'manual',
      createdBy: creator,
      createdAt: at,
    );

    expect(
      () => build(FundTxType.contribution, const Money.paisa(-1)),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => build(FundTxType.expense, const Money.paisa(1)),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => build(FundTxType.reimbursement, Money.zero),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => build(FundTxType.opening, Money.zero),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => build(FundTxType.adjustment, Money.zero),
      throwsA(isA<AssertionError>()),
    );
  });

  test('monthKey must match dateKey', () {
    expect(
      () => FundTransaction(
        id: 'x',
        type: FundTxType.contribution,
        amount: const Money.paisa(1),
        dateKey: date,
        monthKey: MonthKey(2026, 10),
        refType: FundRefType.contribution,
        refId: 'c1',
        createdBy: creator,
        createdAt: at,
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
