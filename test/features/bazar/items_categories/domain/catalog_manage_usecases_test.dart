import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/reactivate_category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/reactivate_item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/reorder_categories.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';

void main() {
  late BazarFixture f;
  setUp(() => f = BazarFixture());

  ReorderCategories reorder() => ReorderCategories(
    catalog: f.backend,
    families: f.backend,
    clock: f.clock,
    newId: f.ids.call,
  );
  ReactivateCategory reactivateCategory() => ReactivateCategory(
    catalog: f.backend,
    families: f.backend,
    clock: f.clock,
    newId: f.ids.call,
  );
  ReactivateItem reactivateItem() => ReactivateItem(
    catalog: f.backend,
    families: f.backend,
    clock: f.clock,
    newId: f.ids.call,
  );

  List<String> order() =>
      (f.backend.categoriesOf(BazarFixture.familyId).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
          .map((c) => c.id)
          .toList();

  group('ReorderCategories', () {
    setUp(() {
      f
        ..putCategory(id: 'a', nameBn: 'এ', sortOrder: 0)
        ..putCategory(id: 'b', nameBn: 'বি', sortOrder: 1)
        ..putCategory(id: 'c', nameBn: 'সি', sortOrder: 2);
    });

    test('writes the new order as 0, 1, 2', () async {
      final result = await reorder()(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        orderedIds: ['c', 'a', 'b'],
      );
      expect(result.isSuccess, isTrue);
      expect(order(), ['c', 'a', 'b']);
    });

    test('an unchanged order writes nothing', () async {
      final before = f.backend.events.length;
      await reorder()(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        orderedIds: ['a', 'b', 'c'],
      );
      expect(f.backend.events.length, before);
    });

    test('an unknown id is NotFound and nothing is written', () async {
      final result = await reorder()(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        orderedIds: ['c', 'zzz'],
      );
      expect(result.failureOrNull, isA<NotFound>());
      expect(order(), ['a', 'b', 'c']);
    });

    test('a member may not reorder', () async {
      final result = await reorder()(
        actorUid: 'cara',
        familyId: BazarFixture.familyId,
        orderedIds: ['c', 'b', 'a'],
      );
      expect(result.failureOrNull, isA<PermissionDenied>());
      expect(order(), ['a', 'b', 'c']);
    });
  });

  group('reactivate', () {
    test('a hidden category comes back', () async {
      f.putCategory(id: 'a', active: false);
      final result = await reactivateCategory()(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        categoryId: 'a',
      );
      expect(result.valueOrNull?.active, isTrue);
      expect(f.backend.categoriesOf(BazarFixture.familyId).single.active, isTrue);
    });

    test('a hidden item comes back; an active one is a no-op', () async {
      f
        ..putCategory()
        ..putItem(id: 'i1', active: false)
        ..putItem(id: 'i2', nameBn: 'ডাল');
      final ok = await reactivateItem()(
        actorUid: 'bob',
        familyId: BazarFixture.familyId,
        itemId: 'i1',
      );
      expect(ok.valueOrNull?.active, isTrue);

      final before = f.backend.events.length;
      await reactivateItem()(
        actorUid: 'bob',
        familyId: BazarFixture.familyId,
        itemId: 'i2',
      );
      expect(f.backend.events.length, before);
    });

    test('a member may not reactivate', () async {
      f.putCategory(id: 'a', active: false);
      final result = await reactivateCategory()(
        actorUid: 'cara',
        familyId: BazarFixture.familyId,
        categoryId: 'a',
      );
      expect(result.failureOrNull, isA<PermissionDenied>());
    });
  });
}
