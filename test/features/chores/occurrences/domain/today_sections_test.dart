import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/today_sections.dart';
import 'package:family_hub/features/chores/occurrences/presentation/today_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';

/// U-05 / U-06 / U-08: the pure grouping and progress behind the Today screen.
void main() {
  ChoreItem item(String id, ChoreStatus status) =>
      ChoreItem.fromOccurrence(anOccurrence(id: id)).copyWith(status: status);

  group('TodaySections.of', () {
    test('splits overdue, upcoming and done', () {
      final sections = TodaySections.of(<ChoreItem>[
        item('a', ChoreStatus.scheduled),
        item('b', ChoreStatus.overdue),
        item('c', ChoreStatus.completed),
        item('d', ChoreStatus.verified),
        item('e', ChoreStatus.inProgress),
        item('f', ChoreStatus.skipped),
      ]);

      expect(sections.overdue.map((i) => i.id), <String>['b']);
      expect(sections.upcoming.map((i) => i.id), <String>['a', 'e', 'f']);
      expect(sections.done.map((i) => i.id), <String>['c', 'd']);
    });

    test('allDone only when work was done and nothing is left', () {
      expect(
        TodaySections.of(<ChoreItem>[
          item('a', ChoreStatus.completed),
          item('b', ChoreStatus.verified),
        ]).allDone,
        isTrue,
      );
      expect(TodaySections.of(const <ChoreItem>[]).allDone, isFalse);
      expect(
        TodaySections.of(<ChoreItem>[
          item('a', ChoreStatus.completed),
          item('b', ChoreStatus.overdue),
        ]).allDone,
        isFalse,
      );
      // A skipped chore stays visible, so the day is not "all done".
      expect(
        TodaySections.of(<ChoreItem>[
          item('a', ChoreStatus.completed),
          item('b', ChoreStatus.skipped),
        ]).allDone,
        isFalse,
      );
    });
  });

  group('isActionableStatus', () {
    test('only open states can be completed from a swipe', () {
      for (final status in ChoreStatus.values) {
        final expected =
            status == ChoreStatus.scheduled ||
            status == ChoreStatus.inProgress ||
            status == ChoreStatus.overdue;
        expect(isActionableStatus(status), expected, reason: '$status');
      }
    });
  });

  group('TodayProgress.of', () {
    test('counts completed and verified as done', () {
      final progress = TodayProgress.of(<ChoreItem>[
        item('a', ChoreStatus.completed),
        item('b', ChoreStatus.verified),
        item('c', ChoreStatus.scheduled),
        item('d', ChoreStatus.overdue),
      ]);
      expect(progress.done, 2);
      expect(progress.total, 4);
      expect(progress.fraction, 0.5);
      expect(progress.isComplete, isFalse);
    });

    test('an empty day has fraction 0 and is not complete', () {
      final progress = TodayProgress.of(const <ChoreItem>[]);
      expect(progress.fraction, 0);
      expect(progress.isComplete, isFalse);
    });

    test('a full day is complete', () {
      final progress = TodayProgress.of(<ChoreItem>[
        item('a', ChoreStatus.completed),
      ]);
      expect(progress.fraction, 1);
      expect(progress.isComplete, isTrue);
    });
  });
}
