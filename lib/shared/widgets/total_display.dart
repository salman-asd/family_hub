import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';

/// The big total of an entry form: label, amount, and — when the amount was
/// derived — a note saying so.  A missing total shows a dash, never "0".
class TotalDisplay extends StatelessWidget {
  const TotalDisplay({
    required this.total,
    required this.label,
    this.calculated = false,
    super.key,
  });

  final Money? total;
  final String label;

  /// `true` when [total] came from quantity × unit price.
  final bool calculated;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final theme = Theme.of(context).textTheme;
    final value = total;
    final amountStyle = theme.headlineMedium?.copyWith(
      color: t.textPrimary,
      fontWeight: FontWeight.w700,
    );

    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.labelLarge?.copyWith(color: t.textSecondary)),
          const SizedBox(height: 4),
          if (value == null)
            Semantics(
              label: l10n.totalDisplayEmpty,
              excludeSemantics: true,
              child: Text('—', style: amountStyle), // i18n-exempt
            )
          else
            MoneyText(value: value, style: amountStyle),
          if (calculated && value != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.calculate_outlined, size: 14, color: t.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n.totalDisplayCalculated,
                    style: theme.bodySmall?.copyWith(color: t.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
