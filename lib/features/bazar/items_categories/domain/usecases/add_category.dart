import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_repository.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_validation.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Adds a custom category.  `Permission.manageCatalogAndBudgets` only.
class AddCategory {
  const AddCategory({
    required this._catalog,
    required this._families,
    required this._clock,
    required this._newId,
  });

  final CatalogRepository _catalog;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<Category>> call({
    required String actorUid,
    required String familyId,
    required String nameBn,
    String? nameEn,
    required int colorIndex,
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
    if (denied != null) return Failure<Category>(denied);

    final invalid =
        validateNameBn(nameBn) ??
        validateNameEn(nameEn) ??
        validateColorIndex(colorIndex) ??
        validateEmoji(emoji) ??
        validateImageData(imageData);
    if (invalid != null) return Failure<Category>(invalid);

    final loaded = await _catalog.getCategories(familyId);
    final failure = loaded.failureOrNull;
    if (failure != null) return Failure<Category>(failure);
    final categories = loaded.valueOrNull ?? const <Category>[];

    final id = _newId();
    final category = Category(
      id: id,
      nameBn: nameBn.trim(),
      nameEn: cleanOptional(nameEn),
      colorIndex: colorIndex,
      emoji: cleanOptional(emoji),
      imageData: cleanOptional(imageData),
      sortOrder: _nextSortOrder(categories),
    );
    final saved = await _catalog.saveCategory(
      familyId,
      category,
      AuditEvent(
        id: _newId(),
        type: AuditEventType.bazarCategoryCreated,
        actorId: actorUid,
        refType: AuditRefType.category,
        refId: id,
        at: _clock.nowUtc(),
        params: <String, String>{'name': category.nameBn},
      ),
      isNew: true,
    );
    final saveFailure = saved.failureOrNull;
    return saveFailure != null
        ? Failure<Category>(saveFailure)
        : Success<Category>(category);
  }
}

int _nextSortOrder(Iterable<Category> categories) {
  var maximum = -1;
  for (final category in categories) {
    if (category.sortOrder > maximum) maximum = category.sortOrder;
  }
  return maximum + 1;
}
