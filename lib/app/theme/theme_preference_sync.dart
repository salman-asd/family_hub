import 'package:family_hub/app/theme/theme_prefs.dart';

/// Contract for syncing theme preferences to a remote backend.
///
/// The no-op implementation [NoOpThemePreferenceSync] is used until Step 9
/// wires up the Firestore implementation inside `features/family`.
///
/// Implementations must be idempotent — calling [push] with the same value
/// twice must not cause errors.
abstract class ThemePreferenceSync {
  /// Push the current prefs to the remote.  Fire-and-forget from the caller's
  /// perspective; errors should be logged but not rethrown.
  Future<void> push(ThemePrefs prefs);

  /// Watch for remote changes.  Emits `null` when the remote has no value yet.
  Stream<ThemePrefs?> watch();
}

/// No-op implementation — used from bootstrap until Step 9.
class NoOpThemePreferenceSync implements ThemePreferenceSync {
  const NoOpThemePreferenceSync();

  @override
  Future<void> push(ThemePrefs prefs) async {}

  @override
  Stream<ThemePrefs?> watch() => const Stream.empty();
}

