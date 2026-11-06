import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permission.dart';
import 'package:family_hub/core/permissions/permission_actor.dart';
import 'package:family_hub/core/permissions/permission_policy.dart';
import 'package:family_hub/core/permissions/permission_settings.dart';
import 'package:family_hub/core/permissions/role.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

final class UpdateDashboardPolicy {
  const UpdateDashboardPolicy({
    required this.families,
    required this.policies,
    required this.clock,
    required this.newId,
  });

  final FamilyRepository families;
  final DashboardPolicyRepository policies;
  final Clock clock;
  final IdGenerator newId;

  /// Input keys mirror the Firestore document and allow malformed UI/form
  /// values to return stable validation failures rather than throwing.
  Future<Result<DashboardPolicy>> call({
    required String actorUid,
    required String familyId,
    required Map<String, Map<String, String>> roles,
  }) async {
    final actor = await requirePermission(
      families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageDashboardLayout,
    );
    final denied = actor.failureOrNull;
    if (denied != null) return Failure<DashboardPolicy>(denied);

    final parsed = _parseRoles(roles);
    final failure = parsed.failureOrNull;
    if (failure != null) return Failure<DashboardPolicy>(failure);

    final saved = await policies.savePolicy(
      familyId,
      parsed.valueOrNull!,
      AuditEvent(
        id: newId(),
        type: AuditEventType.familyDashboardPolicyUpdated,
        actorId: actorUid,
        refType: AuditRefType.dashboardSettings,
        refId: familyId,
        at: clock.nowUtc(),
      ),
    );
    final saveFailure = saved.failureOrNull;
    return saveFailure != null
        ? Failure<DashboardPolicy>(saveFailure)
        : Success<DashboardPolicy>(saved.valueOrNull!);
  }

  Result<Map<Role, Map<String, CardAccess>>> _parseRoles(
    Map<String, Map<String, String>> input,
  ) {
    if (input.containsKey(Role.admin.name)) {
      return const Failure<Map<Role, Map<String, CardAccess>>>(
        Validation('roles', 'admin_not_allowed'),
      );
    }

    final roles = <Role, Map<String, CardAccess>>{};
    for (final entry in input.entries) {
      final role = Role.values.where((value) => value.name == entry.key);
      if (role.isEmpty || role.single == Role.admin) {
        return const Failure<Map<Role, Map<String, CardAccess>>>(
          Validation('roles', 'invalid_role'),
        );
      }

      final roleAccess = <String, CardAccess>{};
      for (final cell in entry.value.entries) {
        final card = CardCatalog.find(cell.key);
        if (card == null) {
          return const Failure<Map<Role, Map<String, CardAccess>>>(
            Validation('cardId', 'unknown_card'),
          );
        }
        final accessValues = CardAccess.values.where(
          (access) => access.name == cell.value,
        );
        if (accessValues.isEmpty) {
          return const Failure<Map<Role, Map<String, CardAccess>>>(
            Validation('access', 'invalid_access'),
          );
        }
        final access = accessValues.single;
        if (_grantsUnavailablePermission(role.single, card, access)) {
          return const Failure<Map<Role, Map<String, CardAccess>>>(
            Validation('access', 'permission_unavailable'),
          );
        }
        roleAccess[cell.key] = access;
      }
      roles[role.single] = roleAccess;
    }
    return Success<Map<Role, Map<String, CardAccess>>>(roles);
  }

  bool _grantsUnavailablePermission(
    Role role,
    DashboardCardDef card,
    CardAccess access,
  ) {
    if (access != CardAccess.on && access != CardAccess.required) {
      return false;
    }
    final actor = PermissionActor(
      uid: 'dashboard-policy',
      role: role,
      isActive: true,
    );
    final settings = PermissionSettings.defaults.copyWith(
      choreVerificationEnabled: true,
    );
    bool can(Permission permission) => PermissionPolicy.can(
      actor,
      permission,
      ownerId: permission == Permission.verifyChore ? 'another-member' : null,
      settings: settings,
      template: const PermissionTemplate(verificationEnabled: true),
    );

    final single = card.requiredPermission;
    if (single != null && !can(single)) return true;
    return card.anyRequiredPermissions.isNotEmpty &&
        !card.anyRequiredPermissions.any(can);
  }
}
