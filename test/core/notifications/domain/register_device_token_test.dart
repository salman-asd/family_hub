import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/notifications/domain/device_token.dart';
import 'package:family_hub/core/notifications/domain/usecases/register_device_token.dart';
import 'package:flutter_test/flutter_test.dart';

final class _RecordingDeviceTokenRepository implements DeviceTokenRepository {
  String? uid;
  String? deviceId;
  DeviceTokenRegistration? registration;

  @override
  Future<Result<void>> register({
    required String uid,
    required String deviceId,
    required DeviceTokenRegistration registration,
  }) async {
    this.uid = uid;
    this.deviceId = deviceId;
    this.registration = registration;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> remove({
    required String uid,
    required String deviceId,
  }) async => const Success<void>(null);
}

void main() {
  final at = DateTime.utc(2026, 11, 6);

  test(
    'registers a validated installation token with UTC timestamps',
    () async {
      final repository = _RecordingDeviceTokenRepository();
      final register = RegisterDeviceToken(repository);

      final result = await register(
        uid: 'member-1',
        deviceId: 'install-1',
        token: 'registration-token',
        languageCode: 'bn',
        appVersion: '0.1.0',
        flavor: 'dev',
        createdAt: at,
        lastSeenAt: at.add(const Duration(hours: 1)),
      );

      expect(result.isSuccess, isTrue);
      expect(repository.uid, 'member-1');
      expect(repository.deviceId, 'install-1');
      expect(repository.registration?.languageCode, 'bn');
      expect(repository.registration?.createdAt.isUtc, isTrue);
      expect(repository.registration?.lastSeenAt.isUtc, isTrue);
    },
  );

  test('rejects invalid fields without writing', () async {
    final repository = _RecordingDeviceTokenRepository();
    final register = RegisterDeviceToken(repository);

    final result = await register(
      uid: 'member-1',
      deviceId: 'install-1',
      token: 'registration-token',
      languageCode: 'fr',
      appVersion: '0.1.0',
      flavor: 'dev',
      createdAt: at,
      lastSeenAt: at,
    );

    expect(result.isFailure, isTrue);
    expect(repository.registration, isNull);
  });
}
