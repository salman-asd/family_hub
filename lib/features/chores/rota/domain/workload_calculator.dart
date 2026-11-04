import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/rota/domain/workload_summary.dart';
import 'package:family_hub/features/chores/templates/domain/template_enums.dart';

/// Pure workload maths over the chore items of a range (P3-28).
///
/// A chore is weighted by its difficulty ([weightOf]: 1 / 2 / 3). The weights
/// are placeholders a family can live with, named constants rather than
/// settings. Skipped chores count for nobody. Nothing here reads Firestore: the
/// screen hands over the items it already listens to.
abstract final class WorkloadCalculator {
  static const int easyWeight = 1;
  static const int normalWeight = 2;
  static const int hardWeight = 3;

  static int weightOf(Difficulty difficulty) => switch (difficulty) {
    Difficulty.easy => easyWeight,
    Difficulty.normal => normalWeight,
    Difficulty.hard => hardWeight,
  };

  static WorkloadSummary compute({
    required Iterable<ChoreItem> items,
    required List<String> memberIds,
    required DateKey from,
    required DateKey to,
    AvailabilityIndex availability = AvailabilityIndex.empty,
  }) {
    final assigned = <String, int>{};
    final done = <String, int>{};
    final points = <String, int>{};
    final minutes = <String, int>{};
    final given = <String, int>{};
    final received = <String, int>{};

    for (final item in items) {
      if (item.status == ChoreStatus.skipped) continue;
      if (item.dateKey.isBefore(from) || item.dateKey.isAfter(to)) continue;
      final owner = item.assigneeId;
      if (owner != null) {
        assigned[owner] = (assigned[owner] ?? 0) + 1;
        points[owner] = (points[owner] ?? 0) + weightOf(item.difficulty);
        minutes[owner] = (minutes[owner] ?? 0) + (item.estimatedMinutes ?? 0);
        if (item.status == ChoreStatus.completed ||
            item.status == ChoreStatus.verified) {
          done[owner] = (done[owner] ?? 0) + 1;
        }
        if (item.flags.contains(ChoreFlag.isCover)) {
          given[owner] = (given[owner] ?? 0) + 1;
        }
      }
      final planned = item.plannedAssigneeId;
      if (planned != null && owner != null && planned != owner) {
        received[planned] = (received[planned] ?? 0) + 1;
      }
    }

    final total = memberIds.fold<int>(0, (sum, id) => sum + (points[id] ?? 0));
    final days = from.daysUntil(to) + 1;
    return WorkloadSummary(
      totalPoints: total,
      members: <MemberWorkload>[
        for (final id in memberIds)
          MemberWorkload(
            memberId: id,
            assigned: assigned[id] ?? 0,
            done: done[id] ?? 0,
            points: points[id] ?? 0,
            minutes: minutes[id] ?? 0,
            coversGiven: given[id] ?? 0,
            coversReceived: received[id] ?? 0,
            unavailableDays: <int>[
              for (var i = 0; i < days; i++)
                if (availability.isUnavailable(id, from.addDays(i))) i,
            ].length,
            share: total == 0 ? 0 : (points[id] ?? 0) / total,
          ),
      ],
    );
  }
}
