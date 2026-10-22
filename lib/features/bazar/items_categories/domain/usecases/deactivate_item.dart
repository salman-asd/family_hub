import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_repository.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_validation.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Hides an item from pickers without deleting its document.
/// `Permission.manageCatalogAndBudgets` only.
class DeactivateItem {
  const DeactivateItem({
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
  }) async {
    final actor = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageCatalogAndBudgets,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<Item>(denied);

    final loaded = await _catalog.getItems(familyId);
    final failure = loaded.failureOrNull;
    if (failure != null) return Failure<Item>(failure);
    final items = loaded.valueOrNull ?? const <Item>[];
    final existing = findItem(items, itemId);
    if (existing == null) {
      return const Failure<Item>(NotFound(entity: 'item'));
    }
    if (!existing.active) return Success<Item>(existing);

    final updated = existing.copyWith(active: false);
    final saved = await _catalog.saveItem(
      familyId,
      updated,
      AuditEvent(
        id: _newId(),
        type: AuditEventType.bazarItemDeactivated,
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
