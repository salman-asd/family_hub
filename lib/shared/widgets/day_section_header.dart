import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';

/// The header of one day in a list: the date on the left, the day's total on
/// the right.  A long date wraps instead of pushing the total off screen.
class DaySectionHeader extends StatelessWidget {
  const DaySectionHeader({
    required this.dateLabel,
    required this.total,
    super.key,
  });

  final String dateLabel;
  final Money total;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              dateLabel,
              style: theme.titleSmall?.copyWith(color: t.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          MoneyText(
            value: total,
            hideZeroFraction: true,
            style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
