import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/localization/unit_labels.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/expenses/domain/amount_input.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/expense_field_errors.dart';
import 'package:family_hub/shared/widgets/amount_field.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:family_hub/shared/widgets/total_display.dart';
import 'package:flutter/material.dart';

/// The amount part of an entry form, shared by Add expense and the trip line
/// sheet: a typed total OR quantity + unit + price per unit, and the total
/// always shown large.  When quantity and price are both filled the total is
/// calculated and the typed total is disabled.
class AmountBlock extends StatelessWidget {
  const AmountBlock({
    required this.total,
    required this.qty,
    required this.unitPrice,
    required this.unit,
    required this.amount,
    required this.errors,
    required this.onTotalChanged,
    required this.onQtyChanged,
    required this.onUnitPriceChanged,
    required this.onUnitChanged,
    this.unitPriceHint,
    this.totalFocus,
    this.enabled = true,
    super.key,
  });

  final TextEditingController total;
  final TextEditingController qty;
  final TextEditingController unitPrice;
  final Unit? unit;
  final AmountInput amount;
  final Map<String, String> errors;
  final ValueChanged<String> onTotalChanged;
  final ValueChanged<String> onQtyChanged;
  final ValueChanged<String> onUnitPriceChanged;
  final ValueChanged<Unit?> onUnitChanged;

  /// The item's last price per unit: a hint only, never filled in.
  final Money? unitPriceHint;
  final FocusNode? totalFocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final label = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: t.textSecondary);
    final hint = unitPriceHint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmountField(
          key: const ValueKey('field-total'),
          controller: total,
          focusNode: totalFocus,
          label: l10n.expenseTotalField,
          errorText: fieldErrorText(l10n, errors, 'total'),
          onChanged: onTotalChanged,
          enabled: enabled && !amount.calculated,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        Text(l10n.expenseQtyPriceSection, style: label),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AmountField(
                key: const ValueKey('field-qty'),
                controller: qty,
                label: l10n.expenseQtyField,
                scale: 3,
                errorText: fieldErrorText(l10n, errors, 'qty'),
                onChanged: onQtyChanged,
                enabled: enabled,
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AmountField(
                key: const ValueKey('field-unit-price'),
                controller: unitPrice,
                label: l10n.expenseUnitPriceField,
                errorText: fieldErrorText(l10n, errors, 'unitPrice'),
                onChanged: onUnitPriceChanged,
                enabled: enabled,
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        ),
        if (hint != null && unitPrice.text.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.expenseUnitPriceHint(
                moneyEditText(hint),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: t.textSecondary),
            ),
          ),
        if (qty.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          IgnorePointer(
            ignoring: !enabled,
            child: ChoiceWrap<Unit>(
              selected: unit,
              onChanged: onUnitChanged,
              options: [
                for (final u in Unit.values) ChoiceOption(u, l10n.unitLabel(u)),
              ],
            ),
          ),
          if (errors['unit'] != null)
            Text(
              fieldErrorText(l10n, errors, 'unit')!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: t.danger),
            ),
        ],
        const SizedBox(height: 16),
        TotalDisplay(
          total: amount.total,
          label: l10n.expenseTotalLabel,
          calculated: amount.calculated,
        ),
      ],
    );
  }
}
