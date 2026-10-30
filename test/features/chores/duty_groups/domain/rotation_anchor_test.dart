import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/duty_groups/domain/rotation.dart';
import 'package:family_hub/features/chores/duty_groups/domain/rotation_engine.dart';
import 'package:family_hub/features/chores/templates/domain/recurrence/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';

/// Q-07: the `occurrence` unit when the anchor date itself does not fire.
void main() {
  DateKey day(int date) => DateKey(2026, 10, date);

  // Saturday to Thursday: Friday never fires.
  const noFriday = WeekdaysRecurrence(weekdays: <int>[6, 7, 1, 2, 3, 4]);

  String? plan(Rotation rotation, DateKey on) =>
      RotationEngine.planned(rotation, on, recurrence: noFriday);

  test('a non-firing anchor still hands over person by person', () {
    // 9 Oct 2026 is a Friday: the anchor does not fire.
    final rotation = aRotation(
      members: <String>['alice', 'bob', 'cara'],
      cycleUnit: CycleUnit.occurrence,
      anchorDate: day(9),
    );

    // First firing on/after the anchor is cycle 0.
    expect(plan(rotation, day(10)), 'alice');
    expect(plan(rotation, day(11)), 'bob');
    expect(plan(rotation, day(12)), 'cara');
    expect(plan(rotation, day(13)), 'alice');
    // Firing days before the anchor count down without skipping anyone.
    expect(plan(rotation, day(8)), 'cara');
    expect(plan(rotation, day(7)), 'bob');
  });

  test('consecutive firings are always one person apart', () {
    final rotation = aRotation(
      members: <String>['alice', 'bob', 'cara'],
      cycleUnit: CycleUnit.occurrence,
      anchorDate: day(9),
    );
    final firing = <int>[1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15]
      ..removeWhere((d) => DateKey(2026, 10, d).isoWeekday == 5);
    final order = <String>['alice', 'bob', 'cara'];
    for (var i = 1; i < firing.length; i++) {
      final a = order.indexOf(plan(rotation, day(firing[i - 1]))!);
      final b = order.indexOf(plan(rotation, day(firing[i]))!);
      expect(b, (a + 1) % 3, reason: '${firing[i - 1]} -> ${firing[i]}');
    }
  });

  test('a firing anchor keeps cycle 0 (F.2 case 9 unchanged)', () {
    final rotation = aRotation(
      members: <String>['alice', 'cara'],
      cycleUnit: CycleUnit.occurrence,
      anchorDate: day(3),
    );
    expect(plan(rotation, day(3)), 'alice');
    expect(plan(rotation, day(4)), 'cara');
    expect(plan(rotation, day(10)), 'alice');
  });
}
