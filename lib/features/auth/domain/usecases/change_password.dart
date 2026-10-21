import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/domain/auth_credentials.dart';
import 'package:family_hub/features/auth/domain/auth_repository.dart';

/// Changes the signed-in user's password (H9).
///
/// Re-authenticates with [currentPassword] first, then sets [newPassword].  The
/// new password follows the sign-up rule (at least
/// [AuthCredentials.minPasswordLength] characters) and must differ from the
/// current one.  Nothing is trimmed.
class ChangePassword {
  const ChangePassword(this._repository);

  final AuthRepository _repository;

  /// Validation code for "new password equals the current one".
  static const String codeSameAsCurrent = 'password_same';

  Future<Result<void>> call({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword.isEmpty) {
      return const Failure<void>(Validation('current_password', 'required'));
    }
    final checked = AuthCredentials.checkPassword(newPassword);
    final invalid = checked.failureOrNull;
    if (invalid != null) return Failure<void>(invalid);
    if (newPassword == currentPassword) {
      return const Failure<void>(Validation('password', codeSameAsCurrent));
    }

    final reauth = await _repository.reauthenticate(password: currentPassword);
    final reauthFailure = reauth.failureOrNull;
    if (reauthFailure != null) return Failure<void>(reauthFailure);

    return _repository.changePassword(newPassword: newPassword);
  }
}
