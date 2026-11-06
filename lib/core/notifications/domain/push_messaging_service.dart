import 'package:family_hub/core/notifications/domain/notification_tap_router.dart';
import 'package:family_hub/core/notifications/domain/push_message.dart';

abstract interface class PushMessagingService {
  Future<void> initialize(NotificationTapRouter tapRouter);

  Future<bool> notificationsGranted();

  Future<bool> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<PushMessage> get onForegroundMessage;

  Future<void> deleteToken();
}
