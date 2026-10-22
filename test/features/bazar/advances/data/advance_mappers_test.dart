import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/advances/data/advance_mappers.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 10, 18, 9);
  final meta = BaseMapper.createMetadata(uid: 'u1', clock: FakeClock(at));
  final day = DateKey(2026, 10, 18);

  test('an advance survives a map round trip', () {
    final advance = MemberAdvance(
      expenseId: 'e1',
      memberId: 'u2',
      amount: const Money.paisa(8000),
      settled: Money.zero,
      status: AdvanceStatus.pending,
      dateKey: day,
      monthKey: day.monthKey,
    );
    final map = AdvanceMappers.advanceToMap(advance, meta);
    expect(map['amountPaisa'], 8000);
    expect(map['status'], 'pending');
    expect(AdvanceMappers.advanceFromMap(advance.expenseId, map), advance);
  });

  test('a voided advance keeps its stored status', () {
    final advance = MemberAdvance(
      expenseId: 'e1',
      memberId: 'u2',
      amount: const Money.paisa(8000),
      settled: Money.zero,
      status: AdvanceStatus.voided,
      dateKey: day,
      monthKey: day.monthKey,
    );
    final restored = AdvanceMappers.advanceFromMap(
      advance.expenseId,
      AdvanceMappers.advanceToMap(advance, meta),
    );
    expect(restored.status, AdvanceStatus.voided);
  });

  test('a contradicting stored status is recomputed', () {
    final advance = MemberAdvance(
      expenseId: 'e1',
      memberId: 'u2',
      amount: const Money.paisa(8000),
      settled: Money.zero,
      status: AdvanceStatus.pending,
      dateKey: day,
      monthKey: day.monthKey,
    );
    final raw = AdvanceMappers.advanceToMap(advance, meta);
    raw['status'] = 'settled';
    raw['settledPaisa'] = 9000;
    final restored = AdvanceMappers.advanceFromMap('e1', raw);
    expect(restored.settled.paisa, 0);
    expect(restored.status, AdvanceStatus.pending);
  });

  test('advanceChangeMap touches only the mutable fields', () {
    final advance = MemberAdvance(
      expenseId: 'e1',
      memberId: 'u2',
      amount: const Money.paisa(8000),
      settled: const Money.paisa(2000),
      status: AdvanceStatus.partial,
      dateKey: day,
      monthKey: day.monthKey,
    );
    final map = AdvanceMappers.advanceChangeMap(
      advance,
      actorUid: 'u1',
      now: at,
    );
    expect(map.containsKey('expenseId'), isFalse);
    expect(map.containsKey('createdAt'), isFalse);
    expect(map['settledPaisa'], 2000);
    expect(map['status'], 'partial');
    expect(map['updatedBy'], 'u1');
  });

  test('a settlement survives a map round trip', () {
    final settlement = Settlement(
      id: 's1',
      advanceId: 'e1',
      memberId: 'u2',
      amount: const Money.paisa(3000),
      dateKey: day,
      monthKey: day.monthKey,
      fundTxId: 'stl_s1',
      method: 'cash',
      note: 'paid',
    );
    final map = AdvanceMappers.settlementToMap(settlement, meta);
    expect(map['amountPaisa'], 3000);
    expect(map['fundTxId'], 'stl_s1');
    expect(AdvanceMappers.settlementFromMap(settlement.id, map), settlement);
  });
}
