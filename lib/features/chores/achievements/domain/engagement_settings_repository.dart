import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';

abstract interface class EngagementSettingsRepository {
  Stream<EngagementSettings> watch(
    String familyId, {
    required EngagementSettings defaults,
  });

  Future<Result<EngagementSettings>> get(
    String familyId, {
    required EngagementSettings defaults,
  });

  Future<Result<EngagementSettings>> save(
    String familyId,
    EngagementSettings settings,
    List<AuditEvent> events,
  );
}
