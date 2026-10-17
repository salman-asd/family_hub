import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/domain/auth_credentials.dart';
import 'package:family_hub/features/auth/domain/auth_repository.dart';

/// Creates a new account and requests email verification.
///
/// Order matters: local validation runs **before** any network call, so an
/// obviously bad form never costs a round-trip or a rate-limit token.
///
/// Returns the created [AppUser] (normally `emailVerified == false`), or
/// `Success(null)` when the backend completed the operation without returning a
/// user object — the auth state stream is the source of truth either way.
class SignUp {
  const SignUp(this._repository);

  final AuthRepository _repository;

  Future<Result<AppUser?>> call({
    required String email,
    required String password,
  }) async {
    final checkedEmail = AuthCredentials.checkEmail(email);
    if (checkedEmail.isFailure) {
      return Failure<AppUser?>(checkedEmail.failureOrNull!);
    }
    final checkedPassword = AuthCredentials.checkPassword(password);
    if (checkedPassword.isFailure) {
      return Failure<AppUser?>(checkedPassword.failureOrNull!);
    }

    return _repository.signUp(
      email: checkedEmail.valueOrNull!,
      password: checkedPassword.valueOrNull!,
    );
  }
}
