import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/audit_writer.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/doc_watch.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/budgets/data/budget_mappers.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget.dart';
import 'package:family_hub/features/bazar/budgets/domain/budget_repository.dart';

/// Firestore implementation of [BudgetRepository].
///
/// The document id is the month key.  A save is ONE batch (the full budget plus
/// its audit entry) with no server probe, so it queues offline.  The original
/// author and creation time come from the [Budget] itself, which means a
/// re-save needs no read first.
class FirestoreBudgetRepository implements BudgetRepository {
  FirestoreBudgetRepository({
    required this._tx,
    this._firestore,
  });

  final TxRunner _tx;
  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  String _path(String familyId, MonthKey month) =>
      FirestorePaths.budgetDoc(familyId, month.toString());

  @override
  Stream<Budget?> watchBudget(String familyId, MonthKey month) =>
      watchKnownDoc(_db.doc(_path(familyId, month))).map(
        (data) =>
            data == null ? null : BudgetMappers.fromMap(month.toString(), data),
      );

  @override
  Future<Result<Budget?>> getBudget(String familyId, MonthKey month) =>
      guardFirestore<Budget?>(() async {
        final snapshot = await _db.doc(_path(familyId, month)).get();
        final data = snapshot.data();
        if (!snapshot.exists || data == null) return null;
        return BudgetMappers.fromMap(month.toString(), data);
      });

  @override
  Future<Result<void>> saveBudget(
    String familyId,
    Budget budget,
    AuditEvent event,
  ) => guardWrite(
    () => _tx.runBatch((batch) {
      final meta = BaseDocumentMetadata(
        createdAt: budget.createdAt ?? event.at,
        createdBy: budget.createdBy ?? event.actorId,
        updatedAt: event.at,
        updatedBy: event.actorId,
      );
      batch.set(_path(familyId, budget.month), BudgetMappers.toMap(budget, meta));
      AuditWriter.write(batch, familyId, event);
    }),
  );
}
