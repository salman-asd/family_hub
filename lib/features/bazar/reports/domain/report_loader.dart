import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/reports/domain/report_query.dart';

/// The rows a report loaded, and whether the cap cut them off.
final class ReportLoad {
  ReportLoad({required List<Expense> expenses, required this.truncated})
    : expenses = List<Expense>.unmodifiable(expenses);

  final List<Expense> expenses;

  /// `true` when [kMaxReportDocs] rows were reached and more may exist: the
  /// screen then tells the user to shorten the range instead of paging forever.
  final bool truncated;

  int get count => expenses.length;
}

/// Loads every expense of a range, page by page, up to [kMaxReportDocs].
///
/// Each page is `queryRange(..., limit: kReportPageSize, startAfter: last)`,
/// the same `(dateKey DESC, id DESC)` continuation the expense list uses, so a
/// report never needs an unbounded query (rule 11) and a failure stops the
/// load with that failure instead of returning a half report silently.
///
/// The filters are applied by the ENGINE (`ReportEngine.build`), not here: a
/// category/item/member filter would otherwise leave the per-category and
/// per-member breakdowns empty.
Future<Result<ReportLoad>> loadRange(
  ExpenseRepository expenses,
  String familyId,
  ReportQuery query, {
  int maxDocs = kMaxReportDocs,
  int pageSize = kReportPageSize,
}) async {
  assert(pageSize > 0 && maxDocs > 0, 'page size and cap must be positive');
  final range = query.resolvedRange;
  final rows = <Expense>[];
  Expense? cursor;

  while (rows.length < maxDocs) {
    final take = (maxDocs - rows.length).clamp(1, pageSize);
    final page = await expenses.queryRange(
      familyId,
      range,
      purchaserId: query.memberId,
      funding: query.funding,
      limit: take,
      startAfter: cursor,
    );
    final failure = page.failureOrNull;
    if (failure != null) return Failure<ReportLoad>(failure);
    final batch = page.valueOrNull ?? const <Expense>[];
    rows.addAll(batch);
    // A short page is the last one; an empty page cannot advance the cursor.
    if (batch.length < take) {
      return Success<ReportLoad>(
        ReportLoad(expenses: rows, truncated: false),
      );
    }
    final last = batch.last;
    // A server that keeps returning the same cursor would loop forever.
    if (cursor != null && last.id == cursor.id) break;
    cursor = last;
  }

  return Success<ReportLoad>(ReportLoad(expenses: rows, truncated: true));
}


