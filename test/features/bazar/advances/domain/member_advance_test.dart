import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateKey(2026, 9, 15);
  final month = MonthKey(2026, 9);

  MemberAdvance advance({
    Money amount = const Money.paisa(10000),
    Money settled = Money.zero,
    AdvanceStatus status = AdvanceStatus.pending,
  }) => MemberAdvance(
    expenseId: 'e1',
    memberId: 'u1',
    amount: amount,
    settled: settled,
    status: status,
    dateKey: date,
    monthKey: month,
  );

  test('statusFor follows pending -> partial -> settled', () {
    expect(
      MemberAdvance.statusFor(const Money.paisa(100), Money.zero),
      AdvanceStatus.pending,
    );
    expect(
      MemberAdvance.statusFor(const Money.paisa(100), const Money.paisa(1)),
      AdvanceStatus.partial,
    );
    expect(
      MemberAdvance.statusFor(const Money.paisa(100), const Money.paisa(100)),
      AdvanceStatus.settled,
    );
    expect(
      MemberAdvance.statusFor(Money.zero, Money.zero),
      AdvanceStatus.pending,
    );
  });

  test('remaining is amount minus settled', () {
    expect(advance().remaining, const Money.paisa(10000));
    expect(
      advance(
        settled: const Money.paisa(2500),
        status: AdvanceStatus.partial,
      ).remaining,
      const Money.paisa(7500),
    );
  });

  test('settled cannot exceed the amount', () {
    expect(
      () => advance(
        settled: const Money.paisa(10001),
        status: AdvanceStatus.settled,
      ),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => MemberAdvance.statusFor(
        const Money.paisa(100),
        const Money.paisa(101),
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('a non-voided status must match the amounts', () {
    expect(
      () => advance(status: AdvanceStatus.partial),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => advance(
        settled: const Money.paisa(5000),
        status: AdvanceStatus.pending,
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('a voided advance keeps its amounts but is not open', () {
    final voided = advance(
      settled: const Money.paisa(5000),
      status: AdvanceStatus.voided,
    );

    expect(voided.status, AdvanceStatus.voided);
    expect(voided.remaining, const Money.paisa(5000));
  });

  test('copyWith keeps the identity and can settle an advance', () {
    final settled = advance().copyWith(
      settled: const Money.paisa(10000),
      status: AdvanceStatus.settled,
    );

    expect(settled.expenseId, 'e1');
    expect(settled.memberId, 'u1');
    expect(settled.remaining, Money.zero);
    expect(settled.status, AdvanceStatus.settled);
  });
}
