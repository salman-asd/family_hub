import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/budgets/presentation/controllers/budget_controller.dart';
import 'package:family_hub/features/bazar/budgets/presentation/widgets/dry_grocery_table_editor.dart';
import 'package:family_hub/features/bazar/items_categories/domain/category.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/shared/widgets/amount_field.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The budget editor: total, one estimate per category, the dry-grocery table,
/// Save and Cancel.  When the table has lines, the Dry-groceries estimate is
/// their sum (shown read-only), so there is one source of truth.
class BudgetEditorForm extends ConsumerStatefulWidget {
  const BudgetEditorForm({
    required this.month,
    required this.categories,
    required this.onSaved,
    super.key,
  });

  final MonthKey month;
  final List<Category> categories;
  final VoidCallback onSaved;

  @override
  ConsumerState<BudgetEditorForm> createState() => _BudgetEditorFormState();
}

class _BudgetEditorFormState extends ConsumerState<BudgetEditorForm> {
  final Map<String, TextEditingController> _fields =
      <String, TextEditingController>{};
  late final TextEditingController _total;
  int _loadedVersion = -1;

  @override
  void initState() {
    super.initState();
    _total = TextEditingController();
  }

  @override
  void dispose() {
    _total.dispose();
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Reloads the text fields when the draft was replaced (editing started).
  void _sync(BudgetEditState state) {
    if (_loadedVersion == state.version) return;
    _loadedVersion = state.version;
    _total.text = state.totalText;
    for (final c in widget.categories) {
      _fieldFor(c.id, state).text = state.categoryTexts[c.id] ?? '';
    }
  }

  /// A category's text field, created with the draft's text (categories may
  /// load after the editor opened).
  TextEditingController _fieldFor(String id, BudgetEditState state) =>
      _fields[id] ??= TextEditingController(
        text: state.categoryTexts[id] ?? '',
      );

  String? _error(String? code, String field) => code == null
      ? null
      : context.l10n.bazarFailureMessage(Validation(field, code));

  Future<void> _save() async {
    final saved = await ref
        .read(budgetControllerProvider(widget.month).notifier)
        .save();
    if (saved && mounted) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final state = ref.watch(budgetControllerProvider(widget.month));
    final controller = ref.read(budgetControllerProvider(widget.month).notifier);
    _sync(state);
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    final hasLines = state.lines.any((l) => !l.isBlank);
    final failure = state.failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AmountField(
          key: const ValueKey('budget-total'),
          controller: _total,
          label: l10n.budgetTotalField,
          errorText: _error(state.totalError, 'totalEstimate'),
          onChanged: controller.setTotal,
        ),
        const SizedBox(height: 20),
        Text(
          l10n.budgetCategoryEstimates,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        for (final c in widget.categories)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: c.id == kDryGroceriesCategoryId && hasLines
                ? _DryFromLines(
                    name: c.displayName(bangla: bangla),
                    controller: controller,
                  )
                : AmountField(
                    key: ValueKey('budget-cat-${c.id}'),
                    controller: _fieldFor(c.id, state),
                    label: c.displayName(bangla: bangla),
                    errorText: _error(state.categoryErrors[c.id], c.id),
                    onChanged: (v) => controller.setCategory(c.id, v),
                  ),
          ),
        const SizedBox(height: 12),
        Text(
          l10n.budgetDryTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DryGroceryTableEditor(month: widget.month),
        if (failure != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              l10n.bazarFailureMessage(failure),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: t.danger),
            ),
          ),
        const SizedBox(height: 20),
        BusyButton(
          key: const ValueKey('budget-save'),
          label: l10n.actionSave,
          busy: state.saving,
          busyLabel: l10n.loadingSemantics,
          onPressed: _save,
        ),
        TextButton(
          key: const ValueKey('budget-cancel'),
          onPressed: state.saving ? null : controller.cancel,
          child: Text(l10n.actionCancel),
        ),
      ],
    );
  }
}

/// Read-only Dry-groceries estimate: the sum of the lines.
class _DryFromLines extends StatelessWidget {
  const _DryFromLines({required this.name, required this.controller});

  final String name;
  final BudgetController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                l10n.budgetDryFromLines,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        MoneyText(
          key: const ValueKey('budget-dry-sum'),
          value: controller.linesTotal,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
