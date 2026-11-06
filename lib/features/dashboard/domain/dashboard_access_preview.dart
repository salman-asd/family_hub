import 'package:family_hub/core/permissions/permission.dart';
import 'package:family_hub/core/permissions/permission_actor.dart';
import 'package:family_hub/core/permissions/permission_policy.dart';
import 'package:family_hub/core/permissions/permission_settings.dart';
import 'package:family_hub/core/permissions/role.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_resolver.dart';

abstract final class DashboardAccessPreview {
  static bool canRoleSeeCard(
    Role role,
    DashboardCardDef card,
    PermissionSettings settings,
  ) {
    final actor = _previewActor(role);
    bool can(Permission permission) => permission == Permission.verifyChore
        ? PermissionPolicy.canVerifyOthers(actor, settings: settings)
        : PermissionPolicy.can(actor, permission, settings: settings);

    final single = card.requiredPermission;
    if (single != null && !can(single)) return false;
    final alternatives = card.anyRequiredPermissions;
    return alternatives.isEmpty || alternatives.any(can);
  }

  static DashboardLayout resolve({
    required Role role,
    required DashboardPolicy policy,
    required Map<String, bool> modulesEnabled,
    required PermissionSettings settings,
  }) {
    final actor = _previewActor(role);
    return DashboardResolver.resolve(
      role: role,
      policy: policy,
      prefs: DashboardPrefs.defaults,
      modulesEnabled: modulesEnabled,
      can: (permission) => permission == Permission.verifyChore
          ? PermissionPolicy.canVerifyOthers(actor, settings: settings)
          : PermissionPolicy.can(actor, permission, settings: settings),
    );
  }

  static PermissionActor _previewActor(Role role) =>
      PermissionActor(uid: 'dashboard-preview', role: role, isActive: true);
}
