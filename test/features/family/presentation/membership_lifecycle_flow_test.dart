import 'package:family_hub/app/app.dart';
import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/router.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/membership_providers.dart';
import 'package:family_hub/features/onboarding/presentation/profile_providers.dart';
import 'package:family_hub/modules/module_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_auth_repository.dart';
import '../family_test_helpers.dart';

const _me = AppUser(uid: 'me', email: 'me@example.com', emailVerified: true);

String _path(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(FamilyHubApp)))
        .read(routerProvider)
        .routeInformationProvider
        .value
        .uri
        .path;

Future<void> _pumpApp(WidgetTester tester, Fixture f) async {
  tester.view
    ..physicalSize = const Size(400, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final auth = FakeAuthRepository(signedInAs: _me);
  addTearDown(auth.dispose);
  final b = f.backend;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        flavorProvider.overrideWithValue(Flavor.dev),
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(b),
        userProfileRepositoryProvider.overrideWithValue(b),
        membershipRepositoryProvider.overrideWithValue(b),
        moduleFlagsRepositoryProvider.overrideWithValue(b),
        familyRepositoryProvider.overrideWithValue(b),
        clockProvider.overrideWithValue(f.clock),
        idGeneratorProvider.overrideWithValue(f.ids.call),
      ],
      child: const FamilyHubApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(Key(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'pending person cancels the request and returns to family choice',
    (tester) async {
      final f = Fixture()
        ..seedFamily({'admin': (MemberRole.admin, MembershipStatus.active)})
        ..profile('me');
      addTearDown(f.backend.dispose);
      f.backend.invitations['ABCD2345'] = Invitation(
        code: 'ABCD2345',
        familyId: 'fam',
        role: MemberRole.member,
        expiresAt: f.clock.nowUtc().add(const Duration(days: 7)),
        createdBy: 'admin',
        createdAt: f.clock.nowUtc(),
      );
      await _pumpApp(tester, f);
      await _tap(tester, 'choice_join');
      await tester.enterText(find.byKey(const Key('join_code')), 'ABCD2345');
      await tester.pumpAndSettle();
      await _tap(tester, 'join_submit');
      expect(_path(tester), '/pending');

      await _tap(tester, 'pending_cancel');

      expect(_path(tester), '/family-choice');
      expect(f.backend.members['fam']!['me']!.removedAt, isNotNull);
      expect(f.backend.events.last.type, 'member.cancelled');
    },
  );

  testWidgets('an active member leaves after confirming', (tester) async {
    final f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'me': (MemberRole.member, MembershipStatus.active),
      })
      ..profile('me');
    addTearDown(f.backend.dispose);
    await _pumpApp(tester, f);
    expect(_path(tester), '/home');

    await tester.tap(find.byKey(const Key('tab_family')));
    await tester.pumpAndSettle();
    await _tap(tester, 'family_leave');
    expect(find.byKey(const Key('family_leave_confirm')), findsOneWidget);
    await tester.tap(find.byKey(const Key('family_leave_confirm')));
    await tester.pumpAndSettle();

    expect(_path(tester), '/family-choice');
    expect(f.backend.members['fam']!['me']!.leftAt, isNotNull);
  });

  testWidgets(
    'the only admin cannot leave: the action is blocked with a reason',
    (tester) async {
      final f = Fixture()
        ..seedFamily({'me': (MemberRole.admin, MembershipStatus.active)})
        ..profile('me');
      addTearDown(f.backend.dispose);
      await _pumpApp(tester, f);

      await tester.tap(find.byKey(const Key('tab_family')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('family_leave')));
      await tester.pumpAndSettle();

      expect(find.textContaining('একমাত্র অ্যাডমিন'), findsWidgets);
      await tester.tap(
        find.byKey(const Key('family_leave')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('family_leave_confirm')), findsNothing);
      expect(f.backend.members['fam']!['me']!.isActive, isTrue);
    },
  );
}
