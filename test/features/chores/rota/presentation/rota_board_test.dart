import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/rota/presentation/rota_board_screen.dart';
import 'package:family_hub/features/chores/rota/presentation/rota_providers.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/templates/domain/template_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';
import '../../presentation/chores_p3_15_support.dart';

/// P3-28: the rota board screen.
void main() {
  late ChoresFixture fixture;

  setUp(() => fixture = ChoresFixture());

  Future<void> open(
    WidgetTester tester, {
    String uid = 'bob',
    Role role = Role.moderator,
    String language = 'en',
    double scale = 1,
  }) async {
    await pumpP3Screen(
      tester,
      home: const RotaBoardScreen(),
      sharedFixture: fixture,
      uid: uid,
      role: role,
      occurrences: [
        anOccurrence(
          id: 'a',
          dateKey: DateKey(2026, 10, 24),
          assigneeId: 'cara',
        ),
        anOccurrence(
          id: 'b',
          dateKey: DateKey(2026, 10, 24),
          assigneeId: 'dave',
          difficulty: Difficulty.hard,
        ),
        anOccurrence(
          id: 'c',
          dateKey: DateKey(2026, 10, 25),
          assigneeId: 'cara',
        ),
      ],
      languageCode: language,
      textScale: scale,
      height: 1400,
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  test('a week starts on the family week-start day', () {
    // 2026-10-24 is a Saturday; the default week starts on Saturday (6).
    final saturday = rotaBoundsFor(
      range: RotaRange.week,
      today: DateKey(2026, 10, 24),
      weekStartDay: 6,
    );
    expect(saturday.from, DateKey(2026, 10, 24));
    expect(saturday.to, DateKey(2026, 10, 30));
    final wednesday = rotaBoundsFor(
      range: RotaRange.week,
      today: DateKey(2026, 10, 28),
      weekStartDay: 6,
    );
    expect(wednesday.from, DateKey(2026, 10, 24));
    final sundayStart = rotaBoundsFor(
      range: RotaRange.week,
      today: DateKey(2026, 10, 24),
      weekStartDay: 0,
    );
    expect(sundayStart.from, DateKey(2026, 10, 18));
  });

  test('a month is the calendar month', () {
    final month = rotaBoundsFor(
      range: RotaRange.month,
      today: DateKey(2026, 12, 5),
      weekStartDay: 6,
    );
    expect(month.from, DateKey(2026, 12, 1));
    expect(month.to, DateKey(2026, 12, 31));
  });

  testWidgets('a manager sees today’s duty, each share and the grid', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('On duty today'), findsOneWidget);
    expect(find.byKey(const Key('rota_share_cara')), findsOneWidget);
    expect(find.byKey(const Key('rota_share_dave')), findsOneWidget);
    // cara 2 + 2 = 4 points, dave 3: cara 57%, dave 43%.
    expect(find.text('57% of the work'), findsOneWidget);
    expect(find.text('43% of the work'), findsOneWidget);
    expect(find.byKey(const Key('rota_matrix')), findsOneWidget);
  });

  testWidgets('switching to Month keeps the board', (tester) async {
    await open(tester);
    await tester.tap(find.text('Month'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('rota_matrix')), findsOneWidget);
  });

  testWidgets('members do not see the board while the workload is hidden', (
    tester,
  ) async {
    fixture.settings.settings = ChoreSettings.defaults.copyWith(
      workloadVisibleToMembers: false,
    );
    await open(tester, uid: 'cara', role: Role.member);
    expect(find.text('The workload is hidden from members.'), findsOneWidget);
    expect(find.byKey(const Key('rota_matrix')), findsNothing);
  });

  testWidgets('members see it when the family turns it on', (tester) async {
    fixture.settings.settings = ChoreSettings.defaults.copyWith(
      workloadVisibleToMembers: true,
    );
    await open(tester, uid: 'cara', role: Role.member);
    expect(find.byKey(const Key('rota_matrix')), findsOneWidget);
  });

  testWidgets('Bangla at text scale 2.0 does not overflow', (tester) async {
    await open(tester, language: 'bn', scale: 2);
    expect(tester.takeException(), isNull);
  });
}
