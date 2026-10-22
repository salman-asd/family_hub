import 'package:family_hub/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';

void main() {
  late BazarFixture f;

  setUp(() => f = BazarFixture());

  test('warns for the same item, total and a recent expense', () async {
    f.putExpense(
      id: 'e1',
      itemName: 'চাল',
      total: const Money.paisa(10000),
      createdAt: f.clock.nowUtc().subtract(const Duration(minutes: 5)),
    );

    final result = await f.checkDuplicate(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      draft: f.draft(itemName: 'চাল'),
      total: const Money.paisa(10000),
    );

    expect(result.valueOrNull?.expense.id, 'e1');
  });

  test('does not warn after ten minutes', () async {
    f.putExpense(
      id: 'e1',
      itemName: 'চাল',
      total: const Money.paisa(10000),
      createdAt: f.clock.nowUtc().subtract(const Duration(minutes: 11)),
    );

    final result = await f.checkDuplicate(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      draft: f.draft(),
      total: const Money.paisa(10000),
    );

    expect(result.valueOrNull, isNull);
  });

  test('ignores deleted expenses and different totals', () async {
    f.putExpense(
      id: 'e1',
      itemName: 'চাল',
      total: const Money.paisa(10000),
      deletedAt: f.clock.nowUtc(),
      deletedBy: 'alice',
    );
    f.putExpense(id: 'e2', itemName: 'চাল', total: const Money.paisa(9999));

    final result = await f.checkDuplicate(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      draft: f.draft(),
      total: const Money.paisa(10000),
    );

    expect(result.valueOrNull, isNull);
  });

  test('matches by item id even when the typed name differs', () async {
    f.putExpense(
      id: 'e1',
      itemId: 'item_rice',
      itemName: 'চাল',
      total: const Money.paisa(10000),
    );

    final result = await f.checkDuplicate(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      draft: f.draft(itemId: 'item_rice', itemName: 'rice'),
      total: const Money.paisa(10000),
    );

    expect(result.valueOrNull?.expense.id, 'e1');
  });

  test('denies a pending actor when an actor is supplied', () async {
    f.putExpense(id: 'e1', total: const Money.paisa(10000));

    final result = await f.checkDuplicate(
      actorUid: 'dave',
      familyId: BazarFixture.familyId,
      draft: f.draft(),
      total: const Money.paisa(10000),
    );

    expect(result.isFailure, isTrue);
  });
}
