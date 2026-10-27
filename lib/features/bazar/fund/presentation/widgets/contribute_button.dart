import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/contributions/presentation/controllers/contribution_form_state.dart';
import 'package:family_hub/features/bazar/contributions/presentation/widgets/record_contribution_sheet.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Add contribution" for a manager, "Request contribution" for a member.
///
/// In a closed month the button still shows, but says why it cannot be used
/// (icon + label, never colour alone).
class ContributeButton extends ConsumerWidget {
  const ContributeButton({required this.month, super.key});

  final MonthKey month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canRecord = ref.can(Permission.recordContribution);
    final locked = ref.watch(monthLockedProvider(month));

    if (locked) {
      return FloatingActionButton.extended(
        key: const ValueKey('fund-add-contribution'),
        onPressed: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.bazarErrMonthLocked))),
        icon: const Icon(Icons.lock_outline),
        label: Text(l10n.fundContributionLocked),
      );
    }
    return FloatingActionButton.extended(
      key: const ValueKey('fund-add-contribution'),
      onPressed: () => showContributionSheet(
        context,
        canRecord
            ? ContributionFormMode.record
            : ContributionFormMode.request,
        month: month,
      ),
      icon: const Icon(Icons.add),
      label: Text(
        canRecord ? l10n.fundAddContribution : l10n.fundRequestContribution,
      ),
    );
  }
}
