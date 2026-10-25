import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/localization/unit_labels.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_draft.dart';
import 'package:family_hub/features/bazar/budgets/presentation/controllers/budget_controller.dart';
import 'package:family_hub/features/bazar/budgets/presentation/widgets/budget_line_total.dart';
import 'package:family_hub/features/bazar/expenses/domain/amount_input.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/shared/widgets/amount_field.dart';
import 'package:family_hub/shared/widgets/app_card.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Dry-grocery estimate table: one card per line (item, planned quantity
/// and unit, rate, an automatic total, optional stock), an "add line" button
/// and a footer with the sum.  Everything is held by [BudgetController]; the
/// rows only show it and report edits.
class DryGroceryTableEditor extends ConsumerWidget {
  const DryGroceryTableEditor({required this.month, super.key});

  final MonthKey month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(budgetControllerProvider(month));
    final controller = ref.read(budgetControllerProvider(month).notifier);
    final total = Money.sum(
      readLineDrafts(state.lines).lines.map((l) => l.estimate),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < state.lines.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LineRow(
              // The version changes when the draft is replaced, so the row
              // reloads its text; plain typing keeps the same row.
              key: ValueKey('${state.lines[i].id}-${state.version}'),
              index: i,
              draft: state.lines[i],
              errors: state.lineErrors[state.lines[i].id] ?? const {},
              onChanged: (edit) =>
                  controller.updateLine(state.lines[i].id, edit),
              onRemove: () => controller.removeLine(state.lines[i].id),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('line-add'),
            onPressed: controller.addLine,
            icon: const Icon(Icons.add),
            label: Text(l10n.budgetAddLine),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.budgetLinesSum,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            MoneyText(
              key: const ValueKey('lines-sum'),
              value: total,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}

class _LineRow extends StatefulWidget {
  const _LineRow({
    required this.index,
    required this.draft,
    required this.errors,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final BudgetLineDraft draft;
  final Map<String, String> errors;
  final void Function(BudgetLineDraft Function(BudgetLineDraft)) onChanged;
  final VoidCallback onRemove;

  @override
  State<_LineRow> createState() => _LineRowState();
}

class _LineRowState extends State<_LineRow> {
  late final TextEditingController _name;
  late final TextEditingController _qty;
  late final TextEditingController _rate;
  late final TextEditingController _total;
  late final TextEditingController _stock;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _name = TextEditingController(text: d.name);
    _qty = TextEditingController(text: d.qtyText);
    _rate = TextEditingController(text: d.rateText);
    _total = TextEditingController(text: d.totalText);
    _stock = TextEditingController(text: d.stockText);
  }

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _rate.dispose();
    _total.dispose();
    _stock.dispose();
    super.dispose();
  }

  String? _error(String field) {
    final code = widget.errors[field];
    if (code == null) return null;
    return context.l10n.bazarFailureMessage(Validation(field, code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final i = widget.index;
    final d = widget.draft;
    final live = readAmountInput(
      qtyText: d.qtyText,
      unit: d.unit,
      unitPriceText: d.rateText,
      totalText: d.totalText,
      strict: false,
    );

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: ValueKey('line-name-$i'),
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.budgetLineName,
                    errorText: _error('name'),
                  ),
                  onChanged: (v) => widget.onChanged((x) => x.copyWith(name: v)),
                ),
              ),
              IconButton(
                key: ValueKey('line-remove-$i'),
                tooltip: l10n.budgetRemoveLine,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: widget.onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AmountField(
                  key: ValueKey('line-qty-$i'),
                  controller: _qty,
                  label: l10n.expenseQtyField,
                  scale: 3,
                  errorText: _error('qty'),
                  onChanged: (v) => widget.onChanged((x) => x.copyWith(qtyText: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<Unit>(
                  key: ValueKey('line-unit-$i'),
                  initialValue: d.unit,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.expenseUnitLabel,
                    errorText: _error('unit'),
                  ),
                  items: [
                    for (final u in Unit.values)
                      DropdownMenuItem<Unit>(
                        value: u,
                        child: Text(l10n.unitLabel(u)),
                      ),
                  ],
                  onChanged: (u) => widget.onChanged((x) => x.copyWith(unit: u)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AmountField(
                  key: ValueKey('line-rate-$i'),
                  controller: _rate,
                  label: l10n.budgetLineRate,
                  errorText: _error('unitPrice'),
                  onChanged: (v) =>
                      widget.onChanged((x) => x.copyWith(rateText: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: live.calculated
                    ? BudgetLineCalculatedTotal(total: live.total)
                    : AmountField(
                        key: ValueKey('line-total-$i'),
                        controller: _total,
                        label: l10n.budgetLineTotal,
                        errorText: _error('total'),
                        onChanged: (v) =>
                            widget.onChanged((x) => x.copyWith(totalText: v)),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AmountField(
            key: ValueKey('line-stock-$i'),
            controller: _stock,
            label: l10n.budgetLineStock,
            scale: 3,
            errorText: _error('stock'),
            onChanged: (v) => widget.onChanged((x) => x.copyWith(stockText: v)),
          ),
        ],
      ),
    );
  }
}
