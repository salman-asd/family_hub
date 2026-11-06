import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/cover_counter.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:flutter_test/flutter_test.dart';

import 'engagement_test_support.dart';

void main() {
  test('counts covers grouped by assignee for the requested month', () {
    final result = CoverCounter.count(<ChoreOccurrence>[
      engagementOccurrence(
        id: 'first',
        coverForId: 'covered-a',
        assigneeId: 'helper-a',
      ),
      engagementOccurrence(
        id: 'second',
        coverForId: 'covered-b',
        assigneeId: 'helper-a',
      ),
      engagementOccurrence(
        id: 'third',
        coverForId: 'covered-c',
        assigneeId: 'helper-b',
      ),
      engagementOccurrence(id: 'no-cover', coverForId: null),
      engagementOccurrence(
        id: 'other-month',
        day: DateKey(2026, 10, 5),
        coverForId: 'covered-d',
      ),
    ], MonthKey(2026, 11));
    expect(result, <String, int>{'helper-a': 2, 'helper-b': 1});
  });

  test('ignores deleted and unassigned cover occurrences', () {
    final result = CoverCounter.count(<ChoreOccurrence>[
      engagementOccurrence(id: 'deleted', coverForId: 'covered', deleted: true),
      engagementOccurrence(
        id: 'unassigned',
        coverForId: 'covered',
        assigneeId: null,
      ),
    ], MonthKey(2026, 11));
    expect(result, isEmpty);
  });
}
