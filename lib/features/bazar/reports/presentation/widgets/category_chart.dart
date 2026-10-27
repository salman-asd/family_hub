import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/reports/domain/period_comparison.dart';
import 'package:family_hub/features/bazar/reports/domain/report_data.dart';
import 'package:family_hub/features/bazar/reports/presentation/widgets/report_chart_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Spend per category as a pie, with an accessible text alternative.
///
/// Colours come only from `context.tokens.chart` (rule 22); the slices are
/// capped at the ten token colours and the rest is grouped into "other", so a
/// family with 40 categories still gets a readable, accessible chart.  The
/// table under it is the authoritative list.
class CategoryChart extends ConsumerWidget {
  const CategoryChart({
    required this.categories,
    required this.byCategory,
    super.key,
  });

  final List<CategoryTotal> categories;
  final Map<String, Category> byCategory;

  static const int maxSlices = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);
    String money(Money value) => formatters.money(value, hideZeroFraction: true);
    final bangla = Localizations.localeOf(context).languageCode == 'bn';

    final nonZero = <CategoryTotal>[
      for (final c in categories)
        if (!c.total.isZero) c,
    ];
    if (nonZero.isEmpty) {
      return ReportChartEmpty(message: l10n.chartNoData);
    }

    final shown = nonZero.take(maxSlices).toList();
    final hidden = nonZero.skip(maxSlices).toList();
    final hiddenTotal = Money.sum(hidden.map((c) => c.total));
    final labels = <String>[
      for (final c in shown)
        byCategory[c.categoryId]?.displayName(bangla: bangla) ?? c.categoryId,
      if (hidden.isNotEmpty) l10n.chartOther,
    ];
    final values = <Money>[
      for (final c in shown) c.total,
      if (hidden.isNotEmpty) hiddenTotal,
    ];

    final total = Money.sum(nonZero.map((c) => c.total));
    int percentOf(Money value) => total.isZero
        ? 0
        : (halfUpRatioBp(delta: value, base: total) / 100).round();

    final semantics = <String>[
      for (var i = 0; i < shown.length; i++)
        l10n.chartSlice(labels[i], money(values[i]), '${percentOf(values[i])}'),
      if (hidden.isNotEmpty)
        l10n.chartSlice(
          l10n.chartOther,
          money(hiddenTotal),
          '${percentOf(hiddenTotal)}',
        ),
    ].join(', ');

    return ReportChartCard(
      title: l10n.reportTabCategories,
      semanticsLabel: semantics,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: <PieChartSectionData>[
                  for (var i = 0; i < values.length; i++)
                    PieChartSectionData(
                      value: values[i].paisa.toDouble(),
                      color: t.chart[i % t.chart.length],
                      radius: 40,
                      showTitle: false,
                    ),
                ],
              ),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (var i = 0; i < labels.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: t.chart[i % t.chart.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
