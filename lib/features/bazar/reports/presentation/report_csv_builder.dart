import 'package:csv/csv.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/expenses/domain/expense.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/effective_status.dart';

abstract final class ReportCsvBuilder {
  static final _codec = Csv(lineDelimiter: '\n');

  static String expenses(Iterable<Expense> expenses) => _codec.encode([
    const <String>[
      'id',
      'date',
      'item',
      'category_id',
      'total_paisa',
      'funding',
      'spender_id',
      'shop',
      'note',
      'deleted',
    ],
    for (final expense in expenses)
      <Object?>[
        expense.id,
        expense.dateKey.toString(),
        expense.itemName,
        expense.categoryId,
        expense.total.paisa,
        expense.funding.name,
        expense.spenderId,
        expense.shop ?? '',
        expense.note ?? '',
        expense.isDeleted,
      ],
  ]);

  static String contributions(Iterable<Contribution> contributions) =>
      _codec.encode([
        const <String>[
          'id',
          'date',
          'member_id',
          'amount_paisa',
          'status',
          'method',
          'voided',
          'note',
        ],
        for (final contribution in contributions)
          <Object?>[
            contribution.id,
            contribution.dateKey.toString(),
            contribution.memberId,
            contribution.amount.paisa,
            contribution.status.name,
            contribution.method?.name ?? '',
            contribution.isVoided,
            contribution.note ?? '',
          ],
      ]);

  static String chores(Iterable<ChoreOccurrence> occurrences) => _codec.encode([
    const <String>[
      'id',
      'date',
      'name_bn',
      'name_en',
      'assignee_id',
      'status',
      'completed_at',
      'verified_at',
      'deleted',
    ],
    for (final occurrence in occurrences)
      <Object?>[
        occurrence.id,
        occurrence.dateKey.toString(),
        occurrence.nameBn,
        occurrence.nameEn ?? '',
        occurrence.assigneeId ?? '',
        effectiveStatus(occurrence).id,
        occurrence.completedAt?.toIso8601String() ?? '',
        occurrence.verifiedAt?.toIso8601String() ?? '',
        occurrence.isDeleted,
      ],
  ]);
}
