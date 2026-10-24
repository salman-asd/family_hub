import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/bazar/items_categories/domain/default_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../bazar_test_helpers.dart';

void main() {
  test(
    'backfills the starter catalog once and then reports a conflict',
    () async {
      final f = BazarFixture();

      final first = await f.ensureCatalogSeeded(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
      );

      expect(first.failureOrNull, isNull);
      expect(
        f.backend.categoriesOf(BazarFixture.familyId),
        hasLength(defaultCatalogCategories.length),
      );
      expect(
        f.backend.itemsOf(BazarFixture.familyId),
        hasLength(defaultCatalogItems.length),
      );
      final event = f.backend.events.single;
      expect(event.type, AuditEventType.bazarCatalogSeeded);
      expect(event.refType, AuditRefType.family);
      expect(event.refId, BazarFixture.familyId);
      expect(event.params, <String, String>{'categories': '11', 'items': '54'});
      final writesAfterFirst = f.backend.writes;

      final second = await f.ensureCatalogSeeded(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
      );

      expect(second.failureOrNull, const Conflict(code: 'catalog_not_empty'));
      expect(f.backend.writes, writesAfterFirst);
      expect(f.backend.events, hasLength(1));
    },
  );

  test('a plain member may not backfill the catalog', () async {
    final f = BazarFixture();

    final result = await f.ensureCatalogSeeded(
      actorUid: 'cara',
      familyId: BazarFixture.familyId,
    );

    expect(result.failureOrNull, const PermissionDenied());
    expect(f.backend.categoriesOf(BazarFixture.familyId), isEmpty);
    expect(f.backend.itemsOf(BazarFixture.familyId), isEmpty);
    expect(f.backend.writes, 0);
  });

  test('offline fails before writing anything', () async {
    final f = BazarFixture()..backend.failNextWrite = const Network();

    final result = await f.ensureCatalogSeeded(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
    );

    expect(result.failureOrNull, const Network());
    expect(f.backend.categoriesOf(BazarFixture.familyId), isEmpty);
    expect(f.backend.itemsOf(BazarFixture.familyId), isEmpty);
    expect(f.backend.events, isEmpty);
    expect(f.backend.writes, 0);
  });
}
