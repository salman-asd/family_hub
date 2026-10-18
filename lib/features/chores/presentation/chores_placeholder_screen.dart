import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// Placeholder for the Chores tab until Phase 3 (calendar, Step 26).
class ChoresPlaceholderScreen extends StatelessWidget {
  const ChoresPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navChores)),
      body: EmptyState(
        icon: Icons.checklist_rounded,
        title: l10n.moduleComingSoonTitle,
        message: l10n.moduleComingSoonMessage,
      ),
    );
  }
}
