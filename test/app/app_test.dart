import 'package:family_hub/app/app.dart';
import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/dashboard/presentation/home_screen.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/presentation/membership_providers.dart';
import 'package:family_hub/features/onboarding/presentation/profile_providers.dart';
import 'package:family_hub/modules/module_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/app_test_side_effect_overrides.dart';
import '../support/fake_auth_repository.dart';
import '../support/fake_session_repositories.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final flavor in Flavor.values) {
    testWidgets('Home uses the ${flavor.name} flavor', (tester) async {
      const user = AppUser(uid: 'u1', email: 'a@b.com', emailVerified: true);
      final prefs = await SharedPreferences.getInstance();
      final auth = FakeAuthRepository(signedInAs: user);
      final session = FakeSessionRepositories(
        profiles: {user.uid},
        memberships: {
          user.uid: const Membership(
            status: MembershipStatus.active,
            familyId: 'f',
          ),
        },
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
          child: appTestSideEffectScope(child: const FamilyHubApp()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
        flavor.label,
      );
      expect(
        find.byKey(const Key('flavor_name')),
        flavor == Flavor.dev ? findsOneWidget : findsNothing,
      );
    });
  }

  test('dev label differs from prod label', () {
    expect(Flavor.dev.label, 'Family Hub (dev)');
    expect(Flavor.prod.label, 'Family Hub');
  });
}
