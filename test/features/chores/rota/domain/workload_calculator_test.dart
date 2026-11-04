import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/domain/availability_index.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/rota/domain/rota_matrix.dart';
import 'package:family_hub/features/chores/rota/domain/workload_calculator.dart';
import 'package:family_hub/features/chores/templates/domain/template_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';

/// P3-28: workload maths and the rota matrix.
void main() {
  final from = DateKey(2026, 10, 24);
  final to = DateKey(2026, 10, 30);

  ChoreItem chore(
    String id,
    int day, {
    String who = 'cara',
    String? planned,
    Difficulty difficulty = Difficulty.normal,
    OccurrenceStatus status = OccurrenceStatus.scheduled,
    String? coverFor,
    int? minutes,
  }) => ChoreItem.fromOccurrence(
    anOccurrence(
      id: id,
      dateKey: DateKey(2026, 10, day),
      assigneeId: who,
      plannedAssigneeId: planned ?? who,
      difficulty: difficulty,
      status: status,
      coverForId: coverFor,
      estimatedMinutes: minutes,
    ),
  );

  const members = <String>['alice', 'bob', 'cara'];

  test('points weigh difficulty 1 / 2 / 3 and shares add up to 1', () {
    final summary = WorkloadCalculator.compute(
      items: <ChoreItem>[
        chore('a', 24, who: 'alice', difficulty: Difficulty.easy),
        chore('b', 25, who: 'bob', difficulty: Difficulty.hard),
        chore('c', 26, who: 'cara'),
        chore('d', 27, who: 'cara', difficulty: Difficulty.hard),
      ],
      memberIds: members,
      from: from,
      to: to,
    );
    expect(summary.totalPoints, 1 + 3 + 2 + 3);
    expect(summary.of('alice')!.points, 1);
    expect(summary.of('cara')!.points, 5);
    expect(summary.members.fold<double>(0, (s, m) => s + m.share), closeTo(1, 1e-9));
    expect(summary.of('cara')!.share, closeTo(5 / 9, 1e-9));
  });

  test('done, skipped, range and minutes', () {
    final summary = WorkloadCalculator.compute(
      items: <ChoreItem>[
        chore('a', 24, status: OccurrenceStatus.completed, minutes: 10),
        chore('b', 25, minutes: 20),
        chore('c', 26, status: OccurrenceStatus.skipped),
        chore('d', 31),
      ],
      memberIds: members,
      from: from,
      to: to,
    );
    final cara = summary.of('cara')!;
    expect(cara.assigned, 2, reason: 'skipped and out-of-range excluded');
    expect(cara.done, 1);
    expect(cara.minutes, 30);
  });

  test('covers given and received', () {
    final summary = WorkloadCalculator.compute(
      items: <ChoreItem>[
        chore('a', 24, who: 'bob', planned: 'cara', coverFor: 'cara'),
      ],
      memberIds: members,
      from: from,
      to: to,
    );
    expect(summary.of('bob')!.coversGiven, 1);
    expect(summary.of('cara')!.coversReceived, 1);
    expect(summary.of('cara')!.assigned, 0, reason: 'the work is bob’s now');
  });

  test('days away come from the availability index', () {
    final summary = WorkloadCalculator.compute(
      items: const <ChoreItem>[],
      memberIds: members,
      from: from,
      to: to,
      availability: AvailabilityIndex(<AvailabilitySpan>[
        AvailabilitySpan(memberId: 'bob', startDate: DateKey(2026, 10, 26), endDate: DateKey(2026, 11, 3)),
      ]),
    );
    expect(summary.of('bob')!.unavailableDays, 5, reason: '26..30 inside the range');
    expect(summary.of('alice')!.unavailableDays, 0);
    expect(summary.totalPoints, 0);
    expect(summary.of('alice')!.share, 0, reason: 'no division by zero');
  });

  test('the matrix puts a chore under the person who owns it', () {
    final matrix = RotaMatrix.build(
      items: <ChoreItem>[
        chore('a', 24, who: 'bob', planned: 'cara'),
        chore('b', 24, who: 'bob', status: OccurrenceStatus.completed),
        chore('c', 25, who: 'cara'),
        ChoreItem.fromOccurrence(anOccurrence(id: 'u', dateKey: DateKey(2026, 10, 25), assigneeId: null, plannedAssigneeId: null)),
      ],
      memberIds: members,
      from: from,
      to: to,
    );
    expect(matrix.days, hasLength(7));
    expect(matrix.cell('bob', from), hasLength(2));
    expect(matrix.cell('cara', from), isEmpty);
    expect(matrix.onDuty(from), ['bob']);
    expect(matrix.isDone('bob', from), isFalse, reason: 'one of two done');
    expect(matrix.unassigned[DateKey(2026, 10, 25)], hasLength(1));
  });
}
