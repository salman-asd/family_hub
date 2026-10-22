import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/features/bazar/items_categories/data/catalog_mappers.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/default_catalog.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/family/domain/family_seeder.dart';

/// Builds the 65 starter documents (11 categories + 54 items) as [SeedWrite]s.
///
/// Used in two places: `CreateFamily` seeds them in the family's own batch, and
/// `EnsureCatalogSeeded` backfills an existing family with one tap.  The ids are
/// deterministic (`cat_<key>` / `item_<key>`), so a retried write is idempotent.
List<SeedWrite> buildDefaultCatalogWrites({
  required String familyId,
  required String actorUid,
  required DateTime now,
}) {
  final meta = BaseDocumentMetadata(
    createdAt: now,
    createdBy: actorUid,
    updatedAt: now,
    updatedBy: actorUid,
  );

  return <SeedWrite>[
    for (final seed in defaultCatalogCategories)
      SeedWrite(
        FirestorePaths.bazarCategoryDoc(familyId, seed.id),
        CatalogMappers.categoryToMap(
          Category(
            id: seed.id,
            nameBn: seed.bn,
            nameEn: seed.en,
            colorIndex: seed.colorIndex,
            emoji: seed.emoji,
            sortOrder: seed.order,
            builtIn: true,
            seedKey: seed.key,
          ),
          meta,
        ),
      ),
    for (final seed in defaultCatalogItems)
      SeedWrite(
        FirestorePaths.bazarItemDoc(familyId, seed.id),
        CatalogMappers.itemToMap(
          Item(
            id: seed.id,
            nameBn: seed.bn,
            nameEn: seed.en,
            categoryId: seed.categoryId,
            defaultUnit: seed.unit,
            aliases: seed.aliases,
            builtIn: true,
            seedKey: seed.key,
          ),
          meta,
        ),
      ),
  ];
}
