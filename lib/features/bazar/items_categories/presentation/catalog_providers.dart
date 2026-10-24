import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_index.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_repository.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/add_category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/add_custom_item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/add_item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/deactivate_category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/deactivate_item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/ensure_catalog_seeded.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/reactivate_category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/reactivate_item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/reorder_categories.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/update_category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/usecases/update_item.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => throw UnimplementedError(
    'catalogRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// The family's categories, live from Firestore.  Empty outside a family and
/// while the first snapshot is loading.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) return Stream.value(const <Category>[]);
  return ref.watch(catalogRepositoryProvider).watchCategories(familyId);
});

/// The family's items, live from Firestore.  Empty outside a family and while
/// the first snapshot is loading.
final itemsProvider = StreamProvider<List<Item>>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) return Stream.value(const <Item>[]);
  return ref.watch(catalogRepositoryProvider).watchItems(familyId);
});

/// The catalog as screens need it: lookup maps, ordered active categories and
/// the shared in-memory search.  `AsyncValue.value ?? const []` keeps this a
/// plain synchronous provider so widgets never branch on a second loading state.
final catalogIndexProvider = Provider<CatalogIndex>(
  (ref) => CatalogIndex(
    categories: ref.watch(categoriesProvider).value ?? const <Category>[],
    items: ref.watch(itemsProvider).value ?? const <Item>[],
  ),
);

// ── Use cases ─────────────────────────────────────────────────────────────

final addCategoryProvider = Provider<AddCategory>(
  (ref) => AddCategory(
    catalog: ref.watch(catalogRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final updateCategoryProvider = Provider<UpdateCategory>(
  (ref) => UpdateCategory(
    catalog: ref.watch(catalogRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final deactivateCategoryProvider = Provider<DeactivateCategory>(
  (ref) => DeactivateCategory(
    catalog: ref.watch(catalogRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final addItemProvider = Provider<AddItem>(
  (ref) => AddItem(
    catalog: ref.watch(catalogRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final addCustomItemProvider = Provider<AddCustomItem>(
  (ref) => AddCustomItem(
    catalog: ref.watch(catalogRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final updateItemProvider = Provider<UpdateItem>(
  (ref) => UpdateItem(
    catalog: ref.watch(catalogRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final deactivateItemProvider = Provider<DeactivateItem>(
  (ref) => DeactivateItem(
    catalog: ref.watch(catalogRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final ensureCatalogSeededProvider = Provider<EnsureCatalogSeeded>(
  (ref) => EnsureCatalogSeeded(
    catalog: ref.watch(catalogRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final reactivateCategoryProvider = Provider<ReactivateCategory>(
  (ref) => ReactivateCategory(
    catalog: ref.watch(catalogRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final reactivateItemProvider = Provider<ReactivateItem>(
  (ref) => ReactivateItem(
    catalog: ref.watch(catalogRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final reorderCategoriesProvider = Provider<ReorderCategories>(
  (ref) => ReorderCategories(
    catalog: ref.watch(catalogRepositoryProvider),
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);
