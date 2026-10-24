import 'package:family_hub/features/bazar/items_categories/data/default_catalog_seeder.dart';
import 'package:family_hub/features/family/domain/usecases/create_family.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../family/family_test_helpers.dart';

void main() {
  test(
    'a new family gets all 11 categories and 54 items in its batch',
    () async {
      final f = Fixture()..profile('u1');
      final create = CreateFamily(
        families: f.backend,
        profiles: f.backend,
        clock: f.clock,
        newId: f.ids.call,
        seeders: const <DefaultCatalogSeeder>[DefaultCatalogSeeder()],
      );

      final result = await create(
        actorUid: 'u1',
        name: 'Home',
        familyId: 'fam',
        eventId: 'e1',
      );

      expect(result.failureOrNull, isNull);
      final categories = f.backend.seeded.keys
          .where((path) => path.contains('/bazarCategories/'))
          .toList();
      final items = f.backend.seeded.keys
          .where((path) => path.contains('/bazarItems/'))
          .toList();
      expect(categories, hasLength(11));
      expect(items, hasLength(54));
      expect(
        f
            .backend
            .seeded['families/fam/bazarCategories/cat_vegetables']!['seedKey'],
        'vegetables',
      );
      expect(
        f.backend.seeded['families/fam/bazarItems/item_rice']!['categoryId'],
        'cat_dry_groceries',
      );
      expect(f.backend.families, contains('fam'));
    },
  );
}
