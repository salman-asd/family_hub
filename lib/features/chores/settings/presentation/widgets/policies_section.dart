import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/chores/settings/presentation/widgets/absence_policy_cards.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Policies and rules (P3-17): the absence policy (A/B/C), swaps and their
/// expiry buffer, whether an absence needs approval, whether members may open
/// the workload board, and (admin only) whether members may complete chores
/// for each other.
///
/// The absence policy and the admin switch live in other documents than
/// `settings/chores`, so they come in as separate values with their own
/// callbacks; the controller saves each one through its own use case.
class PoliciesSection extends ConsumerWidget {
  const PoliciesSection({
    required this.draft,
    required this.policy,
    required this.completeForOthers,
    required this.onSettingsChanged,
    required this.onPolicyChanged,
    required this.onCompleteForOthersChanged,
    super.key,
  });

  final ChoreSettings draft;
  final AbsencePolicy policy;
  final bool completeForOthers;
  final ValueChanged<ChoreSettings> onSettingsChanged;
  final ValueChanged<AbsencePolicy> onPolicyChanged;
  final ValueChanged<bool> onCompleteForOthersChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    final isAdmin = ref.can(Permission.editFamilySettings);
    final hint = Theme.of(context).textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.choresSettingsAbsencePolicyTitle,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        AbsencePolicyCards(selected: policy, onChanged: onPolicyChanged),
        const SizedBox(height: 8),
        SwitchListTile(
          key: const ValueKey<String>('swaps_enabled'),
          contentPadding: EdgeInsets.zero,
          value: draft.swapsEnabled,
          title: Text(l10n.choresSettingsSwapsEnabled),
          subtitle: Text(l10n.choresSettingsSwapsEnabledSubtitle),
          onChanged: (v) => onSettingsChanged(draft.copyWith(swapsEnabled: v)),
        ),
        if (draft.swapsEnabled) ...[
          Text(
            l10n.choresSettingsSwapBuffer(
              formatters.number(draft.swapExpiryBufferMinutes),
            ),
          ),
          Text(l10n.choresSettingsSwapBufferSubtitle, style: hint),
          Slider(
            key: const ValueKey<String>('swap_buffer'),
            value: draft.swapExpiryBufferMinutes.toDouble(),
            max: ChoreSettingsLimits.maxSwapExpiryBufferMinutes.toDouble(),
            divisions: ChoreSettingsLimits.maxSwapExpiryBufferMinutes ~/ 15,
            label: formatters.number(draft.swapExpiryBufferMinutes),
            onChanged: (v) => onSettingsChanged(
              draft.copyWith(swapExpiryBufferMinutes: v.round()),
            ),
          ),
        ],
        SwitchListTile(
          key: const ValueKey<String>('absence_approval'),
          contentPadding: EdgeInsets.zero,
          value: draft.absenceNeedsApproval,
          title: Text(l10n.choresSettingsAbsenceApproval),
          subtitle: Text(l10n.choresSettingsAbsenceApprovalSubtitle),
          onChanged: (v) =>
              onSettingsChanged(draft.copyWith(absenceNeedsApproval: v)),
        ),
        SwitchListTile(
          key: const ValueKey<String>('workload_visible'),
          contentPadding: EdgeInsets.zero,
          value: draft.workloadVisibleToMembers,
          title: Text(l10n.choresSettingsWorkloadVisible),
          subtitle: Text(l10n.choresSettingsWorkloadVisibleSubtitle),
          onChanged: (v) =>
              onSettingsChanged(draft.copyWith(workloadVisibleToMembers: v)),
        ),
        // Admin only (hidden, not disabled, for everybody else).
        PermissionGate(
          allowed: isAdmin,
          child: SwitchListTile(
            key: const ValueKey<String>('complete_for_others'),
            contentPadding: EdgeInsets.zero,
            value: completeForOthers,
            title: Text(l10n.choresSettingsCompleteForOthers),
            subtitle: Text(l10n.choresSettingsCompleteForOthersSubtitle),
            onChanged: onCompleteForOthersChanged,
          ),
        ),
      ],
    );
  }
}
