import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/bazar/items_categories/domain/catalog_repository.dart';
import 'package:family_hub/features/bazar/items_categories/domain/default_catalog.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Backfills the starter catalog into an existing family, once (P2-06).
///
/// Permission check -> server-only empty check -> conflict or seed write.  It
/// never seeds silently: the home screen asks the user, and offline fails before
/// anything is written (G-8).
class EnsureCatalogSeeded {
  const EnsureCatalogSeeded({
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
  }) async {
    final actor = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageCatalogAndBudgets,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<void>(denied);

    final empty = await _catalog.isCatalogEmpty(familyId);
    final readFailure = empty.failureOrNull;
    if (readFailure != null) return Failure<void>(readFailure);
    if (empty.valueOrNull != true) {
      return const Failure<void>(Conflict(code: 'catalog_not_empty'));
    }

    return _catalog.seedDefaultCatalog(
      familyId,
      actorUid,
      AuditEvent(
        id: _newId(),
        type: AuditEventType.bazarCatalogSeeded,
        actorId: actorUid,
        refType: AuditRefType.family,
        refId: familyId,
        at: _clock.nowUtc(),
        params: <String, String>{
          'categories': '${defaultCatalogCategories.length}',
          'items': '${defaultCatalogItems.length}',
        },
      ),
    );
  }
}
