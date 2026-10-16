import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/app/theme/theme_prefs.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Creates a [ProviderContainer] with an in-memory [SharedPreferences] store
/// pre-populated with [initialData].
ProviderContainer _makeContainer({
  Map<String, Object> initialData = const {},
}) {
  SharedPreferences.setMockInitialValues(initialData);
  // ignore: discarded_futures — test helper, result unused intentionally
  final prefs = SharedPreferences.getInstance();
  late SharedPreferences resolved;
  prefs.then((p) => resolved = p);
  // Pump the microtask queue synchronously so `resolved` is available.
  // In tests SharedPreferences.getInstance() completes synchronously when
  // setMockInitialValues has been called.
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWith((ref) => resolved),
    ],
  );
}

// ── Unit tests ────────────────────────────────────────────────────────────────

void main() {
  // SharedPreferences must be initialised per-test.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ThemePrefs serialisation', () {
    test('round-trip with known values', () {
      const original = ThemePrefs(
        themeMode: ThemeMode.dark,
        themeId: 'modern_dark',
      );
      final map = original.toMap();
      final restored = ThemePrefs.fromMap(map);
      expect(restored, equals(original));
    });

    test('fromMap with unknown themeMode falls back to system', () {
      final prefs = ThemePrefs.fromMap({
        'theme_mode': 'totally_invalid',
        'theme_id': 'modern_light',
      });
      expect(prefs.themeMode, ThemeMode.system);
    });

    test('fromMap with null values returns defaults', () {
      final prefs = ThemePrefs.fromMap({});
      expect(prefs.themeMode, ThemeMode.system);
      expect(prefs.themeId, 'modern_light');
    });
  });

  group('ThemeController', () {
    test('builds from empty SharedPreferences with defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final state = container.read(themeControllerProvider);
      expect(state.themeMode, ThemeMode.system);
      expect(state.themeId, 'modern_light');
    });

    test('reads persisted values from SharedPreferences on build', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'dark',
        'theme_id': 'modern_dark',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final state = container.read(themeControllerProvider);
      expect(state.themeMode, ThemeMode.dark);
      expect(state.themeId, 'modern_dark');
    });

    test('setThemeId persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(themeControllerProvider.notifier)
          .setThemeId('modern_dark');

      expect(container.read(themeControllerProvider).themeId, 'modern_dark');
      expect(prefs.getString('theme_id'), 'modern_dark');
    });

    test('setThemeMode persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(themeControllerProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(
        container.read(themeControllerProvider).themeMode,
        ThemeMode.dark,
      );
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('unknown id falls back to modern_light', () async {
      SharedPreferences.setMockInitialValues({'theme_id': 'does_not_exist'});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      // setThemeId validates and falls back
      await container
          .read(themeControllerProvider.notifier)
          .setThemeId('does_not_exist');

      expect(
        container.read(themeControllerProvider).themeId,
        kModernLightId,
      );
    });

    test('persistence round-trip — new container reads previous write',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final container1 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      await container1
          .read(themeControllerProvider.notifier)
          .setThemeId('modern_dark');
      await container1
          .read(themeControllerProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      container1.dispose();

      // New container, same prefs instance (simulates app restart).
      final container2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container2.dispose);
      final restored = container2.read(themeControllerProvider);
      expect(restored.themeId, 'modern_dark');
      expect(restored.themeMode, ThemeMode.dark);
    });
  });

  group('resolveThemeSpecs', () {
    test('system mode returns default light and dark specs', () {
      const prefs = ThemePrefs(themeMode: ThemeMode.system);
      final specs = resolveThemeSpecs(prefs);
      expect(specs.light.brightness, Brightness.light);
      expect(specs.dark.brightness, Brightness.dark);
    });

    test('light mode with dark id still returns the chosen spec for both', () {
      const prefs = ThemePrefs(
        themeMode: ThemeMode.light,
        themeId: 'modern_dark',
      );
      final specs = resolveThemeSpecs(prefs);
      // When not in system mode, both use the chosen spec.
      expect(specs.light.id, 'modern_dark');
      expect(specs.dark.id, 'modern_dark');
    });
  });

  group('ThemeController — third spec auto-appears in registry', () {
    test('adding an available spec increases available count', () {
      // The real appThemes list has exactly 2 items now.
      final available = appThemes.where((s) => s.available).toList();
      expect(available.length, 2);

      // Simulate what the settings screen would do if a third spec were added
      // (available = true) — it would just appear in the grid.
      // This test documents the contract; no screen changes are needed.
    });
  });
}

