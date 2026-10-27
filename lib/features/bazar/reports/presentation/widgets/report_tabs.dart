import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/reports/domain/report_data.dart';
import 'package:family_hub/features/bazar/reports/domain/report_query.dart';
import 'package:family_hub/features/bazar/reports/presentation/widgets/category_chart.dart';
import 'package:family_hub/features/bazar/reports/presentation/widgets/comparison_row.dart';

import 'package:family_hub/features/bazar/reports/presentation/widgets/report_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// `DaysTab`, `MembersTab` and `DryGroceriesTab` live in report_tabs_detail.dart
// (file-size cap); they are re-exported here so a screen imports one module.
export 'package:family_hub/features/bazar/reports/presentation/widgets/report_tabs_detail.dart';

/// Tabs of the reports screen, in display order.
///
/// `contributions` is the one tab a member without `viewFamilyReports` keeps:
/// contributions are visible to every active member (D-P2-5).
enum ReportTab {
  summary,
  categories,
  items,
  days,
  members,
  dryGroceries,
  contributions,
}

/// The calendar day a [DateKey] names, for `AppFormatters.fullDate`.
DateTime dateOf(DateKey key) => DateTime(key.year, key.month, key.day);

/// Localized tab name of a [ReportTab].
String tabLabel(AppLocalizations l10n, ReportTab tab) => switch (tab) {
  ReportTab.summary => l10n.reportTabSummary,
  ReportTab.categories => l10n.reportTabCategories,
  ReportTab.items => l10n.reportTabItems,
  ReportTab.days => l10n.reportTabDays,
  ReportTab.members => l10n.reportTabMembers,
  ReportTab.dryGroceries => l10n.reportTabDry,
  ReportTab.contributions => l10n.reportTabContributions,
};

/// "last month", "last week" ...: the period a comparison refers to.
String previousPeriodName(AppLocalizations l10n, RangePreset preset) =>
    switch (preset) {
      RangePreset.today || RangePreset.yesterday => l10n.reportPrevDay,
      RangePreset.last7Days || RangePreset.thisWeek => l10n.reportPrevWeek,
      RangePreset.thisMonth || RangePreset.lastMonth => l10n.reportPrevMonth,
      RangePreset.thisYear => l10n.reportPrevYear,
      RangePreset.custom => l10n.reportPrevRange,
    };



/// Summary: total, daily average, row count, range and the comparison.
class SummaryTab extends ConsumerWidget {
  const SummaryTab({
    required this.data,
    required this.query,
    super.key,
  });

  final ReportData data;
  final ReportQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    final summary = data.summary;

    return ListView(
      key: const ValueKey('report-tab-summary'),
      padding: const EdgeInsets.all(16),
      children: [
        ReportTable(
          rows: <ReportRow>[
            ReportRow(key: 'total', label: l10n.reportTotal, amount: summary.total),
            ReportRow(
              key: 'average',
              label: l10n.reportAveragePerDay,
              amount: summary.averagePerDay,
            ),
            ReportRow(
              key: 'count',
              label: l10n.reportRows,
              amount: Money.zero,
              trailing: '${summary.count}',
            ),
            ReportRow(
              key: 'range',
              label: l10n.reportRange,
              amount: Money.zero,
              trailing:
                  '${formatters.fullDate(dateOf(summary.range.start))}'
                  ' – ${formatters.fullDate(dateOf(summary.range.end))}',
            ),
          ],
          emptyLabel: l10n.chartNoData,
          nameHeader: l10n.reportSummaryColumn,
          amountHeader: l10n.reportAmount,
        ),
        if (data.comparison case final comparison?) ...[
          const SizedBox(height: 12),
          ComparisonRow(
            comparison: comparison,
            previousLabel: l10n.previousPeriodName(query.preset),
          ),
        ],
      ],
    );
  }
}

/// Categories: the pie chart and the per-category table.
class CategoriesTab extends StatelessWidget {
  const CategoriesTab({
    required this.data,
    required this.byCategory,
    super.key,
  });

  final ReportData data;
  final Map<String, Category> byCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    return ListView(
      key: const ValueKey('report-tab-categories'),
      padding: const EdgeInsets.all(16),
      children: [
        CategoryChart(categories: data.categories, byCategory: byCategory),
        const SizedBox(height: 12),
        ReportTable(
          rows: <ReportRow>[
            for (final c in data.categories)
              ReportRow(
                key: c.categoryId,
                label:
                    byCategory[c.categoryId]?.displayName(bangla: bangla) ??
                    c.categoryId,
                amount: c.total,
                trailing: c.shareBp == null
                    ? null
                    : l10n.reportPercent('${(c.shareBp! / 100).round()}'),
              ),
          ],
          emptyLabel: l10n.chartNoData,
          nameHeader: l10n.reportCategoryColumn,
          amountHeader: l10n.reportAmount,
          totalLabel: l10n.reportTotal,
        ),
      ],
    );
  }
}

/// Items: every item's total and how many times it was bought.
class ItemsTab extends StatelessWidget {
  const ItemsTab({required this.data, super.key});

  final ReportData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      key: const ValueKey('report-tab-items'),
      padding: const EdgeInsets.all(16),
      children: [
        ReportTable(
          rows: <ReportRow>[
            for (final item in data.items)
              ReportRow(
                key: item.key,
                label: item.name,
                amount: item.total,
                trailing: '×${item.count}',
              ),
          ],
          emptyLabel: l10n.chartNoData,
          nameHeader: l10n.reportItemColumn,
          amountHeader: l10n.reportAmount,
          totalLabel: l10n.reportTotal,
        ),
      ],
    );
  }
}




