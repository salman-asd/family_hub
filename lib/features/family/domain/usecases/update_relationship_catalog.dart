import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';
import 'package:family_hub/features/family/domain/relationship_catalog.dart';

/// Edits the family's relationship list (H10, `Permission.editFamilySettings`).
///
/// Custom entries can be added, renamed and disabled; the ten built-ins cannot
/// be changed (`Conflict('built_in')`).  Each call reads the CURRENT catalog,
/// applies one change and writes it with an audit event in one batch.
class UpdateRelationshipCatalog {
  const UpdateRelationshipCatalog({
    required this._families,
    required this._clock,
    required this._newId,
  });

  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  /// A fresh id for a custom entry: `c` + 12 lowercase alphanumerics, which
  /// always matches the id pattern.
  String _customId() {
    final raw = _newId().replaceAll(RegExp('[^a-z0-9]'), '');
    final padded = raw.length >= 12
        ? raw.substring(0, 12)
        : raw.padRight(12, '0');
    return 'c$padded';
  }

  Future<Result<RelationshipCatalog>> add({
    required String actorUid,
    required String familyId,
    required String labelBn,
    required String labelEn,
    bool spouseRelevant = false,
  }) => _apply(
    actorUid,
    familyId,
    'add',
    (catalog) => catalog.add(
      id: _customId(),
      labelBn: labelBn,
      labelEn: labelEn,
      spouseRelevant: spouseRelevant,
    ),
  );

  Future<Result<RelationshipCatalog>> rename({
    required String actorUid,
    required String familyId,
    required RelationshipId id,
    required String labelBn,
    required String labelEn,
    bool? spouseRelevant,
  }) => _apply(
    actorUid,
    familyId,
    'rename',
    (catalog) => catalog.rename(
      id,
      labelBn: labelBn,
      labelEn: labelEn,
      spouseRelevant: spouseRelevant,
    ),
  );

  Future<Result<RelationshipCatalog>> setActive({
    required String actorUid,
    required String familyId,
    required RelationshipId id,
    required bool active,
  }) => _apply(
    actorUid,
    familyId,
    active ? 'enable' : 'disable',
    (catalog) => catalog.setActive(id, active: active),
  );

  Future<Result<RelationshipCatalog>> _apply(
    String actorUid,
    String familyId,
    String change,
    Result<RelationshipCatalog> Function(RelationshipCatalog) edit,
  ) async {
    final actor = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.editFamilySettings,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<RelationshipCatalog>(denied);

    final current = await _families.getRelationshipCatalog(familyId);
    final readFailure = current.failureOrNull;
    if (readFailure != null) return Failure<RelationshipCatalog>(readFailure);

    final edited = edit(current.valueOrNull ?? RelationshipCatalog.defaults);
    final editFailure = edited.failureOrNull;
    if (editFailure != null) return Failure<RelationshipCatalog>(editFailure);
    final next = edited.valueOrNull!;

    final saved = await _families.saveRelationshipCatalog(
      familyId,
      next,
      AuditEvent(
        id: _newId(),
        type: AuditEventType.familyUpdated,
        actorId: actorUid,
        refType: 'family',
        refId: familyId,
        at: _clock.nowUtc(),
        params: <String, String>{'section': 'relationships', 'change': change},
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<RelationshipCatalog>(failure)
        : Success<RelationshipCatalog>(next);
  }
}
