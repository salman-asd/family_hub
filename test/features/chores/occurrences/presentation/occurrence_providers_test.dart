import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/duty_groups/presentation/duty_group_providers.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/today_providers.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/chores/templates/presentation/template_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';

/// P3-13: the occurrence providers over the in-memory repositories.
///
/// The month listener filters soft-deleted documents once, sorts by day/due
/// time and reports a truncated month; the marker and the verify queue follow
/// the same backend.
void main() {
  const familyId = ChoresFixture.familyId;
  late ChoresFixture fixture;

  setUp(() {
    fixture = ChoresFixture();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        occurrenceRepositoryProvider.overrideWithValue(fixture.occurrences),
        generationMarkerRepositoryProvider.overrideWithValue(
          fixture.occurrences,
        ),
        dutyGroupRepositoryProvider.overrideWithValue(
          fixture.chores.dutyGroups,
        ),
        templateRepositoryProvider.overrideWithValue(fixture.chores),
        choreSettingsRepositoryProvider.overrideWithValue(fixture.settings),
        currentFamilyIdProvider.overrideWithValue(familyId),
        currentUidProvider.overrideWithValue('alice'),
        familyRepositoryProvider.overrideWithValue(fixture.families),
        clockProvider.overrideWithValue(fixture.clock),
        // No running timer in a unit test.
        nowTickProvider.overrideWith((ref) => const Stream<DateTime>.empty()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  void seed(List<ChoreOccurrence> occurrences) {
    fixture.occurrences.occurrences[familyId] = <String, ChoreOccurrence>{
      for (final occurrence in occurrences) occurrence.id: occurrence,
    };
  }

  test(
    'monthOccurrencesProvider keeps the live documents of the month',
    () async {
      seed(<ChoreOccurrence>[
        anOccurrence(
          id: 'tpl_1_20261026',
          dateKey: DateKey(2026, 10, 26),
          dueAt: DateTime.utc(2026, 10, 26, 3),
        ),
        anOccurrence(),
        anOccurrence(
          id: 'tpl_2_20261101',
          templateId: 'tpl_2',
          dateKey: DateKey(2026, 11, 1),
          dueAt: DateTime.utc(2026, 11, 1, 3),
        ),
      ]);

      final month = MonthKey(2026, 10);
      final container = makeContainer();
      container.listen(monthOccurrencesProvider(month), (_, _) {});
      await container.pump();

      final items = container.read(monthOccurrencesProvider(month)).value!;
      expect(items.items.map((occurrence) => occurrence.id), <String>[
        'tpl_1_20261024',
        'tpl_1_20261026',
      ]);
      expect(items.truncated, isFalse);
    },
  );

  group('D-01: month listener lifetime', () {
    /// Lets the provider dispose and the stream cancellation finish.
    Future<void> settle(ProviderContainer container) async {
      for (var i = 0; i < 3; i++) {
        await container.pump();
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('a month that is not the current one is cancelled once unwatched',
        () async {
      final container = makeContainer();
      final past = container.listen(
        monthOccurrencesProvider(MonthKey(2026, 9)),
        (_, _) {},
      );
      final future = container.listen(
        monthOccurrencesProvider(MonthKey(2026, 11)),
        (_, _) {},
      );
      await settle(container);
      expect(fixture.occurrences.activeRangeListeners, 2);

      past.close();
      future.close();
      await settle(container);

      expect(fixture.occurrences.activeRangeListeners, 0);
    });

    test('the current month stays alive after its last listener leaves',
        () async {
      final container = makeContainer();
      final current = container.listen(
        monthOccurrencesProvider(MonthKey(2026, 10)),
        (_, _) {},
      );
      await settle(container);
      current.close();
      await settle(container);

      expect(fixture.occurrences.activeRangeListeners, 1);
    });

    test('browsing five months leaves only the current month running', () async {
      final container = makeContainer();
      for (var m = 8; m <= 12; m++) {
        container
            .listen(monthOccurrencesProvider(MonthKey(2026, m)), (_, _) {})
            .close();
      }
      await settle(container);

      expect(fixture.occurrences.activeRangeListeners, 1);
    });

    test('a deep link into an old month does not pin its listener', () async {
      seed(<ChoreOccurrence>[
        anOccurrence(
          id: 'tpl_1_20260915',
          dateKey: DateKey(2026, 9, 15),
          dueAt: DateTime.utc(2026, 9, 15, 3),
        ),
      ]);
      final container = makeContainer();
      final link = container.listen(
        occurrenceItemProvider('tpl_1_20260915'),
        (_, _) {},
      );
      await settle(container);
      expect(fixture.occurrences.activeRangeListeners, 1);
      expect(container.read(occurrenceItemProvider('tpl_1_20260915')), isNotNull);

      link.close();
      await settle(container);

      expect(fixture.occurrences.activeRangeListeners, 0);
    });

    test('a disposed month re-subscribes when it is opened again', () async {
      final container = makeContainer();
      container
          .listen(monthOccurrencesProvider(MonthKey(2026, 9)), (_, _) {})
          .close();
      await settle(container);

      container.listen(monthOccurrencesProvider(MonthKey(2026, 9)), (_, _) {});
      await settle(container);

      expect(
        container
            .read(monthOccurrencesProvider(MonthKey(2026, 9)))
            .hasValue,
        isTrue,
      );
    });
  });

  test('a soft-deleted document never reaches a screen', () async {
    seed(<ChoreOccurrence>[
      anOccurrence(deletedAt: DateTime.utc(2026, 10, 24), deletedBy: 'bob'),
    ]);

    final month = MonthKey(2026, 10);
    final container = makeContainer();
    container.listen(monthOccurrencesProvider(month), (_, _) {});
    await container.pump();

    expect(
      container.read(monthOccurrencesProvider(month)).value!.items,
      isEmpty,
    );
  });

  test('a month past the limit is reported as truncated', () {
    final documents = <ChoreOccurrence>[
      for (var i = 0; i <= 900; i++)
        anOccurrence(id: 'tpl_${i}_20261024', templateId: 'tpl_$i'),
    ];
    final month = MonthOccurrences.fromDocuments(documents);
    expect(month.truncated, isTrue);
    expect(month.items.length, 900);
  });

  test('the sort puts the day, then the due time, then main first', () {
    final late = anOccurrence(
      id: 'tpl_1_20261024_night',
      slotKey: 'night',
      dueAt: DateTime.utc(2026, 10, 24, 15),
    );
    final main = anOccurrence(dueAt: DateTime.utc(2026, 10, 24, 3));
    final sorted = MonthOccurrences.fromDocuments(<ChoreOccurrence>[late, main])
        .items;
    expect(sorted.map((occurrence) => occurrence.id), <String>[
      main.id,
      late.id,
    ]);
  });

  test(
    'occurrenceProvider falls back to null for a missing document',
    () async {
      final container = makeContainer();
      container.listen(occurrenceProvider('tpl_1_20261024'), (_, _) {});
      await container.pump();

      expect(
        container.read(occurrenceProvider('tpl_1_20261024')).value,
        isNull,
      );
    },
  );

  test('verifyQueueProvider lists completed documents, newest first', () async {
    seed(<ChoreOccurrence>[
      anOccurrence(
        status: OccurrenceStatus.completed,
        completedAt: DateTime.utc(2026, 10, 24, 4),
        completedBy: 'cara',
      ),
      anOccurrence(
        id: 'tpl_1_20261022',
        dateKey: DateKey(2026, 10, 22),
        dueAt: DateTime.utc(2026, 10, 22, 3),
        status: OccurrenceStatus.completed,
        completedAt: DateTime.utc(2026, 10, 22, 4),
        completedBy: 'cara',
      ),
      anOccurrence(id: 'tpl_1_20261023', dateKey: DateKey(2026, 10, 23)),
    ]);

    final container = makeContainer();
    container.listen(verifyQueueProvider, (_, _) {});
    await container.pump();

    expect(
      container.read(verifyQueueProvider).value!.map((o) => o.id),
      <String>['tpl_1_20261024', 'tpl_1_20261022'],
    );
  });

  test('generationMarkerProvider exposes the stored through-day', () async {
    fixture.occurrences.markers[familyId] = DateKey(2026, 11, 24);

    final container = makeContainer();
    container.listen(generationMarkerProvider, (_, _) {});
    await container.pump();

    expect(container.read(generationThroughProvider), DateKey(2026, 11, 24));
  });

  test('the app-open hook swallows an offline failure', () async {
    final container = makeContainer();
    container.listen(ensureOccurrencesOnOpenProvider(familyId), (_, _) {});
    fixture.occurrences.nextMarkerFailure = const Network();
    await container.pump();

    expect(
      container.read(ensureOccurrencesOnOpenProvider(familyId)).value,
      isNull,
    );
  });

  test('the app-open hook reports a denied write instead of hiding it', () async {
    // B-01: only "offline" is silent; every other failure is surfaced.
    final container = makeContainer();
    container.listen(ensureOccurrencesOnOpenProvider(familyId), (_, _) {});
    fixture.occurrences.nextMarkerFailure = const PermissionDenied();
    await container.pump();

    final state = container.read(ensureOccurrencesOnOpenProvider(familyId));
    expect(state.hasError, isFalse, reason: 'it never fails the app start');
    expect(state.value, isA<PermissionDenied>());
  });

  test('the app-open hook reports nothing on success', () async {
    final container = makeContainer();
    container.listen(ensureOccurrencesOnOpenProvider(familyId), (_, _) {});
    await container.pump();

    final state = container.read(ensureOccurrencesOnOpenProvider(familyId));
    expect(state.hasError, isFalse);
    expect(state.value, isNull);
  });

  test('the app-open hook does nothing without a signed-in user', () async {
    final container = ProviderContainer(
      overrides: [
        occurrenceRepositoryProvider.overrideWithValue(fixture.occurrences),
        generationMarkerRepositoryProvider.overrideWithValue(
          fixture.occurrences,
        ),
        currentUidProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    container.listen(ensureOccurrencesOnOpenProvider(familyId), (_, _) {});
    await container.pump();

    expect(
      container.read(ensureOccurrencesOnOpenProvider(familyId)).value,
      isNull,
    );
    // The marker was never read or written: nothing was generated.
    expect(fixture.occurrences.markers[familyId], isNull);
  });

  test('the ensure use case is wired to every repository', () {
    final container = makeContainer();
    expect(container.read(ensureOccurrencesProvider), isNotNull);
  });
}
