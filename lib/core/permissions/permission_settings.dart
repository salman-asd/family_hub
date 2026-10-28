import 'package:family_hub/core/permissions/permission.dart';

/// The family-level switches a permission can depend on.
///
/// Two sources feed it: the module switches mirror
/// `families/{id}/settings/modules`, the rest mirrors
/// `families/{id}/settings/permissions` (H7).  A permission whose
/// [Permission.module] is switched off is denied for everybody.  Defaults
/// follow CLAUDE.md: all modules on, verification off, moderators manage
/// finance, members see the family reports but only their own contributions.
final class PermissionSettings {
  const PermissionSettings({
    this.bazarEnabled = true,
    this.choresEnabled = true,
    this.moderatorManagesFinance = true,
    this.membersViewFamilyReports = true,
    this.membersViewAllContributions = false,
    this.membersCanInvite = false,
    this.choreVerificationEnabled = false,
    this.membersCanCompleteForOthers = false,
  });

  /// What a family gets on creation (and what an unreadable document means).
  static const PermissionSettings defaults = PermissionSettings();

  final bool bazarEnabled;
  final bool choresEnabled;

  /// Spec section 6, "Manage budgets/contributions: moderator configurable".
  final bool moderatorManagesFinance;

  /// Spec section 6, "View reports: according to family policy".
  final bool membersViewFamilyReports;

  /// Everybody sees every contribution (CLAUDE.md default: only their own).
  final bool membersViewAllContributions;

  /// Plain members may create invitations (default: admin and moderator only).
  final bool membersCanInvite;

  /// The family half of the `verifyChore` cell (the template has the other).
  final bool choreVerificationEnabled;

  /// Plain members may complete a chore assigned to somebody else (D-P3-14,
  /// default off: the assignee or a manager only).
  final bool membersCanCompleteForOthers;

  bool isModuleEnabled(PermissionModule module) => switch (module) {
    // Family administration is not a switchable module.
    PermissionModule.family => true,
    PermissionModule.bazar => bazarEnabled,
    PermissionModule.chores => choresEnabled,
  };

  PermissionSettings copyWith({
    bool? bazarEnabled,
    bool? choresEnabled,
    bool? moderatorManagesFinance,
    bool? membersViewFamilyReports,
    bool? membersViewAllContributions,
    bool? membersCanInvite,
    bool? choreVerificationEnabled,
    bool? membersCanCompleteForOthers,
  }) => PermissionSettings(
    bazarEnabled: bazarEnabled ?? this.bazarEnabled,
    choresEnabled: choresEnabled ?? this.choresEnabled,
    moderatorManagesFinance:
        moderatorManagesFinance ?? this.moderatorManagesFinance,
    membersViewFamilyReports:
        membersViewFamilyReports ?? this.membersViewFamilyReports,
    membersViewAllContributions:
        membersViewAllContributions ?? this.membersViewAllContributions,
    membersCanInvite: membersCanInvite ?? this.membersCanInvite,
    choreVerificationEnabled:
        choreVerificationEnabled ?? this.choreVerificationEnabled,
    membersCanCompleteForOthers:
        membersCanCompleteForOthers ?? this.membersCanCompleteForOthers,
  );

  @override
  bool operator ==(Object other) =>
      other is PermissionSettings &&
      other.bazarEnabled == bazarEnabled &&
      other.choresEnabled == choresEnabled &&
      other.moderatorManagesFinance == moderatorManagesFinance &&
      other.membersViewFamilyReports == membersViewFamilyReports &&
      other.membersViewAllContributions == membersViewAllContributions &&
      other.membersCanInvite == membersCanInvite &&
      other.choreVerificationEnabled == choreVerificationEnabled &&
      other.membersCanCompleteForOthers == membersCanCompleteForOthers;

  @override
  int get hashCode => Object.hash(
    bazarEnabled,
    choresEnabled,
    moderatorManagesFinance,
    membersViewFamilyReports,
    membersViewAllContributions,
    membersCanInvite,
    choreVerificationEnabled,
    membersCanCompleteForOthers,
  );

  @override
  String toString() =>
      'PermissionSettings(bazar: $bazarEnabled, '
      'chores: $choresEnabled, moderatorFinance: $moderatorManagesFinance, '
      'memberReports: $membersViewFamilyReports, '
      'memberAllContributions: $membersViewAllContributions, '
      'memberInvite: $membersCanInvite, '
      'verification: $choreVerificationEnabled, '
      'memberCompleteForOthers: $membersCanCompleteForOthers)';
}

/// The template-level switch: the "if the template allows it" cell.
///
/// Only the chore template needs one today (roadmap Step 23: a chore may be
/// verified only when its template allows or requires it).
final class PermissionTemplate {
  const PermissionTemplate({this.verificationEnabled = false});

  final bool verificationEnabled;

  @override
  bool operator ==(Object other) =>
      other is PermissionTemplate &&
      other.verificationEnabled == verificationEnabled;

  @override
  int get hashCode => verificationEnabled.hashCode;

  @override
  String toString() => 'PermissionTemplate(verification: $verificationEnabled)';
}
