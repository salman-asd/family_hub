import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';

/// The components shown on the fund card.
///
/// [received], [spent] and [reimbursed] are positive magnitudes for display;
/// [opening] and [adjustments] keep their signed ledger meaning.  [balance] is
/// always the sum of the signed ledger rows, not a separately stored number
/// (ADR 0007).
final class FundSummary {
  const FundSummary({
    required this.received,
    required this.spent,
    required this.reimbursed,
    required this.opening,
    required this.adjustments,
    required this.balance,
  });

  static const FundSummary zero = FundSummary(
    received: Money.zero,
    spent: Money.zero,
    reimbursed: Money.zero,
    opening: Money.zero,
    adjustments: Money.zero,
    balance: Money.zero,
  );

  final Money received;
  final Money spent;
  final Money reimbursed;
  final Money opening;
  final Money adjustments;
  final Money balance;

  @override
  bool operator ==(Object other) =>
      other is FundSummary &&
      other.received == received &&
      other.spent == spent &&
      other.reimbursed == reimbursed &&
      other.opening == opening &&
      other.adjustments == adjustments &&
      other.balance == balance;

  @override
  int get hashCode =>
      Object.hash(received, spent, reimbursed, opening, adjustments, balance);

  @override
  String toString() =>
      'FundSummary(received: $received, spent: $spent, '
      'reimbursed: $reimbursed, opening: $opening, '
      'adjustments: $adjustments, balance: $balance)';
}

/// Pure calculations over the signed fund ledger.
abstract final class FundBalanceCalculator {
  /// Sum of every signed row; the balance is never stored separately.
  static Money balance(Iterable<FundTransaction> transactions) =>
      Money.sum(transactions.map((transaction) => transaction.amount));

  /// Builds the display components and the exact ledger balance.
  static FundSummary summarize(Iterable<FundTransaction> transactions) {
    final rows = transactions.toList(growable: false);
    var received = Money.zero;
    var spent = Money.zero;
    var reimbursed = Money.zero;
    var opening = Money.zero;
    var adjustments = Money.zero;

    for (final transaction in rows) {
      switch (transaction.type) {
        case FundTxType.contribution:
          received += transaction.amount;
          break;
        case FundTxType.expense:
          spent += -transaction.amount;
          break;
        case FundTxType.reimbursement:
          reimbursed += -transaction.amount;
          break;
        case FundTxType.opening:
          opening += transaction.amount;
          break;
        case FundTxType.adjustment:
          adjustments += transaction.amount;
          break;
      }
    }

    return FundSummary(
      received: received,
      spent: spent,
      reimbursed: reimbursed,
      opening: opening,
      adjustments: adjustments,
      balance: balance(rows),
    );
  }

  /// Net ledger amount for one expense, contribution, settlement or manual ref.
  static Money ledgerFor(
    Iterable<FundTransaction> transactions,
    String refId,
  ) => Money.sum(
    transactions
        .where((transaction) => transaction.refId == refId)
        .map((transaction) => transaction.amount),
  );
}
