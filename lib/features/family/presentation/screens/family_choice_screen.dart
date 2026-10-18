import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `/family-choice`: create a new family or join one with a code.
class FamilyChoiceScreen extends ConsumerWidget {
  const FamilyChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: EmptyState(
                icon: Icons.groups_outlined,
                title: l10n.familyChoiceTitle,
                message: l10n.familyChoiceMessage,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      key: const Key('choice_create'),
                      onPressed: () => context.push(AppRoutes.createFamily),
                      child: Text(l10n.familyCreateAction),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      key: const Key('choice_join'),
                      onPressed: () => context.push(AppRoutes.joinFamily),
                      child: Text(l10n.familyJoinAction),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => ref.read(signOutProvider).call(),
              child: Text(l10n.authSignOut),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
