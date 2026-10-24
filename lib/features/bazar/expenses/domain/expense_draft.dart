import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/core/utils/quantity.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';

/// Validated-but-not-saved input from the expense form.
///
/// The draft may contain a stale payer after the user switches funding; the
/// use case normalises that before building an [Expense].
final class ExpenseDraft {
  const ExpenseDraft({
    required this.dateKey,
    this.itemId,
    required this.itemName,
    required this.categoryId,
    this.qty,
    this.unit,
    this.unitPrice,
    this.typedTotal,
    this.funding = FundingSource.fund,
    this.paidByMemberId,
    this.reimbursable = false,
    this.purchaserId,
    this.shop,
    this.note,
    this.rememberItem = false,
  });

  final DateKey dateKey;
  final String? itemId;
  final String itemName;
  final String categoryId;
  final Quantity? qty;
  final Unit? unit;
  final Money? unitPrice;
  final Money? typedTotal;
  final FundingSource funding;
  final String? paidByMemberId;
  final bool reimbursable;
  final String? purchaserId;
  final String? shop;
  final String? note;
  final bool rememberItem;
}
