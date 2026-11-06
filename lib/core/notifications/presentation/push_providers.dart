import 'dart:async';

import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/core/notifications/domain/device_token.dart';
import 'package:family_hub/core/notifications/domain/push_diagnostics.dart';
import 'package:family_hub/core/notifications/domain/push_message.dart';
import 'package:family_hub/core/notifications/domain/push_messaging_service.dart';
import 'package:family_hub/core/notifications/domain/usecases/register_device_token.dart';
import 'package:family_hub/core/notifications/domain/usecases/remove_device_token.dart';
import 'package:family_hub/core/notifications/presentation/push_controller.dart';
import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String kDefaultAppVersion = '0.1.0';
const String kBuildAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: kDefaultAppVersion,
);

final pushMessagingServiceProvider = Provider<PushMessagingService>(
  (ref) => throw UnimplementedError(
    'pushMessagingServiceProvider must be overridden in bootstrap.dart.',
  ),
);

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>(
  (ref) => throw UnimplementedError(
    'deviceTokenRepositoryProvider must be overridden in bootstrap.dart.',
  ),
);

final deviceInstallationStoreProvider = Provider<DeviceInstallationStore>(
  (ref) => throw UnimplementedError(
    'deviceInstallationStoreProvider must be overridden in bootstrap.dart.',
  ),
);

final registerDeviceTokenProvider = Provider<RegisterDeviceToken>(
  (ref) => RegisterDeviceToken(ref.watch(deviceTokenRepositoryProvider)),
);

final removeDeviceTokenProvider = Provider<RemoveDeviceToken>(
  (ref) => RemoveDeviceToken(ref.watch(deviceTokenRepositoryProvider)),
);

final pushControllerProvider = Provider<PushController>((ref) {
  final controller = PushController(
    messaging: ref.watch(pushMessagingServiceProvider),
    registerDeviceToken: ref.watch(registerDeviceTokenProvider),
    removeDeviceToken: ref.watch(removeDeviceTokenProvider),
    installationStore: ref.watch(deviceInstallationStoreProvider),
    newId: randomId,
    clock: ref.watch(clockProvider),
    flavor: ref.watch(flavorProvider),
    appVersion: kBuildAppVersion,
  );
  ref.onDispose(() => unawaited(controller.dispose()));
  return controller;
});

final pushDiagnosticsProvider = StreamProvider<PushDiagnostics>(
  (ref) => ref.watch(pushControllerProvider).diagnosticsStream,
);

final pushForegroundMessagesProvider = StreamProvider.autoDispose<PushMessage>(
  (ref) => ref.watch(pushMessagingServiceProvider).onForegroundMessage,
);

final pushRequestPermissionProvider = Provider<Future<bool> Function()>(
  (ref) => ref.watch(pushControllerProvider).requestPermission,
);
