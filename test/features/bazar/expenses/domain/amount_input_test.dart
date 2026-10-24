import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/expenses/domain/amount_input.dart';
import 'package:flutter_test/flutter_test.dart';

AmountInput read({
  String qty = '',
  Unit? unit,
  String price = '',
  String total = '',
  bool strict = true,
}) => readAmountInput(
  qtyText: qty,
  unit: unit,
  unitPriceText: price,
  totalText: total,
  strict: strict,
);

void main() {
  group('readAmountInput', () {
    test('a typed total alone is the amount', () {
      final r = read(total: '120');
      expect(r.isValid, isTrue);
      expect(r.total, const Money.paisa(12000));
      expect(r.calculated, isFalse);
      expect(r.typedTotal, const Money.paisa(12000));
    });

    test('Bangla digits are accepted', () {
      expect(read(total: '১২০.৫').total, const Money.paisa(12050));
    });

    test('quantity x unit price is calculated and wins over a typed total', () {
      final r = read(qty: '2.5', unit: Unit.kg, price: '80', total: '999');
      expect(r.calculated, isTrue);
      expect(r.total, const Money.paisa(20000));
      expect(r.typedTotal, isNull);
      expect(r.qty, Quantity.parse('2.5').valueOrNull);
      expect(r.unit, Unit.kg);
    });

    test('quantity without a price is an error on the price field', () {
      final r = read(qty: '2', unit: Unit.kg, total: '100');
      expect(r.errors['unitPrice'], 'qty_unit_required');
      expect(r.isValid, isFalse);
    });

    test('a price without a quantity is an error on the quantity field', () {
      final r = read(price: '40', total: '100');
      expect(r.errors['qty'], 'qty_unit_required');
    });

    test('a quantity needs a unit', () {
      final r = read(qty: '2', price: '40');
      expect(r.errors['unit'], 'qty_unit_required');
    });

    test('an empty form asks for an amount only when strict', () {
      expect(read().errors['total'], 'invalid_amount');
      expect(read(strict: false).errors, isEmpty);
      expect(read(strict: false).total, isNull);
    });

    test('zero and garbage are rejected', () {
      expect(read(total: '0').errors['total'], 'amount_not_positive');
      expect(read(total: 'abc').errors['total'], 'invalid_amount');
      expect(read(total: '1.234').errors['total'], 'too_many_decimals');
    });

    test('a total that rounds to zero paisa is rejected', () {
      final r = read(qty: '0.001', unit: Unit.kg, price: '0.01');
      expect(r.errors['total'], 'amount_not_positive');
    });
  });

  group('moneyEditText', () {
    test('writes plain editable text', () {
      expect(moneyEditText(const Money.paisa(12000)), '120');
      expect(moneyEditText(const Money.paisa(12050)), '120.5');
      expect(moneyEditText(const Money.paisa(12005)), '120.05');
      expect(moneyEditText(const Money.paisa(5)), '0.05');
    });
  });
}
