import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/domain/auth_credentials.dart';
import 'package:family_hub/features/auth/domain/usecases/sign_in.dart';
import 'package:family_hub/features/auth/presentation/auth_form_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller behind the Login screen.
///
/// Owns the two field values so the widget can stay stateless about *what* was
/// typed (only about whether it is obscured), and so a widget test can drive the
/// whole flow through the controller without pumping keystrokes.
///
/// Field-level validation is delegated to [AuthCredentials] — the same code the
/// [SignIn] use case runs — so the inline error and the use case error can never
/// disagree.
class LoginController extends AuthFormController<AppUser?> {
  @override
  String get debugLabel => 'LoginController';

  String _email = '';
  String _password = '';

  /// Last submitted email; exposed so tests and the UI can echo it back.
  String get email => _email;

  /// Current password value.
  String get password => _password;

  @override
  bool get canSubmit => _email.trim().isNotEmpty && _password.isNotEmpty;

  /// Inline error for the email field, or `null` when it is acceptable.
  AppFailure? emailError() => AuthCredentials.validateEmail(_email);

  /// Inline error for the password field, or `null` when it is acceptable.
  AppFailure? passwordError() => AuthCredentials.validatePassword(_password);

  void setEmail(String value) {
    _email = value;
    _touchForm();
  }

  void setPassword(String value) {
    _password = value;
    _touchForm();
  }

  /// Re-publishes state after a field changes.
  ///
  /// This must run on **every** keystroke, not only when an error is on screen:
  /// the submit button's enabled state is derived from the current field values,
  /// so without a notification the button would stay disabled after typing.  A
  /// stale server error is cleared in the same step, otherwise "wrong password"
  /// would sit under the field while the user retypes.
  void _touchForm() {
    state = state.copyWith(clearFailure: state.failure != null);
  }

  @override
  Future<AuthOutcome<AppUser?>> submit() async {
    // Run the same per-field validation the form shows, but stop at the first
    // failing field so the returned failure matches what the user can see.
    final emailFailure = AuthCredentials.validateEmail(_email);
    if (emailFailure != null) return authFailure<AppUser?>(emailFailure);
    final passwordFailure = AuthCredentials.validatePassword(_password);
    if (passwordFailure != null) return authFailure<AppUser?>(passwordFailure);

    final result = await ref.read(signInProvider)(
      email: _email,
      password: _password,
    );
    return result.when(
      success: (user) => authSuccess<AppUser?>(user),
      failure: (failure) => authFailure<AppUser?>(failure),
    );
  }
}

final loginControllerProvider =
    NotifierProvider<LoginController, AuthFormState>(LoginController.new);
