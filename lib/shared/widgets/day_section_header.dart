import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';

/// The sticky day heading of the expense list (P2-12).
///
/// A localized date label on the leading edge and that day's total on the
/// trailing edge.  The label is plain data from the caller (already formatted
/// for the active locale); a long Bangla label wraps instead of overflowing,
/// and the amount always goes through [MoneyText].
class DaySectionHeader extends StatelessWidget {
  const DaySectionHeader({
    required this.dateLabel,
    required this.total,
    super.key,
  });

  /// Localized date shown on the left, for example "১৮ অক্টোবর ২০২৬".
  final String dateLabel;

  /// Sum of the visible expenses of that day.
  final Money total;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              dateLabel,
              style: textTheme.titleSmall?.copyWith(
                color: t.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          MoneyText(value: total, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
