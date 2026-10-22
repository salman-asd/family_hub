import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';

/// Read port for the append-only fund ledger and month closings.
///
/// The write methods arrive with the use cases that need them (P2-19…P2-21);
/// this step only fixes the shapes those repositories must provide.
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
}
