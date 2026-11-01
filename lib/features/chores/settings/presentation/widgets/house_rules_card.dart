import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/mini_markdown_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The family's house rules, READ-ONLY, for everybody (P3-17).
///
/// Shown on the Manage hub. It draws nothing while no rules are written, so an
/// empty family does not see an empty box. Editing is only on the settings
/// page, behind `manageChoreTemplates`.
class HouseRulesCard extends ConsumerWidget {
  const HouseRulesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(choreSettingsProvider.select((s) => s.houseRules));
    if (rules.trim().isEmpty) return const SizedBox.shrink();
    final t = context.tokens;
    return AppCard(
      key: const ValueKey<String>('house_rules_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rule_folder_outlined, color: t.accentStrong),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.choresSettingsHouseRulesTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: t.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MiniMarkdownView(markdown: rules, selectable: true),
        ],
      ),
    );
  }
}
