import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/occurrences/domain/occurrence_status.dart';
import 'package:family_hub/features/chores/occurrences/presentation/today_providers.dart';
import 'package:family_hub/features/chores/presentation/dashboard/chores_dashboard_cards.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';
import '../chores_p3_15_support.dart';

/// P3-29: the Home dashboard cards.
void main() {
  late ChoresFixture fixture;

  setUp(() {
    fixture = ChoresFixture();
    fixture.settings.settings = ChoreSettings.defaults.copyWith(
      defaultScope: CalendarScopeKind.all,
    );
  });

  Widget cards() => Scaffold(
    body: ListView(
      children: [
        for (final build in choresDashboardCards) Builder(builder: build),
      ],
    ),
  );

  Future<void> open(
    WidgetTester tester, {
    String uid = 'bob',
    Role role = Role.moderator,
    String language = 'en',
    double scale = 1,
  }) async {
    await pumpP3Screen(
      tester,
      home: cards(),
      sharedFixture: fixture,
      uid: uid,
      role: role,
      languageCode: language,
      textScale: scale,
      height: 1400,
      occurrences: [
        // Due 09:00 Dhaka, the clock says 15:00: overdue.
        anOccurrence(id: 'a', dateKey: DateKey(2026, 10, 24)),
        // Due 21:00 Dhaka: still to do.
        anOccurrence(
          id: 'b',
          dateKey: DateKey(2026, 10, 24),
          nameEn: 'Cook dinner',
          dueMinutes: 1260,
          dueAt: DateTime.utc(2026, 10, 24, 15),
        ),
        anOccurrence(
          id: 'c',
          dateKey: DateKey(2026, 10, 24),
          nameEn: 'Done one',
          status: OccurrenceStatus.completed,
          completedAt: DateTime.utc(2026, 10, 24, 5),
          completedBy: 'cara',
        ),
      ],
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  test('an item already shown as overdue still counts as overdue', () {
    final item = ChoreItem.fromOccurrence(anOccurrence())
        .copyWith(status: ChoreStatus.overdue);
    expect(isOverdueItem(item, DateTime.utc(2026, 10, 24), 0), isTrue);
  });

  testWidgets('Today card: progress and the next chore', (tester) async {
    await open(tester);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('1 of 3 done'), findsOneWidget);
    expect(find.text('Next: Cook dinner'), findsOneWidget);
  });

  testWidgets('Overdue card: count and the oldest chore', (tester) async {
    await open(tester);
    expect(find.text('1 overdue'), findsOneWidget);
    expect(find.text('Oldest: Wash the dishes'), findsOneWidget);
  });

  testWidgets('week strip shows seven days', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('chores_card_week')), findsOneWidget);
    expect(find.byKey(const Key('chores_week_2026-10-24')), findsOneWidget);
    expect(find.byKey(const Key('chores_week_2026-10-30')), findsOneWidget);
  });

  testWidgets('verify card is hidden from a plain member', (tester) async {
    await open(tester, uid: 'cara', role: Role.member);
    expect(find.byKey(const Key('chores_card_verify')), findsNothing);
    expect(find.byKey(const Key('chores_card_today')), findsOneWidget);
  });

  testWidgets('verify card is hidden while nothing waits', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('chores_card_verify')), findsNothing);
  });

  testWidgets('Bangla at text scale 2.0 does not overflow', (tester) async {
    await open(tester, language: 'bn', scale: 2);
    expect(tester.takeException(), isNull);
  });
}
