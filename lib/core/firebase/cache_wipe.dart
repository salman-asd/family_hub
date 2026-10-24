import 'package:shared_preferences/shared_preferences.dart';

/// Sign-out hygiene (H9).
///
/// Cloud Firestore keeps its offline cache on disk.  After a sign-out the next
/// person to sign in on the same phone must not find the previous person's
/// family data there.  `clearPersistence()` may only run while Firestore is not
/// in use, so a sign-out only RAISES a flag; [wipeCacheIfRequested] acts on it
/// at the next start, before Firestore is touched.
///
/// The flag lives in SharedPreferences, never in Firestore, and holds no user
/// data.
abstract final class CacheWipe {
  /// SharedPreferences key of the "wipe on next start" flag.
  static const String flagKey = 'wipeFirestoreCacheOnNextStart';

  /// Raises the flag (called after a successful sign-out or account deletion).
  static Future<void> request(SharedPreferences prefs) =>
      prefs.setBool(flagKey, true);

  /// True while a wipe is pending.
  static bool isRequested(SharedPreferences prefs) =>
      prefs.getBool(flagKey) ?? false;

  /// Runs [clearPersistence] when the flag is raised, then lowers it.
  ///
  /// The flag is lowered only after a successful wipe, so a failed attempt is
  /// retried at the next start.  Returns whether a wipe ran.
  static Future<bool> wipeIfRequested(
    SharedPreferences prefs,
    Future<void> Function() clearPersistence,
  ) async {
    if (!isRequested(prefs)) return false;
    await clearPersistence();
    await prefs.remove(flagKey);
    return true;
  }
}
