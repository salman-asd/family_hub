import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/domain/auth_repository.dart';

/// (Re)sends the verification email for the signed-in account.
///
/// Requires a signed-in user with an unverified address; this is the same rule
/// the repository's `FirebaseAuth.currentUser` naturally enforces, but we
/// return a typed failure instead of relying on a null check downstream.
class SendEmailVerification {
  const SendEmailVerification(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required bool isSignedIn}) async {
    if (!isSignedIn) {
      return const Failure<void>(PermissionDenied());
    }
    return _repository.sendEmailVerification();
  }
}
