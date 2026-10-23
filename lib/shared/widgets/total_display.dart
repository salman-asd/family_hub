import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';

/// The large total shown by the expense and trip forms (P2-12).
///
/// [total] is null until the inputs form a valid amount: the value slot then
/// shows an em dash (localized, never a zero, which would look like a real
/// amount).  When [calculated] is true the subtitle explains that the value
/// came from quantity × unit price rather than from a typed total.
class TotalDisplay extends StatelessWidget {
  const TotalDisplay({
    required this.label,
    this.total,
    this.calculated = false,
    super.key,
  });

  /// Localized caption above the amount (for example "Total").
  final String label;

  /// The amount, or null while the form is incomplete.
  final Money? total;

  /// Whether the amount was computed from quantity and unit price.
  final bool calculated;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;
    final value = total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(color: tokens.textSecondary),
        ),
        const SizedBox(height: 4),
        if (value == null)
          Text(
            l10n.totalEmpty,
            style: textTheme.headlineSmall?.copyWith(
              color: tokens.textDisabled,
            ),
          )
        else
          MoneyText(value: value, style: textTheme.headlineSmall),
        if (calculated) ...[
          const SizedBox(height: 4),
          Text(
            l10n.totalCalculated,
            style: textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
          ),
        ],
      ],
    );
  }
}
