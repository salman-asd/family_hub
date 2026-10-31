import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/presentation/widgets/occurrence_actions_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chores_test_helpers.dart';
import 'chores_p3_15_support.dart';

/// P3-15 / Wave R5: the action bar keeps at most two buttons (U-10).
void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    required Role role,
    double textScale = 1.0,
  }) {
    final item = ChoreItem.fromOccurrence(
      anOccurrence(assigneeId: 'u1', plannedAssigneeId: 'u1'),
    );
    return pumpP3Screen(
      tester,
      uid: 'u1',
      role: role,
      textScale: textScale,
      home: Scaffold(
        bottomNavigationBar: OccurrenceActionsBar(
          item: item,
          completedBy: null,
          onComplete: () {},
          onUndo: () {},
          onVerify: () {},
          onReopen: () {},
          onReassign: () {},
          onSkip: () {},
          onUnskip: () {},
          onException: () {},
        ),
      ),
    );
  }

  testWidgets('a manager gets one button and an overflow menu', (
    tester,
  ) async {
    await pumpBar(tester, role: Role.admin);

    expect(find.byKey(const ValueKey('action_complete')), findsOneWidget);
    expect(find.byKey(const ValueKey('action_skip')), findsNothing);
    expect(find.byKey(const ValueKey('actions_more')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('actions_more')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('action_reassign')), findsOneWidget);
    expect(find.byKey(const ValueKey('action_skip')), findsOneWidget);
    expect(find.byKey(const ValueKey('action_exception')), findsOneWidget);
  });

  testWidgets('a plain member has no overflow menu', (tester) async {
    await pumpBar(tester, role: Role.member);

    expect(find.byKey(const ValueKey('action_complete')), findsOneWidget);
    expect(find.byKey(const ValueKey('actions_more')), findsNothing);
    expect(find.byKey(const ValueKey('action_reassign')), findsNothing);
  });

  testWidgets('no overflow at text scale 2.0', (tester) async {
    await pumpBar(tester, role: Role.admin, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
