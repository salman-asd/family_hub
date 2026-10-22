import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/audit_writer.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/bazar/items_categories/data/catalog_mappers.dart';
import 'package:family_hub/features/bazar/items_categories/data/default_catalog_writes.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_repository.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';

/// Firestore implementation of the catalog port.
///
/// Every write is one batch: the catalog document and its audit/activity entry
/// commit together.  Catalog edits are everyday actions, so they queue offline
/// (no probe); only the one-time default-catalog seed requires the server.
class FirestoreCatalogRepository implements CatalogRepository {
  FirestoreCatalogRepository({
    required this._tx,
    required this._clock,
    this._firestore,
  });

  final TxRunner _tx;
  final Clock _clock;
  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  BaseDocumentMetadata _meta(String uid) =>
      BaseMapper.createMetadata(uid: uid, clock: _clock);

  @override
  Stream<List<Category>> watchCategories(String familyId) => _db
      .collection(FirestorePaths.bazarCategories(familyId))
      .limit(kMaxCatalogDocs)
      .snapshots()
      .map(
        (snapshot) => <Category>[
          for (final document in snapshot.docs)
            CatalogMappers.categoryFromMap(document.id, document.data()),
        ],
      );

  @override
  Stream<List<Item>> watchItems(String familyId) => _db
      .collection(FirestorePaths.bazarItems(familyId))
      .limit(kMaxCatalogDocs)
      .snapshots()
      .map(
        (snapshot) => <Item>[
          for (final document in snapshot.docs)
            CatalogMappers.itemFromMap(document.id, document.data()),
        ],
      );

  @override
  Future<Result<List<Category>>> getCategories(String familyId) =>
      guardFirestore(() async {
        final snapshot = await _db
            .collection(FirestorePaths.bazarCategories(familyId))
            .limit(kMaxCatalogDocs)
            .get();
        return <Category>[
          for (final document in snapshot.docs)
            CatalogMappers.categoryFromMap(document.id, document.data()),
        ];
      });

  @override
  Future<Result<List<Item>>> getItems(String familyId) =>
      guardFirestore(() async {
        final snapshot = await _db
            .collection(FirestorePaths.bazarItems(familyId))
            .limit(kMaxCatalogDocs)
            .get();
        return <Item>[
          for (final document in snapshot.docs)
            CatalogMappers.itemFromMap(document.id, document.data()),
        ];
      });

  @override
  Future<Result<void>> saveCategory(
    String familyId,
    Category category,
    AuditEvent event, {
    required bool isNew,
  }) => guardWrite(
    () => _tx.runBatch((batch) {
      final path = FirestorePaths.bazarCategoryDoc(familyId, category.id);
      if (isNew) {
        batch.set(
          path,
          CatalogMappers.categoryToMap(category, _meta(event.actorId)),
        );
      } else {
        batch.update(
          path,
          CatalogMappers.categoryChangeMap(
            category,
            actorUid: event.actorId,
            now: _clock.nowUtc(),
          ),
        );
      }
      AuditWriter.write(batch, familyId, event);
    }),
  );

  @override
  Future<Result<void>> saveItem(
    String familyId,
    Item item,
    AuditEvent event, {
    required bool isNew,
  }) => guardWrite(
    () => _tx.runBatch((batch) {
      final path = FirestorePaths.bazarItemDoc(familyId, item.id);
      if (isNew) {
        batch.set(path, CatalogMappers.itemToMap(item, _meta(event.actorId)));
      } else {
        batch.update(
          path,
          CatalogMappers.itemChangeMap(
            item,
            actorUid: event.actorId,
            now: _clock.nowUtc(),
          ),
        );
      }
      AuditWriter.write(batch, familyId, event);
    }),
  );

  @override
  Future<Result<bool>> isCatalogEmpty(String familyId) =>
      guardFirestore(() async {
        // Offline is a failure, never "empty": a server read is required before
        // the one-time backfill can decide to seed.
        final snapshot = await _db
            .collection(FirestorePaths.bazarCategories(familyId))
            .limit(1)
            .get(const GetOptions(source: Source.server));
        return snapshot.docs.isEmpty;
      });

  /// One server-only batch: the starter categories, items and audit entry.
  ///
  /// The seed is 65 documents + 2 log documents, far below `kMaxBatchWrites`.
  /// The probe makes the one-time backfill wait for a server round trip, so an
  /// offline device can never write a half-known catalog.
  @override
  Future<Result<void>> seedDefaultCatalog(
    String familyId,
    String actorUid,
    AuditEvent event,
  ) => guardWrite(
    probe: serverProbeFor(_db, actorUid),
    () => _tx.runBatch((batch) {
      for (final write in buildDefaultCatalogWrites(
        familyId: familyId,
        actorUid: actorUid,
        now: event.at,
      )) {
        batch.set(write.path, write.data);
      }
      AuditWriter.write(batch, familyId, event);
    }),
  );
}
