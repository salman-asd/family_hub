import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/notifications/domain/member_notification_prefs.dart';
import 'package:family_hub/features/notifications/domain/notification_defaults.dart';
import 'package:family_hub/features/notifications/domain/notification_delivery_settings.dart';
import 'package:family_hub/features/notifications/presentation/notification_providers.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// The in-memory half of the notification stack that screen tests need.
///
/// `bootstrap.dart` wires the Firestore implementations; a widget test that
/// reaches one of them (the reminder "why" line on the occurrence detail
/// screen reads all three) otherwise builds on the unimplemented providers and
/// throws. These fakes keep the real resolution rules and replace only storage.
class InMemoryMemberNotificationPrefsStore
    implements MemberNotificationPrefsStore {
  final Map<String, MemberNotificationPrefs> _byUid =
      <String, MemberNotificationPrefs>{};

  @override
  MemberNotificationPrefs load(String uid) =>
      _byUid[uid] ?? MemberNotificationPrefs.defaults;

  @override
  Future<Result<void>> save(String uid, MemberNotificationPrefs prefs) async {
    _byUid[uid] = prefs;
    return const Success<void>(null);
  }
}

class InMemoryNotificationDefaultsRepository
    implements NotificationDefaultsRepository {
  NotificationDefaults defaults = NotificationDefaults.defaults;
  NotificationDefaults? saved;

  @override
  Stream<NotificationDefaults> watch(String familyId) =>
      Stream<NotificationDefaults>.value(defaults);

  @override
  Future<Result<void>> save(
    String familyId,
    NotificationDefaults settings,
    AuditEvent event,
  ) async {
    saved = settings;
    return const Success<void>(null);
  }
}

class InMemoryNotificationDeliveryRepository
    implements NotificationDeliveryRepository {
  NotificationDeliverySettings settings =
      NotificationDeliverySettings.defaults();
  NotificationDeliverySettings? saved;

  @override
  Stream<NotificationDeliverySettings> watch(String familyId) =>
      Stream<NotificationDeliverySettings>.value(settings);

  @override
  Future<Result<void>> save(
    String familyId,
    NotificationDeliverySettings settings,
    AuditEvent event,
  ) async {
    saved = settings;
    return const Success<void>(null);
  }
}

/// Overrides for the three stores; pass them to any screen harness that shows a
/// reminder explanation. A test that needs to watch a write can build its own
/// fake and override the provider instead.
List<Override> notificationTestOverrides({
  MemberNotificationPrefsStore? prefsStore,
  NotificationDefaultsRepository? defaultsRepository,
  NotificationDeliveryRepository? deliveryRepository,
}) => [
  memberNotificationPrefsStoreProvider.overrideWithValue(
    prefsStore ?? InMemoryMemberNotificationPrefsStore(),
  ),
  notificationDefaultsRepositoryProvider.overrideWithValue(
    defaultsRepository ?? InMemoryNotificationDefaultsRepository(),
  ),
  notificationDeliveryRepositoryProvider.overrideWithValue(
    deliveryRepository ?? InMemoryNotificationDeliveryRepository(),
  ),
];
