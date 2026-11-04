import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';

/// Who does what on which day (P3-28): one row per member, one column per day.
///
/// Built from the items the screen already listens to. A cell holds the chores
/// the member OWNS that day, so a cover or a swap shows under the person who
/// does the work. Chores with no owner are collected in [unassigned].
final class RotaMatrix {
  RotaMatrix._(this.days, this._cells, this.unassigned);

  factory RotaMatrix.build({
    required Iterable<ChoreItem> items,
    required List<String> memberIds,
    required DateKey from,
    required DateKey to,
  }) {
    final days = <DateKey>[
      for (var i = 0; i <= from.daysUntil(to); i++) from.addDays(i),
    ];
    final cells = <String, Map<DateKey, List<ChoreItem>>>{
      for (final id in memberIds) id: <DateKey, List<ChoreItem>>{},
    };
    final unassigned = <DateKey, List<ChoreItem>>{};
    for (final item in items) {
      if (item.status == ChoreStatus.skipped) continue;
      if (item.dateKey.isBefore(from) || item.dateKey.isAfter(to)) continue;
      final owner = item.assigneeId;
      final target = owner == null ? unassigned : cells[owner];
      if (target == null) continue;
      target.putIfAbsent(item.dateKey, () => <ChoreItem>[]).add(item);
    }
    return RotaMatrix._(days, cells, unassigned);
  }

  final List<DateKey> days;
  final Map<String, Map<DateKey, List<ChoreItem>>> _cells;

  /// Chores nobody owns, by day.
  final Map<DateKey, List<ChoreItem>> unassigned;

  List<ChoreItem> cell(String memberId, DateKey day) =>
      _cells[memberId]?[day] ?? const <ChoreItem>[];

  /// The members who have at least one chore on [day] (the "on duty" strip).
  List<String> onDuty(DateKey day) => <String>[
    for (final entry in _cells.entries)
      if ((entry.value[day] ?? const <ChoreItem>[]).isNotEmpty) entry.key,
  ];

  /// Whether every chore of a cell is finished (icon + label, never colour).
  bool isDone(String memberId, DateKey day) {
    final chores = cell(memberId, day);
    return chores.isNotEmpty &&
        chores.every(
          (c) =>
              c.status == ChoreStatus.completed ||
              c.status == ChoreStatus.verified,
        );
  }
}
