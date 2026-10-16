import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bn = MoneyFormatter(locale: 'bn');
  const en = MoneyFormatter(locale: 'en');

  group('Money.parse', () {
    test('accepts English, Bangla, symbol and commas', () {
      expect(Money.parse('৳১,২৫০.৫০').valueOrNull, const Money.paisa(125050));
      expect(Money.parse('12.5').valueOrNull, const Money.paisa(1250));
      expect(Money.parse('১২').valueOrNull, const Money.paisa(1200));
      expect(Money.parse('১২.৫').valueOrNull, const Money.paisa(1250));
      expect(Money.parse('.5').valueOrNull, const Money.paisa(50));
      expect(Money.parse('-5').valueOrNull, const Money.paisa(-500));
    });

    test('rejects more than 2 decimals with a typed failure', () {
      expect(
        Money.parse('12.555').failureOrNull,
        const Validation('money', 'too_many_decimals'),
      );
    });

    test('rejects empty and malformed input', () {
      expect(Money.parse('').failureOrNull, const Validation('money', 'empty'));
      expect(
        Money.parse('abc').failureOrNull,
        const Validation('money', 'invalid_format'),
      );
      expect(
        Money.parse('1.2.3').failureOrNull,
        const Validation('money', 'invalid_format'),
      );
    });

    test('rejects absurdly large amounts', () {
      expect(
        Money.parse('9999999999999').failureOrNull,
        const Validation('money', 'too_large'),
      );
    });
  });

  group('Money arithmetic', () {
    test('operators', () {
      const a = Money.paisa(1000);
      const b = Money.paisa(250);
      expect(a + b, const Money.paisa(1250));
      expect(a - b, const Money.paisa(750));
      expect(-a, const Money.paisa(-1000));
      expect(b * 3, const Money.paisa(750));
      expect(a > b && b < a && a >= a && b <= b, isTrue);
      expect((b - a).isNegative, isTrue);
      expect(Money.zero.isZero, isTrue);
    });

    test('sum', () {
      expect(
        Money.sum(const [Money.paisa(100), Money.paisa(250)]),
        const Money.paisa(350),
      );
      expect(Money.sum(const <Money>[]), Money.zero);
    });
  });

  group('MoneyFormatter', () {
    test('1250 paisa', () {
      expect(bn.format(const Money.paisa(1250)), '৳১২.৫০');
      expect(en.format(const Money.paisa(1250)), '৳12.50');
    });

    test('hides .00 when asked', () {
      const hide = MoneyFormatter(locale: 'bn', hideZeroFraction: true);
      expect(hide.format(const Money.paisa(1200)), '৳১২');
      expect(hide.format(const Money.paisa(1250)), '৳১২.৫০');
    });

    test('grouping: lakh for bn, international for en', () {
      expect(bn.format(const Money.paisa(123456700)), '৳১২,৩৪,৫৬৭.০০');
      expect(en.format(const Money.paisa(123456700)), '৳1,234,567.00');
      expect(en.format(const Money.paisa(125000)), '৳1,250.00');
    });

    test('negative amounts and the Bangla digits switch', () {
      expect(bn.format(const Money.paisa(-1250)), '-৳১২.৫০');
      const bnLatin = MoneyFormatter(locale: 'bn', useBanglaDigits: false);
      expect(bnLatin.format(const Money.paisa(1250)), '৳12.50');
    });

    test('format then parse round trips', () {
      const value = Money.paisa(98765);
      expect(Money.parse(en.format(value)).valueOrNull, value);
      expect(Money.parse(bn.format(value)).valueOrNull, value);
    });
  });
}
