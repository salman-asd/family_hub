import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/cover_counter.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:family_hub/shared/widgets/error_view.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HelpersHighlight extends ConsumerWidget {
  const HelpersHighlight({required this.month, super.key});

  final MonthKey month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyId = ref.watch(currentFamilyIdProvider);
    if (familyId == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final settings = ref.watch(engagementSettingsProvider(familyId));
    if (!settings.hasValue && settings.isLoading) {
      return const LoadingView(lines: 1);
    }
    if (!settings.hasValue && settings.hasError) {
      return ErrorView(
        message: l10n.errorNetwork,
        onRetry: () => ref.invalidate(engagementSettingsProvider(familyId)),
      );
    }
    final config = settings.requireValue;
    if (!config.enabled || !config.showHelpersHighlight) {
      return const SizedBox.shrink();
    }

    final monthData = ref.watch(monthOccurrencesProvider(month));
    final members = ref.watch(membersProvider);
    if (!monthData.hasValue && monthData.isLoading ||
        !members.hasValue && members.isLoading) {
      return const LoadingView(lines: 1);
    }
    if (!monthData.hasValue && monthData.hasError) {
      return ErrorView(
        message: l10n.errorNetwork,
        onRetry: () => ref.invalidate(monthOccurrencesProvider(month)),
      );
    }
    if (!members.hasValue && members.hasError) {
      return ErrorView(
        message: l10n.errorNetwork,
        onRetry: () => ref.invalidate(membersProvider),
      );
    }

    final counts = CoverCounter.count(monthData.requireValue.items, month);
    final active = members.requireValue.where((member) => member.isActive);
    final helpers =
        [
          for (final member in active)
            if ((counts[member.uid] ?? 0) > 0) (member, counts[member.uid]!),
        ]..sort(
          (a, b) => a.$1.displayName.toLowerCase().compareTo(
            b.$1.displayName.toLowerCase(),
          ),
        );
    if (helpers.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.engagementHelpersTitle,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: context.tokens.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (member, count) in helpers)
                  Semantics(
                    excludeSemantics: true,
                    label:
                        '${member.displayName}, '
                        '${l10n.engagementHelpersCount(ref.read(appFormattersProvider).number(count))}',
                    child: Chip(
                      avatar: AppAvatar(
                        id: member.uid,
                        name: member.displayName,
                        avatarKey: member.avatarKey,
                        size: 32,
                      ),
                      label: Text(
                        '${member.displayName} · '
                        '${ref.read(appFormattersProvider).number(count)}',
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
