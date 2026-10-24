import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/expenses/domain/amount_input.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_draft.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_state.dart';

/// Content errors the form can find without the amount fields (field -> code).
///
/// The same rules `validateExpenseDraft` applies, run first so every problem
/// shows inline at once instead of one per tap.
Map<String, String> expenseContentErrors(
  ExpenseFormState state, {
  required DateKey today,
}) {
  final errors = <String, String>{};
  final name = state.itemName;
  if (name.isEmpty) {
    errors['itemName'] = 'item_name_required';
  } else if (name.runes.length > 80) {
    errors['itemName'] = 'too_long';
  }
  if ((state.categoryId ?? '').isEmpty) {
    errors['categoryId'] = 'category_required';
  }
  if (state.date.isAfter(today)) errors['dateKey'] = 'future_date';
  if (state.funding.needsPayer && (state.paidByMemberId ?? '').isEmpty) {
    errors['paidByMemberId'] = 'member_required';
  }
  if (state.shop.trim().runes.length > 60) errors['shop'] = 'too_long';
  if (state.note.trim().runes.length > 500) errors['note'] = 'too_long';
  return errors;
}

/// The draft the use case receives for a form that passed validation.
ExpenseDraft expenseDraftOf(ExpenseFormState state, AmountInput amount) =>
    ExpenseDraft(
      dateKey: state.date,
      itemId: state.item?.id,
      itemName: state.itemName,
      categoryId: state.categoryId ?? '',
      qty: amount.qty,
      unit: amount.unit,
      unitPrice: amount.unitPrice,
      typedTotal: amount.typedTotal,
      funding: state.funding.source,
      paidByMemberId: state.funding.needsPayer ? state.paidByMemberId : null,
      reimbursable: state.funding.reimbursable,
      purchaserId: state.purchaserId,
      shop: state.shop,
      note: state.note,
      rememberItem: state.item == null && state.rememberItem,
    );
