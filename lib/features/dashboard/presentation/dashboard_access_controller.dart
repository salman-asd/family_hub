import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permission_settings.dart';
import 'package:family_hub/core/permissions/role.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_access_preview.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_resolver.dart';
import 'package:family_hub/features/dashboard/domain/usecases/update_dashboard_policy.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardAccessControllerProvider = Provider<DashboardAccessController>(
  (ref) => DashboardAccessController(ref.watch(updateDashboardPolicyProvider)),
);

final class DashboardAccessController {
  const DashboardAccessController(this._updatePolicy);

  final UpdateDashboardPolicy _updatePolicy;

  Future<Result<DashboardPolicy>> save({
    required String actorUid,
    required String familyId,
    required DashboardPolicy policy,
  }) => _updatePolicy.call(
    actorUid: actorUid,
    familyId: familyId,
    roles: <String, Map<String, String>>{
      for (final entry in policy.roles.entries)
        entry.key.name: <String, String>{
          for (final cell in entry.value.entries) cell.key: cell.value.name,
        },
    },
  );

  static bool canRoleSeeCard(
    Role role,
    DashboardCardDef card,
    PermissionSettings settings,
  ) => DashboardAccessPreview.canRoleSeeCard(role, card, settings);

  static DashboardLayout preview({
    required Role role,
    required DashboardPolicy policy,
    required Map<String, bool> modulesEnabled,
    required PermissionSettings settings,
  }) => DashboardAccessPreview.resolve(
    role: role,
    policy: policy,
    modulesEnabled: modulesEnabled,
    settings: settings,
  );
}
