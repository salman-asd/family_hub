import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_screen.dart';
import 'package:family_hub/features/chores/settings/presentation/widgets/catalog_mapping.dart';
import 'package:family_hub/features/chores/templates/presentation/widgets/slots_editor.dart';
import 'package:family_hub/features/chores/templates/domain/template_parts.dart';
import 'package:family_hub/shared/widgets/weekday_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../chores_test_helpers.dart';
import '../../presentation/chores_p3_15_support.dart';

/// P3-17: the chore settings screen against the fake settings repository.
void main() {
  Future<void> openAndScrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('settings_save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('a plain member sees an explanation, not the controls', (
    tester,
  ) async {
    await pumpP3Screen(tester, home: const ChoreSettingsScreen());

    final l10n = AppLocalizationsEn();
    expect(find.text(l10n.choresSettingsNotAllowed), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('settings_save')), findsNothing);
    expect(find.byKey(const ValueKey<String>('policy_skip')), findsNothing);
  });

  testWidgets('the Save button is off until something changes', (tester) async {
    await pumpP3Screen(
      tester,
      role: Role.admin,
      uid: 'alice',
      home: const ChoreSettingsScreen(),
    );

    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('settings_save')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('choosing a policy card writes that enum, and only that', (
    tester,
  ) async {
    final fixture = await pumpP3Screen(
      tester,
      role: Role.admin,
      uid: 'alice',
      home: const ChoreSettingsScreen(),
    );

    final skip = find.byKey(const ValueKey<String>('policy_skip'));
    await openAndScrollTo(tester, skip);
    await tester.tap(skip);
    await tester.pump();
    await save(tester);

    expect(fixture.settings.policy, AbsencePolicy.skip);
    expect(fixture.settings.policySaves, 1);
    // The settings document itself did not change, so it was not written.
    expect(fixture.settings.saves, 0);
  });

  testWidgets('changing the week start writes weekStartDay', (tester) async {
    final fixture = await pumpP3Screen(
      tester,
      role: Role.admin,
      uid: 'alice',
      home: const ChoreSettingsScreen(),
    );

    final monday = find.byKey(const ValueKey<String>('week_start_1'));
    await openAndScrollTo(tester, monday);
    await tester.tap(monday);
    await tester.pump();
    await save(tester);

    expect(fixture.settings.settings.weekStartDay, DateTime.monday);
    expect(fixture.settings.saves, 1);
  });

  testWidgets('the weekday chips follow the week start', (tester) async {
    expect(WeekdayChips.order(DateTime.saturday), <int>[6, 7, 1, 2, 3, 4, 5]);
    expect(WeekdayChips.order(DateTime.monday), <int>[1, 2, 3, 4, 5, 6, 7]);
    expect(WeekdayChips.order(DateTime.sunday), <int>[7, 1, 2, 3, 4, 5, 6]);
  });

  testWidgets('"members can complete for others" is hidden for a moderator', (
    tester,
  ) async {
    await pumpP3Screen(
      tester,
      role: Role.moderator,
      uid: 'bob',
      home: const ChoreSettingsScreen(),
    );

    final swaps = find.byKey(const ValueKey<String>('swaps_enabled'));
    await openAndScrollTo(tester, swaps);
    expect(
      find.byKey(const ValueKey<String>('complete_for_others')),
      findsNothing,
    );
  });

  testWidgets('an offline save keeps the draft and says it needs internet', (
    tester,
  ) async {
    final fixture = await pumpP3Screen(
      tester,
      role: Role.admin,
      uid: 'alice',
      home: const ChoreSettingsScreen(),
    );
    fixture.settings.nextFailure = const Network();

    final monday = find.byKey(const ValueKey<String>('week_start_1'));
    await openAndScrollTo(tester, monday);
    await tester.tap(monday);
    await tester.pump();
    await save(tester);

    expect(
      find.text(AppLocalizationsEn().choresSettingsNeedsInternet),
      findsOneWidget,
    );
    // Still unsaved: the button is on, nothing was stored.
    expect(fixture.settings.settings.weekStartDay, isNot(DateTime.monday));
    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('settings_save')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('Reset section asks first, then restores the defaults', (
    tester,
  ) async {
    final fixture = ChoresFixture();
    fixture.settings.settings = ChoreSettings.defaults.copyWith(
      generationHorizonDays: 20,
    );
    await pumpP3Screen(
      tester,
      sharedFixture: fixture,
      role: Role.admin,
      uid: 'alice',
      home: const ChoreSettingsScreen(),
    );

    final reset = find.byKey(const ValueKey<String>('reset_generation'));
    await openAndScrollTo(tester, reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    // Cancel leaves everything as it was.
    await tester.tap(find.text(AppLocalizationsEn().actionCancel));
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('settings_save')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);

    await tester.tap(reset);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('reset_confirm')));
    await tester.pumpAndSettle();
    await save(tester);

    expect(
      fixture.settings.settings.generationHorizonDays,
      ChoreSettings.defaults.generationHorizonDays,
    );
  });

  testWidgets('leaving with unsaved changes asks first', (tester) async {
    await pumpP3Screen(
      tester,
      role: Role.admin,
      uid: 'alice',
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChoreSettingsScreen(),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final monday = find.byKey(const ValueKey<String>('week_start_1'));
    await openAndScrollTo(tester, monday);
    await tester.tap(monday);
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.text(AppLocalizationsEn().choresSettingsDiscardTitle),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('discard_confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(ChoreSettingsScreen), findsNothing);
  });

  group('a deactivated due-time preset', () {
    testWidgets('is hidden from the slots of a new chore', (tester) async {
      final fixture = ChoresFixture();
      final first = ChoreSettings.defaults.dueTimePresets.first.id;
      final second = ChoreSettings.defaults.dueTimePresets.last.id;
      fixture.settings.settings = ChoreSettings.defaults.copyWith(
        dueTimePresets: <DueTimePreset>[
          for (final p in ChoreSettings.defaults.dueTimePresets)
            p.id == first ? p.copyWith(active: false) : p,
        ],
      );
      await pumpP3Screen(
        tester,
        sharedFixture: fixture,
        role: Role.admin,
        uid: 'alice',
        home: Scaffold(
          body: SingleChildScrollView(
            child: SlotsEditor(
              slots: <TemplateSlot>[aSlot(dueMinutes: null)],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.byKey(ValueKey<String>('slot_main_preset_$first')),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey<String>('slot_main_preset_$second')),
        findsOneWidget,
      );
    });
  });

  group('CatalogMapping', () {
    test('nextCustomId takes the smallest unused number', () {
      expect(CatalogMapping.nextCustomId(<String>[]), 'custom_1');
      expect(
        CatalogMapping.nextCustomId(<String>['custom_1', 'custom_3']),
        'custom_2',
      );
    });

    test('a renamed group keeps its colour, icon and built-in flag', () {
      final original = ChoreSettings.defaults.groups.first;
      final rows = <CatalogEntry>[
        CatalogMapping.groupEntry(original).copyWith(labelBn: 'নতুন নাম'),
      ];
      final result = CatalogMapping.groupsFrom(rows, <ChoreGroup>[original]);
      expect(result.single.nameBn, 'নতুন নাম');
      expect(result.single.colorIndex, original.colorIndex);
      expect(result.single.iconKey, original.iconKey);
      expect(result.single.builtIn, isTrue);
    });
  });

  group('layout', () {
    for (final language in <String>['en', 'bn']) {
      for (final scale in <double>[1.0, 2.0]) {
        testWidgets('$language at text scale $scale does not overflow', (
          tester,
        ) async {
          await pumpP3Screen(
            tester,
            role: Role.admin,
            uid: 'alice',
            languageCode: language,
            textScale: scale,
            home: const ChoreSettingsScreen(),
          );
          // Walk the whole page so every section is laid out once.
          final list = find.byType(Scrollable).first;
          for (var i = 0; i < 12; i++) {
            await tester.drag(list, const Offset(0, -500));
            await tester.pump();
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
