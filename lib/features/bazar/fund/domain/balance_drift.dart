import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';

/// Why a closed month's stored balance no longer matches the ledger (P2-21).
///
/// Closing computes the balance from a server read just before the write, so a
/// ledger row created in that instant can be missed.  [difference] is
/// `ledger − stored`: positive means more money is in the ledger than the
/// closing recorded.  Reopen -> fix -> Close repairs it through the delta row.
final class BalanceDrift {
  const BalanceDrift({
    required this.month,
    required this.stored,
    required this.ledger,
  });

  final MonthKey month;
  final Money stored;
  final Money ledger;

  Money get difference => ledger - stored;

  @override
  bool operator ==(Object other) =>
      other is BalanceDrift &&
      other.month == month &&
      other.stored == stored &&
      other.ledger == ledger;

  @override
  int get hashCode => Object.hash(month, stored, ledger);

  @override
  String toString() => 'BalanceDrift($month, stored: $stored, ledger: $ledger)';
}

/// Compares the newest closed month's stored balance with what its own ledger
/// window sums to.  Returns `null` when there is no closing, no ledger window
/// or the two agree — so the screen only warns when something is really off.
///
/// [window] is the live ledger window (`fundTransactionsProvider`): every row
/// with `monthKey >= fundWindowStart`.  It only reaches the closed month itself
/// while that month is still open; after a close the window starts in the next
/// month and the comparison uses the carry-forward rows, which must add up to
/// the same balance — that is what makes this check work.
BalanceDrift? detectBalanceDrift({
  required Map<MonthKey, MonthClosing> closings,
  required Iterable<FundTransaction> window,
}) {
  MonthKey? lastClosed;
  for (final closing in closings.values) {
    if (closing.status != MonthStatus.closed || closing.closingBalance == null) {
      continue;
    }
    if (lastClosed == null || closing.monthKey.compareTo(lastClosed) > 0) {
      lastClosed = closing.monthKey;
    }
  }
  if (lastClosed == null) return null;
  final month = lastClosed;
  final stored = closings[month]!.closingBalance!;
  final ledger = Money.sum(
    window
        .where((row) => row.monthKey.compareTo(month) <= 0)
        .map((row) => row.amount),
  );
  return ledger == stored
      ? null
      : BalanceDrift(month: month, stored: stored, ledger: ledger);
}
