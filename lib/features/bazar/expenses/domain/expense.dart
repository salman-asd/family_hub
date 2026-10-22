import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';

const Object _unset = Object();

/// One bazar expense (`families/{f}/expenses/{id}`).
///
/// Money is signed only in the ledger; [total] here is always positive paisa.
/// A member-funded row names its payer, a fund-funded row never does.
final class Expense {
  Expense({
    required this.id,
    required this.dateKey,
    required this.monthKey,
    required this.occurredAt,
    this.itemId,
    required this.itemName,
    required this.categoryId,
    this.qty,
    this.unit,
    this.unitPrice,
    required this.total,
    required this.funding,
    this.paidByMemberId,
    this.reimbursable = false,
    this.purchaserId,
    this.tripId,
    this.shop,
    this.note,
    this.source = ExpenseSource.manual,
    this.importBatchId,
    this.deletedAt,
    this.deletedBy,
    required this.createdBy,
    required this.createdAt,
  }) : assert(total.paisa > 0, 'expense total must be positive'),
       assert(
         (funding == FundingSource.member) == (paidByMemberId != null),
         'member funding requires a payer and fund funding forbids one',
       ),
       assert(
         funding == FundingSource.member || !reimbursable,
         'reimbursable is only meaningful for member funding',
       ),
       assert(
         monthKey.year == dateKey.year && monthKey.month == dateKey.month,
         'monthKey must match dateKey',
       );

  final String id;
  final DateKey dateKey;
  final MonthKey monthKey;
  final DateTime occurredAt;
  final String? itemId;
  final String itemName;
  final String categoryId;
  final Quantity? qty;
  final Unit? unit;
  final Money? unitPrice;
  final Money total;

  final FundingSource funding;
  final String? paidByMemberId;
  final bool reimbursable;

  final String? purchaserId;
  final String? tripId;
  final String? shop;
  final String? note;
  final ExpenseSource source;
  final String? importBatchId;

  final DateTime? deletedAt;
  final String? deletedBy;
  final String createdBy;
  final DateTime createdAt;

  bool get isDeleted => deletedAt != null;

  /// The person the expense is attributed to for reports and filters.
  String get spenderId => purchaserId ?? paidByMemberId ?? createdBy;

  /// Copies the row.  Passing `null` for an optional field clears it; omitting
  /// the argument keeps the current value.
  Expense copyWith({
    DateKey? dateKey,
    MonthKey? monthKey,
    DateTime? occurredAt,
    Object? itemId = _unset,
    String? itemName,
    String? categoryId,
    Object? qty = _unset,
    Object? unit = _unset,
    Object? unitPrice = _unset,
    Money? total,
    FundingSource? funding,
    Object? paidByMemberId = _unset,
    bool? reimbursable,
    Object? purchaserId = _unset,
    Object? tripId = _unset,
    Object? shop = _unset,
    Object? note = _unset,
    ExpenseSource? source,
    Object? importBatchId = _unset,
    Object? deletedAt = _unset,
    Object? deletedBy = _unset,
    String? createdBy,
    DateTime? createdAt,
  }) => Expense(
    id: id,
    dateKey: dateKey ?? this.dateKey,
    monthKey: monthKey ?? this.monthKey,
    occurredAt: occurredAt ?? this.occurredAt,
    itemId: identical(itemId, _unset) ? this.itemId : itemId as String?,
    itemName: itemName ?? this.itemName,
    categoryId: categoryId ?? this.categoryId,
    qty: identical(qty, _unset) ? this.qty : qty as Quantity?,
    unit: identical(unit, _unset) ? this.unit : unit as Unit?,
    unitPrice: identical(unitPrice, _unset)
        ? this.unitPrice
        : unitPrice as Money?,
    total: total ?? this.total,
    funding: funding ?? this.funding,
    paidByMemberId: identical(paidByMemberId, _unset)
        ? this.paidByMemberId
        : paidByMemberId as String?,
    reimbursable: reimbursable ?? this.reimbursable,
    purchaserId: identical(purchaserId, _unset)
        ? this.purchaserId
        : purchaserId as String?,
    tripId: identical(tripId, _unset) ? this.tripId : tripId as String?,
    shop: identical(shop, _unset) ? this.shop : shop as String?,
    note: identical(note, _unset) ? this.note : note as String?,
    source: source ?? this.source,
    importBatchId: identical(importBatchId, _unset)
        ? this.importBatchId
        : importBatchId as String?,
    deletedAt: identical(deletedAt, _unset)
        ? this.deletedAt
        : deletedAt as DateTime?,
    deletedBy: identical(deletedBy, _unset)
        ? this.deletedBy
        : deletedBy as String?,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Expense &&
      other.id == id &&
      other.dateKey == dateKey &&
      other.monthKey == monthKey &&
      other.occurredAt == occurredAt &&
      other.itemId == itemId &&
      other.itemName == itemName &&
      other.categoryId == categoryId &&
      other.qty == qty &&
      other.unit == unit &&
      other.unitPrice == unitPrice &&
      other.total == total &&
      other.funding == funding &&
      other.paidByMemberId == paidByMemberId &&
      other.reimbursable == reimbursable &&
      other.purchaserId == purchaserId &&
      other.tripId == tripId &&
      other.shop == shop &&
      other.note == note &&
      other.source == source &&
      other.importBatchId == importBatchId &&
      other.deletedAt == deletedAt &&
      other.deletedBy == deletedBy &&
      other.createdBy == createdBy &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    dateKey,
    monthKey,
    occurredAt,
    itemId,
    itemName,
    categoryId,
    qty,
    unit,
    unitPrice,
    total,
    funding,
    paidByMemberId,
    reimbursable,
    purchaserId,
    tripId,
    shop,
    note,
    source,
    importBatchId,
    deletedAt,
    deletedBy,
    createdBy,
    createdAt,
  ]);

  @override
  String toString() => 'Expense($id, $itemName, ${total.paisa} paisa)';
}
