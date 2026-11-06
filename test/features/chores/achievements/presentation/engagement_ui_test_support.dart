import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpEngagementApp(
  WidgetTester tester, {
  required Widget home,
  String uid = 'cara',
  Role role = Role.member,
  String languageCode = 'en',
  double textScale = 1,
  List<Override> overrides = const <Override>[],
}) async {
  tester.view
    ..physicalSize = const Size(320, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        appFormattersProvider.overrideWithValue(
          AppFormatters(
            languageCode: languageCode,
            useBanglaDigits: languageCode == 'bn',
          ),
        ),
        currentFamilyIdProvider.overrideWithValue('f1'),
        currentUidProvider.overrideWithValue(uid),
        currentActorProvider.overrideWithValue(
          PermissionActor(uid: uid, role: role, isActive: true),
        ),
        permissionSettingsProvider.overrideWithValue(
          PermissionSettings.defaults,
        ),
        choreSettingsProvider.overrideWithValue(ChoreSettings.defaults),
        ...overrides,
      ],
      child: MaterialApp(
        theme: buildThemeData(appThemes.first),
        locale: Locale(languageCode),
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
}

List<Member> engagementTestMembers() => <Member>[
  for (final (uid, role) in const <(String, MemberRole)>[
    ('alice', MemberRole.admin),
    ('cara', MemberRole.member),
    ('dave', MemberRole.member),
  ])
    Member(
      uid: uid,
      role: role,
      status: MembershipStatus.active,
      fullName: 'Person $uid',
      relationship: 'other',
    ),
];
