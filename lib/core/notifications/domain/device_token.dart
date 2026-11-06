import 'package:family_hub/core/errors/result.dart';

final class DeviceTokenRegistration {
  const DeviceTokenRegistration({
    required this.token,
    required this.languageCode,
    required this.appVersion,
    required this.flavor,
    required this.createdAt,
    required this.lastSeenAt,
  });

  final String token;
  final String languageCode;
  final String appVersion;
  final String flavor;
  final DateTime createdAt;
  final DateTime lastSeenAt;

  @override
  bool operator ==(Object other) =>
      other is DeviceTokenRegistration &&
      other.token == token &&
      other.languageCode == languageCode &&
      other.appVersion == appVersion &&
      other.flavor == flavor &&
      other.createdAt == createdAt &&
      other.lastSeenAt == lastSeenAt;

  @override
  int get hashCode => Object.hash(
    token,
    languageCode,
    appVersion,
    flavor,
    createdAt,
    lastSeenAt,
  );
}

abstract interface class DeviceTokenRepository {
  Future<Result<void>> register({
    required String uid,
    required String deviceId,
    required DeviceTokenRegistration registration,
  });

  Future<Result<void>> remove({required String uid, required String deviceId});
}

final class DeviceInstallation {
  const DeviceInstallation({required this.id, required this.createdAt});

  final String id;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is DeviceInstallation &&
      other.id == id &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, createdAt);
}

abstract interface class DeviceInstallationStore {
  Future<DeviceInstallation?> read();

  Future<DeviceInstallation> getOrCreate({
    required String Function() newId,
    required DateTime nowUtc,
  });
}
