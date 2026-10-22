import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/fake_tx_runner.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/items_categories/data/catalog_mappers.dart';
import 'package:family_hub/features/bazar/items_categories/data/firestore_catalog_repository.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 10, 18, 9);
  late FakeClock clock;
  late FakeTxRunner tx;
  late FirestoreCatalogRepository repository;

  setUp(() {
    clock = FakeClock(at);
    tx = FakeTxRunner(null, clock);
    repository = FirestoreCatalogRepository(tx: tx, clock: clock);
  });

  AuditEvent event(String id, String type, String refType, String refId) =>
      AuditEvent(
        id: id,
        type: type,
        actorId: 'u1',
        refType: refType,
        refId: refId,
        at: clock.nowUtc(),
        params: const <String, String>{'name': 'নাম'},
      );

  test('a new category writes the document and both log entries', () async {
    const category = Category(
      id: 'c1',
      nameBn: 'মুদি',
      nameEn: 'Staples',
      colorIndex: 2,
      sortOrder: 0,
      builtIn: true,
      seedKey: 'staples',
    );
    final result = await repository.saveCategory(
      'f1',
      category,
      event(
        'e1',
        AuditEventType.bazarCategoryCreated,
        AuditRefType.category,
        'c1',
      ),
      isNew: true,
    );

    expect(result.failureOrNull, isNull);
    final path = FirestorePaths.bazarCategoryDoc('f1', 'c1');
    final document = tx.store[path]!;
    expect(document['nameBn'], 'মুদি');
    expect(document['colorIndex'], 2);
    expect(document['builtIn'], true);
    expect(document['seedKey'], 'staples');
    expect(document['createdBy'], 'u1');
    expect(document['updatedBy'], 'u1');
    expect(
      BaseMapper.timestampToDateTime(document['createdAt']),
      clock.nowUtc(),
    );

    final activity = tx.store[FirestorePaths.activityDoc('f1', 'e1')]!;
    expect(activity['type'], AuditEventType.bazarCategoryCreated);
    expect(activity['refType'], AuditRefType.category);
    expect(activity['refId'], 'c1');
    expect(
      tx.store[FirestorePaths.auditLogDoc('f1', 'e1')]!['type'],
      AuditEventType.bazarCategoryCreated,
    );
  });

  test('a category update keeps the immutable seed fields', () async {
    const category = Category(
      id: 'c1',
      nameBn: 'মুদি',
      colorIndex: 2,
      sortOrder: 0,
      builtIn: true,
      seedKey: 'staples',
    );
    final path = FirestorePaths.bazarCategoryDoc('f1', 'c1');
    tx.store[path] = CatalogMappers.categoryToMap(
      category,
      BaseMapper.createMetadata(uid: 'u1', clock: clock),
    );

    final result = await repository.saveCategory(
      'f1',
      category.copyWith(nameBn: 'নতুন মুদি'),
      AuditEvent(
        id: 'e2',
        type: AuditEventType.bazarCategoryUpdated,
        actorId: 'u2',
        refType: AuditRefType.category,
        refId: 'c1',
        at: clock.nowUtc(),
      ),
      isNew: false,
    );

    expect(result.failureOrNull, isNull);
    final document = tx.store[path]!;
    expect(document['nameBn'], 'নতুন মুদি');
    expect(document['builtIn'], true);
    expect(document['seedKey'], 'staples');
    expect(document['createdBy'], 'u1');
    expect(document['updatedBy'], 'u2');
    expect(
      tx.store[FirestorePaths.activityDoc('f1', 'e2')]!['type'],
      AuditEventType.bazarCategoryUpdated,
    );
  });

  test(
    'a new item stores prices as integer paisa and keeps its logs',
    () async {
      final item = Item(
        id: 'i1',
        nameBn: 'চাল',
        nameEn: 'Rice',
        categoryId: 'c1',
        defaultUnit: Unit.kg,
        aliases: const <String>['rice'],
        useCount: 0,
        lastPrice: const Money.paisa(12500),
        lastUnitPrice: const Money.paisa(6500),
        lastUsedAt: at,
      );
      final result = await repository.saveItem(
        'f1',
        item,
        event('e3', AuditEventType.bazarItemCreated, AuditRefType.item, 'i1'),
        isNew: true,
      );

      expect(result.failureOrNull, isNull);
      final document = tx.store[FirestorePaths.bazarItemDoc('f1', 'i1')]!;
      expect(document['defaultUnit'], 'kg');
      expect(document['aliases'], <String>['rice']);
      expect(document['lastPricePaisa'], 12500);
      expect(document['lastUnitPricePaisa'], 6500);
      expect(document['lastPricePaisa'], isA<int>());
      expect(document.containsKey('lastPrice'), isFalse);
      expect(tx.store[FirestorePaths.activityDoc('f1', 'e3')]!['refId'], 'i1');
      expect(tx.store[FirestorePaths.auditLogDoc('f1', 'e3')], isNotNull);
    },
  );

  test('an item update does not overwrite usage or seed flags', () async {
    const item = Item(
      id: 'i1',
      nameBn: 'চাল',
      categoryId: 'c1',
      defaultUnit: Unit.kg,
      useCount: 7,
      lastPrice: Money.paisa(12500),
      builtIn: true,
      seedKey: 'rice',
    );
    final path = FirestorePaths.bazarItemDoc('f1', 'i1');
    tx.store[path] = CatalogMappers.itemToMap(
      item,
      BaseMapper.createMetadata(uid: 'u1', clock: clock),
    );

    final result = await repository.saveItem(
      'f1',
      item.copyWith(nameBn: 'চাল premium'),
      AuditEvent(
        id: 'e4',
        type: AuditEventType.bazarItemUpdated,
        actorId: 'u2',
        refType: AuditRefType.item,
        refId: 'i1',
        at: clock.nowUtc(),
      ),
      isNew: false,
    );

    expect(result.failureOrNull, isNull);
    final document = tx.store[path]!;
    expect(document['nameBn'], 'চাল premium');
    expect(document['useCount'], 7);
    expect(document['lastPricePaisa'], 12500);
    expect(document['builtIn'], true);
    expect(document['seedKey'], 'rice');
    expect(document['updatedBy'], 'u2');
  });

  test(
    'a failed batch writes neither the document nor the audit entry',
    () async {
      tx.failNextBatchWith = StateError('offline');
      const category = Category(
        id: 'c1',
        nameBn: 'মুদি',
        colorIndex: 2,
        sortOrder: 0,
      );

      final result = await repository.saveCategory(
        'f1',
        category,
        event(
          'e5',
          AuditEventType.bazarCategoryCreated,
          AuditRefType.category,
          'c1',
        ),
        isNew: true,
      );

      expect(result.failureOrNull, isNotNull);
      expect(tx.store, isEmpty);
    },
  );
}
