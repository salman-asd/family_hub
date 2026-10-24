import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/features/bazar/expenses/presentation/screens/add_expense_screen.dart';
import 'package:family_hub/features/bazar/expenses/presentation/screens/bazar_trip_screen.dart';
import 'package:family_hub/features/bazar/expenses/presentation/screens/expense_detail_screen.dart';
import 'package:family_hub/features/bazar/expenses/presentation/screens/expense_list_screen.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/screens/catalog_manager_screen.dart';
import 'package:family_hub/features/bazar/presentation/bazar_home_screen.dart';
import 'package:family_hub/features/bazar/settings/presentation/screens/bazar_settings_screen.dart';
import 'package:family_hub/modules/family_module.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The Bazar module.  The module switch is the gate, so
/// `requiredPermission` stays `null`.
class BazarModule extends FamilyModule {
  const BazarModule();

  @override
  String get id => 'bazar';

  @override
  String get nameBn => 'বাজার';

  @override
  String get nameEn => 'Bazar';

  @override
  String label(AppLocalizations l10n) => l10n.navBazar;

  @override
  IconData get icon => Icons.shopping_basket_outlined;

  @override
  IconData get selectedIcon => Icons.shopping_basket_rounded;

  @override
  String get basePath => AppRoutes.bazar;

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: AppRoutes.bazar,
      builder: (context, state) => const BazarHomeScreen(),
      routes: [
        // Declared before `expenses/:id`, which would otherwise match "new".
        GoRoute(
          path: 'expenses/new',
          builder: (context, state) => const AddExpenseScreen(),
        ),
        GoRoute(
          path: 'expenses',
          builder: (context, state) => const ExpenseListScreen(),
        ),
        GoRoute(
          path: 'expenses/:id',
          builder: (context, state) =>
              ExpenseDetailScreen(expenseId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => AddExpenseScreen(
                editingId: state.pathParameters['id'],
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'trip/new',
          builder: (context, state) => const BazarTripScreen(),
        ),
        GoRoute(
          path: 'catalog',
          builder: (context, state) => const CatalogManagerScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const BazarSettingsScreen(),
        ),
      ],
    ),
  ];
}
