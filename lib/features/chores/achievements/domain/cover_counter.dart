import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';

abstract final class CoverCounter {
  static Map<String, int> count(
    Iterable<ChoreOccurrence> monthItems,
    MonthKey month,
  ) {
    final result = <String, int>{};
    for (final item in monthItems) {
      final assigneeId = item.assigneeId;
      if (item.monthKey != month ||
          item.isDeleted ||
          item.coverForId == null ||
          assigneeId == null) {
        continue;
      }
      result.update(assigneeId, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map<String, int>.unmodifiable(result);
  }
}
