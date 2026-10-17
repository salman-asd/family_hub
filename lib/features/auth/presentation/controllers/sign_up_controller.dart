import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/domain/auth_credentials.dart';
import 'package:family_hub/features/auth/presentation/auth_form_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller behind the SignUp screen.
///
/// Adds a confirmation-password field on top of the login shape.  The
/// confirmation is validated *locally only* — it is never sent to the backend —
/// using a dedicated [Validation] code so the widget can show "passwords do not
/// match" rather than "password too short".
class SignUpController extends AuthFormController<AppUser?> {
  @override
  String get debugLabel => 'SignUpController';

  /// Validation code for a mismatched confirmation.
  static const String codePasswordMismatch = 'password_mismatch';
  static const String fieldPasswordConfirm = 'password_confirm';

  String _email = '';
  String _password = '';
  String _passwordConfirm = '';

  String get email => _email;
  String get password => _password;
  String get passwordConfirm => _passwordConfirm;

  @override
  bool get canSubmit =>
      _email.trim().isNotEmpty &&
      _password.isNotEmpty &&
      _passwordConfirm.isNotEmpty;

  AppFailure? emailError() => AuthCredentials.validateEmail(_email);

  AppFailure? passwordError() => AuthCredentials.validatePassword(_password);

  /// Confirmation error, or `null` when the two passwords match.
  AppFailure? passwordConfirmError() {
    if (_passwordConfirm.isEmpty) {
      return const Validation(
        fieldPasswordConfirm,
        AuthCredentials.codeRequired,
      );
    }
    if (_passwordConfirm != _password) {
      return const Validation(fieldPasswordConfirm, codePasswordMismatch);
    }
    return null;
  }

  void setEmail(String value) {
    _email = value;
    _touchForm();
  }

  void setPassword(String value) {
    _password = value;
    _touchForm();
  }

  void setPasswordConfirm(String value) {
    _passwordConfirm = value;
    _touchForm();
  }

  /// Re-publishes state after a field changes.
  ///
  /// Runs on **every** keystroke because the submit button and the inline errors
  /// are derived from the current field values.  It also clears a stale server
  /// error so a previous failure does not sit under the field while retyping.
  void _touchForm() {
    state = state.copyWith(clearFailure: state.failure != null);
  }

  @override
  Future<AuthOutcome<AppUser?>> submit() async {
    final emailFailure = AuthCredentials.validateEmail(_email);
    if (emailFailure != null) return authFailure<AppUser?>(emailFailure);
    final passwordFailure = AuthCredentials.validatePassword(_password);
    if (passwordFailure != null) return authFailure<AppUser?>(passwordFailure);
    final confirmFailure = passwordConfirmError();
    if (confirmFailure != null) return authFailure<AppUser?>(confirmFailure);

    final result = await ref.read(signUpProvider)(
      email: _email,
      password: _password,
    );
    return result.when(
      success: (user) => authSuccess<AppUser?>(user),
      failure: (failure) => authFailure<AppUser?>(failure),
    );
  }
}

final signUpControllerProvider =
    NotifierProvider<SignUpController, AuthFormState>(SignUpController.new);
