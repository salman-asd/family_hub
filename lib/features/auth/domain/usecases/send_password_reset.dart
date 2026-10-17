import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/domain/auth_credentials.dart';
import 'package:family_hub/features/auth/domain/auth_repository.dart';

/// Sends a password-reset email.
///
/// The email is validated locally, but the caller must still treat the call as
/// **always succeeding for a well-formed address**: Firebase returns success
/// for unknown addresses too, on purpose, so the screen cannot be used to probe
/// which emails have accounts.
class SendPasswordReset {
  const SendPasswordReset(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) async {
    final checked = AuthCredentials.checkEmail(email);
    if (checked.isFailure) return Failure<void>(checked.failureOrNull!);
    return _repository.sendPasswordReset(email: checked.valueOrNull!);
  }
}
