import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/permissions/permission.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/date_ranges.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution_repository.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense_repository.dart';
import 'package:family_hub/features/bazar/reports/domain/report_export_rows.dart';
import 'package:family_hub/features/bazar/reports/domain/report_loader.dart';
import 'package:family_hub/features/bazar/reports/domain/report_query.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

final class ExportReportRows {
  const ExportReportRows(
    this._expenses,
    this._contributions,
    this._occurrences,
    this._families, {
    this.maxDocs = kMaxReportDocs,
  });

  final ExpenseRepository _expenses;
  final ContributionRepository _contributions;
  final OccurrenceRepository _occurrences;
  final FamilyRepository _families;
  final int maxDocs;

  Future<Result<ReportExportRows>> call({
    required String familyId,
    required String actorUid,
    required DateKeyRange range,
  }) async {
    final permission = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.exportData,
    );
    final denied = permission.failureOrNull;
    if (denied != null) return Failure<ReportExportRows>(denied);

    final expenseResult = await loadRange(
      _expenses,
      familyId,
      ReportQuery(preset: RangePreset.custom, range: range),
      maxDocs: maxDocs,
    );
    final expenseFailure = expenseResult.failureOrNull;
    if (expenseFailure != null) {
      return Failure<ReportExportRows>(expenseFailure);
    }
    final expenseLoad = expenseResult.valueOrNull!;
    if (expenseLoad.truncated) {
      return const Failure<ReportExportRows>(
        Validation('range', 'export_limit'),
      );
    }

    final contributions = <Contribution>[];
    for (
      var month = range.start.monthKey;
      month.compareTo(range.end.monthKey) <= 0;
      month = month.addMonths(1)
    ) {
      final page = await _contributions
          .watchContributions(familyId, month)
          .first;
      if (page.length >= kMaxListenerDocs ||
          contributions.length + page.length > maxDocs) {
        return const Failure<ReportExportRows>(
          Validation('range', 'export_limit'),
        );
      }
      contributions.addAll(
        page.where(
          (row) =>
              !row.dateKey.isBefore(range.start) &&
              !row.dateKey.isAfter(range.end),
        ),
      );
    }

    final choreResult = await _occurrences.listRangeOnce(
      familyId,
      from: range.start,
      to: range.end,
      limit: maxDocs + 1,
    );
    final choreFailure = choreResult.failureOrNull;
    if (choreFailure != null) return Failure<ReportExportRows>(choreFailure);
    final chores = choreResult.valueOrNull!;
    if (chores.length > maxDocs) {
      return const Failure<ReportExportRows>(
        Validation('range', 'export_limit'),
      );
    }
    return Success<ReportExportRows>(
      ReportExportRows(
        expenses: expenseLoad.expenses,
        contributions: contributions,
        chores: chores,
      ),
    );
  }
}
