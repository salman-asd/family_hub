import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/reports/domain/report_data.dart';
import 'package:family_hub/features/bazar/reports/presentation/widgets/report_chart_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Spend per day as a bar chart (every day of the range, zero-filled).
///
/// Long ranges keep every day but the x labels are thinned out, so a year does
/// not turn into unreadable text; the table beneath has every value.
class DayChart extends ConsumerWidget {
  const DayChart({required this.days, super.key});

  final List<DayTotal> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    final total = Money.sum(days.map((d) => d.total));

    if (days.isEmpty || total.isZero) {
      return ReportChartEmpty(message: l10n.chartNoData);
    }

    final maxPaisa = days
        .map((d) => d.total.paisa)
        .reduce((a, b) => a > b ? a : b);
    // `FlGridData` rejects a zero interval (a single non-zero day x 4).
    final gridInterval = maxPaisa <= 0 ? 1.0 : maxPaisa / 4;
    final busiest = days.reduce((a, b) => a.total.paisa >= b.total.paisa ? a : b);
    final step = (days.length / 8).ceil().clamp(1, 366);

    return ReportChartCard(
      title: l10n.reportTabDays,
      semanticsLabel: l10n.chartDaySummary(
        formatters.fullDate(
          DateTime(busiest.day.year, busiest.day.month, busiest.day.day),
        ),
        formatters.money(busiest.total, hideZeroFraction: true),
      ),
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceBetween,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: gridInterval,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: t.chartGrid, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if (index < 0 || index >= days.length) {
                    return const SizedBox.shrink();
                  }
                  if (index % step != 0) return const SizedBox.shrink();
                  return Text(
                    '${days[index].day.day}',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                formatters.money(
                  days[group.x].total,
                  hideZeroFraction: true,
                ),
                Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
              ),
            ),
          ),
          barGroups: <BarChartGroupData>[
            for (var i = 0; i < days.length; i++)
              BarChartGroupData(
                x: i,
                barRods: <BarChartRodData>[
                  BarChartRodData(
                    toY: days[i].total.paisa.toDouble(),
                    width: days.length > 62 ? 2 : 6,
                    borderRadius: BorderRadius.circular(2),
                    color: t.chart[0],
                  ),
                ],
              ),
          ],
        ),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
      ),
    );
  }
}
