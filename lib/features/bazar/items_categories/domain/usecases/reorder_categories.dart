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

/// Saves a new category order as `sortOrder` 0, 1, 2 ... in the given order.
///
/// Only the categories whose position changed are written, one batch (with
/// its own audit entry) each; a failure part-way leaves a valid, partly
/// re-ordered list, never a broken one.  Categories not named in
/// [orderedIds] keep their order after the named ones.
/// `Permission.manageCatalogAndBudgets` only.
class ReorderCategories {
  const ReorderCategories({
    required this._catalog,
    required this._families,
    required this._clock,
    required this._newId,
  });

  final CatalogRepository _catalog;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<void>> call({
    required String actorUid,
    required String familyId,
    required List<String> orderedIds,
  }) async {
    final actor = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageCatalogAndBudgets,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<void>(denied);

    final loaded = await _catalog.getCategories(familyId);
    final failure = loaded.failureOrNull;
    if (failure != null) return Failure<void>(failure);
    final byId = <String, Category>{
      for (final c in loaded.valueOrNull ?? const <Category>[]) c.id: c,
    };
    for (final id in orderedIds) {
      if (!byId.containsKey(id)) {
        return const Failure<void>(NotFound(entity: 'category'));
      }
    }

    for (var position = 0; position < orderedIds.length; position++) {
      final existing = byId[orderedIds[position]]!;
      if (existing.sortOrder == position) continue;
      final updated = existing.copyWith(sortOrder: position);
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
      if (saveFailure != null) return Failure<void>(saveFailure);
    }
    return const Success<void>(null);
  }
}
