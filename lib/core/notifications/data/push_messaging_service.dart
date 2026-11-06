import 'dart:async';
import 'dart:developer' as developer;

import 'package:family_hub/core/notifications/domain/notification_tap_router.dart';
import 'package:family_hub/core/notifications/domain/push_message.dart';
import 'package:family_hub/core/notifications/domain/push_messaging_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> familyHubFirebaseMessagingBackgroundHandler(
  RemoteMessage _,
) async {}

abstract interface class FirebaseMessagingDriver {
  Future<void> registerBackgroundHandler();

  Future<bool> notificationsGranted();

  Future<bool> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<PushMessage> get onForegroundMessage;

  Stream<PushMessage> get onOpenedApp;

  Future<PushMessage?> getInitialMessage();

  Future<void> deleteToken();
}

final class FirebasePushMessagingService implements PushMessagingService {
  FirebasePushMessagingService({FirebaseMessagingDriver? driver})
    : _driver = driver ?? FirebaseMessagingDriverImpl();

  final FirebaseMessagingDriver _driver;
  StreamSubscription<PushMessage>? _openedAppSubscription;
  bool _initialized = false;

  @override
  Future<void> initialize(NotificationTapRouter tapRouter) async {
    if (_initialized) return;
    await _driver.registerBackgroundHandler();
    _openedAppSubscription = _driver.onOpenedApp.listen(
      (message) => tapRouter.routePush(message.route),
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'Push-open stream failed (${error.runtimeType}).',
          name: 'family_hub.notifications',
          stackTrace: stackTrace,
          level: 1000,
        );
      },
    );
    final initialMessage = await _driver.getInitialMessage();
    if (initialMessage != null) tapRouter.routePush(initialMessage.route);
    _initialized = true;
  }

  @override
  Future<bool> notificationsGranted() => _driver.notificationsGranted();

  @override
  Future<bool> requestPermission() => _driver.requestPermission();

  @override
  Future<String?> getToken() => _driver.getToken();

  @override
  Stream<String> get onTokenRefresh => _driver.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage => _driver.onForegroundMessage;

  @override
  Future<void> deleteToken() => _driver.deleteToken();

  Future<void> dispose() async {
    await _openedAppSubscription?.cancel();
  }
}

final class FirebaseMessagingDriverImpl implements FirebaseMessagingDriver {
  FirebaseMessagingDriverImpl({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<void> registerBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(
      familyHubFirebaseMessagingBackgroundHandler,
    );
  }

  // P4-15 sends to FCM registration tokens; the newer FID registration API is
  // not interchangeable with those tokens.
  @override
  Future<bool> notificationsGranted() async {
    final settings = await _messaging.getNotificationSettings();
    return _granted(settings.authorizationStatus);
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return _granted(settings.authorizationStatus);
  }

  @override
  // ignore: deprecated_member_use
  Future<String?> getToken() => _messaging.getToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(_fromRemoteMessage);

  @override
  Stream<PushMessage> get onOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(_fromRemoteMessage);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _fromRemoteMessage(message);
  }

  @override
  // ignore: deprecated_member_use
  Future<void> deleteToken() => _messaging.deleteToken();

  static bool _granted(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  static PushMessage _fromRemoteMessage(RemoteMessage message) => PushMessage(
    title: message.notification?.title,
    body: message.notification?.body,
    data: <String, String>{
      for (final entry in message.data.entries)
        if (entry.value is String) entry.key: entry.value as String,
    },
  );
}
