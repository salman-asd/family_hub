import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/write_plans.dart';

/// Page size for range queries; the screen's month listener uses the larger
/// `kMaxListenerDocs` cap in the data layer.
const int defaultExpensePageSize = 30;

/// One entry in an expense's append-only revision history.
final class ExpenseRevision {
  const ExpenseRevision({
    required this.id,
    required this.before,
    required this.changedFields,
    this.reason,
    required this.at,
    required this.by,
  });

  final String id;
  final Map<String, Object?> before;
  final List<String> changedFields;
  final String? reason;
  final DateTime at;
  final String by;

  @override
  bool operator ==(Object other) =>
      other is ExpenseRevision &&
      other.id == id &&
      _sameMap(other.before, before) &&
      _sameList(other.changedFields, changedFields) &&
      other.reason == reason &&
      other.at == at &&
      other.by == by;

  @override
  int get hashCode => Object.hash(
    id,
    Object.hashAll(before.entries.map((e) => Object.hash(e.key, e.value))),
    Object.hashAll(changedFields),
    reason,
    at,
    by,
  );

  @override
  String toString() => 'ExpenseRevision($id, ${changedFields.join(', ')})';
}

bool _sameMap(Map<String, Object?> a, Map<String, Object?> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Port for the expense collection and its revision subcollection.
///
/// Plans are staged by the repository in one batch; the use cases never touch
/// Firestore.  Reads return `Network`/`Unknown` unchanged so callers can show
/// the offline state instead of treating a missing page as empty.
abstract interface class ExpenseRepository {
  Future<Result<void>> commitAdd(
    String familyId,
    ExpenseWritePlan plan,
    AuditEvent event,
  );

  Future<Result<void>> commitTrip(
    String familyId,
    TripWritePlan plan,
    AuditEvent event,
  );

  Future<Result<void>> commitEdit(
    String familyId,
    ExpenseEditPlan plan,
    AuditEvent event,
  );

  Future<Result<void>> commitDelete(
    String familyId,
    ExpenseDeletePlan plan,
    AuditEvent event,
  );

  Future<Result<void>> commitRestore(
    String familyId,
    ExpenseRestorePlan plan,
    AuditEvent event,
  );

  Future<Result<Expense?>> getExpense(String familyId, String id);

  Future<Result<List<Expense>>> getByDate(
    String familyId,
    DateKey date, {
    int limit = 50,
  });

  Stream<List<Expense>> watchMonth(String familyId, MonthKey month);

  Future<Result<List<Expense>>> queryRange(
    String familyId,
    DateKeyRange range, {
    String? categoryId,
    String? itemId,
    String? purchaserId,
    FundingSource? funding,
    int limit = defaultExpensePageSize,
    Expense? startAfter,
  });

  Stream<List<ExpenseRevision>> watchRevisions(
    String familyId,
    String expenseId,
  );
}
