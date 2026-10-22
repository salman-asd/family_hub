import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/items_categories/data/default_catalog_writes.dart';
import 'package:family_hub/features/bazar/items_categories/domain/default_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the starter catalog is 11 categories and 54 items', () {
    expect(defaultCatalogCategories, hasLength(11));
    expect(defaultCatalogItems, hasLength(54));
  });

  test('category and item keys are unique and ids follow the pattern', () {
    final categoryKeys = defaultCatalogCategories.map((c) => c.key).toSet();
    final itemKeys = defaultCatalogItems.map((i) => i.key).toSet();
    expect(categoryKeys, hasLength(defaultCatalogCategories.length));
    expect(itemKeys, hasLength(defaultCatalogItems.length));

    final categoryId = RegExp(r'^cat_[a-z0-9_]+$');
    final itemId = RegExp(r'^item_[a-z0-9_]+$');
    for (final category in defaultCatalogCategories) {
      expect(category.id, matches(categoryId));
    }
    for (final item in defaultCatalogItems) {
      expect(item.id, matches(itemId));
    }
  });

  test("every item's category exists", () {
    final categoryKeys = defaultCatalogCategories.map((c) => c.key).toSet();
    for (final item in defaultCatalogItems) {
      expect(
        categoryKeys,
        contains(item.categoryKey),
        reason: '${item.id} points at ${item.categoryKey}',
      );
      expect(item.categoryId, 'cat_${item.categoryKey}');
    }
  });

  test('every unit parses back to its enum value', () {
    for (final item in defaultCatalogItems) {
      expect(Unit.values.byName(item.unit.name), item.unit);
    }
  });

  test('names, aliases and sort orders fit the Firestore rules', () {
    final orders = defaultCatalogCategories.map((c) => c.order).toList();
    expect(orders, List<int>.generate(11, (i) => i));
    for (final category in defaultCatalogCategories) {
      expect(category.bn.runes.length, inInclusiveRange(1, 60));
      expect(category.en.runes.length, inInclusiveRange(1, 60));
      expect(category.colorIndex, inInclusiveRange(0, 11));
      expect(category.emoji.runes.length, lessThanOrEqualTo(8));
    }
    for (final item in defaultCatalogItems) {
      expect(item.bn.runes.length, inInclusiveRange(1, 60));
      expect(item.en.runes.length, inInclusiveRange(1, 60));
      expect(item.aliases.length, lessThanOrEqualTo(10));
      for (final alias in item.aliases) {
        expect(alias.trim(), alias);
        expect(alias.runes.length, inInclusiveRange(1, 40));
      }
    }
  });

  test('the seed writes all 65 documents well below the batch limit', () {
    final writes = buildDefaultCatalogWrites(
      familyId: 'f1',
      actorUid: 'u1',
      now: DateTime.utc(2026, 10, 18, 9),
    );

    expect(writes, hasLength(65));
    expect(
      writes.length + 9 + 2,
      lessThanOrEqualTo(kMaxBatchWrites),
      reason: '65 catalog + nine family documents + two audit entries',
    );
    expect(writes.map((w) => w.path).toSet(), hasLength(65));

    final byId = <String, Map<String, dynamic>>{
      for (final write in writes) write.path.split('/').last: write.data,
    };
    final vegetables = byId['cat_vegetables']!;
    expect(vegetables['nameBn'], 'সবজি');
    expect(vegetables['nameEn'], 'Vegetables');
    expect(vegetables['colorIndex'], 0);
    expect(vegetables['sortOrder'], 0);
    expect(vegetables['builtIn'], true);
    expect(vegetables['seedKey'], 'vegetables');
    expect(vegetables['createdBy'], 'u1');

    final rice = byId['item_rice']!;
    expect(rice['categoryId'], 'cat_dry_groceries');
    expect(rice['defaultUnit'], 'kg');
    expect(rice['aliases'], <String>['chal']);
    expect(rice['useCount'], 0);
    expect(rice['builtIn'], true);
    expect(rice['seedKey'], 'rice');
    expect(rice.containsKey('lastPricePaisa'), isFalse);
  });
}
