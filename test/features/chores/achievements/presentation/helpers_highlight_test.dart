import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/chores/achievements/presentation/widgets/helpers_highlight.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/engagement_test_support.dart';
import 'engagement_ui_test_support.dart';

void main() {
  final month = DateKey(2026, 10, 1).monthKey;

  testWidgets('shows active helpers alphabetically from the current month', (
    tester,
  ) async {
    final settings = defaultEngagementSettings(
      startedOn: DateKey(2026, 10, 1),
      graceMinutes: 0,
    ).copyWith(showHelpersHighlight: true);
    final covers = [
      engagementOccurrence(
        id: 'cover_dave_20261024',
        day: DateKey(2026, 10, 24),
        assigneeId: 'dave',
        coverForId: 'cara',
      ),
      engagementOccurrence(
        id: 'cover_cara_20261024',
        day: DateKey(2026, 10, 24),
        assigneeId: 'cara',
        coverForId: 'dave',
      ),
    ];
    await pumpEngagementApp(
      tester,
      home: HelpersHighlight(month: month),
      overrides: [
        engagementSettingsProvider.overrideWith(
          (ref, familyId) => Stream.value(settings),
        ),
        membersProvider.overrideWith(
          (ref) => Stream.value(engagementTestMembers()),
        ),
        monthOccurrencesProvider.overrideWith(
          (ref, requestedMonth) => Stream.value(
            MonthOccurrences.fromDocuments(
              covers.where((item) => item.monthKey == requestedMonth).toList(),
            ),
          ),
        ),
      ],
    );

    expect(find.text('Family helpers this month'), findsOneWidget);
    expect(find.textContaining('Person cara'), findsOneWidget);
    expect(find.textContaining('Person dave'), findsOneWidget);
    // Order in the list is what "alphabetically" means here; the chips wrap on
    // a narrow screen, so their x coordinates are not comparable.
    final chips = find.byType(Chip);
    expect(
      (tester.widget<Chip>(chips.first).label as Text).data,
      startsWith('Person cara'),
    );
    expect(
      (tester.widget<Chip>(chips.last).label as Text).data,
      startsWith('Person dave'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('is hidden when the highlight switch is off or no one covered', (
    tester,
  ) async {
    final settings = defaultEngagementSettings(
      startedOn: DateKey(2026, 10, 1),
      graceMinutes: 0,
    );
    await pumpEngagementApp(
      tester,
      home: HelpersHighlight(month: month),
      overrides: [
        engagementSettingsProvider.overrideWith(
          (ref, familyId) => Stream.value(settings),
        ),
        membersProvider.overrideWith(
          (ref) => Stream.value(engagementTestMembers()),
        ),
      ],
    );

    expect(find.text('Family helpers this month'), findsNothing);
  });

  testWidgets('enabled highlight is scroll-safe with Bangla at 2x', (
    tester,
  ) async {
    final settings = defaultEngagementSettings(
      startedOn: DateKey(2026, 10, 1),
      graceMinutes: 0,
    ).copyWith(showHelpersHighlight: true);
    final covers = [
      engagementOccurrence(
        id: 'cover_dave_20261024',
        day: DateKey(2026, 10, 24),
        assigneeId: 'dave',
        coverForId: 'cara',
      ),
    ];
    await pumpEngagementApp(
      tester,
      home: HelpersHighlight(month: month),
      languageCode: 'bn',
      textScale: 2,
      overrides: [
        engagementSettingsProvider.overrideWith(
          (ref, familyId) => Stream.value(settings),
        ),
        membersProvider.overrideWith(
          (ref) => Stream.value(engagementTestMembers()),
        ),
        monthOccurrencesProvider.overrideWith(
          (ref, requestedMonth) => Stream.value(
            MonthOccurrences.fromDocuments(
              covers.where((item) => item.monthKey == requestedMonth).toList(),
            ),
          ),
        ),
      ],
    );

    expect(find.text('এই মাসের পারিবারিক সহায়তাকারী'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
