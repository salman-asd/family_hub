import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';

/// Port for the one Bazar settings document (`settings/bazar`).
abstract interface class BazarSettingsRepository {
  /// Live settings; an absent document yields [BazarSettings.defaults].
  Stream<BazarSettings> watch(String familyId);

  /// One-shot read; an absent document yields [BazarSettings.defaults].
  Future<Result<BazarSettings>> get(String familyId);

  /// Writes the settings and the audit entry in one server-required batch.
  Future<Result<void>> save(
    String familyId,
    BazarSettings settings,
    AuditEvent event,
  );
}
