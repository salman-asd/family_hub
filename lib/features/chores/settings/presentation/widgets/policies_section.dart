import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Policies & rules section of the chore settings screen (P3-17).
///
/// Edits: absence policy (A/B/C), swaps enabled + expiry buffer,
/// absence needs approval, workload visible to members, and (admin only)
/// members can complete for others.
///
/// The "members can complete for others" flag lives in `settings/permissions`,
/// not `settings/chores`. It is exposed read-only from [permissionSettingsProvider]
/// and its toggle is forwarded via [onCompleteForOthersChanged] so the parent
/// can batch it in a separate [UpdatePermissionSettings] call on save.
class PoliciesSection extends ConsumerWidget {
  const PoliciesSection({
    required this.draft,
    required this.policy,
    required this.membersCanCompleteForOthers,
    required this.onSettingsChanged,
    required this.onPolicyChanged,
    required this.onCompleteForOthersChanged,
    super.key,
  });

  final ChoreSettings draft;
  final AbsencePolicy policy;

  /// Current value of `settings/permissions.membersCanCompleteForOthers`.
  final bool membersCanCompleteForOthers;

  final ValueChanged<ChoreSettings> onSettingsChanged;
  final ValueChanged<AbsencePolicy> onPolicyChanged;

  /// Called when the admin toggles "members can complete for others".
  /// The parent keeps the new value in its own state and saves it separately.
  final ValueChanged<bool> onCompleteForOthersChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    final isAdmin = ref.can(Permission.manageFamilySettings);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Absence policy ─────────────────────────────────────────────
          Text(
            l10n.choresSettingsAbsencePolicyTitle,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          _AbsencePolicyCards(
            selected: policy,
            onChanged: onPolicyChanged,
          ),
          const SizedBox(height: 16),

          // ── Swaps enabled ──────────────────────────────────────────────
          SwitchListTile(
            key: const ValueKey('swaps-enabled'),
            value: draft.swapsEnabled,
            title: Text(l10n.choresSettingsSwapsEnabled),
            subtitle: Text(l10n.choresSettingsSwapsEnabledSubtitle),
            contentPadding: EdgeInsets.zero,
            onChanged: (v) =>
                onSettingsChanged(draft.copyWith(swapsEnabled: v)),
          ),

          // ── Swap expiry buffer (only when swaps enabled) ───────────────
          if (draft.swapsEnabled) ...[
            Text(
              l10n.choresSettingsSwapBuffer(
                formatters.number(draft.swapExpiryBufferMinutes),
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              l10n.choresSettingsSwapBufferSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Slider(
              key: const ValueKey('swap-buffer-slider'),
              value: draft.swapExpiryBufferMinutes.toDouble(),
              min: 0,
              max: ChoreSettingsLimits.maxSwapExpiryBufferMinutes.toDouble(),
              divisions: ChoreSettingsLimits.maxSwapExpiryBufferMinutes ~/ 15,
              label: formatters.number(draft.swapExpiryBufferMinutes),
              onChanged: (v) => onSettingsChanged(
                draft.copyWith(swapExpiryBufferMinutes: v.round()),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Absence needs approval ─────────────────────────────────────
          SwitchListTile(
            key: const ValueKey('absence-approval'),
            value: draft.absenceNeedsApproval,
            title: Text(l10n.choresSettingsAbsenceApproval),
            subtitle: Text(l10n.choresSettingsAbsenceApprovalSubtitle),
            contentPadding: EdgeInsets.zero,
            onChanged: (v) =>
                onSettingsChanged(draft.copyWith(absenceNeedsApproval: v)),
          ),

          // ── Workload visible to members ────────────────────────────────
          SwitchListTile(
            key: const ValueKey('workload-visible'),
            value: draft.workloadVisibleToMembers,
            title: Text(l10n.choresSettingsWorkloadVisible),
            subtitle: Text(l10n.choresSettingsWorkloadVisibleSubtitle),
            contentPadding: EdgeInsets.zero,
            onChanged: (v) =>
                onSettingsChanged(draft.copyWith(workloadVisibleToMembers: v)),
          ),

          // ── Members can complete for others (admin only) ───────────────
          PermissionGate(
            allowed: isAdmin,
            mode: PermissionGateMode.hide,
            deniedMessage: '',
            child: SwitchListTile(
              key: const ValueKey('complete-for-others'),
              value: membersCanCompleteForOthers,
              title: Text(l10n.choresSettingsCompleteForOthers),
              subtitle: Text(l10n.choresSettingsCompleteForOthersSubtitle),
              contentPadding: EdgeInsets.zero,
              onChanged: onCompleteForOthersChanged,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Three explanatory radio cards for the absence policy (road map §Contents).
class _AbsencePolicyCards extends StatelessWidget {
  const _AbsencePolicyCards({
    required this.selected,
    required this.onChanged,
  });

  final AbsencePolicy selected;
  final ValueChanged<AbsencePolicy> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        _PolicyCard(
          key: const ValueKey('policy-ask-cover'),
          policy: AbsencePolicy.askCover,
          selected: selected,
          title: l10n.choresPolicyAskCoverTitle,
          description: l10n.choresPolicyAskCoverDesc,
          example: l10n.choresPolicyAskCoverExample,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        _PolicyCard(
          key: const ValueKey('policy-auto-cover'),
          policy: AbsencePolicy.autoCover,
          selected: selected,
          title: l10n.choresPolicyAutoCoverTitle,
          description: l10n.choresPolicyAutoCoverDesc,
          example: l10n.choresPolicyAutoCoverExample,
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        _PolicyCard(
          key: const ValueKey('policy-skip'),
          policy: AbsencePolicy.skip,
          selected: selected,
          title: l10n.choresPolicySkipTitle,
          description: l10n.choresPolicySkipDesc,
          example: l10n.choresPolicySkipExample,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.policy,
    required this.selected,
    required this.title,
    required this.description,
    required this.example,
    required this.onChanged,
    super.key,
  });

  final AbsencePolicy policy;
  final AbsencePolicy selected;
  final String title;
  final String description;
  final String example;
  final ValueChanged<AbsencePolicy> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = policy == selected;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged(policy),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? scheme.primaryContainer.withValues(alpha: 0.25)
              : null,
        ),
        child: ListTile(
          leading: Radio<AbsencePolicy>(
            value: policy,
            groupValue: selected,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description),
              const SizedBox(height: 4),
              Text(
                example,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
          isThreeLine: true,
        ),
      ),
    );
  }
}
