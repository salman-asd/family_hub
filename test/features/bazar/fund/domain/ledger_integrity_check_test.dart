import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/ledger_integrity_check.dart';
import 'package:flutter_test/flutter_test.dart';

final DateKey _day = DateKey(2026, 10, 18);
final MonthKey _october = MonthKey(2026, 10);
final DateTime _at = DateTime.utc(2026, 10, 18, 9);

Expense _expense(
  String id, {
  int paisa = 12000,
  FundingSource funding = FundingSource.fund,
  DateTime? deletedAt,
}) => Expense(
  id: id,
  dateKey: _day,
  monthKey: _day.monthKey,
  occurredAt: _at,
  itemName: 'Rice',
  categoryId: 'c1',
  total: Money.paisa(paisa),
  funding: funding,
  paidByMemberId: funding == FundingSource.member ? 'u1' : null,
  reimbursable: funding == FundingSource.member,
  createdBy: 'u1',
  createdAt: _at,
  deletedAt: deletedAt,
  deletedBy: deletedAt == null ? null : 'u1',
);

FundTransaction _row(
  String id,
  int paisa, {
  FundRefType refType = FundRefType.expense,
  FundTxType? type,
  MonthKey? month,
}) => FundTransaction(
  id: id,
  type: type ??
      (paisa < 0 ? FundTxType.expense : FundTxType.adjustment),
  amount: Money.paisa(paisa),
  dateKey: (month ?? _october).startOfMonth,
  monthKey: month ?? _october,
  refType: refType,
  refId: id.startsWith('exp_') ? id.substring(4) : id,
  createdBy: 'u1',
  createdAt: _at,
);

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

  group('checkLedger', () {
    test('a fund-funded expense whose row sums to -total is clean', () {
      expect(
        checkLedger(
          expenses: <Expense>[_expense('e1')],
          txs: <FundTransaction>[_row('e1', -12000)],
          month: _october,
        ),
        isEmpty,
      );
    });

    test('an edited expense is repaired by its adjustment row', () {
      expect(
        checkLedger(
          expenses: <Expense>[_expense('e1', paisa: 15000)],
          txs: <FundTransaction>[_row('e1', -12000), _row('e1', -3000)],
          month: _october,
        ),
        isEmpty,
      );
    });

    test('a missing row is a mismatch with the expected amount', () {
      final issues = checkLedger(
        expenses: <Expense>[_expense('e1')],
        txs: const <FundTransaction>[],
        month: _october,
      );
      expect(issues, hasLength(1));
      expect(issues.single.kind, LedgerIssueKind.mismatch);
      expect(issues.single.expected, const Money.paisa(-12000));
      expect(issues.single.actual, Money.zero);
    });

    test('a member-funded or deleted expense must sum to zero', () {
      final member = _expense('m1', funding: FundingSource.member);
      final deleted = _expense('d1', deletedAt: _at);
      expect(
        checkLedger(
          expenses: <Expense>[member, deleted],
          txs: const <FundTransaction>[],
          month: _october,
        ),
        isEmpty,
      );
      final issues = checkLedger(
        expenses: <Expense>[deleted],
        txs: <FundTransaction>[_row('d1', 12000)],
        month: _october,
      );
      expect(issues.single.expected, Money.zero);
      expect(issues.single.actual, const Money.paisa(12000));
    });

    test('a row pointing at no expense is an orphan', () {
      final issues = checkLedger(
        expenses: const <Expense>[],
        txs: <FundTransaction>[_row('gone', -5000)],
        month: _october,
      );
      expect(issues.single.kind, LedgerIssueKind.orphan);
      expect(issues.single.refId, 'gone');
    });

    test('contribution and month rows are never reported', () {
      expect(
        checkLedger(
          expenses: const <Expense>[],
          txs: <FundTransaction>[
            _row('c1', 100000, refType: FundRefType.contribution),
            _row('2026-10', 50000, refType: FundRefType.month),
          ],
          month: _october,
        ),
        isEmpty,
      );
    });

    test('only the checked month counts, so a moved correction is ignored', () {
      // The expense was moved to November; its rows live there now.
      expect(
        checkLedger(
          expenses: const <Expense>[],
          txs: <FundTransaction>[
            _row('e1', -12000, month: MonthKey(2026, 11)),
          ],
          month: _october,
        ),
        isEmpty,
      );
    });

    test('reports are sorted by reference, never twice', () {
      final issues = checkLedger(
        expenses: <Expense>[_expense('e2'), _expense('e1')],
        txs: <FundTransaction>[_row('e1', -1000)],
        month: _october,
      );
      expect(issues.map((i) => i.refId), <String>['e1', 'e2']);
    });
  });
}
