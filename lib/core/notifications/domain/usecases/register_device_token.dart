import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/notifications/domain/device_token.dart';

final class RegisterDeviceToken {
  const RegisterDeviceToken(this._repository);

  final DeviceTokenRepository _repository;

  Future<Result<void>> call({
    required String uid,
    required String deviceId,
    required String token,
    required String languageCode,
    required String appVersion,
    required String flavor,
    required DateTime createdAt,
    required DateTime lastSeenAt,
  }) {
    if (uid.isEmpty ||
        deviceId.isEmpty ||
        deviceId.length > 64 ||
        token.isEmpty ||
        token.length > 4096 ||
        !const <String>{'bn', 'en'}.contains(languageCode) ||
        appVersion.isEmpty ||
        appVersion.length > 32 ||
        !const <String>{'dev', 'prod'}.contains(flavor)) {
      return Future<Result<void>>.value(
        const Failure<void>(Validation('deviceToken', 'invalid')),
      );
    }

    return _repository.register(
      uid: uid,
      deviceId: deviceId,
      registration: DeviceTokenRegistration(
        token: token,
        languageCode: languageCode,
        appVersion: appVersion,
        flavor: flavor,
        createdAt: createdAt.toUtc(),
        lastSeenAt: lastSeenAt.toUtc(),
      ),
    );
  }
}
