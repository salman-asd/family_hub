import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/domain/auth_repository.dart';

/// Confirms the signed-in user's identity with their current password (H9).
///
/// Used before the two sensitive account actions: changing the password and
/// deleting the account.  The password is never trimmed.
class ReauthenticateWithPassword {
  const ReauthenticateWithPassword(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String password}) async {
    if (password.isEmpty) {
      return const Failure<void>(Validation('password', 'required'));
    }
    return _repository.reauthenticate(password: password);
  }
}
