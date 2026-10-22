import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';

/// Port for the bazar catalog (`bazarCategories` and `bazarItems`).
///
/// Every write is one batch and writes its [AuditEvent] in the same batch.
/// Reads return `Network`/`Unknown` unchanged so a screen can show the offline
/// state instead of treating a missing document as absent data.
abstract interface class CatalogRepository {
  Stream<List<Category>> watchCategories(String familyId);

  Stream<List<Item>> watchItems(String familyId);

  Future<Result<List<Category>>> getCategories(String familyId);

  Future<Result<List<Item>>> getItems(String familyId);

  Future<Result<void>> saveCategory(
    String familyId,
    Category category,
    AuditEvent event, {
    required bool isNew,
  });

  Future<Result<void>> saveItem(
    String familyId,
    Item item,
    AuditEvent event, {
    required bool isNew,
  });

  /// Server read (`limit(1)` on categories): offline is a failure, never
  /// "empty" (CLAUDE.md offline rule).
  Future<Result<bool>> isCatalogEmpty(String familyId);

  /// Writes the built-in catalog and the seed audit event in one batch.
  Future<Result<void>> seedDefaultCatalog(
    String familyId,
    String actorUid,
    AuditEvent event,
  );
}
