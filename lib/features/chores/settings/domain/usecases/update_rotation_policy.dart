import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Changes `settings/rotationPolicy.absencePolicy` (P3-06, closes C-3).
///
/// The document is written when a family is created, but until now nothing
/// could edit it. [AbsencePolicy] is a closed enum, so there is no validation
/// code to report: any other value cannot reach this use case.
///
/// INTEGRITY write: the policy decides what happens to future absences on every
/// device, so it needs the server.
class UpdateRotationPolicy {
  const UpdateRotationPolicy({
    required this._settings,
    required this._families,
    required this._clock,
    required this._newId,
  });

  final ChoreSettingsRepository _settings;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<void>> call({
    required String actorUid,
    required String familyId,
    required AbsencePolicy policy,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageChoreTemplates,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<void>(denied);

    return _settings.saveAbsencePolicy(
      familyId,
      policy,
      AuditEvent(
        id: _newId(),
        type: AuditEventType.choresRotationPolicyUpdated,
        actorId: actorUid,
        refType: AuditRefType.choreSettings,
        refId: familyId,
        at: _clock.nowUtc(),
        params: <String, String>{'policy': policy.id},
      ),
    );
  }
}
