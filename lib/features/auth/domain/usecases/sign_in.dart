import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/domain/app_user.dart';
import 'package:family_hub/features/auth/domain/auth_credentials.dart';
import 'package:family_hub/features/auth/domain/auth_repository.dart';

/// Signs an existing user in with email and password.
///
/// Local validation runs first (same reasoning as [SignUp]); the password is
/// never trimmed.
class SignIn {
  const SignIn(this._repository);

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

    return _repository.signIn(
      email: checkedEmail.valueOrNull!,
      password: checkedPassword.valueOrNull!,
    );
  }
}
