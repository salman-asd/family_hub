import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/expenses/presentation/controllers/expense_form_state.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/presentation/bazar_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The field setters of the expense form.  Each one clears the inline errors
/// it could have caused and any pending duplicate warning.
abstract class ExpenseFormSetters extends Notifier<ExpenseFormState> {
  // ── Editing the fields ──────────────────────────────────────────────────

  Map<String, String> _without(List<String> keys) => <String, String>{
    for (final e in state.fieldErrors.entries)
      if (!keys.contains(e.key)) e.key: e.value,
  };

  void typeItem(String text) {
    final selected = state.item;
    final keep = selected != null && selected.nameBn.trim() == text.trim();
    state = state.copyWith(
      itemQuery: text,
      item: keep ? selected : null,
      customItemName: null,
      unitPriceHint: keep ? state.unitPriceHint : null,
      fieldErrors: _without(const ['itemName']),
      duplicate: null,
      failure: null,
    );
  }

  /// Picks a catalog item: category, default unit and the price hint follow.
  void selectItem(Item item) {
    state = state.copyWith(
      item: item,
      itemQuery: item.nameBn,
      customItemName: null,
      categoryId: item.categoryId,
      unit: item.defaultUnit,
      unitPriceHint: item.lastUnitPrice,
      rememberItem: false,
      fieldErrors: _without(const ['itemName', 'categoryId']),
      duplicate: null,
      failure: null,
    );
  }

  /// Uses [name] as a new item; the category must then be chosen by hand.
  void chooseNewItem(String name) {
    state = state.copyWith(
      item: null,
      itemQuery: name,
      customItemName: name.trim(),
      unitPriceHint: null,
      fieldErrors: _without(const ['itemName']),
      duplicate: null,
    );
  }

  void setCategory(String id) => state = state.copyWith(
    categoryId: id,
    fieldErrors: _without(const ['categoryId']),
  );

  void setRememberItem({required bool value}) =>
      state = state.copyWith(rememberItem: value);

  void setQty(String text) => state = state.copyWith(
    qtyText: text,
    fieldErrors: _without(const ['qty', 'unit', 'unitPrice', 'total']),
    duplicate: null,
  );

  void setUnit(Unit? unit) => state = state.copyWith(
    unit: unit,
    fieldErrors: _without(const ['unit']),
  );

  void setUnitPrice(String text) => state = state.copyWith(
    unitPriceText: text,
    fieldErrors: _without(const ['qty', 'unitPrice', 'total']),
    duplicate: null,
  );

  void setTotal(String text) => state = state.copyWith(
    totalText: text,
    fieldErrors: _without(const ['total']),
    duplicate: null,
  );

  void setFunding(FundingChoice choice) => state = state.copyWith(
    funding: choice,
    paidByMemberId: choice.needsPayer
        ? (state.paidByMemberId ?? ref.read(currentUidProvider))
        : state.paidByMemberId,
    fieldErrors: _without(const ['paidByMemberId']),
  );

  void setPaidBy(String? memberId) => state = state.copyWith(
    paidByMemberId: memberId,
    fieldErrors: _without(const ['paidByMemberId']),
  );

  /// A future date is refused here and by the use case.
  void setDate(DateKey date) {
    if (date.isAfter(ref.read(currentDateKeyProvider))) {
      state = state.copyWith(
        fieldErrors: <String, String>{
          ...state.fieldErrors,
          'dateKey': 'future_date',
        },
      );
      return;
    }
    state = state.copyWith(
      date: date,
      fieldErrors: _without(const ['dateKey']),
      duplicate: null,
      failure: null,
    );
  }

  void setShop(String text) => state = state.copyWith(
    shop: text,
    fieldErrors: _without(const ['shop']),
  );

  void setNote(String text) => state = state.copyWith(
    note: text,
    fieldErrors: _without(const ['note']),
  );

  void setPurchaser(String? memberId) =>
      state = state.copyWith(purchaserId: memberId);

  /// Hides the duplicate sheet without saving.
  void dismissDuplicate() => state = state.copyWith(duplicate: null);
}
