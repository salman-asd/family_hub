import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/money_math.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('basisPoints', () {
    test('part/whole as basis points', () {
      expect(
        basisPoints(const Money.paisa(8000), const Money.paisa(10000)),
        8000,
      );
      expect(
        basisPoints(const Money.paisa(10000), const Money.paisa(10000)),
        10000,
      );
      expect(basisPoints(Money.zero, const Money.paisa(10000)), 0);
    });

    test('rounds half up', () {
      // 1 / 20000 = 0.00005 -> 0.5 bp
      expect(basisPoints(const Money.paisa(1), const Money.paisa(20000)), 1);
      // 3 / 20000 -> 1.5 bp -> 2
      expect(basisPoints(const Money.paisa(3), const Money.paisa(20000)), 2);
      // 1 / 30000 -> 0.33 bp -> 0
      expect(basisPoints(const Money.paisa(1), const Money.paisa(30000)), 0);
    });

    test('ties for a negative part go away from zero', () {
      expect(basisPoints(const Money.paisa(-1), const Money.paisa(20000)), -1);
      expect(basisPoints(const Money.paisa(-3), const Money.paisa(20000)), -2);
    });

    test('a zero or negative whole has no ratio', () {
      expect(basisPoints(const Money.paisa(1), Money.zero), isNull);
      expect(
        basisPoints(const Money.paisa(1), const Money.paisa(-100)),
        isNull,
      );
    });
  });

  group('splitEqually', () {
    test('৳100.00 into 3 keeps every paisa', () {
      final parts = splitEqually(const Money.paisa(10000), 3);
      expect(parts.map((m) => m.paisa), [3334, 3333, 3333]);
      expect(Money.sum(parts), const Money.paisa(10000));
    });

    test('exact division, one part and zero', () {
      expect(splitEqually(const Money.paisa(900), 3).map((m) => m.paisa), [
        300,
        300,
        300,
      ]);
      expect(splitEqually(const Money.paisa(999), 1), [const Money.paisa(999)]);
      expect(splitEqually(Money.zero, 4).map((m) => m.paisa), [0, 0, 0, 0]);
    });

    test('rejects a zero or negative part count', () {
      expect(
        () => splitEqually(const Money.paisa(100), 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => splitEqually(const Money.paisa(100), -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a negative total', () {
      expect(
        () => splitEqually(const Money.paisa(-1), 3),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  test('maxMoney and minMoney', () {
    const small = Money.paisa(100);
    const large = Money.paisa(250);
    expect(maxMoney(small, large), large);
    expect(maxMoney(large, small), large);
    expect(minMoney(small, large), small);
    expect(minMoney(large, small), small);
  });

  group('tryLineTotal', () {
    test('null unless both inputs are present', () {
      expect(tryLineTotal(null, const Money.paisa(8000)), isNull);
      expect(tryLineTotal(const Quantity.milli(2500), null), isNull);
      expect(tryLineTotal(null, null), isNull);
    });

    test('delegates to lineTotal when both are present', () {
      expect(
        tryLineTotal(const Quantity.milli(2500), const Money.paisa(8000)),
        const Money.paisa(20000),
      );
      expect(tryLineTotal(Quantity.zero, const Money.paisa(8000)), Money.zero);
    });
  });
}
