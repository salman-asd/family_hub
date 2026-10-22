import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/firebase/audit_writer.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/bazar/advances/data/advance_mappers.dart';
import 'package:family_hub/features/bazar/expenses/data/expense_mappers.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/expenses/domain/write_plans.dart';
import 'package:family_hub/features/bazar/fund/data/fund_mappers.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/items_categories/data/catalog_mappers.dart';
import 'package:family_hub/features/bazar/items_categories/domain/item_usage_bump.dart';

/// Stages the documents of one expense write plan in a single batch.
///
/// The repository owns the transaction; this class only translates entities to
/// maps, so every commit stays a flat, reviewable list of `set`/`update` calls.
class ExpenseWriteStager {
  const ExpenseWriteStager({required this._clock});

  final Clock _clock;

  BaseDocumentMetadata _meta(String uid) =>
      BaseMapper.createMetadata(uid: uid, clock: _clock);

  void stageAdd(
    BatchContext batch,
    String familyId,
    ExpenseWritePlan plan,
    AuditEvent event,
  ) {
    _stagePlan(batch, familyId, plan, event.actorId);
    AuditWriter.write(batch, familyId, event);
  }

  void stageTrip(
    BatchContext batch,
    String familyId,
    TripWritePlan plan,
    AuditEvent event,
  ) {
    batch.set(
      FirestorePaths.bazarTripDoc(familyId, plan.trip.id),
      ExpenseMappers.tripToMap(plan.trip, _meta(event.actorId)),
    );
    for (final line in plan.lines) {
      _stagePlan(batch, familyId, line, event.actorId);
    }
    for (final bump in plan.usage) {
      stageUsage(batch, familyId, bump, event.actorId);
    }
    AuditWriter.write(batch, familyId, event);
  }

  void stageEdit(
    BatchContext batch,
    String familyId,
    ExpenseEditPlan plan,
    AuditEvent event,
  ) {
    batch.update(
      FirestorePaths.expenseDoc(familyId, plan.updated.id),
      ExpenseMappers.expenseChangeMap(
        plan.updated,
        actorUid: event.actorId,
        now: _clock.nowUtc(),
      ),
    );
    _stageRevision(
      batch,
      familyId,
      plan.updated.id,
      event,
      plan.before,
      plan.changedFields,
    );
    _stageAdjustments(batch, familyId, plan.adjustments, event.actorId);
    _stageAdvanceChange(batch, familyId, plan.advanceChange, event.actorId);
    AuditWriter.write(batch, familyId, event);
  }

  void stageSoftDelete(
    BatchContext batch,
    String familyId,
    Expense updated,
    Map<String, Object?> before,
    List<FundTransaction> adjustments,
    AdvanceChange? advanceChange,
    AuditEvent event,
  ) {
    batch.update(
      FirestorePaths.expenseDoc(familyId, updated.id),
      ExpenseMappers.expenseSoftDeleteMap(
        updated,
        actorUid: event.actorId,
        now: _clock.nowUtc(),
      ),
    );
    _stageRevision(batch, familyId, updated.id, event, before, const <String>[
      'deletedAt',
      'deletedBy',
    ]);
    _stageAdjustments(batch, familyId, adjustments, event.actorId);
    _stageAdvanceChange(batch, familyId, advanceChange, event.actorId);
    AuditWriter.write(batch, familyId, event);
  }

  void stageUsage(
    BatchContext batch,
    String familyId,
    ItemUsageBump bump,
    String actorUid,
  ) {
    batch.update(
      FirestorePaths.bazarItemDoc(familyId, bump.itemId),
      CatalogMappers.itemUsageMap(
        bump,
        actorUid: actorUid,
        now: _clock.nowUtc(),
      ),
    );
  }

  void _stagePlan(
    BatchContext batch,
    String familyId,
    ExpenseWritePlan plan,
    String actorUid,
  ) {
    batch.set(
      FirestorePaths.expenseDoc(familyId, plan.expense.id),
      ExpenseMappers.expenseToMap(plan.expense, _meta(actorUid)),
    );
    if (plan.fundTx != null) {
      batch.set(
        FirestorePaths.fundTransactionDoc(familyId, plan.fundTx!.id),
        FundMappers.fundTxToMap(plan.fundTx!, _meta(actorUid)),
      );
    }
    if (plan.advance != null) {
      batch.set(
        FirestorePaths.memberAdvanceDoc(familyId, plan.advance!.expenseId),
        AdvanceMappers.advanceToMap(plan.advance!, _meta(actorUid)),
      );
    }
    if (plan.newItem != null) {
      batch.set(
        FirestorePaths.bazarItemDoc(familyId, plan.newItem!.id),
        CatalogMappers.itemToMap(plan.newItem!, _meta(actorUid)),
      );
    }
    if (plan.usage != null) {
      stageUsage(batch, familyId, plan.usage!, actorUid);
    }
  }

  void _stageAdjustments(
    BatchContext batch,
    String familyId,
    List<FundTransaction> rows,
    String actorUid,
  ) {
    for (final row in rows) {
      batch.set(
        FirestorePaths.fundTransactionDoc(familyId, row.id),
        FundMappers.fundTxToMap(row, _meta(actorUid)),
      );
    }
  }

  void _stageRevision(
    BatchContext batch,
    String familyId,
    String expenseId,
    AuditEvent event,
    Map<String, Object?> before,
    List<String> changedFields,
  ) {
    batch.set(
      FirestorePaths.expenseRevisionDoc(familyId, expenseId, event.id),
      ExpenseMappers.revisionToMap(
        ExpenseRevision(
          id: event.id,
          before: before,
          changedFields: changedFields,
          at: event.at,
          by: event.actorId,
        ),
        _meta(event.actorId),
      ),
    );
  }

  void _stageAdvanceChange(
    BatchContext batch,
    String familyId,
    AdvanceChange? change,
    String actorUid,
  ) {
    if (change == null) return;
    final path = FirestorePaths.memberAdvanceDoc(
      familyId,
      change.after.expenseId,
    );
    if (change.isNew) {
      batch.set(
        path,
        AdvanceMappers.advanceToMap(change.after, _meta(actorUid)),
      );
    } else {
      batch.update(
        path,
        AdvanceMappers.advanceChangeMap(
          change.after,
          actorUid: actorUid,
          now: _clock.nowUtc(),
        ),
      );
    }
  }
}
