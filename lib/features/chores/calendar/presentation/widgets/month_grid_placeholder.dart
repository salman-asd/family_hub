import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/month_matrix.dart';
import 'package:flutter/material.dart';

/// The grid before the month's chores are known: the real dates, no markers, a
/// static placeholder (no shimmer, so reduced motion needs no special case).
class MonthGridPlaceholder extends StatelessWidget {
  const MonthGridPlaceholder({
    required this.month,
    required this.weekStartDay,
    required this.formatters,
    required this.cellHeight,
    super.key,
  });

  final MonthKey month;
  final int weekStartDay;
  final AppFormatters formatters;
  final double cellHeight;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final matrix = MonthMatrix.build(month, weekStartDay);
    return Column(
      children: [
        for (final row in matrix.rows)
          Row(
            children: [
              for (final day in row)
                Expanded(
                  child: SizedBox(
                    height: cellHeight,
                    child: Center(
                      child: Text(
                        formatters.number(day.day),
                        style: TextStyle(
                          color: matrix.isInMonth(day)
                              ? t.textSecondary
                              : t.textDisabled,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
