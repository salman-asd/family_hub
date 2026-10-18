import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';

/// Placeholder for the Bazar tab until Phase 2 (expense list, Step 15).
class BazarPlaceholderScreen extends StatelessWidget {
  const BazarPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navBazar)),
      body: EmptyState(
        icon: Icons.shopping_basket_outlined,
        title: l10n.moduleComingSoonTitle,
        message: l10n.moduleComingSoonMessage,
      ),
    );
  }
}
