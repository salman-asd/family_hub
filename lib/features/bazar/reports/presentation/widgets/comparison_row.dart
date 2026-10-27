import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/reports/domain/period_comparison.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Up ৳400 (+50 %) against last month".
///
/// Direction is an icon + a word + a colour, never colour alone (rule 13), and
/// a period with no previous spending shows the amount without a percentage
/// (`deltaBp == null`).
class ComparisonRow extends ConsumerWidget {
  const ComparisonRow({
    required this.comparison,
    required this.previousLabel,
    super.key,
  });

  final PeriodComparison comparison;

  /// Already-localized name of the earlier period ("last month", "last week").
  final String previousLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final style = Theme.of(context).textTheme;
    final formatters = ref.watch(appFormattersProvider);
    String money(Money value) =>
        formatters.money(value, hideZeroFraction: true);
    final (icon, word, color) = comparison.isFlat
        ? (Icons.remove_circle_outline, l10n.reportFlat, t.textSecondary)
        : comparison.isUp
        ? (Icons.trending_up, l10n.reportUp, t.statusOverdueOn)
        : (Icons.trending_down, l10n.reportDown, t.statusCompletedOn);

    final percent = comparison.deltaBp;
    final percentText = percent == null
        ? l10n.reportNoPreviousData
        : l10n.reportPercent('${(percent / 100).abs().toStringAsFixed(0)}');

    return AppCard(
      child: Semantics(
        container: true,
        label: l10n.reportComparisonSemantics(
          word,
          money(comparison.delta.abs()),
          percentText,
          previousLabel,
        ),
        excludeSemantics: true,
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$word ',
                        style: style.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      MoneyText(
                        key: const ValueKey('report-delta'),
                        value: comparison.delta.abs(),
                        hideZeroFraction: true,
                        style: style.bodyMedium,
                      ),
                      Text(' $percentText', style: style.bodyMedium),
                    ],
                  ),
                  Text(
                    l10n.reportComparedWith(previousLabel),
                    style: style.bodySmall?.copyWith(color: t.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.reportPrevious,
                  style: style.bodySmall?.copyWith(color: t.textSecondary),
                ),
                MoneyText(
                  key: const ValueKey('report-previous'),
                  value: comparison.previous,
                  hideZeroFraction: true,
                  style: style.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
