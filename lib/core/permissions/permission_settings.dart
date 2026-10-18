import 'package:family_hub/core/permissions/permission.dart';

/// The family-level switches a permission can depend on.
///
/// The two module switches mirror `families/{id}/settings/modules`; a
/// permission whose [Permission.module] is switched off is denied for
/// everybody.  [choreVerificationEnabled] is the family half of the
/// `verifyChore` cell: the family must want verification *and* the template must
/// allow it.  Defaults follow CLAUDE.md: all modules on, verification off.
final class PermissionSettings {
  const PermissionSettings({
    this.bazarEnabled = true,
    this.choresEnabled = true,
    this.choreVerificationEnabled = false,
  });

  /// All modules on, verification off: what a family gets on creation.
  static const PermissionSettings defaults = PermissionSettings();

  final bool bazarEnabled;
  final bool choresEnabled;
  final bool choreVerificationEnabled;

  bool isModuleEnabled(PermissionModule module) => switch (module) {
        // Family administration is not a switchable module.
        PermissionModule.family => true,
        PermissionModule.bazar => bazarEnabled,
        PermissionModule.chores => choresEnabled,
      };

  @override
  bool operator ==(Object other) =>
      other is PermissionSettings &&
      other.bazarEnabled == bazarEnabled &&
      other.choresEnabled == choresEnabled &&
      other.choreVerificationEnabled == choreVerificationEnabled;

  @override
  int get hashCode =>
      Object.hash(bazarEnabled, choresEnabled, choreVerificationEnabled);

  @override
  String toString() => 'PermissionSettings(bazar: $bazarEnabled, '
      'chores: $choresEnabled, verification: $choreVerificationEnabled)';
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
