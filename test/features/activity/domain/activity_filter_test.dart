import 'package:family_hub/features/activity/domain/activity_entry.dart';
import 'package:family_hub/features/activity/domain/activity_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final entries = <ActivityEntry>[
    ActivityEntry(
      id: 'bazar-1',
      type: 'bazar.expense_created',
      actorId: 'one',
      params: const {},
      refType: 'expense',
      refId: 'expense-1',
      createdAt: DateTime.utc(2026, 11),
    ),
    ActivityEntry(
      id: 'chores-1',
      type: 'chores.occurrence_completed',
      actorId: 'two',
      params: const {},
      refType: 'occurrence',
      refId: 'chore-1',
      createdAt: DateTime.utc(2026, 11, 1),
    ),
    ActivityEntry(
      id: 'unknown-1',
      type: 'future.changed',
      actorId: 'one',
      params: const {},
      refType: 'futureRef',
      refId: 'x',
      createdAt: DateTime.utc(2026, 11, 2),
    ),
  ];

  test('module filtering is prefix-based and keeps unknown modules in All', () {
    expect(
      const ActivityFilter(module: ActivityModuleFilter.bazar)
          .apply(entries)
          .map((entry) => entry.id),
      ['bazar-1'],
    );
    expect(
      const ActivityFilter(module: ActivityModuleFilter.chores)
          .apply(entries)
          .map((entry) => entry.id),
      ['chores-1'],
    );
    expect(const ActivityFilter().apply(entries).map((entry) => entry.id), [
      'bazar-1',
      'chores-1',
      'unknown-1',
    ]);
  });

  test('activity entries defensively copy their parameter maps', () {
    final params = <String, String>{'key': 'before'};
    final entry = ActivityEntry(
      id: 'immutable',
      type: 'future.changed',
      actorId: 'member',
      params: params,
      refType: 'futureRef',
      refId: 'record',
      createdAt: DateTime.utc(2026, 11),
    );

    params['key'] = 'after';
    expect(entry.params['key'], 'before');
    expect(() => entry.params['new'] = 'value', throwsUnsupportedError);
  });
}
