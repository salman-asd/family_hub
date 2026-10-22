import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/features/chores/presentation/chores_placeholder_screen.dart';
import 'package:family_hub/modules/family_module.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The Chores module (stub: a placeholder screen until Phase 3).
class ChoresModule extends FamilyModule {
  const ChoresModule();

  @override
  String get id => 'chores';

  @override
  String get nameBn => 'কাজ';

  @override
  String get nameEn => 'Chores';

  @override
  String label(AppLocalizations l10n) => l10n.navChores;

  @override
  IconData get icon => Icons.checklist_rtl_rounded;

  @override
  IconData get selectedIcon => Icons.checklist_rounded;

  @override
  String get basePath => AppRoutes.chores;

  @override
  List<RouteBase> get routes => [
    GoRoute(
      path: AppRoutes.chores,
      builder: (context, state) => const ChoresPlaceholderScreen(),
    ),
  ];
}
