import 'package:family_hub/app/theme/theme_preference_sync.dart';
import 'package:family_hub/app/theme/theme_prefs.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

/// Exposes the [SharedPreferences] instance that was pre-loaded in bootstrap.
///
/// Bootstrap **must** override this provider before running [runApp] so that
/// the theme is resolved synchronously on the first frame — no flash of the
/// wrong theme.
///
/// Usage in bootstrap:
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// runApp(ProviderScope(
///   overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
///   child: FamilyHubApp(),
/// ));
/// ```
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in bootstrap before runApp.',
  ),
);

/// Exposes the [ThemePreferenceSync] used to push/pull prefs from the remote.
/// Overridden with [FirestoreThemePreferenceSync] in Step 9.
final themePreferenceSyncProvider = Provider<ThemePreferenceSync>(
  (ref) => const NoOpThemePreferenceSync(),
);

/// The main theme controller.  Reads [SharedPreferences] synchronously on
/// build (already loaded in bootstrap) and writes back on every change.
final themeControllerProvider =
    NotifierProvider<ThemeController, ThemePrefs>(ThemeController.new);

// ── Keys ──────────────────────────────────────────────────────────────────────

const _kModeKey = 'theme_mode';
const _kIdKey = 'theme_id';

// ── Controller ────────────────────────────────────────────────────────────────

/// Riverpod [Notifier] that owns the persisted theme preferences.
///
/// - Reads synchronously from [SharedPreferences] (pre-loaded in bootstrap).
/// - Writes back on every mutation.
/// - Fires-and-forgets a [ThemePreferenceSync.push] for remote sync.
class ThemeController extends Notifier<ThemePrefs> {
  @override
  ThemePrefs build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ThemePrefs.fromMap({
      _kModeKey: prefs.getString(_kModeKey),
      _kIdKey: prefs.getString(_kIdKey),
    });
  }

  /// Switch the colour palette.  Falls back to [modernLightSpec] for unknown
  /// ids (mirrors [themeById] behaviour).
  Future<void> setThemeId(String id) async {
    // Validate that the id exists; fall back if not.
    final resolvedId = themeById(id).id;
    state = state.copyWith(themeId: resolvedId);
    await _persist();
  }

  /// Switch between system / light / dark.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _persist();
  }

  /// Applies preferences that came from the account (after sign-in).  Stores
  /// them locally but does NOT push them back, so sync cannot loop.
  Future<void> applyRemote(ThemePrefs remote) async {
    final resolved = remote.copyWith(themeId: themeById(remote.themeId).id);
    if (resolved == state) return;
    state = resolved;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kModeKey, state.themeMode.name);
    await prefs.setString(_kIdKey, state.themeId);
  }

  Future<void> _persist() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kModeKey, state.themeMode.name);
    await prefs.setString(_kIdKey, state.themeId);
    // Fire-and-forget remote sync (no-op until Step 9).
    unawaited(
      ref.read(themePreferenceSyncProvider).push(state),
    );
  }
}

/// Derives the effective [ThemeData] pair from the current [ThemePrefs].
///
/// When [ThemePrefs.themeMode] is [ThemeMode.system] the app uses the first
/// available light spec for [MaterialApp.theme] and the first available dark
/// spec for [MaterialApp.darkTheme] — so the OS controls brightness.
///
/// When a specific id is chosen both theme and darkTheme are built from the
/// same spec so the brightness is always the spec's own brightness regardless
/// of [ThemeMode].
({AppThemeSpec light, AppThemeSpec dark}) resolveThemeSpecs(ThemePrefs prefs) {
  if (prefs.themeMode == ThemeMode.system) {
    return (light: defaultLightSpec, dark: defaultDarkSpec);
  }
  final chosen = themeById(prefs.themeId);
  return (light: chosen, dark: chosen);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Convenience — avoids the need to import `dart:async` in callers.
void unawaited(Future<void> future) {
  future.ignore();
}
