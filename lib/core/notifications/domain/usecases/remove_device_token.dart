import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/notifications/domain/device_token.dart';

final class RemoveDeviceToken {
  const RemoveDeviceToken(this._repository);

  final DeviceTokenRepository _repository;

  Future<Result<void>> call({required String uid, required String deviceId}) {
    if (uid.isEmpty || deviceId.isEmpty || deviceId.length > 64) {
      return Future<Result<void>>.value(
        const Failure<void>(Validation('deviceId', 'invalid')),
      );
    }
    return _repository.remove(uid: uid, deviceId: deviceId);
  }
}
