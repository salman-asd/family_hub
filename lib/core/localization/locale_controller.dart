import 'package:family_hub/app/theme/theme_controller.dart'
    show sharedPreferencesProvider;
import 'package:family_hub/core/localization/locale_prefs.dart';
import 'package:family_hub/core/localization/locale_preference_sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Exposes the [LocalePreferenceSync] used to push/pull language prefs from the
/// remote.  Overridden with the Firestore implementation in Step 9.
final localePreferenceSyncProvider = Provider<LocalePreferenceSync>(
  (ref) => const NoOpLocalePreferenceSync(),
);

/// The main language controller.
///
/// Reads [LocalePrefs] synchronously from [sharedPreferencesProvider] (which is
/// pre-loaded in bootstrap before `runApp`) so the first frame already renders
/// in the saved language — no flash of the wrong language.
final localeControllerProvider =
    NotifierProvider<LocaleController, LocalePrefs>(LocaleController.new);

// ── Keys ──────────────────────────────────────────────────────────────────────

const _kLanguageKey = 'language_code';
const _kBanglaDigitsKey = 'use_bangla_digits';

// ── Controller ────────────────────────────────────────────────────────────────

/// Riverpod [Notifier] that owns the persisted language preferences.
///
/// - Reads synchronously from [SharedPreferences] (pre-loaded in bootstrap).
/// - Writes back on every mutation.
/// - Fires-and-forgets a [LocalePreferenceSync.push] for remote sync.
class LocaleController extends Notifier<LocalePrefs> {
  @override
  LocalePrefs build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final rawLanguage = prefs.getString(_kLanguageKey);
    final rawDigits = prefs.getBool(_kBanglaDigitsKey);
    return LocalePrefs.fromMap({
      _kLanguageKey: rawLanguage,
      if (rawDigits != null) _kBanglaDigitsKey: rawDigits,
    });
  }

  /// Switch the app language.  Unknown codes fall back to Bangla.
  Future<void> setLanguageCode(String code) async {
    final resolved = LocalePrefs.supportedLanguageCodes.contains(code)
        ? code
        : LocalePrefs.defaultLanguageCode;
    state = state.copyWith(languageCode: resolved);
    await _persist();
  }

  /// Toggle Bangla digits (০১২৩) for numbers and dates.
  Future<void> setUseBanglaDigits(bool value) async {
    state = state.copyWith(useBanglaDigits: value);
    await _persist();
  }

  /// Applies preferences that came from the account (after sign-in).  Stores
  /// them locally but does NOT push them back, so sync cannot loop.
  Future<void> applyRemote(LocalePrefs remote) async {
    if (remote == state) return;
    state = remote;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kLanguageKey, state.languageCode);
    await prefs.setBool(_kBanglaDigitsKey, state.useBanglaDigits);
  }

  Future<void> _persist() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kLanguageKey, state.languageCode);
    await prefs.setBool(_kBanglaDigitsKey, state.useBanglaDigits);
    // Fire-and-forget remote sync (no-op until Step 9).
    ref.read(localePreferenceSyncProvider).push(state).ignore();
  }
}
