import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/auth/domain/auth_credentials.dart';
import 'package:family_hub/features/auth/presentation/auth_form_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller behind the ForgotPassword screen.
///
/// Reports success through [AuthFormState.succeeded] rather than navigating:
/// the screen renders a confirmation panel naming the address, which is the
/// behaviour the roadmap asks for and is friendlier than a bare snackbar.
///
/// Success here means "the request was accepted".  Firebase returns success for
/// unknown addresses too, deliberately, so this screen can never be used to
/// discover which emails have accounts — the confirmation copy must not claim
/// that an email definitely exists.
class ForgotPasswordController extends AuthFormController<void> {
  @override
  String get debugLabel => 'ForgotPasswordController';

  String _email = '';

  String get email => _email;

  @override
  bool get canSubmit => _email.trim().isNotEmpty;

  AppFailure? emailError() => AuthCredentials.validateEmail(_email);

  void setEmail(String value) {
    _email = value;
    // Notify on every keystroke: the submit button's enabled state and the
    // inline error both derive from the current value.
    state = state.copyWith(clearFailure: state.failure != null);
  }

  /// Clears the confirmation so the user can send to a different address.
  void reset() {
    state = const AuthFormState();
  }

  @override
  Future<AuthOutcome<void>> submit() async {
    final emailFailure = AuthCredentials.validateEmail(_email);
    if (emailFailure != null) return authFailure<void>(emailFailure);

    final result = await ref.read(sendPasswordResetProvider)(email: _email);
    return result.when(
      success: (_) => authSuccess<void>(null),
      failure: (failure) => authFailure<void>(failure),
    );
  }
}

final forgotPasswordControllerProvider =
    NotifierProvider<ForgotPasswordController, AuthFormState>(
  ForgotPasswordController.new,
);
