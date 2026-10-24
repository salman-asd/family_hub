import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_repository.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_validation.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Edits an item's catalog fields.  Usage counters and last prices are kept.
/// `Permission.manageCatalogAndBudgets` only.
class UpdateItem {
  const UpdateItem({
    required this._catalog,
    required this._families,
    required this._clock,
    required this._newId,
  });

  final CatalogRepository _catalog;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<Item>> call({
    required String actorUid,
    required String familyId,
    required String itemId,
    required String nameBn,
    String? nameEn,
    required String categoryId,
    required Unit defaultUnit,
    List<String> aliases = const <String>[],
    String? emoji,
    String? imageData,
  }) async {
    final actor = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageCatalogAndBudgets,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<Item>(denied);

    final cleanedAliases = cleanAliases(aliases);
    final invalid =
        validateNameBn(nameBn) ??
        validateNameEn(nameEn) ??
        validateAliases(cleanedAliases) ??
        validateEmoji(emoji) ??
        validateImageData(imageData);
    if (invalid != null) return Failure<Item>(invalid);

    final categoriesResult = await _catalog.getCategories(familyId);
    final categoriesFailure = categoriesResult.failureOrNull;
    if (categoriesFailure != null) return Failure<Item>(categoriesFailure);
    final categories = categoriesResult.valueOrNull ?? const <Category>[];
    if (activeCategory(categories, categoryId) == null) {
      return const Failure<Item>(NotFound(entity: 'category'));
    }

    final itemsResult = await _catalog.getItems(familyId);
    final itemsFailure = itemsResult.failureOrNull;
    if (itemsFailure != null) return Failure<Item>(itemsFailure);
    final items = itemsResult.valueOrNull ?? const <Item>[];
    final existing = findItem(items, itemId);
    if (existing == null) {
      return const Failure<Item>(NotFound(entity: 'item'));
    }
    if (hasDuplicateItemName(
      items,
      nameBn,
      categoryId: categoryId,
      excludeId: itemId,
    )) {
      return const Failure<Item>(Conflict(code: 'duplicate_item'));
    }

    final updated = Item(
      id: existing.id,
      nameBn: nameBn.trim(),
      nameEn: cleanOptional(nameEn),
      categoryId: categoryId,
      defaultUnit: defaultUnit,
      aliases: cleanedAliases,
      emoji: cleanOptional(emoji),
      imageData: cleanOptional(imageData),
      useCount: existing.useCount,
      lastPrice: existing.lastPrice,
      lastUnitPrice: existing.lastUnitPrice,
      lastUsedAt: existing.lastUsedAt,
      active: existing.active,
      builtIn: existing.builtIn,
      seedKey: existing.seedKey,
    );
    final saved = await _catalog.saveItem(
      familyId,
      updated,
      AuditEvent(
        id: _newId(),
        type: AuditEventType.bazarItemUpdated,
        actorId: actorUid,
        refType: AuditRefType.item,
        refId: updated.id,
        at: _clock.nowUtc(),
        params: <String, String>{'name': updated.nameBn},
      ),
      isNew: false,
    );
    final saveFailure = saved.failureOrNull;
    return saveFailure != null
        ? Failure<Item>(saveFailure)
        : Success<Item>(updated);
  }
}
