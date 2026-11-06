import 'package:csv/csv.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/bazar/expenses/domain/funding.dart';
import 'package:family_hub/features/bazar/reports/data/report_csv_builder.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense CSV round-trips commas, quotes, and paisa amounts', () {
    final expense = Expense(
      id: 'exp-1',
      dateKey: DateKey(2026, 4, 3),
      monthKey: MonthKey(2026, 4),
      occurredAt: DateTime.utc(2026, 4, 3),
      itemName: 'rice, "fine"',
      categoryId: 'dry',
      total: const Money.paisa(12345),
      funding: FundingSource.fund,
      createdBy: 'member-1',
      createdAt: DateTime.utc(2026, 4, 3),
    );

    final decoded = Csv().decode(ReportCsvBuilder.expenses([expense]));

    expect(decoded.first, contains('total_paisa'));
    expect(decoded[1][2], 'rice, "fine"');
    expect(decoded[1][4], '12345');
  });

  test('contribution CSV preserves status and identifiers', () {
    final contribution = Contribution(
      id: 'con-1',
      memberId: 'member-1',
      monthKey: MonthKey(2026, 4),
      dateKey: DateKey(2026, 4, 2),
      amount: const Money.paisa(10000),
      status: ContributionApproval.approved,
      requestedBy: 'member-1',
      createdAt: DateTime.utc(2026, 4, 2),
    );

    final decoded = Csv().decode(
      ReportCsvBuilder.contributions([contribution]),
    );

    expect(decoded[1][0], 'con-1');
    expect(decoded[1][3], '10000');
    expect(decoded[1][4], 'approved');
  });

  test('chore CSV exports derived status rather than the stored cache', () {
    final occurrence = ChoreOccurrence(
      id: 'occ-1',
      templateId: 'template-1',
      templateRev: 1,
      dateKey: DateKey(2026, 4, 2),
      monthKey: MonthKey(2026, 4),
      dueAt: DateTime.utc(2026, 4, 2),
      nameBn: 'ঘর পরিষ্কার',
      subtasks: const [],
      status: OccurrenceStatus.completed,
    );

    final decoded = Csv().decode(ReportCsvBuilder.chores([occurrence]));

    expect(decoded[1][2], 'ঘর পরিষ্কার');
    expect(decoded[1][5], 'scheduled');
  });
}
