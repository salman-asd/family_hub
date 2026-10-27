import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_status.dart';
import 'package:family_hub/features/bazar/contributions/presentation/contribution_providers.dart';
import 'package:family_hub/features/bazar/reports/presentation/widgets/report_table.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contributions of the selected month, for everyone.
///
/// This is the one tab a member without `viewFamilyReports` keeps: every
/// active member may read contributions (D-P2-5).  The month comes from the
/// selected report range when that range is one whole month, else from the
/// current month.
class ContributionsTab extends ConsumerWidget {
  const ContributionsTab({
    required this.month,
    required this.memberNames,
    super.key,
  });

  final MonthKey month;
  final Map<String, String> memberNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statuses = ref.watch(contributionStatusProvider(month));
    final myId = ref.watch(currentUidProvider);

    final rows = <ReportRow>[
      for (final status in statuses)
        if (status.memberId == myId ||
            !status.received.isZero ||
            !status.expected.isZero)
          ReportRow(
            key: status.memberId,
            label: memberNames[status.memberId] ?? status.memberId,
            amount: status.received,
            trailing: '${l10n.reportExpected}: '
                '${_money(context, ref, status.expected)}',
          ),
    ];

    final expected = ContributionStatusCalculator.totalExpected(statuses);
    final received = ContributionStatusCalculator.totalReceived(statuses);

    return ListView(
      key: const ValueKey('report-tab-contributions'),
      padding: const EdgeInsets.all(16),
      children: [
        ReportTable(
          rows: rows,
          emptyLabel: l10n.fundHistoryEmpty,
          nameHeader: l10n.reportMemberColumn,
          amountHeader: l10n.fundReceived,
          totalLabel: l10n.reportTotal,
        ),
        const SizedBox(height: 12),
        ReportTable(
          rows: <ReportRow>[
            ReportRow(
              key: 'expected',
              label: l10n.monthCloseExpected,
              amount: expected,
            ),
            ReportRow(
              key: 'received',
              label: l10n.monthCloseReceived,
              amount: received,
            ),
            ReportRow(
              key: 'pending',
              label: l10n.fundPendingTitle,
              amount: Money.sum(statuses.map((s) => s.pendingTotal)),
            ),
          ],
          emptyLabel: l10n.fundHistoryEmpty,
          nameHeader: l10n.reportSummaryColumn,
          amountHeader: l10n.reportAmount,
        ),
      ],
    );
  }

  static String _money(BuildContext context, WidgetRef ref, Money value) {
    final formatters = ref.watch(appFormattersProvider);
    return formatters.money(value, hideZeroFraction: true);
  }
}

/// The month the contributions tab shows.
///
/// A range that is exactly one whole month uses that month; anything else uses
/// [fallback] (the current month), so the tab always has one bounded query.
MonthKey contributionMonthFor(DateKeyRange range, MonthKey fallback) {
  final start = range.start.monthKey;
  if (start != range.end.monthKey) return fallback;
  final wholeMonth =
      range.start.day == 1 && range.end.day == start.daysInMonth;
  return wholeMonth ? start : fallback;
}
