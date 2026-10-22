import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/ledger_integrity_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a mismatch carries the expected and actual ledger sums', () {
    const issue = LedgerIssue(
      kind: LedgerIssueKind.mismatch,
      refId: 'e1',
      expected: Money.paisa(-5000),
      actual: Money.paisa(-4000),
    );

    expect(issue.kind, LedgerIssueKind.mismatch);
    expect(issue.refId, 'e1');
    expect(issue.expected, const Money.paisa(-5000));
    expect(issue.actual, const Money.paisa(-4000));
  });

  test('an orphan has no expected/actual amount', () {
    const issue = LedgerIssue(kind: LedgerIssueKind.orphan, refId: 'e9');

    expect(issue.kind, LedgerIssueKind.orphan);
    expect(issue.expected, isNull);
    expect(issue.actual, isNull);
  });

  test('value equality compares the kind, reference and amounts', () {
    const a = LedgerIssue(
      kind: LedgerIssueKind.mismatch,
      refId: 'e1',
      expected: Money.paisa(-5000),
      actual: Money.paisa(-4000),
    );
    const b = LedgerIssue(
      kind: LedgerIssueKind.mismatch,
      refId: 'e1',
      expected: Money.paisa(-5000),
      actual: Money.paisa(-4000),
    );

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(
      a == const LedgerIssue(kind: LedgerIssueKind.orphan, refId: 'e1'),
      isFalse,
    );
  });
}
