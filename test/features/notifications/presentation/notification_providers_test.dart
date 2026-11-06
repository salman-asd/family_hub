import 'package:family_hub/core/notifications/domain/delivery_policy.dart';
import 'package:family_hub/core/notifications/domain/notification_type.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/notifications/domain/member_notification_prefs.dart';
import 'package:family_hub/features/notifications/presentation/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Spark mode resolves every notification type to backendUnavailable', () {
    final container = ProviderContainer(
      overrides: [
        currentFamilyIdProvider.overrideWithValue(null),
        currentUidProvider.overrideWithValue(null),
        memberNotificationPrefsStoreProvider.overrideWithValue(_Store()),
        pushCapabilityProvider.overrideWithValue(
          const DeliveryCapability(
            tokenRegistered: false,
            osPermissionGranted: false,
            memberPushEnabled: false,
            backendAvailable: false,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    for (final type in NotificationTypes.all) {
      expect(
        container.read(effectiveModeProvider(type.id)).value,
        const EffectiveDelivery(
          mode: DeliveryMode.normal,
          reason: DeliveryReason.backendUnavailable,
        ),
        reason: type.id,
      );
    }
  });
}

final class _Store implements MemberNotificationPrefsStore {
  @override
  MemberNotificationPrefs load(String uid) => MemberNotificationPrefs.defaults;

  @override
  Future<Result<void>> save(String uid, MemberNotificationPrefs prefs) =>
      throw UnimplementedError();
}
