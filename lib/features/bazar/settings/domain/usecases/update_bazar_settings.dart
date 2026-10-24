import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Saves the Bazar settings after checking permission and every range rule.
///
/// The write is server-required (the repository probes) because alert
/// thresholds and the fund start month change financial calculations on every
/// device.  The audit entry is written in the same batch.
class UpdateBazarSettings {
  const UpdateBazarSettings({
    required this._settings,
    required this._families,
    required this._clock,
    required this._newId,
  });

  final BazarSettingsRepository _settings;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<void>> call({
    required String actorUid,
    required String familyId,
    required BazarSettings settings,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageCatalogAndBudgets,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<void>(denied);

    final invalid = _validate(settings);
    if (invalid != null) return Failure<void>(invalid);

    return _settings.save(
      familyId,
      settings,
      AuditEvent(
        id: _newId(),
        type: AuditEventType.bazarSettingsUpdated,
        actorId: actorUid,
        refType: AuditRefType.family,
        refId: familyId,
        at: _clock.nowUtc(),
      ),
    );
  }

  static AppFailure? _validate(BazarSettings s) {
    if (s.weekStartDay < 1 || s.weekStartDay > 7) {
      return const Validation('weekStartDay', 'invalid');
    }
    if (s.contributionDueDay < 1 || s.contributionDueDay > 28) {
      return const Validation('contributionDueDay', 'invalid');
    }
    if (s.defaultMonthlyContribution.isNegative) {
      return const Validation('defaultMonthlyContribution', 'negative');
    }

    final thresholds = s.alertThresholds;
    if (thresholds.isEmpty) {
      return const Validation('alertThresholds', 'empty');
    }
    if (thresholds.length > 4) {
      return const Validation('alertThresholds', 'too_many');
    }
    var previous = 0;
    for (final value in thresholds) {
      if (value < 1 || value > 200) {
        return const Validation('alertThresholds', 'out_of_range');
      }
      if (value == previous) {
        return const Validation('alertThresholds', 'duplicate');
      }
      if (value < previous) {
        return const Validation('alertThresholds', 'not_ascending');
      }
      previous = value;
    }
    return null;
  }
}
