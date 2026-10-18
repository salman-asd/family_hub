import 'package:family_hub/core/permissions/permission.dart';
import 'package:family_hub/core/permissions/permission_actor.dart';
import 'package:family_hub/core/permissions/permission_settings.dart';

/// The one permission matrix (roadmap 2.2 / Step 10), used by the UI
/// (`PermissionGate`), by the use cases (`requirePermission`) and by the tests.
///
/// ## The matrix
///
/// | Permission | admin | moderator | member |
/// | --- | --- | --- | --- |
/// | inviteMembers | yes | yes | no |
/// | approveMembers | yes | yes | no |
/// | removeMembers | yes | no | no |
/// | changeRoles | yes | no | no |
/// | editFamilySettings | yes | no | no |
/// | viewFamilyReports | yes | yes | yes |
/// | exportData | yes | no | no |
/// | manageCatalogAndBudgets | yes | yes | no |
/// | addOwnExpense | yes | yes | yes |
/// | editOthersExpense | yes | yes | no |
/// | recordContribution | yes | yes | no |
/// | manageChoreTemplates | yes | yes | no |
/// | reassignChore | yes | yes | no |
/// | requestSwap | own | own | own |
/// | completeOwnChore | own | own | own |
/// | commentOnChore | yes | yes | yes |
/// | verifyChore | other | other | no |
///
/// ("own" means `ownerId` must be the actor; "other" means `ownerId` must be
/// somebody else — nobody verifies their own chore.)
///
/// Every cell is additionally false when the actor is not active, and false
/// while the permission's module is switched off in [PermissionSettings].
///
/// Roadmap 2.2 itself was not present in ROADMAP.md, so this table was derived
/// from the rules the roadmap states elsewhere (Step 9's "admin does
/// everything, moderator invites/approves/rejects"; Step 15's "members may edit
/// only their own expenses, admin/moderator any"; Step 25's "reassign
/// (admin/moderator)"; CLAUDE.md's "members see only their own contributions").
abstract final class PermissionPolicy {
  /// True when [actor] may do [permission].
  ///
  /// [ownerId] is the member an occurrence/expense belongs to: the assignee for
  /// `completeOwnChore` and `requestSwap`, the completer for `verifyChore`.
  /// [settings] carries the family switches, [template] the template switch.
  static bool can(
    PermissionActor actor,
    Permission permission, {
    String? ownerId,
    PermissionSettings settings = PermissionSettings.defaults,
    PermissionTemplate? template,
  }) {
    if (!actor.isActive) return false;
    if (!settings.isModuleEnabled(permission.module)) return false;

    return switch (permission) {
      // ── Family administration ──────────────────────────────────────────
      Permission.inviteMembers => actor.isManager,
      Permission.approveMembers => actor.isManager,
      Permission.removeMembers => actor.isAdmin,
      Permission.changeRoles => actor.isAdmin,
      Permission.editFamilySettings => actor.isAdmin,
      Permission.viewFamilyReports => true,
      Permission.exportData => actor.isAdmin,

      // ── Bazar and family finance ───────────────────────────────────────
      Permission.manageCatalogAndBudgets => actor.isManager,
      Permission.addOwnExpense => true,
      Permission.editOthersExpense => actor.isManager,
      Permission.recordContribution => actor.isManager,

      // ── Chores ─────────────────────────────────────────────────────────
      Permission.manageChoreTemplates => actor.isManager,
      Permission.reassignChore => actor.isManager,
      Permission.requestSwap => _owns(actor, ownerId),
      Permission.completeOwnChore => _owns(actor, ownerId),
      Permission.commentOnChore => true,

      // Verification needs the family switch, the template switch and a
      // *different* person: self-verification is never allowed.
      Permission.verifyChore => actor.isManager &&
          settings.choreVerificationEnabled &&
          (template?.verificationEnabled ?? false) &&
          ownerId != null &&
          ownerId != actor.uid,
    };
  }

  /// The actor owns the record.  An unknown owner (`ownerId == null`) is never
  /// "own", so a caller that forgets the context is denied rather than trusted.
  static bool _owns(PermissionActor actor, String? ownerId) =>
      ownerId != null && ownerId == actor.uid;
}
