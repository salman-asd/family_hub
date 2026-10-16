import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quantity.parse', () {
    test('milli-unit conversion', () {
      expect(Quantity.parse('2.5').valueOrNull, const Quantity.milli(2500));
      expect(Quantity.parse('২.৫').valueOrNull, const Quantity.milli(2500));
      expect(Quantity.parse('0.001').valueOrNull, const Quantity.milli(1));
      expect(Quantity.parse('1,000').valueOrNull, const Quantity.milli(1000000));
    });

    test('rejects 4 decimals and negatives', () {
      expect(
        Quantity.parse('1.2345').failureOrNull,
        const Validation('quantity', 'too_many_decimals'),
      );
      expect(
        Quantity.parse('-1').failureOrNull,
        const Validation('quantity', 'negative'),
      );
    });
  });

  test('toDecimalString trims trailing zeros', () {
    expect(const Quantity.milli(2500).toDecimalString(), '2.5');
    expect(const Quantity.milli(2000).toDecimalString(), '2');
    expect(const Quantity.milli(1).toDecimalString(), '0.001');
    expect(const Quantity.milli(0).toDecimalString(), '0');
  });

  group('lineTotal (half-up to the paisa)', () {
    test('2.5 kg x ৳80/kg = ৳200', () {
      expect(
        lineTotal(const Quantity.milli(2500), const Money.paisa(8000)),
        const Money.paisa(20000),
      );
    });

    test('rounding edges', () {
      // 0.001 x 499 paisa = 0.499 paisa -> 0
      expect(
        lineTotal(const Quantity.milli(1), const Money.paisa(499)),
        Money.zero,
      );
      // 0.001 x 500 paisa = 0.5 paisa -> 1 (half-up)
      expect(
        lineTotal(const Quantity.milli(1), const Money.paisa(500)),
        const Money.paisa(1),
      );
      // 0.333 x 100 paisa = 33.3 -> 33
      expect(
        lineTotal(const Quantity.milli(333), const Money.paisa(100)),
        const Money.paisa(33),
      );
      // 0.335 x 100 paisa = 33.5 -> 34
      expect(
        lineTotal(const Quantity.milli(335), const Money.paisa(100)),
        const Money.paisa(34),
      );
    });

    test('zero quantity and negative price', () {
      expect(lineTotal(Quantity.zero, const Money.paisa(8000)), Money.zero);
      expect(
        lineTotal(const Quantity.milli(1), const Money.paisa(-500)),
        const Money.paisa(-1),
      );
    });
  });

  test('Quantity operators', () {
    expect(
      const Quantity.milli(1500) + const Quantity.milli(500),
      const Quantity.milli(2000),
    );
    expect(const Quantity.milli(2) > const Quantity.milli(1), isTrue);
  });
}
