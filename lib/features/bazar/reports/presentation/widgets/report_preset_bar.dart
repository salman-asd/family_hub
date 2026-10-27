import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/features/bazar/reports/domain/report_query.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:flutter/material.dart';

/// The period chips above the report tabs.
///
/// "Custom" opens the range picker through [onPreset]; the other presets are
/// set directly.  The selected chip is shown by a check mark as well as colour.
class ReportPresetBar extends StatelessWidget {
  const ReportPresetBar({
    required this.query,
    required this.onPreset,
    super.key,
  });

  final ReportQuery query;
  final ValueChanged<RangePreset> onPreset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: ChoiceWrap<RangePreset>(
        selected: query.preset,
        onChanged: onPreset,
        options: <ChoiceOption<RangePreset>>[
          for (final preset in RangePreset.values)
            ChoiceOption(
              preset,
              rangeLabel(l10n, preset),
              key: ValueKey('report-preset-${preset.name}'),
            ),
        ],
      ),
    );
  }
}

/// Localized name of a [RangePreset] (the expense list's wording).
String rangeLabel(AppLocalizations l10n, RangePreset preset) =>
    switch (preset) {
      RangePreset.today => l10n.expenseRangeToday,
      RangePreset.yesterday => l10n.expenseRangeYesterday,
      RangePreset.last7Days => l10n.expenseRangeLast7Days,
      RangePreset.thisWeek => l10n.expenseRangeThisWeek,
      RangePreset.thisMonth => l10n.expenseRangeThisMonth,
      RangePreset.lastMonth => l10n.expenseRangeLastMonth,
      RangePreset.thisYear => l10n.expenseRangeThisYear,
      RangePreset.custom => l10n.expenseRangeCustom,
    };


