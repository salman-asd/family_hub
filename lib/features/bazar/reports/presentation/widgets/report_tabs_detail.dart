import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/reports/domain/report_data.dart';
import 'package:family_hub/features/bazar/reports/presentation/widgets/day_chart.dart';
import 'package:family_hub/features/bazar/reports/presentation/widgets/report_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Days: the bar chart and every day's value (zero days included).
class DaysTab extends StatelessWidget {
  const DaysTab({required this.data, super.key});

  final ReportData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      key: const ValueKey('report-tab-days'),
      padding: const EdgeInsets.all(16),
      children: [
        DayChart(days: data.days),
        const SizedBox(height: 12),
        ReportTable(
          rows: <ReportRow>[
            for (final day in data.days)
              ReportRow(
                key: day.day.toString(),
                label: '${day.day.day}/${day.day.month}/${day.day.year}',
                amount: day.total,
              ),
          ],
          emptyLabel: l10n.chartNoData,
          nameHeader: l10n.reportDayColumn,
          amountHeader: l10n.reportAmount,
          totalLabel: l10n.reportTotal,
        ),
      ],
    );
  }
}

/// Members: "who spent" per member.
class MembersTab extends StatelessWidget {
  const MembersTab({
    required this.data,
    required this.memberNames,
    super.key,
  });

  final ReportData data;

  /// uid -> display name; an unknown uid falls back to itself.
  final Map<String, String> memberNames;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      key: const ValueKey('report-tab-members'),
      padding: const EdgeInsets.all(16),
      children: [
        ReportTable(
          rows: <ReportRow>[
            for (final member in data.members)
              ReportRow(
                key: member.memberId,
                label: memberNames[member.memberId] ?? member.memberId,
                amount: member.total,
              ),
          ],
          emptyLabel: l10n.chartNoData,
          nameHeader: l10n.reportMemberColumn,
          amountHeader: l10n.reportAmount,
          totalLabel: l10n.reportTotal,
        ),
      ],
    );
  }
}

/// Dry groceries: the plan against the actual spend, then line by line.
class DryGroceriesTab extends ConsumerWidget {
  const DryGroceriesTab({required this.data, super.key});

  final ReportData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    String money(Money value) =>
        formatters.money(value, hideZeroFraction: true);
    final dry = data.dryGrocery;

    return ListView(
      key: const ValueKey('report-tab-dry'),
      padding: const EdgeInsets.all(16),
      children: [
        ReportTable(
          rows: <ReportRow>[
            ReportRow(
              key: 'estimate',
              label: l10n.reportDryEstimate,
              amount: dry.estimate,
            ),
            ReportRow(
              key: 'actual',
              label: l10n.reportDryActual,
              amount: dry.actual,
            ),
            ReportRow(
              key: 'delta',
              label: l10n.reportDryDelta,
              amount: dry.delta.abs(),
              trailing: dry.delta.isNegative
                  ? l10n.reportUnder
                  : dry.delta.isZero
                  ? null
                  : l10n.reportOver,
            ),
          ],
          emptyLabel: l10n.reportDryEmpty,
          nameHeader: l10n.reportSummaryColumn,
          amountHeader: l10n.reportAmount,
        ),
        const SizedBox(height: 12),
        ReportTable(
          rows: <ReportRow>[
            for (final line in dry.lines)
              ReportRow(
                key: line.key,
                label: line.name,
                amount: line.actual,
                trailing: '${l10n.reportDryPlanned}: ${money(line.estimate)}',
              ),
          ],
          emptyLabel: l10n.reportDryEmpty,
          nameHeader: l10n.reportItemColumn,
          amountHeader: l10n.reportDryActual,
          totalLabel: l10n.reportTotal,
        ),
      ],
    );
  }
}
