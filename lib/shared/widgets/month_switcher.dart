import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Month header for the bazar screens: "‹ October 2026 ›".
///
/// The two arrows keep a 48dp touch target and are disabled at [min] / [max],
/// so a caller can bound the range without the widget ever going outside it.
/// Tapping the label opens a month picker sheet, which is bounded the same way.
///
/// The label is formatted by [AppFormatters.monthLabel], so it follows the
/// active language and the "Use Bangla digits" switch.  The widget takes plain
/// values only: no Firebase, no feature import.
class MonthSwitcher extends ConsumerWidget {
  const MonthSwitcher({
    required this.month,
    required this.onChanged,
    this.min,
    this.max,
    super.key,
  });

  /// The month currently shown.
  final MonthKey month;

  /// Called with the previous/next month, or the month picked from the sheet.
  final ValueChanged<MonthKey> onChanged;

  /// Earliest selectable month (inclusive); `null` = no lower bound.
  final MonthKey? min;

  /// Latest selectable month (inclusive); `null` = no upper bound.
  final MonthKey? max;

  bool get _canGoPrevious {
    final lower = min;
    return lower == null || month.compareTo(lower) > 0;
  }

  bool get _canGoNext {
    final upper = max;
    return upper == null || month.compareTo(upper) < 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final label = ref.watch(appFormattersProvider).monthLabel(month);

    return Row(
      children: [
        IconButton(
          onPressed: _canGoPrevious
              ? () => onChanged(month.addMonths(-1))
              : null,
          tooltip: l10n.monthSwitcherPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
        Expanded(
          child: TextButton(
            onPressed: () => _openPicker(context),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: tokens.textPrimary,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: _canGoNext ? () => onChanged(month.addMonths(1)) : null,
          tooltip: l10n.monthSwitcherNext,
          icon: const Icon(Icons.chevron_right_rounded),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        ),
      ],
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<MonthKey>(
      context: context,
      showDragHandle: true,
      builder: (context) =>
          _MonthPickerSheet(initial: month, min: min, max: max),
    );
    if (picked != null) onChanged(picked);
  }
}

/// The bottom sheet opened by tapping the month label.
class _MonthPickerSheet extends ConsumerStatefulWidget {
  const _MonthPickerSheet({required this.initial, this.min, this.max});

  final MonthKey initial;
  final MonthKey? min;
  final MonthKey? max;

  @override
  ConsumerState<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends ConsumerState<_MonthPickerSheet> {
  late int _year = widget.initial.year;

  bool _allowed(MonthKey month) {
    final lower = widget.min;
    final upper = widget.max;
    return (lower == null || month.compareTo(lower) >= 0) &&
        (upper == null || month.compareTo(upper) <= 0);
  }

  bool get _canGoPreviousYear {
    final lower = widget.min;
    return lower == null || _year > lower.year;
  }

  bool get _canGoNextYear {
    final upper = widget.max;
    return upper == null || _year < upper.year;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final formatters = ref.watch(appFormattersProvider);
    final tokens = context.tokens;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.monthSwitcherSelectTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: tokens.textPrimary),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _canGoPreviousYear
                      ? () => setState(() => _year--)
                      : null,
                  tooltip: l10n.monthSwitcherPreviousYear,
                  icon: const Icon(Icons.chevron_left_rounded),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
                Text(
                  formatters.number(_year),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: tokens.textPrimary),
                ),
                IconButton(
                  onPressed: _canGoNextYear
                      ? () => setState(() => _year++)
                      : null,
                  tooltip: l10n.monthSwitcherNextYear,
                  icon: const Icon(Icons.chevron_right_rounded),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var month = 1; month <= 12; month++)
                  _monthChip(MonthKey(_year, month), formatters),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthChip(MonthKey month, AppFormatters formatters) {
    final enabled = _allowed(month);
    return ChoiceChip(
      label: Text(formatters.monthName(month.month)),
      selected:
          month.year == widget.initial.year &&
          month.month == widget.initial.month,
      onSelected: enabled ? (_) => Navigator.pop(context, month) : null,
    );
  }
}
