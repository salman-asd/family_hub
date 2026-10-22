import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';

void _expectFailure(Result<Object?> result, AppFailure failure) {
  expect(result.failureOrNull, failure);
}

void main() {
  group('AddCustomItem', () {
    test('a plain member may remember an item', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');

      final result = await f.addCustomItem(
        actorUid: 'cara',
        familyId: BazarFixture.familyId,
        nameBn: '  লাল আটা  ',
        nameEn: ' Red flour ',
        categoryId: 'cat_food',
        defaultUnit: Unit.kg,
        aliases: const <String>[' atta ', 'flour'],
      );

      final created = result.valueOrNull!;
      expect(created.nameBn, 'লাল আটা');
      expect(created.nameEn, 'Red flour');
      expect(created.aliases, <String>['atta', 'flour']);
      expect(created.builtIn, isFalse);
      expect(created.useCount, 0);
      expect(created.active, isTrue);

      final event = f.backend.events.single;
      expect(event.type, AuditEventType.bazarItemCreated);
      expect(event.refType, AuditRefType.item);
      expect(event.refId, created.id);
      expect(event.actorId, 'cara');
    });

    test('a pending member is denied', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      _expectFailure(
        await f.addCustomItem(
          actorUid: 'dave',
          familyId: BazarFixture.familyId,
          nameBn: 'চাল',
          categoryId: 'cat_food',
          defaultUnit: Unit.kg,
        ),
        const PermissionDenied(),
      );
    });

    test('the bazar module switch is honoured', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      f.backend.permissionSettings[BazarFixture.familyId] =
          const PermissionSettings(bazarEnabled: false);
      _expectFailure(
        await f.addCustomItem(
          actorUid: 'cara',
          familyId: BazarFixture.familyId,
          nameBn: 'চাল',
          categoryId: 'cat_food',
          defaultUnit: Unit.kg,
        ),
        const PermissionDenied(),
      );
    });

    test('an unknown category is not found', () async {
      final f = BazarFixture();
      _expectFailure(
        await f.addCustomItem(
          actorUid: 'cara',
          familyId: BazarFixture.familyId,
          nameBn: 'চাল',
          categoryId: 'missing',
          defaultUnit: Unit.kg,
        ),
        const NotFound(entity: 'category'),
      );
    });

    test('a duplicate name in the category is a conflict', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      f.putItem(id: 'item_rice', nameBn: 'চাল', categoryId: 'cat_food');

      _expectFailure(
        await f.addCustomItem(
          actorUid: 'cara',
          familyId: BazarFixture.familyId,
          nameBn: ' চাল ',
          categoryId: 'cat_food',
          defaultUnit: Unit.kg,
        ),
        const Conflict(code: 'duplicate_item'),
      );
    });
  });
}
