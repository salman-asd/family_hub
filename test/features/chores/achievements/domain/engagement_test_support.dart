import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';

ChoreOccurrence engagementOccurrence({
  String id = 'occurrence',
  DateKey? day,
  DateTime? completedAt,
  String? completedBy = 'member',
  Difficulty difficulty = Difficulty.normal,
  DateTime? verifiedAt,
  int reopenCount = 0,
  String? coverForId,
  String? assigneeId = 'member',
  OccurrenceStatus status = OccurrenceStatus.completed,
  SkipReason? skipReason,
  bool deleted = false,
  List<TemplateSubtask> subtasks = const <TemplateSubtask>[],
  Map<String, SubtaskDone> subtaskDone = const <String, SubtaskDone>{},
}) {
  final date = day ?? DateKey(2026, 11, 5);
  return ChoreOccurrence(
    id: id,
    templateId: 'template',
    templateRev: 1,
    dateKey: date,
    monthKey: date.monthKey,
    dueAt: DateTime.utc(date.year, date.month, date.day, 12),
    nameBn: 'কাজ',
    subtasks: subtasks,
    difficulty: difficulty,
    status: status,
    assigneeId: assigneeId,
    coverForId: coverForId,
    completedAt:
        completedAt ?? DateTime.utc(date.year, date.month, date.day, 11),
    completedBy: completedBy,
    verifiedAt: verifiedAt,
    reopenCount: reopenCount,
    skipReason: skipReason,
    subtaskDone: subtaskDone,
    deletedAt: deleted ? DateTime.utc(date.year, date.month, date.day) : null,
  );
}

List<TemplateSubtask> engagementSubtasks({bool secondRequired = false}) =>
    <TemplateSubtask>[
      const TemplateSubtask(id: 'first', title: 'First', required: true),
      const TemplateSubtask(id: 'second', title: 'Second', required: false),
      if (secondRequired)
        const TemplateSubtask(id: 'third', title: 'Third', required: true),
    ];

Map<String, SubtaskDone> engagementTicks(Iterable<String> ids) =>
    <String, SubtaskDone>{
      for (final id in ids)
        id: SubtaskDone(at: DateTime.utc(2026, 11, 5, 11), by: 'member'),
    };
