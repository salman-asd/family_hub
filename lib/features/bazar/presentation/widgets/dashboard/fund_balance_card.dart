import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_status.dart';
import 'package:family_hub/features/bazar/contributions/presentation/contribution_providers.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FundBalanceCard extends ConsumerWidget {
  const FundBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final month = ref.watch(familyDateKeysProvider).thisMonth();
    final transactions = ref.watch(fundTransactionsProvider);
    final plans = ref.watch(contributionPlansProvider(month));
    final contributions = ref.watch(contributionsProvider(month));
    final members = ref.watch(membersProvider);
    final onTap = () => context.go(AppRoutes.bazarFund);

    return AppCard(
      key: const ValueKey('dashboard-fund-balance'),
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fundBalanceTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            ref.watch(appFormattersProvider).monthLabel(month),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (transactions.isLoading ||
              plans.isLoading ||
              contributions.isLoading ||
              members.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (transactions.hasError ||
              plans.hasError ||
              contributions.hasError ||
              members.hasError)
            _DashboardError(message: l10n.errorNetwork)
          else
            _FundSummary(
              balance: ref.watch(fundBalanceProvider),
              statuses: ref.watch(contributionStatusProvider(month)),
              canReview: ref.can(Permission.recordContribution),
              pendingCount:
                  ref.watch(pendingContributionsProvider(month)).length,
            ),
        ],
      ),
    );
  }
}

class _FundSummary extends ConsumerWidget {
  const _FundSummary({
    required this.balance,
    required this.statuses,
    required this.canReview,
    required this.pendingCount,
  });

  final Money balance;
  final List<MemberContributionStatus> statuses;
  final bool canReview;
  final int pendingCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    final received = ContributionStatusCalculator.totalReceived(statuses);
    final remaining = Money.sum(statuses.map((row) => row.remaining));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MoneyText(
          key: const ValueKey('dashboard-fund-value'),
          value: balance,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _AmountLabel(label: l10n.fundReceived, amount: received),
            Text(
              l10n.fundRemainingAmount(formatters.money(remaining)),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        if (canReview && pendingCount > 0) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            key: const ValueKey('dashboard-fund-pending'),
            onPressed: () => context.go(AppRoutes.bazarFundPending),
            icon: const Icon(Icons.pending_actions_outlined),
            label: Text(
              l10n.bazarDashboardPendingApprovals(
                formatters.number(pendingCount),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AmountLabel extends StatelessWidget {
  const _AmountLabel({required this.label, required this.amount});

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(
        '$label:',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: context.tokens.textSecondary,
        ),
      ),
      MoneyText(value: amount, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.cloud_off_outlined, color: context.tokens.danger),
      const SizedBox(width: 8),
      Expanded(child: Text(message)),
    ],
  );
}
