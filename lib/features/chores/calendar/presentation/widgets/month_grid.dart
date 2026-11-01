import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_enums.dart';
import 'package:family_hub/features/chores/calendar/domain/calendar_month_model.dart';
import 'package:family_hub/features/chores/calendar/presentation/widgets/day_cell.dart';
import 'package:flutter/material.dart';

/// The rows of day cells of one month (P3-22). Pure drawing: it takes the model
/// and callbacks, never a provider.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    required this.model,
    required this.selectedDay,
    required this.scope,
    required this.markerStyle,
    required this.formatters,
    required this.cellHeight,
    required this.onSelect,
    required this.onLongPress,
    super.key,
  });

  final CalendarMonthModel model;
  final DateKey selectedDay;
  final CalendarScope scope;
  final MarkerStyle markerStyle;
  final AppFormatters formatters;
  final double cellHeight;
  final ValueChanged<DateKey> onSelect;
  final ValueChanged<DateKey> onLongPress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final week in model.weeks)
          Row(
            children: [
              for (final summary in week)
                Expanded(
                  child: DayCell(
                    summary: summary,
                    selected: summary.dateKey == selectedDay,
                    scope: scope,
                    markerStyle: markerStyle,
                    formatters: formatters,
                    minHeight: cellHeight,
                    onTap: () => onSelect(summary.dateKey),
                    onLongPress: () => onLongPress(summary.dateKey),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
