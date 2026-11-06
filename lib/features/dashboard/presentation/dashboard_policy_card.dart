import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_access_preview.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_card_labels.dart';
import 'package:family_hub/shared/widgets/access_cell.dart';
import 'package:flutter/material.dart';

class DashboardPolicyCard extends StatelessWidget {
  const DashboardPolicyCard({
    required this.cardId,
    required this.policy,
    required this.settings,
    required this.busy,
    required this.onAccessChanged,
    super.key,
  });

  final String cardId;
  final DashboardPolicy policy;
  final PermissionSettings settings;
  final bool busy;
  final void Function(Role role, String cardId, CardAccess access)
  onAccessChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final card = CardCatalog.find(cardId);
    if (card == null) {
      // A saved policy can name a card the catalog no longer has (a module
      // was switched off); there is nothing to configure, so this row draws
      // nothing instead of taking the whole matrix down (P4-23).
      return const SizedBox.shrink();
    }
    final managerCanSee = DashboardAccessPreview.canRoleSeeCard(
      Role.moderator,
      card,
      settings,
    );
    final memberCanSee = DashboardAccessPreview.canRoleSeeCard(
      Role.member,
      card,
      settings,
    );
    const values = <CardAccess, AccessCellState>{
      CardAccess.hidden: AccessCellState.hidden,
      CardAccess.on: AccessCellState.on,
      CardAccess.off: AccessCellState.off,
      CardAccess.required: AccessCellState.requiredAccess,
    };
    final labels = <AccessCellState, String>{
      AccessCellState.hidden: l10n.dashboardAccessHidden,
      AccessCellState.on: l10n.dashboardAccessVisible,
      AccessCellState.off: l10n.dashboardAccessOff,
      AccessCellState.requiredAccess: l10n.dashboardRequired,
    };
    return Card(
      key: Key('dashboard_policy_$cardId'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dashboardCardTitle(l10n, cardId),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _roleRow(
              context,
              role: Role.moderator,
              roleLabel: l10n.roleModerator,
              access: policy.accessFor(Role.moderator, cardId),
              canSee: managerCanSee,
              labels: labels,
              values: values,
            ),
            const Divider(),
            _roleRow(
              context,
              role: Role.member,
              roleLabel: l10n.roleMember,
              access: policy.accessFor(Role.member, cardId),
              canSee: memberCanSee,
              labels: labels,
              values: values,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleRow(
    BuildContext context, {
    required Role role,
    required String roleLabel,
    required CardAccess access,
    required bool canSee,
    required Map<AccessCellState, String> labels,
    required Map<CardAccess, AccessCellState> values,
  }) => Row(
    children: [
      Expanded(child: Text(roleLabel)),
      Expanded(
        flex: 3,
        child: AccessCell(
          value: values[access]!,
          labels: labels,
          enabled: canSee && !busy,
          disabledReason: canSee
              ? null
              : context.l10n.dashboardCardPermissionMissing,
          onChanged: (state) =>
              onAccessChanged(role, cardId, _accessForCellState(state)),
        ),
      ),
    ],
  );

  CardAccess _accessForCellState(AccessCellState state) => switch (state) {
    AccessCellState.hidden => CardAccess.hidden,
    AccessCellState.on => CardAccess.on,
    AccessCellState.off => CardAccess.off,
    AccessCellState.requiredAccess => CardAccess.required,
  };
}
