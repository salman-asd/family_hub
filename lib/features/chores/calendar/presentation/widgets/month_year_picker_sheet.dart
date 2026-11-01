import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:flutter/material.dart';

/// Jump to any month of any year in two taps (B.4): a year with arrows and the
/// twelve months. Returns the chosen [MonthKey], or null when dismissed.
Future<MonthKey?> showMonthYearPickerSheet(
  BuildContext context, {
  required MonthKey current,
  required MonthKey first,
  required MonthKey last,
  required AppFormatters formatters,
}) => showModalBottomSheet<MonthKey>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => MonthYearPickerSheet(
    current: current,
    first: first,
    last: last,
    formatters: formatters,
  ),
);

class MonthYearPickerSheet extends StatefulWidget {
  const MonthYearPickerSheet({
    required this.current,
    required this.first,
    required this.last,
    required this.formatters,
    super.key,
  });

  final MonthKey current;
  final MonthKey first;
  final MonthKey last;
  final AppFormatters formatters;

  @override
  State<MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<MonthYearPickerSheet> {
  late int _year = widget.current.year;

  bool _allowed(int year, int month) {
    final key = MonthKey(year, month);
    return key.compareTo(widget.first) >= 0 && key.compareTo(widget.last) <= 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = widget.formatters;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  key: const Key('calendar_picker_previous_year'),
                  tooltip: l10n.calendarPreviousYear,
                  onPressed: _year > widget.first.year
                      ? () => setState(() => _year--)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  f.monthLabel(MonthKey(_year, 1)).split(' ').last,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  key: const Key('calendar_picker_next_year'),
                  tooltip: l10n.calendarNextYear,
                  onPressed: _year < widget.last.year
                      ? () => setState(() => _year++)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var month = 1; month <= 12; month++)
                  ChoiceChip(
                    key: Key('calendar_picker_month_$month'),
                    showCheckmark: true,
                    label: Text(f.monthName(month)),
                    selected:
                        widget.current == MonthKey(_year, month),
                    onSelected: _allowed(_year, month)
                        ? (_) => Navigator.of(context).pop(
                            MonthKey(_year, month),
                          )
                        : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
