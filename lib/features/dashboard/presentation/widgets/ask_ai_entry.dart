import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/dashboard_card_frame.dart';
import 'package:flutter/material.dart';

class AskAiEntry extends StatelessWidget {
  const AskAiEntry({super.key});

  @override
  Widget build(BuildContext context) => DashboardCardFrame(
    title: context.l10n.dashboardAskAiTitle,
    icon: Icons.auto_awesome_outlined,
    child: Text(context.l10n.dashboardAskAiMessage),
  );
}
