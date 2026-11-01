import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:flutter/material.dart';

/// The seven weekday names above the grid, starting on [weekStartDay]
/// (1 = Monday … 7 = Sunday), so a family that starts the week on Saturday
/// sees Saturday first (B.9-1).
class WeekdayHeaderRow extends StatelessWidget {
  const WeekdayHeaderRow({
    required this.weekStartDay,
    required this.formatters,
    super.key,
  });

  final int weekStartDay;
  final AppFormatters formatters;

  /// The weekday (1 … 7) of column [index].
  static int weekdayAt(int weekStartDay, int index) =>
      (weekStartDay - 1 + index) % 7 + 1;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Semantics(
              label: formatters.weekdayName(weekdayAt(weekStartDay, i)),
              excludeSemantics: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatters.weekdayShort(weekdayAt(weekStartDay, i)),
                    maxLines: 1,
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
