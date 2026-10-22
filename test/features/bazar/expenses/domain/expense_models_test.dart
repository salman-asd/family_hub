import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_filters.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/month_spend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Expense invariants', () {
    test('member funding requires a payer', () {
      expect(
        () => _expense(funding: FundingSource.member, paidByMemberId: null),
        throwsAssertionError,
      );
    });

    test('fund funding forbids a payer', () {
      expect(
        () => _expense(funding: FundingSource.fund, paidByMemberId: 'alice'),
        throwsAssertionError,
      );
    });

    test('reimbursable is only allowed for member funding', () {
      expect(
        () => _expense(funding: FundingSource.fund, reimbursable: true),
        throwsAssertionError,
      );
    });

    test('monthKey must match dateKey', () {
      expect(() => _expense(monthKey: MonthKey(2026, 9)), throwsAssertionError);
    });

    test('the total must be positive', () {
      expect(() => _expense(total: Money.zero), throwsAssertionError);
    });
  });

  test('copyWith clears optional fields when null is passed', () {
    final expense = _expense(
      itemId: 'item-1',
      shop: 'bazar',
      deletedAt: DateTime.utc(2026, 10, 18),
      deletedBy: 'alice',
    );

    final cleared = expense.copyWith(
      itemId: null,
      shop: null,
      deletedAt: null,
      deletedBy: null,
    );

    expect(cleared.itemId, isNull);
    expect(cleared.shop, isNull);
    expect(cleared.deletedAt, isNull);
    expect(cleared.deletedBy, isNull);
    expect(cleared.isDeleted, isFalse);
    expect(cleared.id, expense.id);
  });

  test('spenderId falls back from purchaser to payer to creator', () {
    expect(_expense(purchaserId: 'cara', createdBy: 'alice').spenderId, 'cara');
    expect(
      _expense(
        funding: FundingSource.member,
        paidByMemberId: 'bob',
        createdBy: 'alice',
      ).spenderId,
      'bob',
    );
    expect(_expense(createdBy: 'alice').spenderId, 'alice');
  });

  test('MonthSpend excludes deleted rows and groups category/day', () {
    final dayOne = DateKey(2026, 10, 18);
    final dayTwo = DateKey(2026, 10, 19);
    final spend = MonthSpend.of(<Expense>[
      _expense(total: const Money.paisa(10000), categoryId: 'food'),
      _expense(
        id: 'e2',
        total: const Money.paisa(2500),
        categoryId: 'food',
        dateKey: dayTwo,
      ),
      _expense(
        id: 'e3',
        total: const Money.paisa(7000),
        categoryId: 'transport',
      ),
      _expense(
        id: 'e4',
        total: const Money.paisa(9999),
        deletedAt: DateTime.utc(2026, 10, 18),
      ),
    ]);

    expect(spend.total, const Money.paisa(19500));
    expect(spend.count, 3);
    expect(spend.byCategory['food'], const Money.paisa(12500));
    expect(spend.byCategory['transport'], const Money.paisa(7000));
    expect(spend.byDay[dayOne], const Money.paisa(17000));
    expect(spend.byDay[dayTwo], const Money.paisa(2500));
  });

  group('ExpenseFilters', () {
    final day = DateKey(2026, 10, 18);
    final rows = <Expense>[
      _expense(
        itemName: 'চাল',
        categoryId: 'food',
        shop: 'Karwan Bazar',
        purchaserId: 'cara',
      ),
      _expense(
        id: 'e2',
        itemName: 'Bus fare',
        categoryId: 'transport',
        note: 'office',
        purchaserId: 'bob',
        funding: FundingSource.member,
        paidByMemberId: 'bob',
      ),
      _expense(
        id: 'e3',
        itemName: 'Old rice',
        categoryId: 'food',
        deletedAt: DateTime.utc(2026, 10, 18),
      ),
    ];

    test('hides deleted rows by default', () {
      expect(applyFilters(rows, const ExpenseFilters()).length, 2);
      expect(
        applyFilters(rows, const ExpenseFilters(includeDeleted: true)).length,
        3,
      );
    });

    test('narrows by range, category, member and funding', () {
      final filtered = applyFilters(
        rows,
        ExpenseFilters(
          range: DateKeyRange(DateKey(2026, 10, 18), DateKey(2026, 10, 18)),
          categoryId: 'transport',
          memberId: 'bob',
          funding: FundingSource.member,
        ),
      );
      expect(filtered.map((row) => row.id), <String>['e2']);
    });

    test('normalizes the text query across name, shop and note', () {
      expect(
        applyFilters(rows, const ExpenseFilters(text: 'karwan')).single.id,
        'e1',
      );
      expect(
        applyFilters(rows, const ExpenseFilters(text: 'OFFICE')).single.id,
        'e2',
      );
      expect(
        applyFilters(rows, const ExpenseFilters(text: 'চাল')).single.id,
        'e1',
      );
    });

    test('groups by day in input order', () {
      final groups = groupExpensesByDay(rows);
      expect(groups[day]?.length, 3);
    });
  });
}

Expense _expense({
  String id = 'e1',
  DateKey? dateKey,
  MonthKey? monthKey,
  String? itemId,
  String itemName = 'চাল',
  String categoryId = 'food',
  Money total = const Money.paisa(10000),
  FundingSource funding = FundingSource.fund,
  String? paidByMemberId,
  bool reimbursable = false,
  String? purchaserId,
  String? shop,
  String? note,
  DateTime? deletedAt,
  String? deletedBy,
  String createdBy = 'alice',
}) {
  final day = dateKey ?? DateKey(2026, 10, 18);
  return Expense(
    id: id,
    dateKey: day,
    monthKey: monthKey ?? day.monthKey,
    occurredAt: DateTime.utc(2026, 10, 18, 9),
    itemId: itemId,
    itemName: itemName,
    categoryId: categoryId,
    total: total,
    funding: funding,
    paidByMemberId: paidByMemberId,
    reimbursable: reimbursable,
    purchaserId: purchaserId,
    shop: shop,
    note: note,
    deletedAt: deletedAt,
    deletedBy: deletedBy,
    createdBy: createdBy,
    createdAt: DateTime.utc(2026, 10, 18, 9),
  );
}
