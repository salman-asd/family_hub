import 'package:family_hub/app/app.dart';
import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/notifications/domain/device_token.dart';
import 'package:family_hub/core/notifications/presentation/push_providers.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/presentation/membership_providers.dart';
import 'package:family_hub/features/onboarding/presentation/profile_providers.dart';
import 'package:family_hub/modules/module_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_push_service.dart';
import '../support/fake_session_repositories.dart';

final class _FakeDeviceTokenRepository implements DeviceTokenRepository {
  @override
  Future<Result<void>> register({
    required String uid,
    required String deviceId,
    required DeviceTokenRegistration registration,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> remove({
    required String uid,
    required String deviceId,
  }) async => const Success<void>(null);
}

final class _FakeDeviceInstallationStore implements DeviceInstallationStore {
  DeviceInstallation? installation;

  @override
  Future<DeviceInstallation?> read() async => installation;

  @override
  Future<DeviceInstallation> getOrCreate({
    required String Function() newId,
    required DateTime nowUtc,
  }) async =>
      installation ??= DeviceInstallation(id: newId(), createdAt: nowUtc);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final flavor in Flavor.values) {
    testWidgets('an active member sees the ${flavor.name} flavor on Home', (
      tester,
    ) async {
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
      final pushService = FakePushService();
      addTearDown(auth.dispose);
      addTearDown(session.dispose);
      addTearDown(pushService.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            flavorProvider.overrideWithValue(flavor),
            sharedPreferencesProvider.overrideWithValue(prefs),
            authRepositoryProvider.overrideWithValue(auth),
            pushMessagingServiceProvider.overrideWithValue(pushService),
            deviceInstallationStoreProvider.overrideWithValue(
              _FakeDeviceInstallationStore(),
            ),
            deviceTokenRepositoryProvider.overrideWithValue(
              _FakeDeviceTokenRepository(),
            ),
            profileRepositoryProvider.overrideWithValue(session),
            membershipRepositoryProvider.overrideWithValue(session),
            moduleFlagsRepositoryProvider.overrideWithValue(session),
          ],
          child: const FamilyHubApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(flavor.name), findsOneWidget);
      // The app bar title is the localized app name (Bangla by default).
      final l10n = await AppLocalizations.delegate.load(const Locale('bn'));
      expect(find.text(l10n.appName), findsOneWidget);
    });
  }

  test('dev label differs from prod label', () {
    expect(Flavor.dev.label, 'Family Hub (dev)');
    expect(Flavor.prod.label, 'Family Hub');
  });
}
