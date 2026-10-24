import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/features/family/domain/family_seeder.dart';
import 'package:family_hub/features/family/domain/usecases/create_family.dart';
import 'package:flutter_test/flutter_test.dart';

import '../family_test_helpers.dart';

class _CatalogSeeder implements FamilySeeder {
  @override
  List<SeedWrite> seed(SeedContext c) => [
    SeedWrite('families/${c.familyId}/bazarCategories/cat_vegetables', {
      'nameEn': 'Vegetables',
    }),
    SeedWrite('families/${c.familyId}/bazarCategories/cat_fish', {
      'nameEn': 'Fish',
    }),
  ];
}

void main() {
  test(
    'seeders run inside CreateFamily and their writes reach the repository',
    () async {
      final f = Fixture()..profile('u1');
      final create = CreateFamily(
        families: f.backend,
        profiles: f.backend,
        clock: f.clock,
        newId: f.ids.call,
        seeders: [_CatalogSeeder()],
      );
      final r = await create(actorUid: 'u1', name: 'Home', familyId: 'fam9');
      expect(r.isSuccess, isTrue);
      expect(
        f.backend.seeded.keys,
        containsAll([
          'families/fam9/bazarCategories/cat_vegetables',
          'families/fam9/bazarCategories/cat_fish',
        ]),
      );
    },
  );

  test('with no seeders nothing extra is written', () async {
    final f = Fixture()..profile('u1');
    final create = CreateFamily(
      families: f.backend,
      profiles: f.backend,
      clock: f.clock,
      newId: f.ids.call,
    );
    await create(actorUid: 'u1', name: 'Home');
    expect(f.backend.seeded, isEmpty);
  });

  group('batch limit', () {
    test('500 writes are fine, the 501st throws', () async {
      final tx = FakeTxRunner();
      await tx.runBatch((b) {
        for (var i = 0; i < kMaxBatchWrites; i++) {
          b.set('c/d$i', {'i': i});
        }
      });
      expect(tx.store, hasLength(kMaxBatchWrites));
      await expectLater(
        tx.runBatch((b) {
          for (var i = 0; i <= kMaxBatchWrites; i++) {
            b.set('c/e$i', {'i': i});
          }
        }),
        throwsStateError,
      );
    });
  });
}
