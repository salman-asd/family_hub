import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/presentation/verify_queue_screen.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chores_test_helpers.dart';
import 'chores_p3_15_support.dart';

/// P3-15 / Wave R5: the verification queue (U-09, B-02).
void main() {
  final verifyOn = PermissionSettings.defaults.copyWith(
    choreVerificationEnabled: true,
  );

  ChoreOccurrence waiting(String id, {String by = 'cara'}) => anOccurrence(
    id: id,
    dateKey: DateKey(2026, 10, 24),
    verification: VerificationMode.required,
    status: OccurrenceStatus.completed,
    completedAt: DateTime.utc(2026, 10, 24, 4),
    completedBy: by,
  );

  testWidgets('a manager sees the chore that waits for a check', (
    tester,
  ) async {
    await pumpP3Screen(
      tester,
      home: const VerifyQueueScreen(),
      uid: 'bob',
      role: Role.moderator,
      occurrences: <ChoreOccurrence>[waiting('a_20261024')],
      overrides: [permissionSettingsProvider.overrideWithValue(verifyOn)],
    );

    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Send back'), findsOneWidget);
  });

  testWidgets('the viewer\'s own completion is not in their queue', (
    tester,
  ) async {
    await pumpP3Screen(
      tester,
      home: const VerifyQueueScreen(),
      uid: 'bob',
      role: Role.moderator,
      occurrences: <ChoreOccurrence>[waiting('a_20261024', by: 'bob')],
      overrides: [permissionSettingsProvider.overrideWithValue(verifyOn)],
    );

    expect(find.text('Approve'), findsNothing);
    expect(find.text('Nothing to verify'), findsOneWidget);
  });

  testWidgets('a plain member gets the explanation, not a list', (
    tester,
  ) async {
    await pumpP3Screen(
      tester,
      home: const VerifyQueueScreen(),
      occurrences: <ChoreOccurrence>[waiting('a_20261024', by: 'dave')],
      overrides: [permissionSettingsProvider.overrideWithValue(verifyOn)],
    );

    expect(find.text('Approve'), findsNothing);
    expect(find.text('Nothing to verify'), findsOneWidget);
  });

  testWidgets('U-09: a failed queue listener shows an error with Retry', (
    tester,
  ) async {
    await pumpP3Screen(
      tester,
      home: const VerifyQueueScreen(),
      uid: 'bob',
      role: Role.moderator,
      overrides: [
        permissionSettingsProvider.overrideWithValue(verifyOn),
        verifyQueueProvider.overrideWith(
          (ref) => Stream<List<ChoreOccurrence>>.error(StateError('failed')),
        ),
      ],
    );

    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Nothing to verify'), findsNothing);
  });

  testWidgets('the queue supports pull to refresh', (tester) async {
    await pumpP3Screen(
      tester,
      home: const VerifyQueueScreen(),
      uid: 'bob',
      role: Role.moderator,
      occurrences: <ChoreOccurrence>[waiting('a_20261024')],
      overrides: [permissionSettingsProvider.overrideWithValue(verifyOn)],
    );

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('no overflow at text scale 2.0', (tester) async {
    await pumpP3Screen(
      tester,
      home: const VerifyQueueScreen(),
      uid: 'bob',
      role: Role.moderator,
      textScale: 2,
      occurrences: <ChoreOccurrence>[waiting('a_20261024')],
      overrides: [permissionSettingsProvider.overrideWithValue(verifyOn)],
    );

    expect(tester.takeException(), isNull);
  });
}
