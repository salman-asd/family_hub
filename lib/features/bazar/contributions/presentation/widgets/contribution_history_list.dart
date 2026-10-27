import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/presentation/widgets/pending_approvals_section.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One member's contributions of a month, newest first.
///
/// The status is icon + label + colour (never colour alone).  A manager can
/// void an approved row (a compensating ledger row, never an edit); the owner
/// sees the reject reason on their own row.
class ContributionHistoryList extends ConsumerWidget {
  const ContributionHistoryList({
    required this.rows,
    required this.onVoid,
    super.key,
  });

  final List<Contribution> rows;
  final void Function(Contribution row) onVoid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final style = Theme.of(context).textTheme;
    final canRecord = ref.can(Permission.recordContribution);
    final myId = ref.watch(currentUidProvider);

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(_icon(row), size: 18, color: t.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          MoneyText(
                            value: row.amount,
                            hideZeroFraction: true,
                            style: style.bodyLarge,
                          ),
                          Text(
                            _status(l10n, row),
                            style: style.bodySmall?.copyWith(
                              color: t.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${row.dateKey} · '
                        '${contributionMethodLabel(l10n, row.method)}',
                        style: style.bodySmall?.copyWith(color: t.textSecondary),
                      ),
                      if (row.status == ContributionApproval.rejected &&
                          row.memberId == myId &&
                          row.rejectReason != null)
                        Text(
                          l10n.fundRejectedReason(row.rejectReason!),
                          style: style.bodySmall?.copyWith(color: t.danger),
                        ),
                    ],
                  ),
                ),
                if (canRecord && row.isApproved)
                  IconButton(
                    key: ValueKey('void-${row.id}'),
                    tooltip: l10n.fundVoid,
                    icon: const Icon(Icons.block_outlined),
                    onPressed: () => onVoid(row),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static IconData _icon(Contribution row) {
    if (row.isVoided) return Icons.block_outlined;
    return switch (row.status) {
      ContributionApproval.pending => Icons.schedule_rounded,
      ContributionApproval.approved => Icons.check_circle_outline_rounded,
      ContributionApproval.rejected => Icons.cancel_outlined,
    };
  }

  static String _status(AppLocalizations l10n, Contribution row) {
    if (row.isVoided) return l10n.fundStatusVoided;
    return switch (row.status) {
      ContributionApproval.pending => l10n.fundStatusPending,
      ContributionApproval.approved => l10n.fundStatusApproved,
      ContributionApproval.rejected => l10n.fundStatusRejected,
    };
  }
}
