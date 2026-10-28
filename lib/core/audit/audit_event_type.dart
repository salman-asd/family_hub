/// The closed set of audit/activity event types (H5).
///
/// Mirror of `eventTypes()` in `firebase/firestore.rules`; the two lists are
/// compared by `test/core/audit/audit_event_type_test.dart`, so a new type here
/// that is missing from the rules (or the other way round) fails the build.
///
/// These are machine values.  A screen localizes them by type + params; an
/// event never carries display text (CLAUDE.md rule 18).
abstract final class AuditEventType {
  static const String familyCreated = 'family.created';
  static const String familyUpdated = 'family.updated';
  static const String memberRequested = 'member.requested';
  static const String memberApproved = 'member.approved';
  static const String memberRejected = 'member.rejected';
  static const String memberDisabled = 'member.disabled';
  static const String memberRoleChanged = 'member.role_changed';
  static const String memberAdminTransferred = 'member.admin_transferred';
  static const String memberLeft = 'member.left';
  static const String memberCancelled = 'member.cancelled';
  static const String invitationCreated = 'invitation.created';
  static const String invitationRevoked = 'invitation.revoked';

  // ── Bazar and family finance (Phase 2, roadmap section 3.9) ─────────────
  static const String bazarCatalogSeeded = 'bazar.catalog_seeded';
  static const String bazarCategoryCreated = 'bazar.category_created';
  static const String bazarCategoryUpdated = 'bazar.category_updated';
  static const String bazarCategoryDeactivated = 'bazar.category_deactivated';
  static const String bazarItemCreated = 'bazar.item_created';
  static const String bazarItemUpdated = 'bazar.item_updated';
  static const String bazarItemDeactivated = 'bazar.item_deactivated';
  static const String bazarExpenseCreated = 'bazar.expense_created';
  static const String bazarExpenseUpdated = 'bazar.expense_updated';
  static const String bazarExpenseDeleted = 'bazar.expense_deleted';
  static const String bazarExpenseRestored = 'bazar.expense_restored';
  static const String bazarTripCreated = 'bazar.trip_created';
  static const String bazarBudgetSaved = 'bazar.budget_saved';
  static const String bazarSettingsUpdated = 'bazar.settings_updated';
  static const String bazarContributionPlanSet = 'bazar.contribution_plan_set';
  static const String bazarContributionRecorded = 'bazar.contribution_recorded';
  static const String bazarContributionVoided = 'bazar.contribution_voided';
  static const String bazarContributionRequested =
      'bazar.contribution_requested';
  static const String bazarContributionRequestEdited =
      'bazar.contribution_request_edited';
  static const String bazarContributionRequestCancelled =
      'bazar.contribution_request_cancelled';
  static const String bazarContributionApproved = 'bazar.contribution_approved';
  static const String bazarContributionRejected = 'bazar.contribution_rejected';
  static const String bazarContributionChangeRequested =
      'bazar.contribution_change_requested';
  static const String bazarContributionChangeApproved =
      'bazar.contribution_change_approved';
  static const String bazarContributionChangeRejected =
      'bazar.contribution_change_rejected';
  static const String bazarOpeningBalanceSet = 'bazar.opening_balance_set';
  static const String bazarAdvanceSettled = 'bazar.advance_settled';
  static const String bazarMonthClosed = 'bazar.month_closed';
  static const String bazarMonthReopened = 'bazar.month_reopened';
  static const String bazarImportCompleted = 'bazar.import_completed';
  static const String bazarImportUndone = 'bazar.import_undone';

  // ── Chores (Phase 3, road map 3.9) ───────────────────────────────────────
  static const String choresSettingsUpdated = 'chores.settings_updated';
  static const String choresRotationPolicyUpdated =
      'chores.rotation_policy_updated';
  static const String choresTemplateCreated = 'chores.template_created';
  static const String choresTemplateUpdated = 'chores.template_updated';
  static const String choresTemplatePaused = 'chores.template_paused';
  static const String choresTemplateResumed = 'chores.template_resumed';
  static const String choresTemplateArchived = 'chores.template_archived';
  static const String choresTemplateDuplicated = 'chores.template_duplicated';
  static const String choresStarterPackApplied = 'chores.starter_pack_applied';
  static const String choresDutyGroupCreated = 'chores.duty_group_created';
  static const String choresDutyGroupUpdated = 'chores.duty_group_updated';
  static const String choresRotationChanged = 'chores.rotation_changed';
  static const String choresOccurrencesGenerated =
      'chores.occurrences_generated';
  static const String choresOccurrencesReplanned =
      'chores.occurrences_replanned';
  static const String choresOccurrenceCompleted = 'chores.occurrence_completed';
  static const String choresOccurrenceUncompleted =
      'chores.occurrence_uncompleted';
  static const String choresOccurrenceVerified = 'chores.occurrence_verified';
  static const String choresOccurrenceReopened = 'chores.occurrence_reopened';
  static const String choresOccurrenceException = 'chores.occurrence_exception';
  static const String choresOccurrenceSkipped = 'chores.occurrence_skipped';
  static const String choresOccurrenceUnskipped = 'chores.occurrence_unskipped';
  static const String choresOccurrenceReassigned =
      'chores.occurrence_reassigned';
  static const String choresCommentAdded = 'chores.comment_added';
  static const String choresCommentHidden = 'chores.comment_hidden';
  static const String choresAvailabilityAdded = 'chores.availability_added';
  static const String choresAvailabilityCancelled =
      'chores.availability_cancelled';
  static const String choresAvailabilityDecided = 'chores.availability_decided';
  static const String choresSwapRequested = 'chores.swap_requested';
  static const String choresSwapAccepted = 'chores.swap_accepted';
  static const String choresSwapDeclined = 'chores.swap_declined';
  static const String choresSwapCancelled = 'chores.swap_cancelled';
  static const String choresSwapExpired = 'chores.swap_expired';
  static const String choresCoverAssigned = 'chores.cover_assigned';

  /// Every type, in the same order as the rules list.
  static const List<String> all = <String>[
    familyCreated,
    memberRequested,
    memberApproved,
    memberRejected,
    memberDisabled,
    memberRoleChanged,
    memberAdminTransferred,
    memberLeft,
    memberCancelled,
    invitationCreated,
    invitationRevoked,
    familyUpdated,
    bazarCatalogSeeded,
    bazarCategoryCreated,
    bazarCategoryUpdated,
    bazarCategoryDeactivated,
    bazarItemCreated,
    bazarItemUpdated,
    bazarItemDeactivated,
    bazarExpenseCreated,
    bazarExpenseUpdated,
    bazarExpenseDeleted,
    bazarExpenseRestored,
    bazarTripCreated,
    bazarBudgetSaved,
    bazarSettingsUpdated,
    bazarContributionPlanSet,
    bazarContributionRecorded,
    bazarContributionVoided,
    bazarContributionRequested,
    bazarContributionRequestEdited,
    bazarContributionRequestCancelled,
    bazarContributionApproved,
    bazarContributionRejected,
    bazarContributionChangeRequested,
    bazarContributionChangeApproved,
    bazarContributionChangeRejected,
    bazarOpeningBalanceSet,
    bazarAdvanceSettled,
    bazarMonthClosed,
    bazarMonthReopened,
    bazarImportCompleted,
    bazarImportUndone,
    choresSettingsUpdated,
    choresRotationPolicyUpdated,
    choresTemplateCreated,
    choresTemplateUpdated,
    choresTemplatePaused,
    choresTemplateResumed,
    choresTemplateArchived,
    choresTemplateDuplicated,
    choresStarterPackApplied,
    choresDutyGroupCreated,
    choresDutyGroupUpdated,
    choresRotationChanged,
    choresOccurrencesGenerated,
    choresOccurrencesReplanned,
    choresOccurrenceCompleted,
    choresOccurrenceUncompleted,
    choresOccurrenceVerified,
    choresOccurrenceReopened,
    choresOccurrenceException,
    choresOccurrenceSkipped,
    choresOccurrenceUnskipped,
    choresOccurrenceReassigned,
    choresCommentAdded,
    choresCommentHidden,
    choresAvailabilityAdded,
    choresAvailabilityCancelled,
    choresAvailabilityDecided,
    choresSwapRequested,
    choresSwapAccepted,
    choresSwapDeclined,
    choresSwapCancelled,
    choresSwapExpired,
    choresCoverAssigned,
  ];
}
