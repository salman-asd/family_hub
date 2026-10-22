import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Translates Firebase Auth errors into the app's sealed [AppFailure].
///
/// This is the **only** place in the codebase that knows about
/// `FirebaseAuthException`.  Keeping the mapping in one pure function means the
/// whole table is unit-testable without a Firebase instance: the tests build a
/// `FirebaseAuthException` with a chosen `code` and assert the [AppFailure].
///
/// Codes come from the Firebase Auth documentation and are stable strings.  The
/// final branch deliberately returns [Unknown] rather than guessing, so a new
/// backend code shows a generic message instead of a wrong one.
///
/// Reference: https://firebase.google.com/docs/auth/flutter/errors
AppFailure mapFirebaseAuthException(FirebaseAuthException error) =>
    switch (error.code) {
      // ── Credentials ──────────────────────────────────────────────────────
      // Since Firebase Auth 5.x, `invalid-credential` replaces the older and
      // more specific `wrong-password` / `invalid-email` codes for sign-in.
      // `user-not-found` still arrives from other flows and older SDKs.
      'invalid-credential' ||
      'invalid-login-credentials' ||
      'wrong-password' => const InvalidCredentials(),
      'user-not-found' => const UserNotFound(),
      'email-already-in-use' => const EmailAlreadyInUse(),
      'weak-password' => const WeakPassword(),
      'invalid-email' => const InvalidEmail(),

      // ── Account state ────────────────────────────────────────────────────
      'user-disabled' => const UserDisabled(),
      'user-mismatch' ||
      'requires-recent-login' ||
      'recent-login-required' => const RequiresRecentLogin(),
      'operation-not-allowed' => const PermissionDenied(),

      // ── Transport and throttling ─────────────────────────────────────────
      'network-request-failed' ||
      'internal-error' ||
      'timeout' => const Network(),
      'too-many-requests' => const TooManyRequests(),

      // ── Everything else ──────────────────────────────────────────────────
      _ => Unknown(error),
    };

/// Converts a Firebase [User] to the domain `AppUser`.
///
/// Returns `null` for a null [user] so callers can pass
/// `FirebaseAuth.currentUser` straight in.
AppUser? toAppUser(User? user) {
  if (user == null) return null;
  return AppUser(
    uid: user.uid,
    email: user.email,
    emailVerified: user.emailVerified,
  );
}
