/// Which part of the app a permission belongs to.
///
/// The policy uses this to honour the per-family module switches
/// (`families/{id}/settings/modules`): a bazar permission is denied while the
/// bazar module is off, and so on.  Family administration is never switchable.
enum PermissionModule { family, bazar, chores }

/// One permission per row of the roadmap 2.2 matrix (Step 10).
///
/// Names are the roadmap's names, verbatim, so the code and the matrix can be
/// diffed by eye.
enum Permission {
  // Family administration.
  inviteMembers(PermissionModule.family),
  approveMembers(PermissionModule.family),
  removeMembers(PermissionModule.family),
  changeRoles(PermissionModule.family),
  editFamilySettings(PermissionModule.family),
  viewFamilyReports(PermissionModule.family),
  exportData(PermissionModule.family),

  // Bazar and family finance.
  manageCatalogAndBudgets(PermissionModule.bazar),
  addOwnExpense(PermissionModule.bazar),
  editOthersExpense(PermissionModule.bazar),
  recordContribution(PermissionModule.bazar),
  viewAllContributions(PermissionModule.bazar),

  // Chores.
  manageChoreTemplates(PermissionModule.chores),
  reassignChore(PermissionModule.chores),
  requestSwap(PermissionModule.chores),
  completeOwnChore(PermissionModule.chores),
  commentOnChore(PermissionModule.chores),
  verifyChore(PermissionModule.chores);

  const Permission(this.module);

  /// The module switch that gates this permission.
  final PermissionModule module;
}
