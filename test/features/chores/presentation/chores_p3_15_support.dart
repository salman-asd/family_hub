import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/chores/duty_groups/presentation/duty_group_providers.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_occurrence.dart';
import 'package:family_hub/features/chores/occurrences/presentation/occurrence_providers.dart';
import 'package:family_hub/features/chores/occurrences/presentation/today_providers.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/chores/templates/presentation/template_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chores_test_helpers.dart';

/// Shared harness for the P3-15 screen tests (Today, Verify, Detail, bar).
///
/// 320 dp wide, English, `disableAnimations`, the in-memory chores backend and
/// one acting member (`uid`, `role`). `overrides` come last so a test can
/// replace any provider.
Future<ChoresFixture> pumpP3Screen(
  WidgetTester tester, {
  required Widget home,
  String uid = 'cara',
  Role role = Role.member,
  double textScale = 1.0,
  List<ChoreOccurrence> occurrences = const <ChoreOccurrence>[],
  List<Override> overrides = const <Override>[],
}) async {
  tester.view
    ..physicalSize = const Size(320, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final fixture = ChoresFixture();
  fixture.occurrences.occurrences[ChoresFixture.familyId] =
      <String, ChoreOccurrence>{for (final o in occurrences) o.id: o};

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        appFormattersProvider.overrideWithValue(
          const AppFormatters(languageCode: 'en', useBanglaDigits: false),
        ),
        occurrenceRepositoryProvider.overrideWithValue(fixture.occurrences),
        generationMarkerRepositoryProvider.overrideWithValue(
          fixture.occurrences,
        ),
        dutyGroupRepositoryProvider.overrideWithValue(
          fixture.chores.dutyGroups,
        ),
        templateRepositoryProvider.overrideWithValue(fixture.chores),
        choreSettingsRepositoryProvider.overrideWithValue(fixture.settings),
        familyRepositoryProvider.overrideWithValue(fixture.families),
        currentFamilyIdProvider.overrideWithValue(ChoresFixture.familyId),
        currentUidProvider.overrideWithValue(uid),
        clockProvider.overrideWithValue(fixture.clock),
        currentActorProvider.overrideWithValue(
          PermissionActor(uid: uid, role: role, isActive: true),
        ),
        permissionSettingsProvider.overrideWithValue(
          PermissionSettings.defaults,
        ),
        // No running timer in a widget test.
        nowTickProvider.overrideWith((ref) => const Stream<DateTime>.empty()),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildThemeData(appThemes.first),
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 250));
  return fixture;
}
