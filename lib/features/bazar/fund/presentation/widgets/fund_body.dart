import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/contributions/presentation/contribution_providers.dart';
import 'package:family_hub/features/bazar/contributions/presentation/widgets/member_contribution_row.dart';
import 'package:family_hub/features/bazar/contributions/presentation/widgets/pending_approvals_section.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/form_banner.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_balance_calculator.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/bazar/fund/presentation/widgets/fund_balance_card.dart';
import 'package:family_hub/features/bazar/fund/presentation/widgets/fund_history_list.dart';
import 'package:family_hub/features/bazar/fund/presentation/widgets/member_actions_button.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:family_hub/shared/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Fund screen's scrollable content: balance card, banners, per-member
/// rows, the manager tools and the month's ledger.
class FundBody extends ConsumerWidget {
  const FundBody({
    required this.month,
    required this.canRecord,
    this.focusPendingApprovals = false,
    super.key,
  });

  final MonthKey month;
  final bool canRecord;
  final bool focusPendingApprovals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final window = ref.watch(fundTransactionsProvider);

    if (window.isLoading) return const LoadingView(lines: 5);
    if (window.hasError) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: l10n.errorNetwork,
        actionLabel: l10n.actionRetry,
        onAction: () => ref.invalidate(fundTransactionsProvider),
      );
    }

    final closing = ref.watch(monthClosingMapProvider)[month];
    final locked = closing?.status == MonthStatus.closed;
    final summary = ref.watch(fundSummaryProvider);
    final history = <FundTransaction>[
      ...ref.watch(monthFundTransactionsProvider(month)),
    ]..sort(_newestFirst);
    final issues = canRecord ? ref.watch(ledgerIntegrityProvider(month)) : null;
    final drift = canRecord ? ref.watch(balanceDriftProvider) : null;
    final members = ref.watch(membersProvider).value ?? const <Member>[];
    final statuses = ref.watch(contributionStatusProvider(month));
    final contributions =
        ref.watch(contributionsProvider(month)).value ?? const [];
    final myId = ref.watch(currentUidProvider);

    return ListView(
      key: const ValueKey('fund-body'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        FundBalanceCard(
          summary: summary,
          closedLabel: locked ? _closedLabel(context, ref, closing!) : null,
        ),
        const SizedBox(height: 8),
        if (locked)
          FormBanner(
            icon: Icons.lock_outline,
            text: l10n.fundMonthClosedNotice,
            color: t.textSecondary,
          ),
        if (ref.watch(fundWindowOverflowProvider))
          FormBanner(
            icon: Icons.warning_amber_rounded,
            text: l10n.fundOverflowWarning,
            color: t.statusOverdueOn,
          ),
        if (drift != null)
          FormBanner(
            icon: Icons.warning_amber_rounded,
            text: l10n.fundDriftWarning,
            color: t.statusOverdueOn,
          ),
        if (issues != null && issues.isNotEmpty)
          FormBanner(
            icon: Icons.report_outlined,
            text: l10n.fundLedgerIssues(issues.length),
            color: t.statusOverdueOn,
          ),
        const SizedBox(height: 8),
        SectionHeader(title: l10n.fundMembersTitle),
        if (statuses.isEmpty)
          Text(l10n.fundNoMembers)
        else
          for (final status in statuses)
            MemberContributionRow(
              key: ValueKey('fund-member-${status.memberId}'),
              id: status.memberId,
              name: _nameOf(members, status.memberId),
              avatarKey: _avatarOf(members, status.memberId),
              status: status,
              trailing: MemberActionsButton(
                memberId: status.memberId,
                month: month,
                myId: myId,
                canRecord: canRecord,
                contributions: contributions,
              ),
            ),
        if (canRecord) ...[
          const SizedBox(height: 12),
          PendingApprovalsSection(
            month: month,
            focusOnMount: focusPendingApprovals,
          ),
        ],
        const SizedBox(height: 16),
        SectionHeader(title: l10n.fundHistoryTitle),
        if (history.isEmpty)
          AppCard(child: Text(l10n.fundHistoryEmpty))
        else
          AppCard(child: FundHistoryList(rows: history)),
      ],
    );
  }

  static int _newestFirst(FundTransaction a, FundTransaction b) {
    final byDate = b.dateKey.compareTo(a.dateKey);
    return byDate != 0 ? byDate : b.id.compareTo(a.id);
  }

  static String _nameOf(List<Member> members, String uid) {
    for (final member in members) {
      if (member.uid == uid) return member.displayName;
    }
    return uid;
  }

  static String? _avatarOf(List<Member> members, String uid) {
    for (final member in members) {
      if (member.uid == uid) return member.avatarKey;
    }
    return null;
  }

  static String _closedLabel(
    BuildContext context,
    WidgetRef ref,
    MonthClosing closing,
  ) {
    final l10n = context.l10n;
    final closedAt = closing.closedAt;
    if (closedAt == null) return l10n.fundMonthClosedNotice;
    return l10n.fundClosedOn(
      ref.watch(appFormattersProvider).fullDate(closedAt.toLocal()),
    );
  }
}
