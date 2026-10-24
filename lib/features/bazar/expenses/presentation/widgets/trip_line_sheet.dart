import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/expenses/domain/amount_input.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/trip_form_controller.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/amount_block.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/expense_field_errors.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/item_autocomplete_field.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/shared/widgets/busy_button.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the add/edit sheet for one trip line.  Resolves to the line, or
/// `null` when the sheet is dismissed.  [newId] names a brand-new line.
Future<TripLineDraft?> showTripLineSheet(
  BuildContext context, {
  required String Function() newId,
  TripLineDraft? initial,
}) => showModalBottomSheet<TripLineDraft>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: TripLineSheet(initial: initial, newId: newId),
  ),
);

/// Item, amount and category of one trip line (reuses the expense widgets).
class TripLineSheet extends ConsumerStatefulWidget {
  const TripLineSheet({required this.newId, this.initial, super.key});

  final TripLineDraft? initial;
  final String Function() newId;

  @override
  ConsumerState<TripLineSheet> createState() => _TripLineSheetState();
}

class _TripLineSheetState extends ConsumerState<TripLineSheet> {
  final TextEditingController _item = TextEditingController();
  final TextEditingController _qty = TextEditingController();
  final TextEditingController _unitPrice = TextEditingController();
  final TextEditingController _total = TextEditingController();

  Item? _selected;
  String? _categoryId;
  Unit? _unit;
  bool _remember = false;
  Map<String, String> _errors = const <String, String>{};

  @override
  void initState() {
    super.initState();
    final line = widget.initial;
    if (line != null) {
      _item.text = line.itemName;
      _categoryId = line.categoryId;
      _unit = line.unit;
      _remember = line.rememberItem;
      _qty.text = line.qty?.toDecimalString() ?? '';
      _unitPrice.text = line.unitPrice == null
          ? ''
          : moneyEditText(line.unitPrice!);
      _total.text = line.typedTotal == null
          ? ''
          : moneyEditText(line.typedTotal!);
      _selected = ref.read(catalogIndexProvider).itemsById[line.itemId];
    }
  }

  @override
  void dispose() {
    _item.dispose();
    _qty.dispose();
    _unitPrice.dispose();
    _total.dispose();
    super.dispose();
  }

  AmountInput _amount({bool strict = false}) => readAmountInput(
    qtyText: _qty.text,
    unit: _unit,
    unitPriceText: _unitPrice.text,
    totalText: _total.text,
    strict: strict,
  );

  void _clear(List<String> keys) => setState(() {
    _errors = <String, String>{
      for (final e in _errors.entries)
        if (!keys.contains(e.key)) e.key: e.value,
    };
  });

  void _submit() {
    final amount = _amount(strict: true);
    final name = (_selected?.nameBn ?? _item.text).trim();
    final errors = <String, String>{
      if (name.isEmpty) 'itemName': 'item_name_required',
      if (name.runes.length > 80) 'itemName': 'too_long',
      if ((_categoryId ?? '').isEmpty) 'categoryId': 'category_required',
      ...amount.errors,
    };
    final total = amount.total;
    if (errors.isNotEmpty || total == null) {
      setState(() => _errors = errors);
      return;
    }
    Navigator.of(context).pop(
      TripLineDraft(
        id: widget.initial?.id ?? widget.newId(),
        itemId: _selected?.id,
        itemName: name,
        categoryId: _categoryId!,
        qty: amount.qty,
        unit: amount.unit,
        unitPrice: amount.unitPrice,
        typedTotal: amount.typedTotal,
        total: total,
        rememberItem: _selected == null && _remember,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final t = context.tokens;
    final index = ref.watch(catalogIndexProvider);
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    final isNew = _selected == null && _item.text.trim().isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tripLineSheetTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: 12),
            ItemAutocompleteField(
              controller: _item,
              selected: _selected,
              autofocus: widget.initial == null,
              errorText: fieldErrorText(l10n, _errors, 'itemName'),
              onTextChanged: (text) => setState(() {
                if (_selected != null && _selected!.nameBn.trim() != text.trim()) {
                  _selected = null;
                }
              }),
              onSelected: (item) => setState(() {
                _selected = item;
                _item.text = item.nameBn;
                _categoryId = item.categoryId;
                _unit = item.defaultUnit;
              }),
              onNewItem: (name) => setState(() {
                _selected = null;
                _item.text = name;
              }),
            ),
            const SizedBox(height: 12),
            ChoiceWrap<String>(
              selected: _categoryId,
              onChanged: (id) => setState(() => _categoryId = id),
              options: [
                for (final c in index.activeCategories)
                  ChoiceOption(c.id, c.displayName(bangla: bangla)),
              ],
            ),
            if (_errors['categoryId'] != null)
              Text(
                fieldErrorText(l10n, _errors, 'categoryId')!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: t.danger),
              ),
            if (isNew)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? false),
                title: Text(l10n.expenseRememberItem),
              ),
            const SizedBox(height: 12),
            AmountBlock(
              total: _total,
              qty: _qty,
              unitPrice: _unitPrice,
              unit: _unit,
              amount: _amount(),
              errors: _errors,
              unitPriceHint: _selected?.lastUnitPrice,
              onTotalChanged: (_) => _clear(const ['total']),
              onQtyChanged: (_) => _clear(const ['qty', 'unit', 'total']),
              onUnitPriceChanged: (_) =>
                  _clear(const ['unitPrice', 'qty', 'total']),
              onUnitChanged: (u) => setState(() => _unit = u),
            ),
            const SizedBox(height: 16),
            BusyButton(
              key: const ValueKey('trip-line-save'),
              label: l10n.tripLineSheetSave,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
