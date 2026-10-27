import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permission.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

/// One tile on the Bazar home screen.
///
/// Later Phase 2 steps append an entry; the home screen renders this list and
/// hides a tile when the viewer lacks [requires] (H7, never a role test).
class BazarEntry {
  const BazarEntry({
    required this.id,
    required this.icon,
    required this.label,
    required this.route,
    this.requires,
  });

  /// Stable id, used by tests and analytics; never shown.
  final String id;

  final IconData icon;

  /// Localized label, resolved by the screen so no copy lives in this file.
  final String Function(AppLocalizations) label;

  /// Route inside [AppRoutes.bazar].
  final String route;

  /// Permission the viewer needs to see this tile; `null` = everybody.
  final Permission? requires;
}

/// The Bazar home tiles, in display order.  Every later Phase 2 step appends
/// one.  Tiles that change data are hidden from people who may not use them.
final List<BazarEntry> bazarEntries = <BazarEntry>[
  BazarEntry(
    id: 'expense-add',
    icon: Icons.add_circle_outline,
    label: (l10n) => l10n.expenseAddTitle,
    route: AppRoutes.bazarExpenseNew,
    requires: Permission.addOwnExpense,
  ),
  BazarEntry(
    id: 'trip-add',
    icon: Icons.shopping_cart_outlined,
    label: (l10n) => l10n.tripTitle,
    route: AppRoutes.bazarTripNew,
    requires: Permission.addOwnExpense,
  ),
  BazarEntry(
    id: 'expenses',
    icon: Icons.receipt_long_outlined,
    label: (l10n) => l10n.expenseListTitle,
    route: AppRoutes.bazarExpenses,
  ),
  BazarEntry(
    id: 'catalog',
    icon: Icons.inventory_2_outlined,
    label: (l10n) => l10n.catalogTitle,
    route: AppRoutes.bazarCatalog,
  ),
  BazarEntry(
    id: 'budget',
    icon: Icons.savings_outlined,
    label: (l10n) => l10n.budgetTitle,
    route: AppRoutes.bazarBudget,
  ),
  BazarEntry(
    id: 'fund',
    icon: Icons.account_balance_wallet_outlined,
    label: (l10n) => l10n.fundTitle,
    route: AppRoutes.bazarFund,
  ),
  BazarEntry(
    id: 'advances',
    icon: Icons.price_check_outlined,
    label: (l10n) => l10n.advanceTitle,
    route: AppRoutes.bazarAdvances,
  ),
  BazarEntry(
    id: 'month-close',
    icon: Icons.lock_clock_outlined,
    label: (l10n) => l10n.monthCloseTitle,
    route: AppRoutes.bazarMonthClose,
    requires: Permission.closeBazarMonth,
  ),
  BazarEntry(
    id: 'reports',
    icon: Icons.insights_outlined,
    label: (l10n) => l10n.reportTitle,
    route: AppRoutes.bazarReports,
  ),
  BazarEntry(
    id: 'settings',
    icon: Icons.tune_outlined,
    label: (l10n) => l10n.bazarSettingsTitle,
    route: AppRoutes.bazarSettings,
    requires: Permission.manageCatalogAndBudgets,
  ),
];
