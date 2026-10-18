import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which button the VerifyEmail screen last produced its state from.
enum VerifyAction {
  /// "Send the email again".
  resend,

  /// "I have verified".
  checkVerified,
}

/// Everything the VerifyEmail screen renders.
///
/// Unlike the other auth screens this one is *not* built on `AuthFormState`,
/// because it has two actions whose success means different things:
///
/// * resend succeeded -> show "email sent";
/// * check succeeded but the address is still unverified -> show "not verified
///   yet", which is **not** an error.
///
/// Folding those into a single `succeeded` flag would make the screen unable to
/// tell them apart.  Making this the notifier's state is also what makes the
/// screen rebuild reliably: it watches `verifyEmailControllerProvider`, and
/// Riverpod re-emits whenever this value changes by `==`.  Every transition
/// below changes at least one field, so no banner can go stale.
class VerifyEmailState {
  const VerifyEmailState({
    this.isSubmitting = false,
    this.failure,
    this.action,
    this.resendSucceeded = false,
    this.stillUnverified = false,
    this.verified = false,
    this.revision = 0,
  });

  /// True while either action is in flight.  Both buttons are disabled.
  final bool isSubmitting;

  /// A real failure (a failed round trip), or `null`.
  final AppFailure? failure;

  /// Which action produced the current state; `null` before the first action.
  final VerifyAction? action;

  /// The resend completed successfully.
  final bool resendSucceeded;

  /// "I have verified" ran successfully but the address is not verified yet.
  ///
  /// Informational, never an error.
  final bool stillUnverified;

  /// The address is verified; Step 8's router takes over from here.
  final bool verified;

  /// Monotonic counter bumped on every [copyWith], so two otherwise-equal
  /// states ("still unverified" twice) are still distinguishable to Riverpod.
  final int revision;

  VerifyEmailState copyWith({
    bool? isSubmitting,
    AppFailure? failure,
    bool clearFailure = false,
    VerifyAction? action,
    bool? resendSucceeded,
    bool? stillUnverified,
    bool? verified,
    int? revision,
  }) =>
      VerifyEmailState(
        isSubmitting: isSubmitting ?? this.isSubmitting,
        failure: clearFailure ? null : (failure ?? this.failure),
        action: action ?? this.action,
        resendSucceeded: resendSucceeded ?? this.resendSucceeded,
        stillUnverified: stillUnverified ?? this.stillUnverified,
        verified: verified ?? this.verified,
        // Every copyWith is a deliberate change, so the revision always moves.
        // Without it, tapping "I have verified" twice in a row would publish an
        // equal state and the screen would not rebuild for the second tap.
        revision: revision ?? this.revision + 1,
      );

  @override
  bool operator ==(Object other) =>
      other is VerifyEmailState &&
      other.isSubmitting == isSubmitting &&
      other.failure == failure &&
      other.action == action &&
      other.resendSucceeded == resendSucceeded &&
      other.stillUnverified == stillUnverified &&
      other.verified == verified &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(
        isSubmitting,
        failure,
        action,
        resendSucceeded,
        stillUnverified,
        verified,
        revision,
      );

  @override
  String toString() =>
      'VerifyEmailState(submitting: $isSubmitting, action: $action, '
      'resendSucceeded: $resendSucceeded, stillUnverified: $stillUnverified, '
      'verified: $verified, failure: $failure)';
}

/// Controller behind the VerifyEmail screen.
///
/// The shared `AuthFormController` lifecycle is deliberately not reused: its
/// single `succeeded` flag cannot express "resend worked" vs "still unverified"
/// vs "verified".  The two invariants that matter are implemented explicitly:
///
/// 1. **double-tap guard** — a second action while one is in flight is refused
///    without touching the backend (see [_begin]);
/// 2. **stale-banner clearing** — each action clears the other's banner before
///    it starts, so the screen never shows two contradictory messages.
class VerifyEmailController extends Notifier<VerifyEmailState> {
  @override
  VerifyEmailState build() => const VerifyEmailState();

  /// True when the last "I have verified" found the address verified.
  bool get isVerified => state.verified;

  /// The screen's primary button: "I have verified".
  ///
  /// Returns `true` only when the address is verified now.  A refusal (already
  /// busy) returns `false`, as does a failure.
  Future<bool> checkVerified() async {
    if (!_begin(VerifyAction.checkVerified)) return false;

    final result = await _guard(ref.read(reloadUserProvider)());

    if (result.isFailure) {
      state = state.copyWith(
        isSubmitting: false,
        failure: result.failureOrNull,
      );
      return false;
    }

    final verified = result.valueOrNull?.emailVerified ?? false;
    state = state.copyWith(
      isSubmitting: false,
      stillUnverified: !verified,
      verified: verified,
    );
    return verified;
  }

  /// Sends the verification email again.
  ///
  /// Returns `true` only when the send succeeded.
  Future<bool> resend() async {
    if (!_begin(VerifyAction.resend)) return false;

    final result = await _guard(
      ref.read(sendEmailVerificationProvider)(
        // The signed-in flag comes from the auth stream; the use case rejects
        // the call (before any backend round trip) when there is no user.
        isSignedIn: ref.read(authStateProvider).value != null,
      ),
    );

    state = state.copyWith(
      isSubmitting: false,
      failure: result.failureOrNull,
      resendSucceeded: result.isSuccess,
    );
    return result.isSuccess;
  }

  /// Claims the busy flag for [action] and clears both banners.
  ///
  /// Returns `false` when another action is already in flight, which is what
  /// stops a double tap from firing two backend calls.
  bool _begin(VerifyAction action) {
    if (state.isSubmitting) return false;
    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      action: action,
      resendSucceeded: false,
      stillUnverified: false,
    );
    return true;
  }

  /// Converts a thrown exception into an [Unknown] failure.
  ///
  /// Nothing below this layer throws, but a bug must not leave the buttons
  /// disabled forever.
  Future<Result<T>> _guard<T>(Future<Result<T>> call) async {
    try {
      return await call;
    } on Object catch (error) {
      return Failure<T>(Unknown(error));
    }
  }
}

final verifyEmailControllerProvider =
    NotifierProvider<VerifyEmailController, VerifyEmailState>(
  VerifyEmailController.new,
);
