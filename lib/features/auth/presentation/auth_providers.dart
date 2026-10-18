import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/domain/auth_repository.dart';
import 'package:family_hub/features/auth/domain/usecases/auth_use_cases.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Providers of the auth feature.
///
/// The presentation layer reads *only* these; it never constructs a use case or
/// touches the repository directly.
///
/// [authRepositoryProvider] has no default implementation because the choice
/// depends on the flavor (Firebase options) and on the test.  It is overridden:
///
/// * in `bootstrap.dart` with `FirebaseAuthRepository`;
/// * in tests with `FakeAuthRepository` (in-memory) or with a failing fake to
///   exercise error states.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError(
    'authRepositoryProvider must be overridden: bootstrap.dart installs '
    'FirebaseAuthRepository, tests install a fake.',
  ),
);

/// The signed-in user, or `null` when signed out.
///
/// `AsyncValue` is deliberate: `AsyncLoading` means "the first auth event has
/// not arrived yet", which the Step 8 router must treat differently from
/// `AsyncData(null)` (= definitely signed out).
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// True while an identity is present.  Derived state only — never a second
/// source of truth.
final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(authStateProvider).value != null,
);

final signUpProvider = Provider<SignUp>(
  (ref) => SignUp(ref.watch(authRepositoryProvider)),
);

final signInProvider = Provider<SignIn>(
  (ref) => SignIn(ref.watch(authRepositoryProvider)),
);

final signOutProvider = Provider<SignOut>(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);

final sendPasswordResetProvider = Provider<SendPasswordReset>(
  (ref) => SendPasswordReset(ref.watch(authRepositoryProvider)),
);

final sendEmailVerificationProvider = Provider<SendEmailVerification>(
  (ref) => SendEmailVerification(ref.watch(authRepositoryProvider)),
);

/// Re-reads the current user from the backend (the "I have verified" button).
///
/// Exposed as a plain function provider because it returns a `Result` the
/// controller must interpret (for example to distinguish "still unverified"
/// from a network failure).
final reloadUserProvider = Provider<Future<Result<AppUser?>> Function()>(
  (ref) => ref.watch(authRepositoryProvider).reloadUser,
);

/// Maps an [AppFailure] to a stable, machine-readable message code.
///
/// This is the single exhaustive `switch` over the sealed [AppFailure]; the
/// presentation layer turns the code into localized text through
/// `context.l10n.authFailureMessage(code)`.  If a new failure subtype is added,
/// this switch stops compiling until it is handled — no failure can silently
/// fall through to a generic message.
String authFailureCode(AppFailure failure) => switch (failure) {
      PermissionDenied() => 'permission_denied',
      NotFound() => 'not_found',
      Conflict() => 'conflict',
      Network() => 'network',
      InvalidCredentials() => 'invalid_credentials',
      UserNotFound() => 'user_not_found',
      EmailAlreadyInUse() => 'email_already_in_use',
      WeakPassword() => 'weak_password',
      TooManyRequests() => 'too_many_requests',
      UserDisabled() => 'user_disabled',
      RequiresRecentLogin() => 'requires_recent_login',
      InvalidEmail() => 'invalid_email',
      NoCurrentUser() => 'no_current_user',
      Validation(field: final field, code: final code) =>
        'validation.$field.$code',
      Unknown() => 'unknown',
    };
