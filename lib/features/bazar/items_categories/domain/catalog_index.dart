import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item_search.dart';

/// The catalog as screens need it: lookup maps, the active categories in
/// display order and the shared in-memory search.
///
/// Built once per catalog snapshot and then the only thing the UI reads.
final class CatalogIndex {
  CatalogIndex({
    required Iterable<Category> categories,
    required Iterable<Item> items,
  }) : categoriesById = <String, Category>{
         for (final category in categories) category.id: category,
       },
       itemsById = <String, Item>{for (final item in items) item.id: item} {
    for (final item in itemsById.values) {
      (itemsByCategory[item.categoryId] ??= <Item>[]).add(item);
    }
    activeCategories =
        <Category>[
          for (final category in categoriesById.values)
            if (category.active) category,
        ]..sort((a, b) {
          final order = a.sortOrder.compareTo(b.sortOrder);
          if (order != 0) return order;
          final name = a.nameBn.compareTo(b.nameBn);
          return name != 0 ? name : a.id.compareTo(b.id);
        });
  }

  final Map<String, Category> categoriesById;
  final Map<String, Item> itemsById;
  final Map<String, List<Item>> itemsByCategory = <String, List<Item>>{};
  late final List<Category> activeCategories;
  late final ItemSearch search = ItemSearch(itemsById.values);

  /// The category an item belongs to, or `null` when it is not loaded yet.
  Category? categoryOf(Item item) => categoriesById[item.categoryId];
}
