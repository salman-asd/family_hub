import 'dart:async';

import 'package:family_hub/core/notifications/domain/notification_tap_router.dart';
import 'package:family_hub/core/notifications/domain/push_message.dart';
import 'package:family_hub/core/notifications/domain/push_messaging_service.dart';

final class FakePushService implements PushMessagingService {
  final StreamController<String> tokenRefreshes =
      StreamController<String>.broadcast();
  final StreamController<PushMessage> foregroundMessages =
      StreamController<PushMessage>.broadcast();

  String? token = 'token-123456789';
  bool notificationsAllowed = true;
  bool permissionRequestResult = true;
  int getTokenCalls = 0;
  int permissionRequests = 0;
  int tokenDeletes = 0;
  NotificationTapRouter? tapRouter;

  @override
  Future<void> initialize(NotificationTapRouter router) async {
    tapRouter = router;
  }

  @override
  Future<bool> notificationsGranted() async => notificationsAllowed;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    notificationsAllowed = permissionRequestResult;
    return notificationsAllowed;
  }

  @override
  Future<String?> getToken() async {
    getTokenCalls++;
    return token;
  }

  @override
  Stream<String> get onTokenRefresh => tokenRefreshes.stream;

  @override
  Stream<PushMessage> get onForegroundMessage => foregroundMessages.stream;

  @override
  Future<void> deleteToken() async {
    tokenDeletes++;
    token = null;
  }

  Future<void> close() async {
    await tokenRefreshes.close();
    await foregroundMessages.close();
  }
}
