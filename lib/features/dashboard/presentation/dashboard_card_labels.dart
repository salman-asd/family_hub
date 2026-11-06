import 'package:family_hub/core/localization/generated/app_localizations.dart';

String dashboardCardTitle(AppLocalizations l10n, String id) => switch (id) {
  'budget_alert' => l10n.dashboardCardBudgetAlert,
  'approvals' => l10n.dashboardCardApprovals,
  'chores_today' => l10n.dashboardCardChoresToday,
  'chores_overdue' => l10n.dashboardCardChoresOverdue,
  'chores_verify' => l10n.dashboardCardChoresVerify,
  'bazar_month' => l10n.dashboardCardBazarMonth,
  'bazar_fund' => l10n.dashboardCardBazarFund,
  'upcoming' => l10n.dashboardCardUpcoming,
  'chores_week' => l10n.dashboardCardChoresWeek,
  'hub_level' => l10n.dashboardCardHubLevel,
  'recent_activity' => l10n.dashboardCardRecentActivity,
  _ => id,
};
