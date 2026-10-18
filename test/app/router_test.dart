import 'package:family_hub/app/app.dart';
import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/router.dart';
import 'package:family_hub/app/shell/app_shell.dart';
import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/presentation/membership_providers.dart';
import 'package:family_hub/features/onboarding/presentation/profile_providers.dart';
import 'package:family_hub/modules/module_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_session_repositories.dart';

const _verified = AppUser(uid: 'u1', email: 'a@b.com', emailVerified: true);
const _unverified = AppUser(uid: 'u1', email: 'a@b.com', emailVerified: false);

class _Harness {
  _Harness(this.auth, this.session);

  final FakeAuthRepository auth;
  final FakeSessionRepositories session;

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(FamilyHubApp)));

  GoRouter router(WidgetTester tester) =>
      container(tester).read(routerProvider);

  /// The path the router currently shows.
  String path(WidgetTester tester) =>
      router(tester).routeInformationProvider.value.uri.path;
}

Future<_Harness> _pumpApp(
  WidgetTester tester, {
  AppUser? user,
  bool hasProfile = false,
  MembershipStatus membership = MembershipStatus.none,
  Flavor flavor = Flavor.dev,
  Size size = const Size(400, 800),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final auth = FakeAuthRepository(signedInAs: user);
  final session = FakeSessionRepositories(
    profiles: hasProfile && user != null ? {user.uid} : const {},
    memberships: user != null && membership != MembershipStatus.none
        ? {user.uid: Membership(status: membership, familyId: 'fam-1')}
        : const {},
  );
  addTearDown(auth.dispose);
  addTearDown(session.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        flavorProvider.overrideWithValue(flavor),
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(session),
        membershipRepositoryProvider.overrideWithValue(session),
        moduleFlagsRepositoryProvider.overrideWithValue(session),
      ],
      child: const FamilyHubApp(),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(auth, session);
}

Finder _tab(String id) => find.byKey(Key('tab_$id'));

Future<void> _openTab(WidgetTester tester, String id) async {
  await tester.tap(_tab(id));
  await tester.pumpAndSettle();
}

void main() {
  group('guards follow the session', () {
    testWidgets('signed out -> /welcome', (tester) async {
      final h = await _pumpApp(tester);
      expect(h.path(tester), '/welcome');
    });

    testWidgets('signed in but unverified -> /verify-email', (tester) async {
      final h = await _pumpApp(tester, user: _unverified);
      expect(h.path(tester), '/verify-email');
    });

    testWidgets('verified, no profile -> /profile-setup', (tester) async {
      final h = await _pumpApp(tester, user: _verified);
      expect(h.path(tester), '/profile-setup');
    });

    testWidgets('profile, no family -> /family-choice', (tester) async {
      final h = await _pumpApp(tester, user: _verified, hasProfile: true);
      expect(h.path(tester), '/family-choice');
    });

    testWidgets('pending member -> /pending', (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.pending,
      );
      expect(h.path(tester), '/pending');
    });

    testWidgets('disabled member -> /disabled', (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.disabled,
      );
      expect(h.path(tester), '/disabled');
    });

    testWidgets('active member -> /home with the tab bar', (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
      );
      expect(h.path(tester), '/home');
      expect(find.byType(AppShell), findsOneWidget);
      for (final id in ['home', 'chores', 'bazar', 'family']) {
        expect(_tab(id), findsOneWidget, reason: id);
      }
    });
  });

  group('the router reacts to changes without screen-level navigation', () {
    testWidgets('onboarding walks through to the shell', (tester) async {
      final h = await _pumpApp(tester, user: _verified);
      expect(h.path(tester), '/profile-setup');

      h.session.addProfile('u1');
      await tester.pumpAndSettle();
      expect(h.path(tester), '/family-choice');

      h.session.setMembership('u1', MembershipStatus.pending);
      await tester.pumpAndSettle();
      expect(h.path(tester), '/pending');

      h.session.setMembership('u1', MembershipStatus.active);
      await tester.pumpAndSettle();
      expect(h.path(tester), '/home');
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('being disabled while using the app leaves the shell',
        (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
      );
      h.session.setMembership('u1', MembershipStatus.disabled);
      await tester.pumpAndSettle();
      expect(h.path(tester), '/disabled');
      expect(find.byType(AppShell), findsNothing);
    });

    testWidgets('signing in moves from /welcome onwards', (tester) async {
      final h = await _pumpApp(tester);
      expect(h.path(tester), '/welcome');

      await h.auth.signIn(email: 'a@b.com', password: 'password1');
      await tester.pumpAndSettle();
      // Verified by the fake, but no profile yet.
      expect(h.path(tester), '/profile-setup');
    });

    testWidgets('signing out from the Family tab returns to /welcome',
        (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
      );
      await _openTab(tester, 'family');
      await tester.tap(find.byKey(const Key('family_sign_out')));
      await tester.pumpAndSettle();
      expect(h.path(tester), '/welcome');
    });
  });

  group('deep links respect the guards', () {
    testWidgets('signed out: /bazar -> /welcome', (tester) async {
      final h = await _pumpApp(tester);
      h.router(tester).go('/bazar');
      await tester.pumpAndSettle();
      expect(h.path(tester), '/welcome');
    });

    testWidgets('pending: /chores -> /pending', (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.pending,
      );
      h.router(tester).go('/chores');
      await tester.pumpAndSettle();
      expect(h.path(tester), '/pending');
    });

    testWidgets('active: a gate screen link bounces to /home', (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
      );
      h.router(tester).go('/pending');
      await tester.pumpAndSettle();
      expect(h.path(tester), '/home');
    });

    testWidgets('active: /bazar opens the Bazar tab', (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
      );
      h.router(tester).go('/bazar');
      await tester.pumpAndSettle();
      expect(h.path(tester), '/bazar');
    });

    testWidgets('an unknown path shows the not-found screen', (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
      );
      h.router(tester).go('/definitely-not-a-route');
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsNothing);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });

  group('tabs', () {
    testWidgets('tapping a tab switches the branch', (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
      );
      await _openTab(tester, 'chores');
      expect(h.path(tester), '/chores');
      await _openTab(tester, 'bazar');
      expect(h.path(tester), '/bazar');
      await _openTab(tester, 'family');
      expect(h.path(tester), '/family');
      await _openTab(tester, 'home');
      expect(h.path(tester), '/home');
    });

    testWidgets('a tab keeps its scroll position while another is open',
        (tester) async {
      await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
        // Short screen so the Family list has to scroll.
        size: const Size(400, 320),
      );
      await _openTab(tester, 'family');

      final scrollable = find.descendant(
        of: find.byKey(const PageStorageKey<String>('family_tab_list')),
        matching: find.byType(Scrollable),
      );
      await tester.drag(scrollable, const Offset(0, -150));
      await tester.pumpAndSettle();
      final before = tester.state<ScrollableState>(scrollable).position.pixels;
      expect(before, greaterThan(0));

      await _openTab(tester, 'home');
      await _openTab(tester, 'family');

      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        before,
      );
    });

    testWidgets('a branch keeps its own navigation stack', (tester) async {
      // Built from AppShell directly so a branch can hold a nested route.
      final router = GoRouter(
        initialLocation: '/a/detail',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => AppShell(
              navigationShell: shell,
              destinations: [
                ShellDestination(
                  id: 'a',
                  icon: Icons.looks_one,
                  label: (_) => 'A',
                ),
                ShellDestination(
                  id: 'b',
                  icon: Icons.looks_two,
                  label: (_) => 'B',
                ),
              ],
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/a',
                    builder: (_, __) => const Text('A root'),
                    routes: [
                      GoRoute(
                        path: 'detail',
                        builder: (_, __) => const Text('A detail'),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/b',
                    builder: (_, __) => const Text('B root'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: buildThemeData(appThemes.first),
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A detail'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tab_b')));
      await tester.pumpAndSettle();
      expect(find.text('B root'), findsOneWidget);

      await tester.tap(find.byKey(const Key('tab_a')));
      await tester.pumpAndSettle();
      expect(find.text('A detail'), findsOneWidget);
      expect(find.text('A root'), findsNothing);
    });
  });

  group('module flags', () {
    testWidgets('a disabled module loses its tab and its route',
        (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
      );
      expect(_tab('chores'), findsOneWidget);

      h.session.setModuleEnabled('chores', enabled: false);
      await tester.pumpAndSettle();

      expect(_tab('chores'), findsNothing);
      expect(_tab('bazar'), findsOneWidget);
      expect(_tab('home'), findsOneWidget);
      expect(_tab('family'), findsOneWidget);

      h.router(tester).go('/chores');
      await tester.pumpAndSettle();
      expect(h.path(tester), '/home');
    });

    testWidgets('switching the module back on restores the tab',
        (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
      );
      h.session.setModuleEnabled('bazar', enabled: false);
      await tester.pumpAndSettle();
      expect(_tab('bazar'), findsNothing);

      h.session.setModuleEnabled('bazar', enabled: true);
      await tester.pumpAndSettle();
      expect(_tab('bazar'), findsOneWidget);
    });

    testWidgets('all modules off still leaves Home and Family', (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
      );
      h.session
        ..setModuleEnabled('chores', enabled: false)
        ..setModuleEnabled('bazar', enabled: false);
      await tester.pumpAndSettle();
      expect(_tab('home'), findsOneWidget);
      expect(_tab('family'), findsOneWidget);
      expect(_tab('chores'), findsNothing);
      expect(_tab('bazar'), findsNothing);
    });
  });

  group('settings are reachable from the Family tab', () {
    testWidgets('Theme and Language open and come back', (tester) async {
      final h = await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
      );
      await _openTab(tester, 'family');

      await tester.tap(find.byKey(const Key('family_settings_theme')));
      await tester.pumpAndSettle();
      expect(h.path(tester), '/settings/theme');

      h.router(tester).pop();
      await tester.pumpAndSettle();
      expect(h.path(tester), '/family');

      await tester.tap(find.byKey(const Key('family_settings_language')));
      await tester.pumpAndSettle();
      expect(h.path(tester), '/settings/language');
    });

    testWidgets('the developer tokens entry exists only in the dev flavor',
        (tester) async {
      await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
      );
      await _openTab(tester, 'family');
      expect(find.byKey(const Key('family_dev_tokens')), findsOneWidget);
      expect(find.byKey(const Key('family_dev_gallery')), findsOneWidget);
    });

    testWidgets('prod flavor hides the developer tokens entry', (tester) async {
      await _pumpApp(
        tester,
        user: _verified,
        hasProfile: true,
        membership: MembershipStatus.active,
        flavor: Flavor.prod,
      );
      await _openTab(tester, 'family');
      expect(find.byKey(const Key('family_dev_tokens')), findsNothing);
      expect(find.byKey(const Key('family_dev_gallery')), findsNothing);
    });
  });
}
