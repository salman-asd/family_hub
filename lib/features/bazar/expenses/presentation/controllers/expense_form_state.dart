import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/usecases/check_duplicate.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';

/// How the user says who paid (the three options of roadmap 4.1).
enum FundingChoice { fundPool, memberReimbursable, memberPersonal }

/// The funding source stored on the expense for a [FundingChoice].
extension FundingChoiceMapping on FundingChoice {
  FundingSource get source => this == FundingChoice.fundPool
      ? FundingSource.fund
      : FundingSource.member;

  bool get reimbursable => this == FundingChoice.memberReimbursable;

  bool get needsPayer => this != FundingChoice.fundPool;

  static FundingChoice of(Expense expense) {
    if (expense.funding == FundingSource.fund) return FundingChoice.fundPool;
    return expense.reimbursable
        ? FundingChoice.memberReimbursable
        : FundingChoice.memberPersonal;
  }
}

/// Where an edit-mode form is in loading the expense it edits.
enum ExpenseFormLoad { ready, loading, failed }

const Object _unset = Object();

/// Everything the Add/Edit expense screen shows, in one immutable value.
///
/// The three ids are generated ONCE when the controller is created and survive
/// a failed save, so a retry rewrites the same documents (CLAUDE.md rule 15).
final class ExpenseFormState {
  const ExpenseFormState({
    required this.expenseId,
    required this.eventId,
    required this.newItemId,
    required this.date,
    this.editing = false,
    this.load = ExpenseFormLoad.ready,
    this.itemQuery = '',
    this.item,
    this.customItemName,
    this.categoryId,
    this.rememberItem = false,
    this.qtyText = '',
    this.unit,
    this.unitPriceText = '',
    this.totalText = '',
    this.unitPriceHint,
    this.funding = FundingChoice.fundPool,
    this.paidByMemberId,
    this.shop = '',
    this.note = '',
    this.purchaserId,
    this.fieldErrors = const <String, String>{},
    this.duplicate,
    this.failure,
    this.saving = false,
  });

  final String expenseId;
  final String eventId;
  final String newItemId;
  final DateKey date;
  final bool editing;
  final ExpenseFormLoad load;

  final String itemQuery;
  final Item? item;
  final String? customItemName;
  final String? categoryId;
  final bool rememberItem;

  final String qtyText;
  final Unit? unit;
  final String unitPriceText;
  final String totalText;

  /// The item's last unit price: shown as a hint, never put in the field.
  final Money? unitPriceHint;

  final FundingChoice funding;
  final String? paidByMemberId;
  final String shop;
  final String note;
  final String? purchaserId;

  /// Field name -> stable validation code (see roadmap 3.6).
  final Map<String, String> fieldErrors;
  final DuplicateWarning? duplicate;

  /// A failure that belongs to no single field (permission, network, lock).
  final AppFailure? failure;
  final bool saving;

  /// The name the expense will be saved under.
  String get itemName => (item?.nameBn ?? customItemName ?? itemQuery).trim();

  bool get isNewItem => item == null && itemName.isNotEmpty;

  ExpenseFormState copyWith({
    String? expenseId,
    String? eventId,
    String? newItemId,
    DateKey? date,
    bool? editing,
    ExpenseFormLoad? load,
    String? itemQuery,
    Object? item = _unset,
    Object? customItemName = _unset,
    Object? categoryId = _unset,
    bool? rememberItem,
    String? qtyText,
    Object? unit = _unset,
    String? unitPriceText,
    String? totalText,
    Object? unitPriceHint = _unset,
    FundingChoice? funding,
    Object? paidByMemberId = _unset,
    String? shop,
    String? note,
    Object? purchaserId = _unset,
    Map<String, String>? fieldErrors,
    Object? duplicate = _unset,
    Object? failure = _unset,
    bool? saving,
  }) => ExpenseFormState(
    expenseId: expenseId ?? this.expenseId,
    eventId: eventId ?? this.eventId,
    newItemId: newItemId ?? this.newItemId,
    date: date ?? this.date,
    editing: editing ?? this.editing,
    load: load ?? this.load,
    itemQuery: itemQuery ?? this.itemQuery,
    item: identical(item, _unset) ? this.item : item as Item?,
    customItemName: identical(customItemName, _unset)
        ? this.customItemName
        : customItemName as String?,
    categoryId: identical(categoryId, _unset)
        ? this.categoryId
        : categoryId as String?,
    rememberItem: rememberItem ?? this.rememberItem,
    qtyText: qtyText ?? this.qtyText,
    unit: identical(unit, _unset) ? this.unit : unit as Unit?,
    unitPriceText: unitPriceText ?? this.unitPriceText,
    totalText: totalText ?? this.totalText,
    unitPriceHint: identical(unitPriceHint, _unset)
        ? this.unitPriceHint
        : unitPriceHint as Money?,
    funding: funding ?? this.funding,
    paidByMemberId: identical(paidByMemberId, _unset)
        ? this.paidByMemberId
        : paidByMemberId as String?,
    shop: shop ?? this.shop,
    note: note ?? this.note,
    purchaserId: identical(purchaserId, _unset)
        ? this.purchaserId
        : purchaserId as String?,
    fieldErrors: fieldErrors ?? this.fieldErrors,
    duplicate: identical(duplicate, _unset)
        ? this.duplicate
        : duplicate as DuplicateWarning?,
    failure: identical(failure, _unset) ? this.failure : failure as AppFailure?,
    saving: saving ?? this.saving,
  );
}

/// The arguments of one form instance.  `editingId == null` adds an expense.
final class ExpenseFormArgs {
  const ExpenseFormArgs({this.editingId});

  final String? editingId;

  @override
  bool operator ==(Object other) =>
      other is ExpenseFormArgs && other.editingId == editingId;

  @override
  int get hashCode => editingId.hashCode;
}

/// What a successful save returns to the screen.
final class ExpenseSaveOutcome {
  const ExpenseSaveOutcome({required this.expense, required this.addAnother});

  final Expense expense;
  final bool addAnother;
}
