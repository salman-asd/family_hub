import 'package:family_hub/core/notifications/data/device_installation_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('keeps one installation id and creation time across launches', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesDeviceInstallationStore(preferences);
    final createdAt = DateTime.utc(2026, 11, 6);

    final first = await store.getOrCreate(
      newId: () => 'install-one',
      nowUtc: createdAt,
    );
    final second = await store.getOrCreate(
      newId: () => 'install-two',
      nowUtc: createdAt.add(const Duration(days: 1)),
    );

    expect(second, first);
    expect(await store.read(), first);
  });

  test('reports corrupt saved installation metadata', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'push_device_installation_id': 'install-one',
      'push_device_installation_created_at': 'not-a-date',
    });
    final store = SharedPreferencesDeviceInstallationStore(
      await SharedPreferences.getInstance(),
    );

    await expectLater(store.read(), throwsFormatException);
  });
}
