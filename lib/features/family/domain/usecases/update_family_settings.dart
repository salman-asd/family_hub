import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Saves family settings: name, timezone, currency and module switches
/// (`Permission.editFamilySettings`: admin only).
class UpdateFamilySettings {
  const UpdateFamilySettings({
    required FamilyRepository families,
    required Clock clock,
    required IdGenerator newId,
  })  : _families = families,
        _clock = clock,
        _newId = newId;

  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<Family>> call({
    required String actorUid,
    required Family family,
  }) async {
    final actor = await requirePermission(
      _families,
      familyId: family.id,
      actorUid: actorUid,
      permission: Permission.editFamilySettings,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<Family>(denied);
    if (family.name.trim().isEmpty) {
      return const Failure<Family>(Validation('name', 'required'));
    }
    if (family.timezone.trim().isEmpty) {
      return const Failure<Family>(Validation('timezone', 'required'));
    }
    final saved = await _families.updateFamily(
      family,
      AuditEvent(
        id: _newId(),
        type: 'family.updated',
        actorId: actorUid,
        refType: 'family',
        refId: family.id,
        at: _clock.nowUtc(),
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null ? Failure<Family>(failure) : Success<Family>(family);
  }
}
