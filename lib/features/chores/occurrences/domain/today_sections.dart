import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';

/// True for a status that counts as finished work (completed or verified).
bool isDoneStatus(ChoreStatus status) =>
    status == ChoreStatus.completed || status == ChoreStatus.verified;

/// True for a status a person can still complete: scheduled, in progress or
/// overdue. A skipped or finished chore is not actionable (U-08).
bool isActionableStatus(ChoreStatus status) =>
    status == ChoreStatus.scheduled ||
    status == ChoreStatus.inProgress ||
    status == ChoreStatus.overdue;

/// Today's list split into the three groups the Today screen shows (P3-15).
///
/// Pure: the screen only lays the groups out. `pending` is everything not done
/// (skipped chores included, they stay visible); `overdue` and `upcoming`
/// partition `pending`.
final class TodaySections {
  const TodaySections({
    required this.overdue,
    required this.upcoming,
    required this.done,
  });

  factory TodaySections.of(List<ChoreItem> items) {
    final overdue = <ChoreItem>[];
    final upcoming = <ChoreItem>[];
    final done = <ChoreItem>[];
    for (final item in items) {
      if (isDoneStatus(item.status)) {
        done.add(item);
      } else if (item.status == ChoreStatus.overdue) {
        overdue.add(item);
      } else {
        upcoming.add(item);
      }
    }
    return TodaySections(overdue: overdue, upcoming: upcoming, done: done);
  }

  final List<ChoreItem> overdue;
  final List<ChoreItem> upcoming;
  final List<ChoreItem> done;

  /// Nothing left to do, but something was done (U-06): the "all done" case.
  bool get allDone => overdue.isEmpty && upcoming.isEmpty && done.isNotEmpty;
}
