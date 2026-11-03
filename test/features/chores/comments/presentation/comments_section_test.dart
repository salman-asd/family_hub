import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/comments/domain/occurrence_comment.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/presentation/occurrence_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';
import '../../presentation/chores_p3_15_support.dart';

/// P3-25: the comment thread on the chore detail screen.
void main() {
  const id = 'a_20261024';
  final at = DateTime.utc(2026, 10, 24, 5);

  ChoreOccurrence chore({bool completed = false}) => anOccurrence(
    id: id,
    dateKey: DateKey(2026, 10, 24),
    status: completed ? OccurrenceStatus.completed : OccurrenceStatus.scheduled,
    completedAt: completed ? at : null,
    completedBy: completed ? 'cara' : null,
    needsAttention: true,
  );

  OccurrenceComment flagged() => OccurrenceComment(
    id: 'f1',
    occurrenceId: id,
    authorId: 'dave',
    text: 'The sink is still dirty',
    createdAt: at,
    needsAttention: true,
  );

  ChoresFixture seeded({bool withFlag = true, bool completed = false}) {
    final fixture = ChoresFixture();
    if (withFlag) {
      fixture.comments.threads[ChoresFixture.familyId] =
          <String, List<OccurrenceComment>>{id: <OccurrenceComment>[flagged()]};
    }
    return fixture;
  }

  Future<ChoresFixture> open(
    WidgetTester tester, {
    required String uid,
    Role role = Role.member,
    bool withFlag = true,
    bool completed = false,
    String language = 'en',
    double scale = 1.0,
  }) async {
    final fixture = seeded(withFlag: withFlag, completed: completed);
    await pumpP3Screen(
      tester,
      home: const OccurrenceDetailScreen(occurrenceId: id),
      sharedFixture: fixture,
      occurrences: <ChoreOccurrence>[chore(completed: completed)],
      uid: uid,
      role: role,
      height: 2400,
      languageCode: language,
      textScale: scale,
    );
    await tester.pump(const Duration(milliseconds: 100));
    return fixture;
  }

  testWidgets('an empty thread says so and a member can write', (tester) async {
    final fixture = await open(tester, uid: 'dave', withFlag: false);

    expect(find.text('Comments'), findsOneWidget);
    expect(find.textContaining('No comments yet'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Looks good');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pump(const Duration(milliseconds: 100));

    final thread = fixture.comments.thread(ChoresFixture.familyId, id);
    expect(thread.single.text, 'Looks good');
    expect(thread.single.authorId, 'dave');
    expect(find.text('Looks good'), findsWidgets);
  });

  testWidgets('a flagged comment is labelled and the assignee can resolve it', (
    tester,
  ) async {
    final fixture = await open(tester, uid: 'cara');

    expect(find.text('The sink is still dirty'), findsWidgets);
    expect(find.text('Needs attention'), findsWidgets);
    await tester.tap(find.text('Mark as resolved'));
    await tester.pump(const Duration(milliseconds: 100));

    final thread = fixture.comments.thread(ChoresFixture.familyId, id);
    expect(thread.single.isResolved, isTrue);
    expect(
      fixture.occurrences.occurrences[ChoresFixture.familyId]![id]!
          .needsAttention,
      isFalse,
    );
  });

  testWidgets('a plain member is not offered resolve, hide or reopen', (
    tester,
  ) async {
    await open(tester, uid: 'dave');

    expect(find.text('Mark as resolved'), findsNothing);
    expect(find.text('Hide'), findsNothing);
    expect(find.text('Reopen with this reason'), findsNothing);
  });

  testWidgets('a manager can hide; everybody else sees the placeholder', (
    tester,
  ) async {
    await open(tester, uid: 'bob', role: Role.moderator);
    expect(find.text('Hide'), findsOneWidget);
  });

  testWidgets('a flag on a finished chore offers Reopen with this reason', (
    tester,
  ) async {
    await open(tester, uid: 'dave', completed: true);
    expect(find.text('Reopen with this reason'), findsOneWidget);

    await tester.tap(find.text('Reopen with this reason'));
    await tester.pump(const Duration(milliseconds: 300));

    // The reason sheet opens with the comment text prefilled.
    expect(
      find.widgetWithText(TextField, 'The sink is still dirty'),
      findsOneWidget,
    );
  });

  testWidgets('Bangla at text scale 2.0 does not overflow', (tester) async {
    await open(tester, uid: 'bob', role: Role.moderator, language: 'bn', scale: 2);
    expect(tester.takeException(), isNull);
  });
}
