import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../budget_test_helpers.dart';

void main() {
  test('quantity x rate wins; Bangla digits are read; total is calculated', () {
    final read = readLineDrafts(const [
      BudgetLineDraft(
        id: 'a',
        name: 'চাল',
        qtyText: '৫০',
        unit: Unit.kg,
        rateText: '৭০',
        totalText: '1',
      ),
    ]);
    expect(read.isValid, isTrue);
    expect(read.lines.single.estimatedTotal, const Money.paisa(350000));
    expect(read.lines.single.plannedQty, const Quantity.milli(50000));
  });

  test('a typed total alone is a valid line; blank rows are ignored', () {
    final read = readLineDrafts(const [
      BudgetLineDraft(id: 'a', name: 'Oil', totalText: '1200'),
      BudgetLineDraft(id: 'b'),
    ]);
    expect(read.isValid, isTrue);
    expect(read.lines, hasLength(1));
    expect(read.lines.single.estimatedTotal, const Money.paisa(120000));
    expect(read.lines.single.plannedQty, isNull);
  });

  test('errors are reported per row and field', () {
    final read = readLineDrafts(const [
      BudgetLineDraft(id: 'noName', totalText: '10'),
      BudgetLineDraft(id: 'noAmount', name: 'Salt'),
      BudgetLineDraft(id: 'loneQty', name: 'Rice', qtyText: '2', unit: Unit.kg),
      BudgetLineDraft(
        id: 'badStock',
        name: 'Oil',
        totalText: '10',
        stockText: 'abc',
      ),
    ]);
    expect(read.isValid, isFalse);
    expect(read.errors['noName'], {'name': 'required'});
    expect(read.errors['noAmount']!['total'], 'invalid_amount');
    expect(read.errors['loneQty']!['unitPrice'], 'qty_unit_required');
    expect(read.errors['badStock'], {'stock': 'invalid_amount'});
    expect(read.lines, isEmpty);
  });

  test('stock may be zero and is kept', () {
    final read = readLineDrafts(const [
      BudgetLineDraft(id: 'a', name: 'Oil', totalText: '10', stockText: '0'),
    ]);
    expect(read.lines.single.stock, Quantity.zero);
  });

  test('fromLine round-trips what the table shows', () {
    final draft = BudgetLineDraft.fromLine('x', riceLine);
    expect(draft.name, 'Rice');
    expect(draft.qtyText, '50');
    expect(draft.rateText, '70');
    expect(draft.totalText, '');
    expect(draft.stockText, '5');
    expect(readLineDrafts([draft]).lines.single.estimatedTotal,
        const Money.paisa(350000));
    final oil = BudgetLineDraft.fromLine('y', oilLine);
    expect(oil.totalText, '1200');
    expect(oil.qtyText, '');
  });

  test('category texts: blank and zero mean no estimate', () {
    final read = readCategoryTexts({
      'a': '1,320'.replaceAll(',', ''),
      'b': '',
      'c': '0',
      'd': 'x',
    });
    expect(read.estimates, {'a': const Money.paisa(132000)});
    expect(read.errors, {'d': 'invalid_amount'});
  });

  test('total text: blank is zero, junk is null', () {
    expect(readTotalText(''), Money.zero);
    expect(readTotalText('৫০০'), const Money.paisa(50000));
    expect(readTotalText('abc'), isNull);
  });
}
