import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_controller.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_state.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/amount_block.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/date_chip_field.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/expense_field_errors.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/expense_more_section.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/expense_text_controllers.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/form_banner.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/funding_selector.dart';
import 'package:family_hub/features/bazar/expenses/presentation/widgets/item_autocomplete_field.dart';
import 'package:family_hub/features/bazar/items_categories/presentation/catalog_providers.dart';
import 'package:family_hub/features/bazar/presentation/bazar_failure_messages.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The fields of the Add/Edit expense screen, in the order of roadmap 4.1:
/// date, item, category, amount, funding, extras.
class ExpenseFormBody extends ConsumerWidget {
  const ExpenseFormBody({
    required this.args,
    required this.text,
    required this.locked,
    super.key,
  });

  final ExpenseFormArgs args;
  final ExpenseTextControllers text;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final state = ref.watch(expenseFormProvider(args));
    final form = ref.read(expenseFormProvider(args).notifier);
    final index = ref.watch(catalogIndexProvider);
    final members = ref.watch(bazarMemberOptionsProvider);
    final bangla = Localizations.localeOf(context).languageCode == 'bn';
    final enabled = !locked && !state.saving;
    final errors = state.fieldErrors;
    final failure = state.failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (locked)
          FormBanner(
            icon: Icons.lock_outline,
            text: l10n.bazarErrMonthLocked,
            color: t.warning,
          ),
        if (failure != null)
          FormBanner(
            icon: Icons.error_outline,
            text: l10n.bazarFailureMessage(failure),
            color: t.danger,
          ),
        DateChipField(
          date: state.date,
          enabled: enabled,
          errorText: fieldErrorText(l10n, errors, 'dateKey'),
          onPicked: form.setDate,
        ),
        const SizedBox(height: 16),
        ItemAutocompleteField(
          controller: text.item,
          selected: state.item,
          enabled: enabled,
          autofocus: !state.editing,
          errorText: fieldErrorText(l10n, errors, 'itemName'),
          onTextChanged: form.typeItem,
          onSelected: (item) {
            form.selectItem(item);
            text.amountFocus.requestFocus();
          },
          onNewItem: (name) {
            form.chooseNewItem(name);
            FocusScope.of(context).nextFocus();
          },
        ),
        const SizedBox(height: 12),
        Text(
          l10n.expenseCategoryLabel,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: t.textSecondary),
        ),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: !enabled,
          child: ChoiceWrap<String>(
            selected: state.categoryId,
            onChanged: form.setCategory,
            options: [
              for (final c in index.activeCategories)
                ChoiceOption(
                  c.id,
                  [
                    if ((c.emoji ?? '').isNotEmpty) c.emoji,
                    c.displayName(bangla: bangla),
                  ].join(' '),
                ),
            ],
          ),
        ),
        if (errors['categoryId'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              fieldErrorText(l10n, errors, 'categoryId')!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: t.danger),
            ),
          ),
        if (state.isNewItem)
          CheckboxListTile(
            key: const ValueKey('remember-item'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: state.rememberItem,
            onChanged: enabled
                ? (value) => form.setRememberItem(value: value ?? false)
                : null,
            title: Text(l10n.expenseRememberItem),
          ),
        const SizedBox(height: 16),
        AmountBlock(
          total: text.total,
          qty: text.qty,
          unitPrice: text.unitPrice,
          unit: state.unit,
          amount: state.amount,
          errors: errors,
          unitPriceHint: state.unitPriceHint,
          totalFocus: text.amountFocus,
          enabled: enabled,
          onTotalChanged: form.setTotal,
          onQtyChanged: form.setQty,
          onUnitPriceChanged: form.setUnitPrice,
          onUnitChanged: form.setUnit,
        ),
        const SizedBox(height: 16),
        FundingSelector(
          funding: state.funding,
          onFundingChanged: form.setFunding,
          members: members,
          paidById: state.paidByMemberId,
          onPaidByChanged: form.setPaidBy,
          errorText: fieldErrorText(l10n, errors, 'paidByMemberId'),
          enabled: enabled,
        ),
        const SizedBox(height: 8),
        ExpenseMoreSection(
          shop: text.shop,
          note: text.note,
          members: members,
          purchaserId: state.purchaserId,
          onShopChanged: form.setShop,
          onNoteChanged: form.setNote,
          onPurchaserChanged: form.setPurchaser,
          shopError: fieldErrorText(l10n, errors, 'shop'),
          noteError: fieldErrorText(l10n, errors, 'note'),
          initiallyExpanded:
              state.shop.isNotEmpty ||
              state.note.isNotEmpty ||
              state.purchaserId != null,
        ),
      ],
    );
  }
}
