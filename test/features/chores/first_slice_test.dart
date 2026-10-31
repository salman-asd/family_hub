import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/effective_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/occurrences/domain/usecases/replan_occurrences.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_action_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/presentation/occurrence_detail_screen.dart';
import 'package:family_hub/features/chores/presentation/today_screen.dart';
import 'package:family_hub/features/chores/presentation/verify_queue_screen.dart';
import 'package:family_hub/features/chores/templates/domain/chore_template.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:family_hub/features/chores/templates/presentation/template_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'chores_test_helpers.dart';
import 'occurrences/domain/usecases/completion_test_support.dart';
import 'presentation/chores_p3_15_support.dart';

/// P-02 (Wave R6): the first-slice milestone of roadmap Appendix E.2, driven
/// through the real screens and use cases on the in-memory backend.
///
/// 1 generate -> Today shows the chore with its assignee
/// 2 tick two steps "2/3" -> tick the rest -> completed -> untick -> in progress
/// 3 the completer cannot verify; a manager can
/// 4 rename the template with "future only": today is unchanged, tomorrow
///   changes.
///
/// It would have caught B-01 (nothing generated on app open), B-02 (the verify
/// queue) and B-04 (reopen / untick behaviour).  Written without an SDK: if a
/// finder or a label does not match, fix the TEST first.
void main() {
  const familyId = ChoresFixture.familyId;
  const todayId = 'tpl_1_20261024';
  const tomorrowId = 'tpl_1_20261025';

  late ChoresFixture fixture;

  GoRouter routerAt(String location) => GoRouter(
    initialLocation: location,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.choresToday,
        builder: (context, state) => const TodayScreen(),
      ),
      GoRoute(
        path: AppRoutes.choresVerify,
        builder: (context, state) => const VerifyQueueScreen(),
      ),
      GoRoute(
        path: AppRoutes.choresOccurrencePattern,
        builder: (context, state) =>
            OccurrenceDetailScreen(occurrenceId: state.pathParameters['id']!),
      ),
    ],
  );

  /// Pumps the app as [uid] on [location], sharing the one in-memory family.
  Future<void> openAs(
    WidgetTester tester,
    String uid,
    Role role,
    String location,
  ) async {
    // A fresh tree: a new person means a new ProviderScope.
    await tester.pumpWidget(const SizedBox());
    await pumpP3Screen(
      tester,
      sharedFixture: fixture,
      router: routerAt(location),
      uid: uid,
      role: role,
      overrides: [
        permissionSettingsProvider.overrideWithValue(
          PermissionSettings.defaults.copyWith(choreVerificationEnabled: true),
        ),
      ],
    );
    await tester.pumpAndSettle();
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

  ChoreOccurrence stored(String id) =>
      fixture.occurrences.occurrences[familyId]![id]!;

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  setUp(() {
    fixture = ChoresFixture();
    seedTemplate(
      fixture,
      ChoreTemplate(
        id: 'tpl_1',
        draft: aTemplate(
          nameBn: 'টেবিল মোছা',
          nameEn: 'Wipe the table',
          // Due 21:00 in Dhaka: not overdue at the fixture clock (15:00).
          slots: <TemplateSlot>[aSlot(dueMinutes: 21 * 60)],
          assignee: const AssigneeSpec(
            strategy: AssigneeStrategy.fixed,
            fixedMemberId: 'cara',
          ),
          verification: VerificationMode.required,
          subtasks: <TemplateSubtask>[
            aSubtask(id: 'step_1', title: 'Clear the table', required: true),
            aSubtask(id: 'step_2', title: 'Wipe it', required: true),
            aSubtask(id: 'step_3', title: 'Dry it', required: true),
          ],
        ),
      ),
    );
  });

  testWidgets('E.2: generate, tick, complete, verify, edit "future only"', (
    tester,
  ) async {
    // ── 1. app open generates, Today shows the chore with its assignee ─────
    await openAs(tester, 'cara', Role.member, AppRoutes.choresToday);
    final failure = await containerOf(
      tester,
    ).read(ensureOccurrencesOnOpenProvider(familyId).future);
    expect(failure, isNull, reason: 'generation must not report a failure');
    await tester.pumpAndSettle();

    expect(fixture.occurrences.occurrences[familyId], contains(todayId));
    expect(fixture.occurrences.occurrences[familyId], contains(tomorrowId));
    expect(stored(todayId).assigneeId, 'cara');
    expect(find.text('Wipe the table'), findsOneWidget);
    expect(find.text('0 of 1 done'), findsOneWidget);

    // ── 2. tick two steps, then the rest, then untick one ──────────────────
    await tap(tester, find.text('Wipe the table'));
    await tap(tester, find.byKey(const ValueKey('subtask_step_1')));
    await tap(tester, find.byKey(const ValueKey('subtask_step_2')));
    expect(find.text('2/3'), findsWidgets);
    expect(effectiveStatus(stored(todayId)), ChoreStatus.inProgress);

    await tap(tester, find.byKey(const ValueKey('subtask_step_3')));
    expect(stored(todayId).completedBy, 'cara');
    expect(effectiveStatus(stored(todayId)), ChoreStatus.completed);

    await tap(tester, find.byKey(const ValueKey('subtask_step_3')));
    expect(stored(todayId).completedAt, isNull);
    expect(effectiveStatus(stored(todayId)), ChoreStatus.inProgress);
    expect(find.text('2/3'), findsWidgets);

    await tap(tester, find.byKey(const ValueKey('subtask_step_3')));
    expect(effectiveStatus(stored(todayId)), ChoreStatus.completed);

    // ── 3. the completer cannot verify; a manager can ──────────────────────
    final denied = await containerOf(tester).read(verifyOccurrenceProvider)(
      familyId: familyId,
      actorUid: 'cara',
      occurrenceId: todayId,
    );
    expect(denied.failureOrNull, isA<AppFailure>());

    await openAs(tester, 'cara', Role.member, AppRoutes.choresVerify);
    expect(find.text('Approve'), findsNothing);

    await openAs(tester, 'bob', Role.moderator, AppRoutes.choresVerify);
    expect(find.text('Approve'), findsOneWidget);
    await tap(tester, find.text('Approve'));
    expect(stored(todayId).verifiedBy, 'bob');
    expect(effectiveStatus(stored(todayId)), ChoreStatus.verified);

    // ── 4. rename with "future only" ───────────────────────────────────────
    final container = containerOf(tester);
    final template = fixture.chores.templates[familyId]!['tpl_1']!;
    final saved = await container.read(updateTemplateProvider)(
      actorUid: 'bob',
      familyId: familyId,
      templateId: 'tpl_1',
      draft: template.draft.copyWith(nameEn: 'Wipe the big table'),
    );
    expect(saved.failureOrNull, isNull);
    final replanned =
        await ReplanOccurrences(
          occurrences: fixture.occurrences,
          templates: fixture.chores,
          dutyGroups: fixture.chores.dutyGroups,
          settings: fixture.settings,
          families: fixture.families,
          dateKeys: fixture.dateKeys,
          clock: fixture.clock,
        )(
          familyId: familyId,
          actorUid: 'bob',
          templateId: 'tpl_1',
          from: DateKey(2026, 10, 25),
        );
    expect(replanned.failureOrNull, isNull);

    expect(stored(todayId).nameEn, 'Wipe the table');
    expect(stored(tomorrowId).nameEn, 'Wipe the big table');
  });
}
