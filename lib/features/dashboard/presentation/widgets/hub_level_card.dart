import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/dashboard_card_frame.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HubLevelCard extends StatelessWidget {
  const HubLevelCard({super.key});

  @override
  Widget build(BuildContext context) => DashboardCardFrame(
    title: context.l10n.dashboardHubLevelTitle,
    icon: Icons.eco_outlined,
    onTap: () => context.go(AppRoutes.chores),
    child: Text(context.l10n.dashboardHubLevelComingSoon),
  );
}
