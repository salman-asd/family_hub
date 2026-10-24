import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../bazar_test_helpers.dart';

String _repeat(String value, int count) =>
    List<String>.filled(count, value).join();

void _expectFailure(Result<Object?> result, AppFailure failure) {
  expect(result.failureOrNull, failure);
}

void main() {
  group('AddItem', () {
    test('creates a custom item with cleaned aliases and an event', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');

      final result = await f.addItem(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        nameBn: '  চাল  ',
        nameEn: ' Rice ',
        categoryId: 'cat_food',
        defaultUnit: Unit.kg,
        aliases: const <String>[' chal ', '', 'rice'],
      );

      final created = result.valueOrNull!;
      expect(created.nameBn, 'চাল');
      expect(created.nameEn, 'Rice');
      expect(created.categoryId, 'cat_food');
      expect(created.defaultUnit, Unit.kg);
      expect(created.aliases, <String>['chal', 'rice']);
      expect(created.useCount, 0);
      expect(created.lastPrice, isNull);
      expect(created.lastUnitPrice, isNull);
      expect(created.lastUsedAt, isNull);
      expect(created.active, isTrue);
      expect(created.builtIn, isFalse);
      expect(created.seedKey, isNull);
      expect(f.backend.items[BazarFixture.familyId]![created.id], created);

      final event = f.backend.events.single;
      expect(event.type, AuditEventType.bazarItemCreated);
      expect(event.refType, AuditRefType.item);
      expect(event.refId, created.id);
      expect(event.params, <String, String>{'name': 'চাল'});
    });

    test('an unknown or inactive category is not found', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_off', active: false);

      _expectFailure(
        await f.addItem(
          actorUid: 'alice',
          familyId: BazarFixture.familyId,
          nameBn: 'চাল',
          categoryId: 'missing',
          defaultUnit: Unit.kg,
        ),
        const NotFound(entity: 'category'),
      );
      _expectFailure(
        await f.addItem(
          actorUid: 'alice',
          familyId: BazarFixture.familyId,
          nameBn: 'চাল',
          categoryId: 'cat_off',
          defaultUnit: Unit.kg,
        ),
        const NotFound(entity: 'category'),
      );
    });

    test('a plain member is denied', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      _expectFailure(
        await f.addItem(
          actorUid: 'cara',
          familyId: BazarFixture.familyId,
          nameBn: 'চাল',
          categoryId: 'cat_food',
          defaultUnit: Unit.kg,
        ),
        const PermissionDenied(),
      );
    });

    test('a pending member is denied', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      _expectFailure(
        await f.addItem(
          actorUid: 'dave',
          familyId: BazarFixture.familyId,
          nameBn: 'চাল',
          categoryId: 'cat_food',
          defaultUnit: Unit.kg,
        ),
        const PermissionDenied(),
      );
    });

    test('a moderator needs the family finance switch', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      f.backend.permissionSettings[BazarFixture.familyId] =
          const PermissionSettings(moderatorManagesFinance: false);
      _expectFailure(
        await f.addItem(
          actorUid: 'bob',
          familyId: BazarFixture.familyId,
          nameBn: 'চাল',
          categoryId: 'cat_food',
          defaultUnit: Unit.kg,
        ),
        const PermissionDenied(),
      );
    });

    test('validates the name and aliases', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');

      Future<Result<Object?>> add({
        String nameBn = 'চাল',
        String? nameEn,
        List<String> aliases = const <String>[],
      }) => f.addItem(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        nameBn: nameBn,
        nameEn: nameEn,
        categoryId: 'cat_food',
        defaultUnit: Unit.kg,
        aliases: aliases,
      );

      _expectFailure(
        await add(nameBn: ''),
        const Validation('nameBn', 'required'),
      );
      _expectFailure(
        await add(nameBn: _repeat('a', 61)),
        const Validation('nameBn', 'too_long'),
      );
      _expectFailure(
        await add(nameEn: _repeat('a', 61)),
        const Validation('nameEn', 'too_long'),
      );
      _expectFailure(
        await add(aliases: List<String>.filled(11, 'a')),
        const Validation('aliases', 'too_many'),
      );
      _expectFailure(
        await add(aliases: <String>[_repeat('a', 41)]),
        const Validation('aliases', 'too_long'),
      );
      expect(f.backend.writes, 0);
    });

    test('rejects a duplicate normalized name in the same category', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      f.putItem(id: 'item_rice', nameBn: 'চাল', categoryId: 'cat_food');

      _expectFailure(
        await f.addItem(
          actorUid: 'alice',
          familyId: BazarFixture.familyId,
          nameBn: '  চাল  ',
          categoryId: 'cat_food',
          defaultUnit: Unit.kg,
        ),
        const Conflict(code: 'duplicate_item'),
      );
    });

    test('duplicate detection normalizes nukta spellings', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      f.putItem(id: 'item_pore', nameBn: 'পড়া', categoryId: 'cat_food');

      _expectFailure(
        await f.addItem(
          actorUid: 'alice',
          familyId: BazarFixture.familyId,
          nameBn: 'পড\u09BCা',
          categoryId: 'cat_food',
          defaultUnit: Unit.kg,
        ),
        const Conflict(code: 'duplicate_item'),
      );
    });

    test('the same name is allowed in another category', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      f.putCategory(id: 'cat_other');
      f.putItem(id: 'item_rice', nameBn: 'চাল', categoryId: 'cat_food');

      final result = await f.addItem(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        nameBn: 'চাল',
        categoryId: 'cat_other',
        defaultUnit: Unit.kg,
      );
      expect(result.valueOrNull!.categoryId, 'cat_other');
    });

    test('inactive items do not block the name', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      f.putItem(
        id: 'item_rice',
        nameBn: 'চাল',
        categoryId: 'cat_food',
        active: false,
      );

      final result = await f.addItem(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        nameBn: 'চাল',
        categoryId: 'cat_food',
        defaultUnit: Unit.kg,
      );
      expect(result.isSuccess, isTrue);
    });
  });

  group('UpdateItem', () {
    test('keeps usage data while changing catalog fields', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      f.putCategory(id: 'cat_other');
      f.putItem(
        id: 'item_rice',
        nameBn: 'চাল',
        nameEn: 'Rice',
        categoryId: 'cat_food',
        defaultUnit: Unit.kg,
        aliases: const <String>['chal'],
        useCount: 7,
        lastPrice: const Money.paisa(12000),
        lastUnitPrice: const Money.paisa(6000),
        lastUsedAt: DateTime.utc(2026, 10, 1),
        builtIn: true,
        seedKey: 'rice',
      );

      final result = await f.updateItem(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        itemId: 'item_rice',
        nameBn: ' মিনিকেট চাল ',
        nameEn: ' Miniket rice ',
        categoryId: 'cat_other',
        defaultUnit: Unit.g,
        aliases: const <String>['miniket'],
        emoji: '🍚',
      );

      final updated = result.valueOrNull!;
      expect(updated.nameBn, 'মিনিকেট চাল');
      expect(updated.nameEn, 'Miniket rice');
      expect(updated.categoryId, 'cat_other');
      expect(updated.defaultUnit, Unit.g);
      expect(updated.aliases, <String>['miniket']);
      expect(updated.emoji, '🍚');
      expect(updated.useCount, 7);
      expect(updated.lastPrice, const Money.paisa(12000));
      expect(updated.lastUnitPrice, const Money.paisa(6000));
      expect(updated.lastUsedAt, DateTime.utc(2026, 10, 1));
      expect(updated.active, isTrue);
      expect(updated.builtIn, isTrue);
      expect(updated.seedKey, 'rice');
      expect(f.backend.events.single.type, AuditEventType.bazarItemUpdated);
    });

    test('keeping its own name is not a duplicate', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      f.putItem(id: 'item_rice', nameBn: 'চাল', categoryId: 'cat_food');

      final result = await f.updateItem(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        itemId: 'item_rice',
        nameBn: 'চাল',
        categoryId: 'cat_food',
        defaultUnit: Unit.kg,
      );
      expect(result.isSuccess, isTrue);
    });

    test('rejects another item name in the target category', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      f.putItem(id: 'item_rice', nameBn: 'চাল', categoryId: 'cat_food');
      f.putItem(id: 'item_dal', nameBn: 'ডাল', categoryId: 'cat_food');

      _expectFailure(
        await f.updateItem(
          actorUid: 'alice',
          familyId: BazarFixture.familyId,
          itemId: 'item_rice',
          nameBn: 'ডাল',
          categoryId: 'cat_food',
          defaultUnit: Unit.kg,
        ),
        const Conflict(code: 'duplicate_item'),
      );
    });

    test('an unknown item or category is not found', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      f.putCategory(id: 'cat_off', active: false);
      f.putItem(id: 'item_rice', nameBn: 'চাল', categoryId: 'cat_food');

      _expectFailure(
        await f.updateItem(
          actorUid: 'alice',
          familyId: BazarFixture.familyId,
          itemId: 'missing',
          nameBn: 'চাল',
          categoryId: 'cat_food',
          defaultUnit: Unit.kg,
        ),
        const NotFound(entity: 'item'),
      );
      _expectFailure(
        await f.updateItem(
          actorUid: 'alice',
          familyId: BazarFixture.familyId,
          itemId: 'item_rice',
          nameBn: 'চাল',
          categoryId: 'cat_off',
          defaultUnit: Unit.kg,
        ),
        const NotFound(entity: 'category'),
      );
    });

    test('a plain member is denied', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      f.putItem(id: 'item_rice', nameBn: 'চাল', categoryId: 'cat_food');

      _expectFailure(
        await f.updateItem(
          actorUid: 'cara',
          familyId: BazarFixture.familyId,
          itemId: 'item_rice',
          nameBn: 'ভাত',
          categoryId: 'cat_food',
          defaultUnit: Unit.kg,
        ),
        const PermissionDenied(),
      );
    });

    test('a pending member is denied', () async {
      final f = BazarFixture();
      f.putCategory(id: 'cat_food');
      f.putItem(id: 'item_rice', nameBn: 'চাল', categoryId: 'cat_food');

      _expectFailure(
        await f.updateItem(
          actorUid: 'dave',
          familyId: BazarFixture.familyId,
          itemId: 'item_rice',
          nameBn: 'ভাত',
          categoryId: 'cat_food',
          defaultUnit: Unit.kg,
        ),
        const PermissionDenied(),
      );
    });
  });

  group('DeactivateItem', () {
    test('sets active=false and writes one event', () async {
      final f = BazarFixture();
      f.putItem(id: 'item_rice', nameBn: 'চাল', builtIn: true, seedKey: 'rice');

      final result = await f.deactivateItem(
        actorUid: 'bob',
        familyId: BazarFixture.familyId,
        itemId: 'item_rice',
      );

      final updated = result.valueOrNull!;
      expect(updated.active, isFalse);
      expect(updated.builtIn, isTrue);
      expect(updated.seedKey, 'rice');
      final event = f.backend.events.single;
      expect(event.type, AuditEventType.bazarItemDeactivated);
      expect(event.refType, AuditRefType.item);
      expect(event.params, <String, String>{'name': 'চাল'});
    });

    test('deactivating twice is a no-op', () async {
      final f = BazarFixture();
      f.putItem(id: 'item_rice');
      await f.deactivateItem(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        itemId: 'item_rice',
      );
      final before = f.backend.events.length;

      final second = await f.deactivateItem(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        itemId: 'item_rice',
      );

      expect(second.valueOrNull!.active, isFalse);
      expect(f.backend.events.length, before);
    });

    test('an unknown item is not found', () async {
      final f = BazarFixture();
      _expectFailure(
        await f.deactivateItem(
          actorUid: 'alice',
          familyId: BazarFixture.familyId,
          itemId: 'missing',
        ),
        const NotFound(entity: 'item'),
      );
    });

    test('a plain member is denied', () async {
      final f = BazarFixture();
      f.putItem(id: 'item_rice');
      _expectFailure(
        await f.deactivateItem(
          actorUid: 'cara',
          familyId: BazarFixture.familyId,
          itemId: 'item_rice',
        ),
        const PermissionDenied(),
      );
    });

    test('a pending member is denied', () async {
      final f = BazarFixture();
      f.putItem(id: 'item_rice');
      _expectFailure(
        await f.deactivateItem(
          actorUid: 'dave',
          familyId: BazarFixture.familyId,
          itemId: 'item_rice',
        ),
        const PermissionDenied(),
      );
    });
  });
}
