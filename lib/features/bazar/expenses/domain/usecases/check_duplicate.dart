import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_draft.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/items_categories/domain/text_normalizer.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// A likely accidental duplicate, never a hard failure.
final class DuplicateWarning {
  const DuplicateWarning(this.expense);

  final Expense expense;

  String get expenseId => expense.id;

  Expense get existing => expense;
}

/// Looks for the same item and amount within ten minutes.
///
/// The caller has already computed [total]; this use case only reads the
/// selected day.  A missing permission is a failure, a duplicate is a warning.
class CheckDuplicate {
  const CheckDuplicate({
    required this._expenses,
    required this._families,
    required this._clock,
  });

  final ExpenseRepository _expenses;
  final FamilyRepository _families;
  final Clock _clock;

  Future<Result<DuplicateWarning?>> call({
    required String familyId,
    required ExpenseDraft draft,
    required Money total,
    String? actorUid,
  }) async {
    if (actorUid != null) {
      final actor = await requirePermission(
        _families,
        familyId: familyId,
        actorUid: actorUid,
        permission: Permission.addOwnExpense,
        ownerId: actorUid,
      );
      final denied = actor.failureOrNull;
      if (denied != null) return Failure<DuplicateWarning?>(denied);
    }

    final loaded = await _expenses.getByDate(familyId, draft.dateKey);
    final failure = loaded.failureOrNull;
    if (failure != null) return Failure<DuplicateWarning?>(failure);

    final now = _clock.nowUtc();
    final key = normalizeSearch(draft.itemName);
    final matches = <Expense>[];
    for (final expense in loaded.valueOrNull ?? const <Expense>[]) {
      if (expense.isDeleted || expense.total != total) continue;
      final itemMatches =
          (draft.itemId != null && expense.itemId == draft.itemId) ||
          (key.isNotEmpty && normalizeSearch(expense.itemName) == key);
      if (!itemMatches) continue;
      final age = now.difference(expense.createdAt);
      if (age < Duration.zero || age > const Duration(minutes: 10)) continue;
      matches.add(expense);
    }

    if (matches.isEmpty) return const Success<DuplicateWarning?>(null);
    matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success<DuplicateWarning?>(DuplicateWarning(matches.first));
  }
}
