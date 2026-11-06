import 'package:family_hub/core/notifications/domain/device_token.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _deviceIdKey = 'push_device_installation_id';
const String _deviceCreatedAtKey = 'push_device_installation_created_at';

final class SharedPreferencesDeviceInstallationStore
    implements DeviceInstallationStore {
  const SharedPreferencesDeviceInstallationStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<DeviceInstallation?> read() async {
    final id = _preferences.getString(_deviceIdKey);
    if (id == null) return null;
    if (id.isEmpty) {
      throw const FormatException('The saved device installation id is empty.');
    }

    final createdAtValue = _preferences.getString(_deviceCreatedAtKey);
    if (createdAtValue == null) {
      throw const FormatException(
        'The saved device installation timestamp is missing.',
      );
    }
    final createdAt = DateTime.tryParse(createdAtValue);
    if (createdAt == null) {
      throw const FormatException(
        'The saved device installation timestamp is invalid.',
      );
    }
    return DeviceInstallation(id: id, createdAt: createdAt.toUtc());
  }

  @override
  Future<DeviceInstallation> getOrCreate({
    required String Function() newId,
    required DateTime nowUtc,
  }) async {
    final existingId = _preferences.getString(_deviceIdKey);
    final existingCreatedAt = _preferences.getString(_deviceCreatedAtKey);
    if (existingId != null && existingCreatedAt != null) {
      final parsed = DateTime.tryParse(existingCreatedAt);
      if (existingId.isEmpty || parsed == null) {
        throw const FormatException(
          'The saved device installation metadata is invalid.',
        );
      }
      return DeviceInstallation(id: existingId, createdAt: parsed.toUtc());
    }

    final id = existingId ?? newId();
    if (id.isEmpty || id.length > 64) {
      throw StateError('The generated device installation id is invalid.');
    }
    final createdAt = existingCreatedAt == null
        ? nowUtc.toUtc()
        : DateTime.tryParse(existingCreatedAt)?.toUtc();
    if (createdAt == null) {
      throw const FormatException(
        'The saved device installation timestamp is invalid.',
      );
    }

    final savedId = await _preferences.setString(_deviceIdKey, id);
    if (!savedId) {
      throw StateError('Failed to save the device installation id.');
    }
    final savedCreatedAt = await _preferences.setString(
      _deviceCreatedAtKey,
      createdAt.toIso8601String(),
    );
    if (!savedCreatedAt) {
      throw StateError('Failed to save the device installation timestamp.');
    }
    return DeviceInstallation(id: id, createdAt: createdAt);
  }
}
