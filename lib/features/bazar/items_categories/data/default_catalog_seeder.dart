import 'package:family_hub/features/bazar/items_categories/data/default_catalog_writes.dart';
import 'package:family_hub/features/family/domain/family_seeder.dart';

/// Seeds the starter catalog in the SAME batch as a new family (H12, P2-06).
///
/// G-2: this concrete seeder lives in `data/`; `CreateFamily` and the
/// presentation layer know only the pure-Dart [FamilySeeder] interface.
class DefaultCatalogSeeder implements FamilySeeder {
  const DefaultCatalogSeeder();

  @override
  List<SeedWrite> seed(SeedContext context) => buildDefaultCatalogWrites(
    familyId: context.familyId,
    actorUid: context.actorUid,
    now: context.now,
  );
}
