import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Saves the family's permission switches (`settings/permissions`, H7):
/// moderator finance rights, member report/contribution visibility, member
/// invitations and chore verification.  `Permission.editFamilySettings`: admin
/// only.  The module switches are NOT part of this document.
class UpdatePermissionSettings {
  const UpdatePermissionSettings({
    required this._families,
    required this._clock,
    required this._newId,
  });

  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<PermissionSettings>> call({
    required String actorUid,
    required String familyId,
    required PermissionSettings settings,
  }) async {
    final actor = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.editFamilySettings,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<PermissionSettings>(denied);

    final saved = await _families.updatePermissionSettings(
      familyId,
      settings,
      AuditEvent(
        id: _newId(),
        type: AuditEventType.familyUpdated,
        actorId: actorUid,
        refType: 'family',
        refId: familyId,
        at: _clock.nowUtc(),
        params: const {'section': 'permissions'},
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<PermissionSettings>(failure)
        : Success<PermissionSettings>(settings);
  }
}
