import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/role_labels.dart';
import 'package:family_hub/core/permissions/role.dart';
import 'package:family_hub/core/utils/money.dart';

/// Localizes an activity / audit entry from its machine `type` + `params`
/// (H10, CLAUDE.md rule 18): an event never stores display text, so the same
/// entry reads correctly in Bangla and in English.
///
/// A missing param renders as an empty string and an unknown type as a neutral
/// sentence, so an entry written by a newer app version never breaks a screen.
extension ActivityText on AppLocalizations {
  String activityText(String type, Map<String, String> params) {
    String p(String key) => params[key] ?? '';
    String money(String key) => _money(p(key));
    return switch (type) {
      AuditEventType.familyCreated => activityFamilyCreated(p('familyName')),
      AuditEventType.familyUpdated => activityFamilyUpdated,
      AuditEventType.memberRequested => activityMemberRequested(
        p('memberName'),
      ),
      AuditEventType.memberApproved => activityMemberApproved(p('memberName')),
      AuditEventType.memberRejected => activityMemberRejected(p('memberName')),
      AuditEventType.memberDisabled => activityMemberDisabled(p('memberName')),
      AuditEventType.memberRoleChanged => activityMemberRoleChanged(
        p('memberName'),
        _roleName(p('newRole')),
      ),
      AuditEventType.memberAdminTransferred => activityAdminTransferred(
        p('memberName'),
      ),
      AuditEventType.memberLeft => activityMemberLeft(p('memberName')),
      AuditEventType.memberCancelled => activityMemberCancelled(
        p('memberName'),
      ),
      AuditEventType.invitationCreated => activityInvitationCreated(p('code')),
      AuditEventType.invitationRevoked => activityInvitationRevoked(p('code')),

      // ── Bazar and family finance (roadmap section 3.9) ───────────────────
      AuditEventType.bazarCatalogSeeded => activityBazarCatalogSeeded(
        p('categories'),
        p('items'),
      ),
      AuditEventType.bazarCategoryCreated => activityBazarCategoryCreated(
        p('name'),
      ),
      AuditEventType.bazarCategoryUpdated => activityBazarCategoryUpdated(
        p('name'),
      ),
      AuditEventType.bazarCategoryDeactivated =>
        activityBazarCategoryDeactivated(p('name')),
      AuditEventType.bazarItemCreated => activityBazarItemCreated(p('name')),
      AuditEventType.bazarItemUpdated => activityBazarItemUpdated(p('name')),
      AuditEventType.bazarItemDeactivated => activityBazarItemDeactivated(
        p('name'),
      ),
      AuditEventType.bazarExpenseCreated => activityBazarExpenseCreated(
        p('item'),
        money('amount'),
        _fundingName(p('funding')),
      ),
      AuditEventType.bazarExpenseUpdated => activityBazarExpenseUpdated(
        p('item'),
        p('fields'),
      ),
      AuditEventType.bazarExpenseDeleted => activityBazarExpenseDeleted(
        p('item'),
        money('amount'),
      ),
      AuditEventType.bazarExpenseRestored => activityBazarExpenseRestored(
        p('item'),
        money('amount'),
      ),
      AuditEventType.bazarTripCreated => activityBazarTripCreated(
        p('lines'),
        money('amount'),
      ),
      AuditEventType.bazarBudgetSaved => activityBazarBudgetSaved(
        p('month'),
        money('amount'),
      ),
      AuditEventType.bazarSettingsUpdated => activityBazarSettingsUpdated,
      AuditEventType.bazarContributionPlanSet =>
        activityBazarContributionPlanSet(
          p('month'),
          p('member'),
          money('amount'),
        ),
      AuditEventType.bazarContributionRecorded =>
        activityBazarContributionRecorded(
          p('month'),
          p('member'),
          money('amount'),
        ),
      AuditEventType.bazarContributionVoided => activityBazarContributionVoided(
        p('month'),
        p('member'),
        money('amount'),
      ),
      AuditEventType.bazarContributionRequested =>
        activityBazarContributionRequested(
          p('month'),
          p('member'),
          money('amount'),
        ),
      AuditEventType.bazarContributionRequestEdited =>
        activityBazarContributionRequestEdited(
          p('month'),
          p('member'),
          money('amount'),
        ),
      AuditEventType.bazarContributionRequestCancelled =>
        activityBazarContributionRequestCancelled(
          p('month'),
          p('member'),
          money('amount'),
        ),
      AuditEventType.bazarContributionApproved =>
        activityBazarContributionApproved(
          p('month'),
          p('member'),
          money('amount'),
        ),
      AuditEventType.bazarContributionRejected =>
        activityBazarContributionRejected(
          p('month'),
          p('member'),
          money('amount'),
          p('reason'),
        ),
      AuditEventType.bazarContributionChangeRequested =>
        activityBazarContributionChangeRequested(
          p('month'),
          p('member'),
          money('amount'),
          money('old'),
        ),
      AuditEventType.bazarContributionChangeApproved =>
        activityBazarContributionChangeApproved(
          p('month'),
          p('member'),
          money('amount'),
          money('old'),
        ),
      AuditEventType.bazarContributionChangeRejected =>
        activityBazarContributionChangeRejected(
          p('month'),
          p('member'),
          money('amount'),
          money('old'),
        ),
      AuditEventType.bazarOpeningBalanceSet => activityBazarOpeningBalanceSet(
        p('month'),
        money('amount'),
      ),
      AuditEventType.bazarAdvanceSettled => activityBazarAdvanceSettled(
        p('member'),
        money('amount'),
        _advanceStatus(p('status')),
      ),
      AuditEventType.bazarMonthClosed => activityBazarMonthClosed(
        p('month'),
        money('balance'),
      ),
      AuditEventType.bazarMonthReopened => activityBazarMonthReopened(
        p('month'),
        p('note'),
      ),
      AuditEventType.bazarImportCompleted => activityBazarImportCompleted(
        p('rows'),
        money('amount'),
      ),
      AuditEventType.bazarImportUndone => activityBazarImportUndone(
        p('rows'),
        money('amount'),
      ),
      _ => activityUnknown,
    };
  }

  String _money(String raw) =>
      MoneyFormatter(locale: localeName)
          .format(Money.paisa(int.tryParse(raw) ?? 0));

  String _roleName(String stored) {
    for (final r in Role.values) {
      if (r.name == stored) return roleLabel(r);
    }
    return stored;
  }

  /// `fundingSource` is `fund` or `member` (roadmap section 3.4).
  String _fundingName(String stored) => switch (stored) {
    'fund' => bazarFundingFund,
    'member' => bazarFundingMember,
    _ => stored,
  };

  /// `AdvanceStatus` values from roadmap section 3.6.
  String _advanceStatus(String stored) => switch (stored) {
    'pending' => bazarAdvancePending,
    'partial' => bazarAdvancePartial,
    'settled' => bazarAdvanceSettled,
    'voided' => bazarAdvanceVoided,
    _ => stored,
  };
}
