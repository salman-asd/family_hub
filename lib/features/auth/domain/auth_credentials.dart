import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';

/// Pure-Dart credential rules shared by the sign-in and sign-up use cases and
/// by the form controllers.
///
/// Roadmap Step 7: "Validation (email format, password >= 8 chars) lives in
/// domain and returns AppFailure.Validation".
///
/// The codes are stable machine-readable strings; the presentation layer maps
/// them to ARB keys, so the domain never holds user-visible text.
abstract final class AuthCredentials {
  /// Minimum password length enforced by the app (Firebase only requires 6 —
  /// we are deliberately stricter).
  static const int minPasswordLength = 8;

  /// Validation codes returned inside [Validation].
  static const String codeRequired = 'required';
  static const String codeInvalidEmail = 'invalid_email';
  static const String codePasswordTooShort = 'password_too_short';

  /// Field names used inside [Validation].
  static const String fieldEmail = 'email';
  static const String fieldPassword = 'password';

  /// `^[^@\s]+@[^@\s.]+(\.[^@\s.]+)+$` — intentionally conservative.
  ///
  /// It rejects `a@b` (no TLD), `a b@c.com` (space), `@a.com` and `a@.com`
  /// while accepting every address Firebase would also accept in practice.
  /// The backend re-validates, so a false negative here is safe; a false
  /// positive is what we must avoid.
  static final RegExp _emailPattern = RegExp(
    r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)+$',
  );

  /// True when [value] looks like an email address.
  static bool isValidEmail(String value) =>
      _emailPattern.hasMatch(value.trim());

  /// True when [value] satisfies the length rule.
  static bool isValidPassword(String value) =>
      value.length >= minPasswordLength;

  /// Validates an email field, returning `null` when it is acceptable.
  static AppFailure? validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return const Validation(fieldEmail, codeRequired);
    if (!isValidEmail(text)) {
      return const Validation(fieldEmail, codeInvalidEmail);
    }
    return null;
  }

  /// Validates a password field, returning `null` when it is acceptable.
  static AppFailure? validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return const Validation(fieldPassword, codeRequired);
    if (!isValidPassword(text)) {
      return const Validation(fieldPassword, codePasswordTooShort);
    }
    return null;
  }

  /// Validation as a [Result], for use inside use cases.
  static Result<String> checkEmail(String raw) {
    final failure = validateEmail(raw);
    if (failure != null) return Failure<String>(failure);
    return Success<String>(raw.trim());
  }

  /// Validation as a [Result], for use inside use cases.  The password is
  /// deliberately **not** trimmed — leading/trailing spaces are part of a
  /// password.
  static Result<String> checkPassword(String raw) {
    final failure = validatePassword(raw);
    if (failure != null) return Failure<String>(failure);
    return Success<String>(raw);
  }
}
