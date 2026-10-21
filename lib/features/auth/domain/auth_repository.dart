import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';

/// Read/query port for authentication.
///
/// Implemented in `data/` by [FirebaseAuthRepository] and faked in tests by
/// `FakeAuthRepository`.  Nothing above this layer knows Firebase exists.
///
/// ## Error contract
///
/// No method throws.  Every failure is returned as `Failure(AppFailure)`;
/// the implementation is responsible for translating backend exceptions.
/// The sign-in / sign-up methods return `Result<AppUser?>`: the backend may
/// complete the operation without returning a user object, and `null` there
/// means "succeeded, no user payload" rather than "failed".
abstract interface class AuthRepository {
  /// Emits the current identity, then every change: sign-in, sign-out, token
  /// refresh, verification.
  ///
  /// Emits immediately with the current value (usually `null`) so callers can
  /// distinguish "still loading" from "signed out" — the router guard in
  /// Step 8 depends on that difference.
  Stream<AppUser?> authStateChanges();

  /// Creates an account and immediately sends the verification email.
  ///
  /// Returns the freshly created user (which normally has
  /// `emailVerified == false`).
  Future<Result<AppUser?>> signUp({
    required String email,
    required String password,
  });

  /// Signs in with email and password.
  Future<Result<AppUser?>> signIn({
    required String email,
    required String password,
  });

  /// Signs the current user out.
  Future<Result<void>> signOut();

  /// Sends a password-reset email.  Never reveals whether the address exists.
  Future<Result<void>> sendPasswordReset({required String email});

  /// (Re)sends the verification email to the current user.
  Future<Result<void>> sendEmailVerification();

  /// Re-fetches the current user from the backend, refreshing
  /// [AppUser.emailVerified].
  Future<Result<AppUser?>> reloadUser();

  /// Re-authenticates the CURRENT user with their password (H9).  Needed
  /// before changing the password or deleting the account, which the backend
  /// only allows for a recent sign-in.
  Future<Result<void>> reauthenticate({required String password});

  /// Sets a new password for the current user (H9).  Fails with
  /// `RequiresRecentLogin` when the sign-in is too old; call
  /// [reauthenticate] first.
  Future<Result<void>> changePassword({required String newPassword});

  /// Permanently deletes the Firebase Auth user (H9).  Local data is wiped by
  /// the caller.  Fails with `RequiresRecentLogin` when the sign-in is too old.
  Future<Result<void>> deleteAuthUser();
}
