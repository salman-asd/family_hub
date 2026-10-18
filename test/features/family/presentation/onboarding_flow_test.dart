import 'package:family_hub/app/app.dart';
import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/router.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/usecases/approve_member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/membership_providers.dart';
import 'package:family_hub/features/onboarding/presentation/profile_providers.dart';
import 'package:family_hub/modules/module_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_auth_repository.dart';
import '../../../support/in_memory_backend.dart';
import '../family_test_helpers.dart';

const _me = AppUser(uid: 'me', email: 'me@example.com', emailVerified: true);

String _path(WidgetTester tester) => ProviderScope.containerOf(
      tester.element(find.byType(FamilyHubApp)),
    ).read(routerProvider).routeInformationProvider.value.uri.path;

Future<void> _pumpApp(WidgetTester tester, Fixture f) async {
  tester.view
    ..physicalSize = const Size(400, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final auth = FakeAuthRepository(signedInAs: _me);
  addTearDown(auth.dispose);
  final InMemoryBackend b = f.backend;

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

Future<void> _type(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(Key(key)), text);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('new user: profile -> create family -> admin in the app',
      (tester) async {
    final f = Fixture();
    addTearDown(f.backend.dispose);
    await _pumpApp(tester, f);
    expect(_path(tester), '/profile-setup');

    // Save stays disabled until a name is typed.
    final save = find.byKey(const Key('profile_save'));
    await tester.ensureVisible(save);
    expect(tester.widget<FilledButton>(find.descendant(of: save, matching: find.byType(FilledButton))).onPressed, isNull);

    await _type(tester, 'profile_full_name', 'Karim Rahman');
    await _tap(tester, 'rel_father');
    await _tap(tester, 'profile_save');
    expect(f.backend.profiles['me']!.fullName, 'Karim Rahman');
    expect(f.backend.profiles['me']!.relationship.name, 'father');
    expect(_path(tester), '/family-choice');

    await _tap(tester, 'choice_create');
    expect(_path(tester), '/family-choice/create');
    await _type(tester, 'family_name', 'Rahman family');
    await _tap(tester, 'family_create_submit');

    expect(_path(tester), '/home');
    final family = f.backend.families.values.single;
    expect(family.name, 'Rahman family');
    expect(f.backend.members[family.id]!['me']!.role, MemberRole.admin);

    // The creator is admin, so the manager entries are on the Family tab.
    await tester.tap(find.byKey(const Key('tab_family')));
    await tester.pumpAndSettle();
    for (final key in [
      'family_members',
      'family_invitations',
      'family_roles',
      'family_settings',
    ]) {
      await tester.ensureVisible(find.byKey(Key(key)));
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
  });

  testWidgets('invited user: join with a code -> pending -> approved -> home',
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
    expect(_path(tester), '/family-choice');

    await _tap(tester, 'choice_join');
    expect(_path(tester), '/family-choice/join');

    // A wrong code shows a message and stays on the screen.
    await _type(tester, 'join_code', 'ZZZZ9999');
    await _tap(tester, 'join_submit');
    expect(_path(tester), '/family-choice/join');
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

    // The right code (typed in lower case) leaves the person pending.
    await _type(tester, 'join_code', 'abcd-2345');
    await _tap(tester, 'join_submit');
    expect(_path(tester), '/pending');
    expect(f.backend.members['fam']!['me']!.status, MembershipStatus.pending);
    expect(f.backend.invitations['ABCD2345']!.status, InvitationStatus.used);

    // The admin approves; the pending screen moves on by itself.
    final approve = ApproveMember(f.runner);
    await approve(actorUid: 'admin', familyId: 'fam', targetUid: 'me');
    await tester.pumpAndSettle();
    expect(_path(tester), '/home');
  });

  testWidgets('a rejected request returns to the family choice', (tester) async {
    final f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'me': (MemberRole.member, MembershipStatus.pending),
      })
      ..profile('me');
    addTearDown(f.backend.dispose);
    await _pumpApp(tester, f);
    expect(_path(tester), '/pending');

    f.backend.members['fam']!['me'] =
        f.backend.members['fam']!['me']!.copyWith(removedAt: f.clock.nowUtc());
    f.backend.backendNotify();
    await tester.pumpAndSettle();
    expect(_path(tester), '/family-choice');
  });
}
