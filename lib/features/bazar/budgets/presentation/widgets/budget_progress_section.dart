import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_status.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/category_badge.dart';
import 'package:family_hub/shared/widgets/progress_bar_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

ProgressLevel _levelOf(BudgetLevel level) => switch (level) {
  BudgetLevel.noLimit || BudgetLevel.ok => ProgressLevel.ok,
  BudgetLevel.warning => ProgressLevel.warning,
  BudgetLevel.exceeded => ProgressLevel.exceeded,
};

/// "৳450 left" / "৳120 over"; nothing when there is no limit.
String? _remainingText(
  AppLocalizations l10n,
  String Function(Money) money,
  CategoryBudgetStatus status,
) {
  if (status.level == BudgetLevel.noLimit) return null;
  return status.remaining.isNegative
      ? l10n.budgetOver(money(-status.remaining))
      : l10n.budgetLeft(money(status.remaining));
}

/// The whole-month bar and one bar per category.  Status is always icon +
/// word + colour (inside [ProgressBarStatus]).  Categories that have neither
/// an estimate nor any spend are left out.
class BudgetProgressSection extends ConsumerWidget {
  const BudgetProgressSection({
    required this.report,
    required this.categories,
    super.key,
  });

  final BudgetStatusReport report;

  /// Active categories in catalog order.
  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    String money(Money m) => formatters.money(m, hideZeroFraction: true);
    final bangla = Localizations.localeOf(context).languageCode == 'bn';

    final rows = <Widget>[
      for (final category in categories)
        if (report.byCategory[category.id] case final status?)
          if (status.level != BudgetLevel.noLimit || !status.spent.isZero)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryBadge(
                    name: category.displayName(bangla: bangla),
                    colorIndex: category.colorIndex,
                    emoji: category.emoji,
                    compact: true,
                  ),
                  const SizedBox(height: 6),
                  ProgressBarStatus(
                    key: ValueKey('budget-bar-${category.id}'),
                    basisPoints: status.percentBp,
                    level: _levelOf(status.level),
                    label: money(status.spent),
                    trailing: _remainingText(l10n, money, status),
                  ),
                ],
              ),
            ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: ProgressBarStatus(
            key: const ValueKey('budget-bar-total'),
            basisPoints: report.total.percentBp,
            level: _levelOf(report.total.level),
            label: '${l10n.budgetOverall}: ${money(report.total.spent)}',
            trailing: _remainingText(l10n, money, report.total),
          ),
        ),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.budgetByCategory,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          AppCard(
            margin: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            ),
          ),
        ],
      ],
    );
  }
}
