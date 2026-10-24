import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_repository.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Shows a hidden category in pickers again.  Audited as a category update.
/// `Permission.manageCatalogAndBudgets` only.
class ReactivateCategory {
  const ReactivateCategory({
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
    required String categoryId,
  }) async {
    final actor = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageCatalogAndBudgets,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<Category>(denied);

    final loaded = await _catalog.getCategories(familyId);
    final failure = loaded.failureOrNull;
    if (failure != null) return Failure<Category>(failure);
    Category? existing;
    for (final category in loaded.valueOrNull ?? const <Category>[]) {
      if (category.id == categoryId) existing = category;
    }
    if (existing == null) {
      return const Failure<Category>(NotFound(entity: 'category'));
    }
    if (existing.active) return Success<Category>(existing);

    final updated = existing.copyWith(active: true);
    final saved = await _catalog.saveCategory(
      familyId,
      updated,
      AuditEvent(
        id: _newId(),
        type: AuditEventType.bazarCategoryUpdated,
        actorId: actorUid,
        refType: AuditRefType.category,
        refId: updated.id,
        at: _clock.nowUtc(),
        params: <String, String>{'name': updated.nameBn},
      ),
      isNew: false,
    );
    final saveFailure = saved.failureOrNull;
    return saveFailure != null
        ? Failure<Category>(saveFailure)
        : Success<Category>(updated);
  }
}
