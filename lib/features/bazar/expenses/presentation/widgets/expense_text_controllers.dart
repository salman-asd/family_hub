import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_state.dart';
import 'package:flutter/widgets.dart';

/// The text controllers and focus node of one expense form.
///
/// The form state owns the text; these only mirror it so the caret never jumps.
/// [sync] writes a field back only when it differs from the state, which is the
/// case after an edit-mode load, choosing an item or "Save & add another".
class ExpenseTextControllers {
  final TextEditingController item = TextEditingController();
  final TextEditingController qty = TextEditingController();
  final TextEditingController unitPrice = TextEditingController();
  final TextEditingController total = TextEditingController();
  final TextEditingController shop = TextEditingController();
  final TextEditingController note = TextEditingController();
  final FocusNode amountFocus = FocusNode();

  void sync(ExpenseFormState state) {
    _set(item, state.itemQuery);
    _set(qty, state.qtyText);
    _set(unitPrice, state.unitPriceText);
    _set(total, state.totalText);
    _set(shop, state.shop);
    _set(note, state.note);
  }

  static void _set(TextEditingController controller, String text) {
    if (controller.text != text) controller.text = text;
  }

  void dispose() {
    item.dispose();
    qty.dispose();
    unitPrice.dispose();
    total.dispose();
    shop.dispose();
    note.dispose();
    amountFocus.dispose();
  }
}
