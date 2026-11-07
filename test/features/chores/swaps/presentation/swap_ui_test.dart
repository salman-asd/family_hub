import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';
import 'package:family_hub/features/chores/availability/presentation/availability_index_provider.dart';
import 'package:family_hub/features/chores/availability/presentation/availability_providers.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/presentation/swap_providers.dart';
import 'package:family_hub/features/chores/swaps/presentation/swap_sheet.dart';
import 'package:family_hub/features/chores/swaps/presentation/swap_status_banner.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';
import '../../presentation/chores_p3_15_support.dart';

/// P3-27: the swap sheet, the status banner and the response sheet.
void main() {
  const occId = 'tpl_1_20261024';
  late ChoresFixture fixture;
  late ChoreOccurrence chore;

  setUp(() {
    fixture = ChoresFixture();
    chore = anOccurrence(
      id: occId,
      dateKey: DateKey(2026, 10, 24),
      dueAt: DateTime.utc(2026, 10, 24, 17),
    );
  });

  // Real overrides need the fixture, so they are built per test.
  List<Override> wired() => [
    availabilityRepositoryProvider.overrideWithValue(fixture.availability),
    swapRepositoryProvider.overrideWithValue(fixture.swaps),
  ];

  SwapRequest pending({String from = 'cara', String to = 'dave'}) =>
      SwapRequest(
        id: 'r1',
        occurrenceId: occId,
        occurrenceDateKey: DateKey(2026, 10, 24),
        kind: SwapKind.swap,
        fromMemberId: from,
        toMemberId: to,
        reason: 'I am travelling',
        status: SwapStatus.pending,
        expiresAt: DateTime.utc(2026, 10, 24, 15),
        requestedBy: from,
      );

  Future<void> openSwapSheet(WidgetTester tester) async {
    await pumpP3Screen(
      tester,
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) {
            ref.watch(availabilityIndexProvider); // keep the index alive
            return TextButton(
              onPressed: () =>
                  ref.requestSwapWithSheet(context, occurrence: chore),
              child: const Text('open'),
            );
          },
        ),
      ),
      sharedFixture: fixture,
      occurrences: <ChoreOccurrence>[chore],
      uid: 'cara',
      height: 1400,
      overrides: wired(),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('open'));
    // Two frames of sheet-open time: the route animation only starts once the
    // family list behind it has been read, and a tap on a button that is still
    // below the screen would miss.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('the swap sheet offers only members who are free', (
    tester,
  ) async {
    fixture.swapWorld.absences['a1'] = MemberAvailability(
      id: 'a1',
      memberId: 'dave',
      startDate: DateKey(2026, 10, 24),
      endDate: DateKey(2026, 10, 24),
      typeId: ChoreSettings.defaults.absenceReasons.first.id,
      reason: 'Fever',
      status: AvailabilityStatus.active,
      createdBy: 'dave',
    );
    await openSwapSheet(tester);

    expect(find.byKey(const Key('swap_person_bob')), findsOneWidget);
    expect(
      find.byKey(const Key('swap_person_dave')),
      findsNothing,
      reason: 'away',
    );
    expect(
      find.byKey(const Key('swap_person_cara')),
      findsNothing,
      reason: 'the requester',
    );
    expect(
      find.byKey(const Key('swap_person_erin')),
      findsNothing,
      reason: 'pending',
    );
  });

  testWidgets('choose a person, give a reason and send', (tester) async {
    await openSwapSheet(tester);
    final send = find.byKey(const Key('swap_send'));
    expect(tester.widget<FilledButton>(send).onPressed, isNull);

    await tester.tap(find.byKey(const Key('swap_person_dave')));
    await tester.enterText(
      find.byKey(const Key('swap_reason')),
      'I am travelling',
    );
    await tester.pump();
    expect(
      find.textContaining('Request to'),
      findsOneWidget,
      reason: 'preview',
    );
    await tester.tap(send);
    await tester.pump(const Duration(milliseconds: 200));

    final request = fixture.swapWorld.swapRequests.values.single;
    expect(request.toMemberId, 'dave');
    expect(request.reason, 'I am travelling');
    expect(request.isPending, isTrue);
  });

  testWidgets('the requester sees the banner and can cancel', (tester) async {
    fixture.swapWorld.swapRequests['r1'] = pending();
    await pumpP3Screen(
      tester,
      home: const Scaffold(body: SwapStatusBanner(occurrenceId: occId)),
      sharedFixture: fixture,
      occurrences: <ChoreOccurrence>[chore],
      uid: 'cara',
      overrides: wired(),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Request sent to'), findsOneWidget);
    await tester.tap(find.byKey(const Key('swap_banner_cancel')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(fixture.swapWorld.swapRequests['r1']!.status, SwapStatus.cancelled);
  });

  testWidgets('the recipient answers from the banner: accept moves the chore', (
    tester,
  ) async {
    fixture.swapWorld.swapRequests['r1'] = pending();
    await pumpP3Screen(
      tester,
      home: const Scaffold(body: SwapStatusBanner(occurrenceId: occId)),
      sharedFixture: fixture,
      occurrences: <ChoreOccurrence>[chore],
      uid: 'dave',
      height: 1200,
      overrides: wired(),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('asked you to take this chore'), findsOneWidget);
    await tester.tap(find.byKey(const Key('swap_banner_answer')));
    // The answer sheet is opened after the chore has been re-read, so the
    // sheet animation starts a frame late; it must be on screen before Accept.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('swap_accept')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(fixture.swapWorld.swapRequests['r1']!.status, SwapStatus.accepted);
    expect(
      fixture
          .occurrences
          .occurrences[ChoresFixture.familyId]![occId]!
          .assigneeId,
      'dave',
    );
  });

  testWidgets('a chore with no pending request shows no banner', (
    tester,
  ) async {
    await pumpP3Screen(
      tester,
      home: const Scaffold(body: SwapStatusBanner(occurrenceId: occId)),
      sharedFixture: fixture,
      uid: 'cara',
      overrides: wired(),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('swap_banner')), findsNothing);
  });

  testWidgets(
    'the sheet waits for the family list instead of claiming nobody is free',
    (tester) async {
      await pumpP3Screen(
        tester,
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () =>
                  ref.requestSwapWithSheet(context, occurrence: chore),
              child: const Text('open'),
            ),
          ),
        ),
        sharedFixture: fixture,
        occurrences: <ChoreOccurrence>[chore],
        uid: 'cara',
        height: 1400,
        overrides: <Override>[
          ...wired(),
          membersProvider.overrideWith(
            (ref) => const Stream<List<Member>>.empty(),
          ),
        ],
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('open'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.byKey(const Key('swap_nobody')), findsNothing);
      expect(find.byKey(const Key('swap_send')), findsNothing);
    },
  );
}
