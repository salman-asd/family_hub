import 'package:family_hub/core/localization/locale_prefs.dart';

/// Contract for syncing language preferences to a remote backend.
///
/// The no-op implementation [NoOpLocalePreferenceSync] is used until Step 9
/// wires up the Firestore implementation (users/{uid}.preferences).
///
/// Implementations must be idempotent — calling [push] with the same value
/// twice must not cause errors.
abstract class LocalePreferenceSync {
  /// Push the current prefs to the remote.  Fire-and-forget from the caller's
  /// perspective; errors should be logged but not rethrown.
  Future<void> push(LocalePrefs prefs);

  /// Watch for remote changes.  Emits `null` when the remote has no value yet.
  Stream<LocalePrefs?> watch();
}

/// No-op implementation — used from bootstrap until Step 9.
class NoOpLocalePreferenceSync implements LocalePreferenceSync {
  const NoOpLocalePreferenceSync();

  @override
  Future<void> push(LocalePrefs prefs) async {}

  @override
  Stream<LocalePrefs?> watch() => const Stream.empty();
}
