import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';

/// Port for `budgets/{yyyy-MM}`.
abstract interface class BudgetRepository {
  /// Live budget of [month]; `null` when none has been saved.
  Stream<Budget?> watchBudget(String familyId, MonthKey month);

  /// One-shot read (cache-friendly, so it also answers offline when cached).
  Future<Result<Budget?>> getBudget(String familyId, MonthKey month);

  /// Writes the whole budget and its audit entry in ONE batch.  An everyday
  /// write: it queues offline.
  Future<Result<void>> saveBudget(
    String familyId,
    Budget budget,
    AuditEvent event,
  );
}
