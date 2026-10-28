import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_validator.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Saves `settings/chores` after a permission check and the full validation.
///
/// Order (CLAUDE.md rule 3): permission → validation → repository write. The
/// write is INTEGRITY (server required): the week start, the generation horizon
/// and the catalogs change what every device shows, so a silently queued
/// offline save is not acceptable (road map 3.4).
class UpdateChoreSettings {
  const UpdateChoreSettings({
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
    required ChoreSettings settings,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageChoreTemplates,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<void>(denied);

    final invalid = ChoreSettingsValidator.validate(settings);
    if (invalid != null) return Failure<void>(invalid);

    return _settings.save(
      familyId,
      settings,
      AuditEvent(
        id: _newId(),
        type: AuditEventType.choresSettingsUpdated,
        actorId: actorUid,
        refType: AuditRefType.choreSettings,
        refId: familyId,
        at: _clock.nowUtc(),
      ),
    );
  }
}
