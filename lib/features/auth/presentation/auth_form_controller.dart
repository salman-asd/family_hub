import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/domain/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Re-export so screens import one file for controllers and providers.
export 'package:family_hub/features/auth/domain/auth_providers.dart'
    show
        authFailureCode,
        authRepositoryProvider,
        authStateProvider,
        isSignedInProvider,
        reloadUserProvider,
        sendEmailVerificationProvider,
        sendPasswordResetProvider,
        signInProvider,
        signOutProvider,
        signUpProvider;

/// ═══════════════════════════════════════════════════════════════════════════
/// The auth form state machine.
/// ═══════════════════════════════════════════════════════════════════════════
///
/// One class, used by five screens.  The roadmap asks for "one `AsyncNotifier`
/// controller per screen" (Step 7) — that is what [AuthFormController] and its
/// five subclasses are: the *behaviour* is shared, but the *screens* each own a
/// controller, so a value typed on Login can never leak into SignUp.
///
/// The state is a plain immutable record rather than `AsyncValue<X>` because an
/// auth form has states `AsyncValue` cannot express:
///
/// * submitted and idle at the same time (a form that failed validation),
/// * "succeeded a moment ago" while the form is still on screen (the
///   password-reset confirmation), which is neither loading nor error.
///
/// Keeping it explicit also makes the widget tests assert on named booleans
/// instead of matching `AsyncData`/`AsyncError` subtypes.
class AuthFormState {
  const AuthFormState({
    this.isSubmitting = false,
    this.failure,
    this.succeeded = false,
    this.revision = 0,
  });

  /// True while a request is in flight.  The submit button is disabled and
  /// shows a spinner while this is true.
  final bool isSubmitting;

  /// The last failure, already mapped from the backend.  `null` means "no
  /// error to show" — never "no error happened yet"; a fresh submit clears it.
  final AppFailure? failure;

  /// True once the last submit completed successfully.  Some screens use this
  /// to render a confirmation panel, others ignore it because they navigate on
  /// success (navigation is the screen's decision, not the controller's).
  final bool succeeded;

  /// Bumped by [copyWith] whenever a change could affect what is rendered.
  ///
  /// The field values live on the controller, not in this object, so a state
  /// transition such as "the email field went from empty to non-empty" would
  /// otherwise produce an `==`-equal value and Riverpod would skip the rebuild —
  /// leaving the submit button disabled after typing.  Carrying a revision makes
  /// every deliberate notification a distinct value.
  final int revision;

  /// True when a request has finished and produced no failure.
  bool get isIdle => !isSubmitting && failure == null;

  AuthFormState copyWith({
    bool? isSubmitting,
    AppFailure? failure,
    bool clearFailure = false,
    bool? succeeded,
    int? revision,
  }) =>
      AuthFormState(
        isSubmitting: isSubmitting ?? this.isSubmitting,
        failure: clearFailure ? null : (failure ?? this.failure),
        succeeded: succeeded ?? this.succeeded,
        // Every copyWith is a deliberate change, so the revision always moves.
        revision: revision ?? this.revision + 1,
      );

  @override
  bool operator ==(Object other) =>
      other is AuthFormState &&
      other.isSubmitting == isSubmitting &&
      other.failure == failure &&
      other.succeeded == succeeded &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(isSubmitting, failure, succeeded, revision);

  @override
  String toString() =>
      'AuthFormState(submitting: $isSubmitting, failure: $failure, '
      'succeeded: $succeeded, revision: $revision)';
}

/// Shared submit lifecycle for every auth screen.
///
/// Subclasses implement [submit] and describe themselves in [debugLabel].
/// The base class guarantees the invariants the UI relies on:
///
/// 1. a submit can never start while another is in flight (double-tap safety),
/// 2. `isSubmitting` is cleared in a `finally`, so a thrown exception cannot
///    leave the button spinning forever,
/// 3. `failure` is cleared at the *start* of a submit, so a stale error never
///    sits under a fresh attempt.
abstract class AuthFormController<T> extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  /// Performs the work, returning either a value or a typed failure.
  Future<({T? value, AppFailure? failure})> submit();

  /// Human-readable name used in logs and test failure messages.
  String get debugLabel;

  /// Disables the submit button (for example an empty field).
  ///
  /// Screens also validate per field for inline messages; this is the coarse
  /// "nothing to submit yet" gate.
  bool get canSubmit => true;

  /// Runs [submit] once, applying the shared invariants.
  ///
  /// Returns the successful value, or `null` when the attempt failed or was
  /// rejected.  Callers that need the value use [lastValue]; callers that only
  /// need "did it work" use the returned boolean-ish check.
  Future<T?> run() async {
    if (state.isSubmitting) return null;
    if (!canSubmit) {
      state = state.copyWith(
        isSubmitting: false,
        succeeded: false,
        failure: const Validation('form', 'required'),
      );
      return null;
    }

    state = state.copyWith(
      isSubmitting: true,
      succeeded: false,
      clearFailure: true,
    );

    try {
      final outcome = await submit();
      if (outcome.failure != null) {
        state = state.copyWith(isSubmitting: false, failure: outcome.failure);
        return null;
      }
      state = state.copyWith(isSubmitting: false, succeeded: true);
      return outcome.value;
    } on Object catch (error) {
      // Nothing thrown in the layers below should reach the UI, but if a bug
      // does, the button must not stay disabled forever.
      state = state.copyWith(
        isSubmitting: false,
        failure: Unknown(error),
      );
      return null;
    }
  }
}

/// The result of one auth submit: a value on success, a failure otherwise.
typedef AuthOutcome<T> = ({T? value, AppFailure? failure});

/// Builds the success outcome.
AuthOutcome<T> authSuccess<T>(T? value) => (value: value, failure: null);

/// Builds the failure outcome.
AuthOutcome<T> authFailure<T>(AppFailure failure) =>
    (value: null, failure: failure);

/// Provider helper: `authFormControllerProvider` instances are declared by the
/// screens that own them, so this file only ships the state and the base class.

/// The signed-in user from the auth stream, as a nullable value.
///
/// Screens that must react to the *current* user (VerifyEmail) read this; it is
/// deliberately a `Provider` over the stream rather than a second listener.
final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(authStateProvider).value,
);
