import 'package:family_hub/features/bazar/presentation/widgets/dashboard/bazar_month_card.dart';
import 'package:family_hub/features/bazar/presentation/widgets/dashboard/budget_alert_card.dart';
import 'package:family_hub/features/bazar/presentation/widgets/dashboard/fund_balance_card.dart';
import 'package:flutter/material.dart';

List<WidgetBuilder> get bazarDashboardCards => <WidgetBuilder>[
  (_) => const BazarMonthCard(),
  (_) => const FundBalanceCard(),
  (_) => const BudgetAlertCard(),
];
