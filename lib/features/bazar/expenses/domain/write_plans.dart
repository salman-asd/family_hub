import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/trip.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item_usage_bump.dart';

/// Everything one add writes, staged as a single batch by the repository.
final class ExpenseWritePlan {
  const ExpenseWritePlan({
    required this.expense,
    this.fundTx,
    this.advance,
    this.usage,
    this.newItem,
  });

  final Expense expense;
  final FundTransaction? fundTx;
  final MemberAdvance? advance;
  final ItemUsageBump? usage;
  final Item? newItem;
}

/// A trip header plus its lines and one aggregated usage bump per item.
final class TripWritePlan {
  const TripWritePlan({
    required this.trip,
    required this.lines,
    required this.usage,
  });

  final Trip trip;
  final List<ExpenseWritePlan> lines;
  final List<ItemUsageBump> usage;
}

/// The advance document change caused by an edit/delete/restore.
final class AdvanceChange {
  const AdvanceChange({required this.after, this.isNew = false});

  final MemberAdvance after;

  /// True when no advance document existed before this change; the repository
  /// then writes it with `set` instead of `update`.
  final bool isNew;
}

/// A content edit: the new expense, the changed old values, ledger repair rows
/// and an optional advance change.
final class ExpenseEditPlan {
  const ExpenseEditPlan({
    required this.updated,
    required this.before,
    required this.changedFields,
    required this.adjustments,
    this.advanceChange,
  });

  final Expense updated;
  final Map<String, Object?> before;
  final List<String> changedFields;
  final List<FundTransaction> adjustments;
  final AdvanceChange? advanceChange;
}

/// A soft delete: the row with `deletedAt/By`, the old values and ledger repair.
final class ExpenseDeletePlan {
  const ExpenseDeletePlan({
    required this.updated,
    required this.before,
    required this.adjustments,
    this.advanceChange,
  });

  final Expense updated;
  final Map<String, Object?> before;
  final List<FundTransaction> adjustments;
  final AdvanceChange? advanceChange;
}

/// A restore: the row with `deletedAt/By` cleared and ledger repair.
final class ExpenseRestorePlan {
  const ExpenseRestorePlan({
    required this.updated,
    required this.before,
    required this.adjustments,
    this.advanceChange,
  });

  final Expense updated;
  final Map<String, Object?> before;
  final List<FundTransaction> adjustments;
  final AdvanceChange? advanceChange;
}
