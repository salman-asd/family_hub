import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/expenses/data/expense_mappers.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 10, 18, 9);
  final meta = BaseMapper.createMetadata(uid: 'u1', clock: FakeClock(at));

  Expense expense({
    String id = 'e1',
    FundingSource funding = FundingSource.fund,
    String? payer,
    bool reimbursable = false,
  }) => Expense(
    id: id,
    dateKey: DateKey(2026, 10, 18),
    monthKey: MonthKey(2026, 10),
    occurredAt: at,
    itemId: 'i1',
    itemName: 'Rice',
    categoryId: 'c1',
    qty: const Quantity.milli(1000),
    unit: Unit.kg,
    unitPrice: const Money.paisa(6000),
    total: const Money.paisa(12000),
    funding: funding,
    paidByMemberId: payer,
    reimbursable: reimbursable,
    purchaserId: 'u1',
    tripId: 't1',
    shop: 'Bazar',
    note: 'note',
    createdBy: 'u1',
    createdAt: at,
  );

  test('a fund expense survives a map round trip', () {
    final original = expense();
    final restored = ExpenseMappers.expenseFromMap(
      original.id,
      ExpenseMappers.expenseToMap(original, meta),
    );
    expect(restored, original);
  });

  test('a member-funded advance expense survives a map round trip', () {
    final original = expense(
      funding: FundingSource.member,
      payer: 'u2',
      reimbursable: true,
    );
    final restored = ExpenseMappers.expenseFromMap(
      original.id,
      ExpenseMappers.expenseToMap(original, meta),
    );
    expect(restored, original);
  });

  test('the map writes keys, names and integer money', () {
    final map = ExpenseMappers.expenseToMap(expense(), meta);
    expect(map['dateKey'], '2026-10-18');
    expect(map['monthKey'], '2026-10');
    expect(map['totalPaisa'], 12000);
    expect(map['qtyMilli'], 1000);
    expect(map['unit'], 'kg');
    expect(map['fundingSource'], 'fund');
    expect(map['source'], 'manual');
    expect(map['occurredAt'], isNotNull);
  });

  test('a tolerant read repairs enum, payer and total damage', () {
    final raw = ExpenseMappers.expenseToMap(expense(), meta);
    raw['fundingSource'] = 'members';
    raw['paidByMemberId'] = 'u9';
    raw['reimbursable'] = true;
    raw['totalPaisa'] = 0;
    raw['dateKey'] = 'nope';
    raw['unit'] = 'stone';

    final restored = ExpenseMappers.expenseFromMap('e1', raw);
    expect(restored.funding, FundingSource.fund);
    expect(restored.paidByMemberId, isNull);
    expect(restored.reimbursable, isFalse);
    expect(restored.total.paisa, 1);
    expect(restored.unit, isNull);
    expect(restored.dateKey, DateKey(2026, 10, 18));
  });

  test('expenseChangeMap drops the immutable provenance fields', () {
    final map = ExpenseMappers.expenseChangeMap(
      expense(),
      actorUid: 'u1',
      now: at,
    );
    expect(map.containsKey('createdAt'), isFalse);
    expect(map.containsKey('createdBy'), isFalse);
    expect(map.containsKey('source'), isFalse);
    expect(map.containsKey('importBatchId'), isFalse);
    expect(map.containsKey('tripId'), isFalse);
    expect(map['occurredAt'], isNotNull);
    expect(map['updatedBy'], 'u1');
  });

  test('expenseSoftDeleteMap touches exactly the four allowed fields', () {
    final deleted = expense();
    final map = ExpenseMappers.expenseSoftDeleteMap(
      deleted,
      actorUid: 'u1',
      now: at,
    );
    expect(map.keys.toSet(), <String>{
      'deletedAt',
      'deletedBy',
      'updatedAt',
      'updatedBy',
    });
  });

  test('a revision survives a map round trip', () {
    final revision = ExpenseRevision(
      id: 'r1',
      before: const <String, Object?>{'itemName': 'Rice', 'totalPaisa': 12000},
      changedFields: const <String>['itemName'],
      reason: 'typo',
      at: at,
      by: 'u1',
    );
    final restored = ExpenseMappers.revisionFromMap(
      revision.id,
      ExpenseMappers.revisionToMap(revision, meta),
    );
    expect(restored, revision);
  });

  test('tripToMap writes the header keys', () {
    final trip = Trip(
      id: 't1',
      dateKey: DateKey(2026, 10, 18),
      monthKey: MonthKey(2026, 10),
      shop: 'Bazar',
      funding: FundingSource.fund,
      lineCount: 2,
      total: const Money.paisa(24000),
    );
    final map = ExpenseMappers.tripToMap(trip, meta);
    expect(map['lineCount'], 2);
    expect(map['totalPaisa'], 24000);
    expect(map['dateKey'], '2026-10-18');
    expect(map['fundingSource'], 'fund');
  });
}
