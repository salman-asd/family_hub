import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_totals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeTotal', () {
    test('quantity x unit price wins over a typed total', () {
      final result = computeTotal(
        qty: const Quantity.milli(1500),
        unitPrice: const Money.paisa(3333),
        typedTotal: const Money.paisa(1),
      );
      expect(result.valueOrNull, const Money.paisa(5000));
    });

    test('rounds half a paisa up', () {
      final result = computeTotal(
        qty: const Quantity.milli(1500),
        unitPrice: const Money.paisa(3333),
      );
      expect(result.valueOrNull, const Money.paisa(5000));
    });

    test('quantity without a unit price is a validation failure', () {
      final result = computeTotal(qty: const Quantity.milli(1000));
      expect(
        result.failureOrNull,
        const Validation('unitPrice', 'qty_unit_required'),
      );
    });

    test('unit price without a quantity is a validation failure', () {
      final result = computeTotal(unitPrice: const Money.paisa(100));
      expect(
        result.failureOrNull,
        const Validation('qty', 'qty_unit_required'),
      );
    });

    test('typed total is used when both derived fields are absent', () {
      final result = computeTotal(typedTotal: const Money.paisa(1299));
      expect(result.valueOrNull, const Money.paisa(1299));
    });

    test('zero, negative and missing typed totals are rejected', () {
      for (final total in <Money?>[null, Money.zero, const Money.paisa(-1)]) {
        final result = computeTotal(typedTotal: total);
        expect(
          result.failureOrNull,
          const Validation('total', 'amount_not_positive'),
        );
      }
    });

    test('a derived zero total is rejected', () {
      final result = computeTotal(
        qty: const Quantity.milli(1000),
        unitPrice: Money.zero,
      );
      expect(
        result.failureOrNull,
        const Validation('total', 'amount_not_positive'),
      );
    });
  });
}
