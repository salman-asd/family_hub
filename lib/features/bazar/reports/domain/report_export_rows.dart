import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';

final class ReportExportRows {
  ReportExportRows({
    required List<Expense> expenses,
    required List<Contribution> contributions,
    required List<ChoreOccurrence> chores,
  }) : expenses = List<Expense>.unmodifiable(expenses),
       contributions = List<Contribution>.unmodifiable(contributions),
       chores = List<ChoreOccurrence>.unmodifiable(chores);

  final List<Expense> expenses;
  final List<Contribution> contributions;
  final List<ChoreOccurrence> chores;
}
