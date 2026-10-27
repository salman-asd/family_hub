import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/domain/month_plans.dart';

/// Port for the append-only fund ledger and the month closings.
abstract interface class FundRepository {
  /// Ledger rows with `monthKey >= from`, newest first.
  Stream<List<FundTransaction>> watchTransactionsFrom(
    String familyId,
    MonthKey from,
  );

  Future<Result<List<FundTransaction>>> getMonthTransactions(
    String familyId,
    MonthKey month,
  );

  Future<Result<List<FundTransaction>>> getTransactionsForRef(
    String familyId,
    String refId,
  );

  Stream<List<MonthClosing>> watchClosings(String familyId);

  Future<Result<MonthClosing?>> getClosing(String familyId, MonthKey month);

  /// The ledger rows with `monthKey >= from`, read from the SERVER.
  ///
  /// Used only by `CloseMonth`: the closing balance must not come from a
  /// cached copy, and the mobile SDK cannot query inside a transaction, so the
  /// read happens just before the batch (see ADR 0007 and the P2-21 card).
  Future<Result<List<FundTransaction>>> getTransactionsFromServer(
    String familyId,
    MonthKey from,
  );

  /// Writes the closing and the carry-forward in ONE batch.  Needs the server.
  Future<Result<void>> commitClose(
    String familyId,
    MonthClosePlan plan,
    AuditEvent event,
  );

  /// Writes the reopened month document in ONE batch.  Needs the server.
  Future<Result<void>> commitReopen(
    String familyId,
    MonthReopenPlan plan,
    AuditEvent event,
  );
}
