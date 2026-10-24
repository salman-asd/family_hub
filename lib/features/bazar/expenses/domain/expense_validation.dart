import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_draft.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';

/// The shared validation order for add, trip and edit.
///
/// Returns `null` when the draft may be priced.  A fund-funded draft ignores a
/// stale payer/reimbursable flag; a member-funded draft must name one.
AppFailure? validateExpenseDraft(ExpenseDraft draft, {required DateKey today}) {
  final itemName = draft.itemName.trim();
  if (itemName.isEmpty) {
    return const Validation('itemName', 'item_name_required');
  }
  if (itemName.runes.length > 80) {
    return const Validation('itemName', 'too_long');
  }

  if (draft.categoryId.trim().isEmpty) {
    return const Validation('categoryId', 'category_required');
  }

  if (draft.dateKey.isAfter(today)) {
    return const Validation('dateKey', 'future_date');
  }

  if (draft.funding == FundingSource.member &&
      (draft.paidByMemberId ?? '').trim().isEmpty) {
    return const Validation('paidByMemberId', 'member_required');
  }

  if ((draft.shop ?? '').trim().runes.length > 60) {
    return const Validation('shop', 'too_long');
  }
  if ((draft.note ?? '').trim().runes.length > 500) {
    return const Validation('note', 'too_long');
  }
  return null;
}

/// Trimmed required text.
String cleanRequired(String value) => value.trim();

/// Trimmed optional text; blank becomes `null`.
String? cleanOptional(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
