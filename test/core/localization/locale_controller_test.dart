import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/core/localization/locale_controller.dart';
import 'package:family_hub/core/localization/locale_prefs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Creates a [ProviderContainer] whose [sharedPreferencesProvider] is backed by
/// an in-memory store pre-populated with [initialData].
///
/// Await the result — [SharedPreferences.getInstance] is asynchronous.
Future<ProviderContainer> _makeContainer({
  Map<String, Object> initialData = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialData);
  return _openContainer();
}

/// Opens a [ProviderContainer] over the *current* in-memory store without
/// resetting it — used to simulate an app restart.
Future<ProviderContainer> _openContainer() async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LocalePrefs serialisation', () {
    test('defaults to Bangla with Bangla digits', () {
      const prefs = LocalePrefs();
      expect(prefs.languageCode, 'bn');
      expect(prefs.useBanglaDigits, isTrue);
      expect(prefs.locale.languageCode, 'bn');
    });

    test('round-trips known values', () {
      const original = LocalePrefs(languageCode: 'en', useBanglaDigits: false);
      final restored = LocalePrefs.fromMap(original.toMap());
      expect(restored, equals(original));
    });

    test('unknown language code falls back to Bangla', () {
      final restored = LocalePrefs.fromMap({
        'language_code': 'fr',
        'use_bangla_digits': false,
      });
      expect(restored.languageCode, 'bn');
      expect(restored.useBanglaDigits, isFalse);
    });

    test('missing digits key defaults to Bangla digits for Bangla', () {
      final bn = LocalePrefs.fromMap({'language_code': 'bn'});
      final en = LocalePrefs.fromMap({'language_code': 'en'});
      expect(bn.useBanglaDigits, isTrue);
      expect(en.useBanglaDigits, isFalse);
    });
  });

  group('LocaleController persistence', () {
    test('build reads persisted language and digits', () async {
      final container = await _makeContainer(
        initialData: const {'language_code': 'en', 'use_bangla_digits': false},
      );
      addTearDown(container.dispose);
      final prefs = container.read(localeControllerProvider);
      expect(prefs.languageCode, 'en');
      expect(prefs.useBanglaDigits, isFalse);
    });

    test('setLanguageCode updates state and SharedPreferences', () async {
      final container = await _makeContainer();
      addTearDown(container.dispose);
      await container
          .read(localeControllerProvider.notifier)
          .setLanguageCode('en');

      expect(container.read(localeControllerProvider).languageCode, 'en');
      final store = await SharedPreferences.getInstance();
      expect(store.getString('language_code'), 'en');
    });

    test('setUseBanglaDigits updates state and SharedPreferences', () async {
      final container = await _makeContainer();
      addTearDown(container.dispose);
      await container
          .read(localeControllerProvider.notifier)
          .setUseBanglaDigits(false);

      expect(container.read(localeControllerProvider).useBanglaDigits, isFalse);
      final store = await SharedPreferences.getInstance();
      expect(store.getBool('use_bangla_digits'), isFalse);
    });

    test('unsupported language falls back to Bangla', () async {
      final container = await _makeContainer();
      addTearDown(container.dispose);
      await container
          .read(localeControllerProvider.notifier)
          .setLanguageCode('zz');
      expect(container.read(localeControllerProvider).languageCode, 'bn');
    });

    test('restart (new container) restores the persisted language', () async {
      final first = await _makeContainer();
      addTearDown(first.dispose);
      await first.read(localeControllerProvider.notifier).setLanguageCode('en');

      // Simulate a fresh app launch reading the same store.
      final second = await _openContainer();
      addTearDown(second.dispose);
      expect(second.read(localeControllerProvider).languageCode, 'en');
    });
  });
}
