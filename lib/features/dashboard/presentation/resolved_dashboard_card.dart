import 'package:family_hub/features/dashboard/domain/dashboard_card_spec.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_resolver.dart';
import 'package:family_hub/modules/family_module.dart';

final class ResolvedDashboardCard {
  const ResolvedDashboardCard({required this.resolved, required this.spec});

  final ResolvedCard resolved;
  final DashboardCardSpec<DashboardCardBuilder> spec;
}
