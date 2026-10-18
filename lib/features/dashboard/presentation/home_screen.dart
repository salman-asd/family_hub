import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder for the Home tab; the real dashboard arrives in Step 27.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final flavor = ref.watch(flavorProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: Column(
        children: [
          Expanded(
            child: EmptyState(
              icon: Icons.home_rounded,
              title: l10n.moduleComingSoonTitle,
              message: l10n.moduleComingSoonMessage,
            ),
          ),
          // Flavor marker kept from Step 1 so a build is identifiable.
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              flavor.name,
              key: const Key('flavor_name'),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: t.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
