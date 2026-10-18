import 'dart:async';

import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/data/auth_failure_mapper.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/domain/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Firebase-backed [AuthRepository].
///
/// Every method funnels its call through [_guard], which catches
/// [FirebaseAuthException] and converts it with
/// [mapFirebaseAuthException] — so nothing above this class ever sees a
/// Firebase exception, and no `try`/`catch` is duplicated per method.
///
/// Round trips to the backend are wrapped in a timeout so a flaky connection
/// surfaces as [Network] instead of hanging the sign-in button forever.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    this.timeout = const Duration(seconds: 30),
  }) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Maximum time to wait for a backend round trip.
  final Duration timeout;

  /// Backed by `userChanges()` rather than `authStateChanges()` on purpose.
  ///
  /// `authStateChanges()` only fires on sign-in and sign-out, so after
  /// `reloadUser()` flips `emailVerified` to true nothing would be emitted and
  /// the router guard (Step 8) would leave the user stuck on /verify-email.
  /// `userChanges()` also fires on `User.reload()` and token refreshes, which is
  /// what the [AuthRepository.authStateChanges] contract promises.
  @override
  Stream<AppUser?> authStateChanges() => _auth.userChanges().map(toAppUser);

  @override
  Future<Result<AppUser?>> signUp({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final credential = await _auth
            .createUserWithEmailAndPassword(email: email, password: password)
            .timeout(timeout);
        final user = credential.user;
        // Send the verification email straight away (Step 7) but never let a
        // failure to send undo a successful sign-up: the account exists and
        // the VerifyEmail screen can resend.
        if (user != null && !user.emailVerified) {
          try {
            await user.sendEmailVerification().timeout(timeout);
          } on FirebaseAuthException {
            // Ignored on purpose: the account is created; resending is the
            // user's next action.  Nothing is swallowed silently in the UI —
            // VerifyEmail surfaces its own failures.
          }
        }
        return toAppUser(user);
      });

  @override
  Future<Result<AppUser?>> signIn({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final credential = await _auth
            .signInWithEmailAndPassword(email: email, password: password)
            .timeout(timeout);
        return toAppUser(credential.user);
      });

  @override
  Future<Result<void>> signOut() => _guard(() async {
        await _auth.signOut().timeout(timeout);
      });

  @override
  Future<Result<void>> sendPasswordReset({required String email}) =>
      _guard(() async {
        await _auth.sendPasswordResetEmail(email: email).timeout(timeout);
      });

  @override
  Future<Result<void>> sendEmailVerification() => _guard(() async {
        final user = _auth.currentUser;
        if (user == null) throw const _MissingUser();
        await user.sendEmailVerification().timeout(timeout);
      });

  @override
  Future<Result<AppUser?>> reloadUser() => _guard(() async {
        final user = _auth.currentUser;
        if (user == null) return null;
        await user.reload().timeout(timeout);
        // `reload()` mutates the cached record; `currentUser` re-reads it.
        return toAppUser(_auth.currentUser);
      });

  /// Runs [call], converting every backend failure into the matching
  /// [AppFailure].
  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Success<T>(await call());
    } on FirebaseAuthException catch (error) {
      return Failure<T>(mapFirebaseAuthException(error));
    } on _MissingUser {
      return Failure<T>(const NoCurrentUser());
    } on TimeoutException {
      return Failure<T>(const Network());
    } on Object catch (error) {
      return Failure<T>(Unknown(error));
    }
  }
}

/// Internal marker for "the operation needs a signed-in user and there is
/// none".  Converted to [NoCurrentUser] by [_guard].
class _MissingUser implements Exception {
  const _MissingUser();
}
