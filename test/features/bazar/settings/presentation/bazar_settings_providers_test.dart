import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';
import 'package:family_hub/features/bazar/settings/presentation/bazar_settings_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../bazar_settings_test_helpers.dart';

void main() {
  test('defaults are available before a family is selected', () {
    final container = ProviderContainer(
      overrides: [
        currentFamilyIdProvider.overrideWithValue(null),
        bazarSettingsRepositoryProvider.overrideWithValue(
          FakeBazarSettingsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(bazarSettingsProvider), BazarSettings.defaults);
  });

  test('an absent/delayed document keeps the defaults, then updates', () async {
    final stored = BazarSettings.defaults.copyWith(weekStartDay: 1);
    final repo = FakeBazarSettingsRepository(stored);
    final container = ProviderContainer(
      overrides: [
        currentFamilyIdProvider.overrideWithValue('f1'),
        bazarSettingsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(bazarSettingsProvider, (_, _) {});
    addTearDown(subscription.close);

    expect(container.read(bazarSettingsProvider), BazarSettings.defaults);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(bazarSettingsProvider), stored);
  });
}
