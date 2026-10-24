import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/expenses/data/expense_mappers.dart';
import 'package:family_hub/features/bazar/expenses/data/expense_write_stager.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/expenses/domain/write_plans.dart';

/// Firestore implementation of the expense port.
///
/// Every plan is one `runBatch` through `guardWrite` with no server probe, so
/// an expense, its ledger row, advance and usage bump queue together offline.
class FirestoreExpenseRepository implements ExpenseRepository {
  FirestoreExpenseRepository({
    required this._tx,
    required this._clock,
    this._firestore,
  });

  final TxRunner _tx;
  final Clock _clock;
  final FirebaseFirestore? _firestore;

  late final ExpenseWriteStager _stager = ExpenseWriteStager(clock: _clock);

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Future<Result<void>> commitAdd(
    String familyId,
    ExpenseWritePlan plan,
    AuditEvent event,
  ) => guardWrite(
    () => _tx.runBatch((batch) {
      _stager.stageAdd(batch, familyId, plan, event);
    }),
  );

  @override
  Future<Result<void>> commitTrip(
    String familyId,
    TripWritePlan plan,
    AuditEvent event,
  ) => guardWrite(
    () => _tx.runBatch((batch) {
      _stager.stageTrip(batch, familyId, plan, event);
    }),
  );

  @override
  Future<Result<void>> commitEdit(
    String familyId,
    ExpenseEditPlan plan,
    AuditEvent event,
  ) => guardWrite(
    () => _tx.runBatch((batch) {
      _stager.stageEdit(batch, familyId, plan, event);
    }),
  );

  @override
  Future<Result<void>> commitDelete(
    String familyId,
    ExpenseDeletePlan plan,
    AuditEvent event,
  ) => guardWrite(
    () => _tx.runBatch((batch) {
      _stager.stageSoftDelete(
        batch,
        familyId,
        plan.updated,
        plan.before,
        plan.adjustments,
        plan.advanceChange,
        event,
      );
    }),
  );

  @override
  Future<Result<void>> commitRestore(
    String familyId,
    ExpenseRestorePlan plan,
    AuditEvent event,
  ) => guardWrite(
    () => _tx.runBatch((batch) {
      _stager.stageSoftDelete(
        batch,
        familyId,
        plan.updated,
        plan.before,
        plan.adjustments,
        plan.advanceChange,
        event,
      );
    }),
  );

  @override
  Future<Result<Expense?>> getExpense(String familyId, String id) =>
      guardFirestore(() async {
        final snapshot = await _db
            .doc(FirestorePaths.expenseDoc(familyId, id))
            .get();
        if (!snapshot.exists) return null;
        return ExpenseMappers.expenseFromMap(id, snapshot.data()!);
      });

  @override
  Future<Result<List<Expense>>> getByDate(
    String familyId,
    DateKey date, {
    int limit = 50,
  }) => guardFirestore(() async {
    final snapshot = await _db
        .collection(FirestorePaths.expenses(familyId))
        .where('dateKey', isEqualTo: date.toString())
        .limit(limit)
        .get();
    final rows = <Expense>[
      for (final document in snapshot.docs)
        ExpenseMappers.expenseFromMap(document.id, document.data()),
    ]..sort(_newestFirst);
    return rows;
  });

  @override
  Stream<List<Expense>> watchMonth(String familyId, MonthKey month) => _db
      .collection(FirestorePaths.expenses(familyId))
      .where('monthKey', isEqualTo: month.toString())
      .orderBy('dateKey', descending: true)
      .limit(kMaxListenerDocs)
      .snapshots()
      .map(_toExpenses);

  @override
  Future<Result<List<Expense>>> queryRange(
    String familyId,
    DateKeyRange range, {
    String? categoryId,
    String? itemId,
    String? purchaserId,
    FundingSource? funding,
    int limit = defaultExpensePageSize,
    Expense? startAfter,
  }) => guardFirestore(() async {
    var query = _db
        .collection(FirestorePaths.expenses(familyId))
        .limit(limit)
        .where('dateKey', isGreaterThanOrEqualTo: range.start.toString())
        .where('dateKey', isLessThanOrEqualTo: range.end.toString());
    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    if (itemId != null) query = query.where('itemId', isEqualTo: itemId);
    if (purchaserId != null) {
      query = query.where('purchaserId', isEqualTo: purchaserId);
    }
    if (funding != null) {
      query = query.where('fundingSource', isEqualTo: funding.name);
    }
    // dateKey alone is not unique: the document id breaks ties, so a page that
    // ends in the middle of a day resumes at the next row, not the next day.
    // (dateKey DESC, __name__ DESC) is covered by the same composite indexes.
    query = query
        .orderBy('dateKey', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
    if (startAfter != null) {
      query = query.startAfter(<Object>[
        startAfter.dateKey.toString(),
        startAfter.id,
      ]);
    }
    final snapshot = await query.get();
    return _toExpenses(snapshot);
  });

  @override
  Stream<List<ExpenseRevision>> watchRevisions(
    String familyId,
    String expenseId,
  ) => _db
      .collection(FirestorePaths.expenseRevisions(familyId, expenseId))
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map(
        (snapshot) => <ExpenseRevision>[
          for (final document in snapshot.docs)
            ExpenseMappers.revisionFromMap(document.id, document.data()),
        ],
      );

  List<Expense> _toExpenses(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      <Expense>[
        for (final document in snapshot.docs)
          ExpenseMappers.expenseFromMap(document.id, document.data()),
      ];

  int _newestFirst(Expense a, Expense b) {
    final byDate = b.dateKey.compareTo(a.dateKey);
    if (byDate != 0) return byDate;
    final byTime = b.occurredAt.compareTo(a.occurredAt);
    return byTime != 0 ? byTime : b.id.compareTo(a.id);
  }
}
