import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/repair_status.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_action_providers.dart';
import 'package:family_hub/features/chores/presentation/occurrence_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chores_test_helpers.dart';
import 'chores_p3_15_support.dart';

/// Records every repair call instead of writing.
class _SpyRepair extends Fake implements RepairStatus {
  final List<String> calls = <String>[];

  @override
  Future<Result<ChoreOccurrence>> call({
    required String familyId,
    required String actorUid,
    required String occurrenceId,
  }) async {
    calls.add(occurrenceId);
    return Success<ChoreOccurrence>(anOccurrence(id: occurrenceId));
  }
}

/// P3-15 / Wave R5: the detail screen (U-01).
void main() {
  // Stored `scheduled`, but a completion is recorded: the cache is stale.
  ChoreOccurrence stale() => anOccurrence(
    id: 'a_20261024',
    dateKey: DateKey(2026, 10, 24),
    status: OccurrenceStatus.scheduled,
    completedAt: DateTime.utc(2026, 10, 24, 4),
    completedBy: 'cara',
  );

  testWidgets('U-01: a cold open repairs a stale status cache once', (
    tester,
  ) async {
    final spy = _SpyRepair();
    final occurrence = stale();
    expect(RepairStatus.needsRepair(occurrence), isTrue);

    await pumpP3Screen(
      tester,
      home: const OccurrenceDetailScreen(occurrenceId: 'a_20261024'),
      occurrences: <ChoreOccurrence>[occurrence],
      overrides: [repairStatusProvider.overrideWithValue(spy)],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Once per screen, not once per snapshot.
    expect(spy.calls, <String>['a_20261024']);
  });

  testWidgets('a consistent document is not repaired', (tester) async {
    final spy = _SpyRepair();
    await pumpP3Screen(
      tester,
      home: const OccurrenceDetailScreen(occurrenceId: 'a_20261024'),
      occurrences: <ChoreOccurrence>[
        anOccurrence(id: 'a_20261024', dateKey: DateKey(2026, 10, 24)),
      ],
      overrides: [repairStatusProvider.overrideWithValue(spy)],
    );
    await tester.pump();

    expect(spy.calls, isEmpty);
  });

  testWidgets('a missing document shows the not-found error, no repair', (
    tester,
  ) async {
    final spy = _SpyRepair();
    await pumpP3Screen(
      tester,
      home: const OccurrenceDetailScreen(occurrenceId: 'nope_20261024'),
      role: Role.member,
      overrides: [repairStatusProvider.overrideWithValue(spy)],
    );
    await tester.pump();

    expect(spy.calls, isEmpty);
    expect(find.text('Retry'), findsOneWidget);
  });
}
