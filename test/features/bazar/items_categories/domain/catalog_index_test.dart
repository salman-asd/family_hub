import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_index.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:flutter_test/flutter_test.dart';

Category _category(String id, int sortOrder, {bool active = true}) => Category(
  id: id,
  nameBn: id,
  colorIndex: 0,
  sortOrder: sortOrder,
  active: active,
);

Item _item(String id, String nameBn, String categoryId) =>
    Item(id: id, nameBn: nameBn, categoryId: categoryId, defaultUnit: Unit.kg);

void main() {
  late CatalogIndex index;

  setUp(() {
    index = CatalogIndex(
      categories: <Category>[
        _category('cat_b', 2),
        _category('cat_a', 1),
        _category('cat_off', 0, active: false),
      ],
      items: <Item>[
        _item('i-1', 'চাল', 'cat_a'),
        _item('i-2', 'ডাল', 'cat_a'),
        _item('i-3', 'আলু', 'cat_b'),
      ],
    );
  });

  test('indexes categories and items by id', () {
    expect(index.categoriesById.keys, containsAll(<String>['cat_a', 'cat_b']));
    expect(index.itemsById['i-2']?.nameBn, 'ডাল');
  });

  test('groups items by category', () {
    expect(index.itemsByCategory['cat_a']?.map((i) => i.id), <String>[
      'i-1',
      'i-2',
    ]);
    expect(index.itemsByCategory['cat_b']?.single.id, 'i-3');
  });

  test(
    'activeCategories are sorted by sortOrder and exclude inactive ones',
    () {
      expect(index.activeCategories.map((c) => c.id), <String>[
        'cat_a',
        'cat_b',
      ]);
    },
  );

  test('categoryOf returns the item category', () {
    expect(index.categoryOf(index.itemsById['i-3']!)?.id, 'cat_b');
  });

  test('the shared search sees the indexed items', () {
    expect(index.search.search('ডাল').single.id, 'i-2');
  });
}
