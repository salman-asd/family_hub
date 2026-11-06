import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/role.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';

abstract interface class DashboardPolicyRepository {
  Stream<DashboardPolicy> watchPolicy(String familyId);

  /// Writes the next policy version and its audit event in one batch.
  Future<Result<DashboardPolicy>> savePolicy(
    String familyId,
    Map<Role, Map<String, CardAccess>> roles,
    AuditEvent event,
  );
}
