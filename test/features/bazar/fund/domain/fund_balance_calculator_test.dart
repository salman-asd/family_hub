import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_balance_calculator.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateKey(2026, 9, 15);
  final at = DateTime.utc(2026, 9, 15, 9);

  FundTransaction tx(FundTxType type, Money amount, String refId) {
    return FundTransaction(
      id: '${type.name}_$refId',
      type: type,
      amount: amount,
      dateKey: date,
      monthKey: MonthKey(2026, 9),
      refType: FundRefType.manual,
      refId: refId,
      createdBy: 'u1',
      createdAt: at,
    );
  }

  test('an empty ledger summarizes as zero', () {
    expect(
      FundBalanceCalculator.balance(const <FundTransaction>[]),
      Money.zero,
    );
    expect(
      FundBalanceCalculator.summarize(const <FundTransaction>[]),
      FundSummary.zero,
    );
  });

  test('a hand-computed month has the expected components and balance', () {
    final ledger = <FundTransaction>[
      tx(FundTxType.contribution, const Money.paisa(100000), 'c1'),
      tx(FundTxType.expense, const Money.paisa(-30000), 'e1'),
      tx(FundTxType.reimbursement, const Money.paisa(-10000), 's1'),
      tx(FundTxType.opening, const Money.paisa(50000), 'm1'),
      tx(FundTxType.adjustment, const Money.paisa(-5000), 'c1'),
    ];

    final summary = FundBalanceCalculator.summarize(ledger);

    expect(summary.received, const Money.paisa(100000));
    expect(summary.spent, const Money.paisa(30000));
    expect(summary.reimbursed, const Money.paisa(10000));
    expect(summary.opening, const Money.paisa(50000));
    expect(summary.adjustments, const Money.paisa(-5000));
    expect(summary.balance, const Money.paisa(105000));
    expect(FundBalanceCalculator.balance(ledger), summary.balance);
  });

  test('ledgerFor sums all rows pointing at one reference', () {
    final ledger = <FundTransaction>[
      tx(FundTxType.contribution, const Money.paisa(100000), 'c1'),
      tx(FundTxType.adjustment, const Money.paisa(-20000), 'c1'),
      tx(FundTxType.expense, const Money.paisa(-5000), 'e1'),
    ];

    expect(
      FundBalanceCalculator.ledgerFor(ledger, 'c1'),
      const Money.paisa(80000),
    );
    expect(
      FundBalanceCalculator.ledgerFor(ledger, 'e1'),
      const Money.paisa(-5000),
    );
    expect(FundBalanceCalculator.ledgerFor(ledger, 'missing'), Money.zero);
  });
}
