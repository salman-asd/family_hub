import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/fund/domain/month_choices.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The month picker list under the close screen's preview.
///
/// A closed month shows a lock icon + "Closed on ..." (icon + word + colour,
/// never colour alone); an open one shows nothing but its name.
class MonthList extends ConsumerWidget {
  const MonthList({
    required this.months,
    required this.selected,
    required this.closings,
    required this.onSelected,
    super.key,
  });

  final List<MonthKey> months;
  final MonthKey selected;
  final List<MonthClosing> closings;
  final ValueChanged<MonthKey> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final formatters = ref.watch(appFormattersProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final month in months)
          ChoiceChip(
            key: ValueKey('close-month-$month'),
            selected: month == selected,
            showCheckmark: true,
            onSelected: (_) => onSelected(month),
            avatar: closingOf(closings, month)?.status == MonthStatus.closed
                ? const Icon(Icons.lock_outline, size: 16)
                : null,
            label: Text(
              closingOf(closings, month)?.status == MonthStatus.closed
                  ? l10n.monthClosedChip(
                      formatters.monthLabel(month),
                    )
                  : formatters.monthLabel(month),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: t.textSecondary),
            ),
          ),
      ],
    );
  }
}
