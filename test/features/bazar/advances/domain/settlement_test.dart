import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateKey(2026, 9, 20);
  final month = MonthKey(2026, 9);

  Settlement settlement({Money amount = const Money.paisa(2500)}) => Settlement(
    id: 's1',
    advanceId: 'e1',
    memberId: 'u1',
    amount: amount,
    dateKey: date,
    monthKey: month,
    fundTxId: 'stl_s1',
    method: 'cash',
    note: 'paid in cash',
  );

  test('holds the settlement fields and the deterministic fund row id', () {
    final value = settlement();

    expect(value.id, 's1');
    expect(value.advanceId, 'e1');
    expect(value.memberId, 'u1');
    expect(value.amount, const Money.paisa(2500));
    expect(value.dateKey, date);
    expect(value.monthKey, month);
    expect(value.fundTxId, 'stl_s1');
    expect(value.method, 'cash');
    expect(value.note, 'paid in cash');
  });

  test('a settlement amount must be positive', () {
    expect(
      () => settlement(amount: Money.zero),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => settlement(amount: const Money.paisa(-1)),
      throwsA(isA<AssertionError>()),
    );
  });

  test('monthKey must match dateKey', () {
    expect(
      () => Settlement(
        id: 's1',
        advanceId: 'e1',
        memberId: 'u1',
        amount: const Money.paisa(1),
        dateKey: date,
        monthKey: MonthKey(2026, 10),
        fundTxId: 'stl_s1',
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('value equality compares every field', () {
    expect(settlement(), settlement());
    expect(settlement().hashCode, settlement().hashCode);
    expect(settlement() == settlement(amount: const Money.paisa(1)), isFalse);
  });
}
