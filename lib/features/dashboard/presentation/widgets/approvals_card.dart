import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/bazar/contributions/presentation/contribution_providers.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/dashboard_card_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ApprovalsCard extends ConsumerWidget {
  const ApprovalsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canApproveMembers = ref.can(Permission.approveMembers);
    final canReviewContributions = ref.can(Permission.recordContribution);
    final month = ref.watch(familyDateKeysProvider).thisMonth();
    final members = canApproveMembers ? ref.watch(membersProvider) : null;
    final contributions = canReviewContributions
        ? ref.watch(contributionsProvider(month))
        : null;
    final l10n = context.l10n;
    final loading =
        (members != null && !members.hasValue && members.isLoading) ||
        (contributions != null &&
            !contributions.hasValue &&
            contributions.isLoading);
    final hasError =
        (members != null && !members.hasValue && members.hasError) ||
        (contributions != null &&
            !contributions.hasValue &&
            contributions.hasError);
    final pendingMembers =
        members?.value
            ?.where((member) => member.status == MembershipStatus.pending)
            .length ??
        0;
    final pendingContributions = canReviewContributions
        ? ref.watch(pendingContributionsProvider(month)).length
        : 0;

    return DashboardCardFrame(
      title: l10n.dashboardApprovalsTitle,
      icon: Icons.pending_actions_outlined,
      mode: loading
          ? DashboardCardMode.loading
          : hasError
          ? DashboardCardMode.error
          : DashboardCardMode.content,
      errorMessage: hasError ? l10n.errorNetwork : null,
      loadingLabel: l10n.loadingSemantics,
      onRetry: hasError
          ? () {
              if (canApproveMembers) ref.invalidate(membersProvider);
              if (canReviewContributions) {
                ref.invalidate(contributionsProvider(month));
              }
            }
          : null,
      onTap: canApproveMembers
          ? () => context.go(AppRoutes.familyMembers)
          : canReviewContributions
          ? () => context.go(AppRoutes.bazarFundPending)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canApproveMembers)
            _ApprovalCount(
              icon: Icons.group_add_outlined,
              text: l10n.dashboardPendingJoinRequests(
                ref.watch(appFormattersProvider).number(pendingMembers),
              ),
              onTap: () => context.go(AppRoutes.familyMembers),
            ),
          if (canReviewContributions)
            _ApprovalCount(
              icon: Icons.savings_outlined,
              text: l10n.dashboardPendingContributions(
                ref.watch(appFormattersProvider).number(pendingContributions),
              ),
              onTap: () => context.go(AppRoutes.bazarFundPending),
            ),
        ],
      ),
    );
  }
}

class _ApprovalCount extends StatelessWidget {
  const _ApprovalCount({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      TextButton.icon(onPressed: onTap, icon: Icon(icon), label: Text(text));
}
