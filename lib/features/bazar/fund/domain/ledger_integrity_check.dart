import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';

/// What is wrong with one reference in the fund ledger.
enum LedgerIssueKind {
  /// The ledger rows do not sum to the amount the expense requires.
  mismatch,

  /// A ledger row points at an expense that is not in the checked month.
  orphan,
}

/// One problem reported by the month ledger check (implemented in P2-22).
final class LedgerIssue {
  const LedgerIssue({
    required this.kind,
    required this.refId,
    this.expected,
    this.actual,
  });

  final LedgerIssueKind kind;
  final String refId;

  /// The required ledger sum, when the issue is a [LedgerIssueKind.mismatch].
  final Money? expected;

  /// The sum actually found, when the issue is a [LedgerIssueKind.mismatch].
  final Money? actual;

  @override
  bool operator ==(Object other) =>
      other is LedgerIssue &&
      other.kind == kind &&
      other.refId == refId &&
      other.expected == expected &&
      other.actual == actual;

  @override
  int get hashCode => Object.hash(kind, refId, expected, actual);

  @override
  String toString() =>
      'LedgerIssue(${kind.name}, $refId, expected: $expected, '
      'actual: $actual)';
}

/// The ledger rows of [month] expected for one expense (rule 28, ADR 0007).
///
/// * a live FUND-funded expense must sum to `-total` (its `exp_` row, plus any
///   `adj_` corrections an edit or delete wrote);
/// * a soft-deleted or member-funded expense must sum to `0` (restored,
///   funded elsewhere, or simply never in the fund).
///
/// Only rows dated in [month] are counted, so a correction that moved an
/// expense into another month never makes this month look wrong.
Money expectedLedgerFor(Expense expense) =>
    expense.isDeleted || expense.funding != FundingSource.fund
    ? Money.zero
    : -expense.total;

/// Pure month ledger check used by the Fund screen (P2-22).
///
/// For each live or deleted expense of the month whose rows are in [txs]:
///
/// 1. the rows with `refId == expense.id` must sum to [expectedLedgerFor];
/// 2. a row whose `refId` belongs to no expense is an [LedgerIssueKind.orphan].
///
/// Rows that belong to another kind of reference (a contribution, a
/// settlement, an opening or a month carry-forward) are never reported: their
/// own use cases guarantee them and the expense check cannot judge them.
///
/// Never throws and never reports the same reference twice.
List<LedgerIssue> checkLedger({
  required Iterable<Expense> expenses,
  required Iterable<FundTransaction> txs,
  required MonthKey month,
}) {
  final rows = <FundTransaction>[
    for (final row in txs)
      if (row.monthKey == month) row,
  ];
  final byRef = <String, List<FundTransaction>>{};
  for (final row in rows) {
    (byRef[row.refId] ??= <FundTransaction>[]).add(row);
  }

  final issues = <LedgerIssue>[];
  final checked = <String>{};
  for (final expense in expenses) {
    checked.add(expense.id);
    final own = byRef[expense.id] ?? const <FundTransaction>[];
    final actual = Money.sum(own.map((row) => row.amount));
    final expected = expectedLedgerFor(expense);
    if (actual == expected) continue;
    issues.add(
      LedgerIssue(
        kind: LedgerIssueKind.mismatch,
        refId: expense.id,
        expected: expected,
        actual: actual,
      ),
    );
  }

  for (final entry in byRef.entries) {
    if (checked.contains(entry.key)) continue;
    final isExpenseRow = entry.value.any(
      (row) =>
          row.refType == FundRefType.expense ||
          row.type == FundTxType.expense ||
          row.id.startsWith('exp_'),
    );
    if (!isExpenseRow) continue;
    issues.add(LedgerIssue(kind: LedgerIssueKind.orphan, refId: entry.key));
  }

  issues.sort((a, b) => a.refId.compareTo(b.refId));
  return issues;
}
