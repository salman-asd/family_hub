import 'package:family_hub/features/bazar/expenses/domain/amount_input.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_state.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';

/// The edit form for [expense].
///
/// A row that has quantity and unit price leaves the total field empty: the
/// total is calculated from the pair again, exactly as `computeTotal` does when
/// the edit is saved.  [item] is the catalog entry when it still exists.
ExpenseFormState expenseFormFromExpense(
  Expense expense, {
  required String eventId,
  required String newItemId,
  Item? item,
}) {
  final calculated = expense.qty != null && expense.unitPrice != null;
  return ExpenseFormState(
    expenseId: expense.id,
    eventId: eventId,
    newItemId: newItemId,
    date: expense.dateKey,
    editing: true,
    itemQuery: expense.itemName,
    item: item,
    customItemName: item == null ? expense.itemName : null,
    categoryId: expense.categoryId,
    qtyText: expense.qty?.toDecimalString() ?? '',
    unit: expense.unit,
    unitPriceText: expense.unitPrice == null
        ? ''
        : moneyEditText(expense.unitPrice!),
    totalText: calculated ? '' : moneyEditText(expense.total),
    unitPriceHint: item?.lastUnitPrice,
    funding: FundingChoiceMapping.of(expense),
    paidByMemberId: expense.paidByMemberId,
    shop: expense.shop ?? '',
    note: expense.note ?? '',
    purchaserId: expense.purchaserId,
  );
}
