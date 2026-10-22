import 'package:family_hub/core/utils/money.dart';

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
