import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/shared/widgets/person_picker.dart';
import 'package:flutter/material.dart';

/// The collapsed extras of the expense form: shop, note and who bought it.
/// (No receipt photo: Cloud Storage is not part of the free plan, D-P2-13.)
class ExpenseMoreSection extends StatelessWidget {
  const ExpenseMoreSection({
    required this.shop,
    required this.note,
    required this.members,
    required this.purchaserId,
    required this.onShopChanged,
    required this.onNoteChanged,
    required this.onPurchaserChanged,
    this.shopError,
    this.noteError,
    this.initiallyExpanded = false,
    super.key,
  });

  final TextEditingController shop;
  final TextEditingController note;
  final List<PersonOption> members;
  final String? purchaserId;
  final ValueChanged<String> onShopChanged;
  final ValueChanged<String> onNoteChanged;
  final ValueChanged<String?> onPurchaserChanged;
  final String? shopError;
  final String? noteError;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpansionTile(
      key: const ValueKey('expense-more'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      initiallyExpanded: initiallyExpanded,
      title: Text(l10n.expenseMoreSection),
      children: [
        TextField(
          controller: shop,
          onChanged: onShopChanged,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.expenseShopField,
            errorText: shopError,
            errorMaxLines: 3,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          onChanged: onNoteChanged,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.expenseNoteField,
            errorText: noteError,
            errorMaxLines: 3,
          ),
        ),
        const SizedBox(height: 12),
        PersonPicker(
          options: members,
          selectedId: purchaserId,
          onChanged: onPurchaserChanged,
          label: l10n.expensePurchaserLabel,
          allowNone: true,
        ),
      ],
    );
  }
}
