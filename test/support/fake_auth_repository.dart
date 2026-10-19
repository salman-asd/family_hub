import 'dart:async';

import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/domain/auth_repository.dart';

/// In-memory [AuthRepository] for tests.
///
/// Implements the same error contract as the real repository: **nothing throws**
/// and every failure comes back as `Failure(AppFailure)`.  That is deliberate —
/// if the fake threw where Firebase returns a failure, the tests would pass
/// against the fake and the app would break against the backend.
///
/// The fake also owns an [authStateChanges] broadcast stream, so a controller
/// test can assert that sign-in/sign-out propagate exactly like they do in
/// production.
///
/// Usage:
/// ```dart
/// final fake = FakeAuthRepository();
/// final container = ProviderContainer(overrides: [
///   authRepositoryProvider.overrideWithValue(fake),
/// ]);
/// ```
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? signedInAs}) : _current = signedInAs;

  /// Programme the next [signIn] outcome.  `null` means "succeed".
  AppFailure? signInFailure;

  /// Programme the next [signUp] outcome.
  AppFailure? signUpFailure;

  /// Programme the next [signOut] outcome.
  AppFailure? signOutFailure;

  /// Programme the next [sendPasswordReset] outcome.
  AppFailure? sendPasswordResetFailure;

  /// Programme the next [sendEmailVerification] outcome.
  AppFailure? sendEmailVerificationFailure;

  /// Programme the next [reloadUser] outcome.
  AppFailure? reloadUserFailure;

  /// The user [reloadUser] returns while [reloadVerified] is true.
  ///
  /// Lets a test model "the user opened the link in their inbox": flip this to
  /// `true` and the next `reloadUser` reports a verified address.
  bool reloadVerified = false;

  /// How many times [reloadUser] refreshed the ID token (H5 mirrors the real
  /// repository's `getIdToken(true)`).
  int tokenRefreshes = 0;

  /// When true, every method parks until [release] is called — used to observe
  /// the in-flight (`isSubmitting`) state.
  ///
  /// A boolean rather than a stored [Completer] so the window can be reopened
  /// for a second call (each gated call awaits its own fresh completer).
  bool hold = false;

  /// Recompletes for each call that parks while [hold] is true.
  Completer<void> _gate = Completer<void>();

  // ── Call recording ────────────────────────────────────────────────────────

  final List<String> calls = <String>[];
  String? lastEmail;
  String? lastPassword;

  AppUser? _current;

  /// A trailing user returned by [signUp] by default.
  AppUser _newUser(String email) => AppUser(
        uid: 'uid-${email.hashCode.toUnsigned(32)}',
        email: email,
        emailVerified: false,
      );

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> authStateChanges() async* {
    // Emit the current value first, mirroring FirebaseAuth.authStateChanges().
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<Result<AppUser?>> signUp({
    required String email,
    required String password,
  }) async {
    calls.add('signUp');
    lastEmail = email;
    lastPassword = password;
    await _wait();
    if (signUpFailure != null) return Failure<AppUser?>(signUpFailure!);
    _setCurrent(_newUser(email));
    return Success<AppUser?>(_current);
  }

  @override
  Future<Result<AppUser?>> signIn({
    required String email,
    required String password,
  }) async {
    calls.add('signIn');
    lastEmail = email;
    lastPassword = password;
    await _wait();
    if (signInFailure != null) return Failure<AppUser?>(signInFailure!);
    _setCurrent(
      AppUser(
        uid: 'uid-${email.hashCode.toUnsigned(32)}',
        email: email,
        emailVerified: true,
      ),
    );
    return Success<AppUser?>(_current);
  }

  @override
  Future<Result<void>> signOut() async {
    calls.add('signOut');
    await _wait();
    if (signOutFailure != null) return Failure<void>(signOutFailure!);
    _setCurrent(null);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async {
    calls.add('sendPasswordReset');
    lastEmail = email;
    await _wait();
    if (sendPasswordResetFailure != null) {
      return Failure<void>(sendPasswordResetFailure!);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    calls.add('sendEmailVerification');
    await _wait();
    if (sendEmailVerificationFailure != null) {
      return Failure<void>(sendEmailVerificationFailure!);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<AppUser?>> reloadUser() async {
    calls.add('reloadUser');
    await _wait();
    if (reloadUserFailure != null) {
      return Failure<AppUser?>(reloadUserFailure!);
    }
    final current = _current;
    if (current == null) return const Success<AppUser?>(null);
    // Mirror FirebaseAuthRepository.reloadUser(): force a token refresh so the
    // `email_verified` claim the rules read is up to date (H5).
    tokenRefreshes++;
    _setCurrent(current.copyWith(emailVerified: reloadVerified));
    return Success<AppUser?>(_current);
  }

  /// Pushes [user] onto the stream and returns it.
  void _setCurrent(AppUser? user) {
    _current = user;
    if (!_controller.isClosed) _controller.add(user);
  }

  /// Test helper: makes the fake look signed in without going through [signIn].
  void signInAs(AppUser user) => _setCurrent(user);

  /// Test helper: lets every parked call finish and reopens the gate later.
  void release() {
    hold = false;
    final g = _gate;
    if (!g.isCompleted) g.complete();
    // Arm the next window so a later `parked` await resolves again.
    _parked = Completer<void>();
  }

  /// Test helper: completes once a call has actually parked, so a test never
  /// has to guess how many microtasks the controller chain needs.
  ///
  /// A [Completer] rather than a stream: a broadcast stream would drop the
  /// event if the call parked before the test subscribed, which is a race.
  Future<void> get parked => _parked.future;
  Completer<void> _parked = Completer<void>();

  Future<void> _wait() async {
    if (!hold) return;
    // Fresh gate + fresh parked completer for this call, so `release()`
    // unblocks exactly this one and a later gated call blocks again rather
    // than being released early.
    _gate = Completer<void>();
    final parked = _parked;
    if (!parked.isCompleted) parked.complete();
    await _gate.future;
  }

  /// Closes the stream.  Call from `tearDown` to avoid a leaked stream.
  Future<void> dispose() async {
    if (!_gate.isCompleted) _gate.complete();
    if (!_parked.isCompleted) _parked.complete();
    await _controller.close();
  }
}
