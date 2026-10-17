import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/domain/auth_repository.dart';

/// Signs the current user out.
///
/// No permission check: signing *yourself* out is always allowed.  Anything
/// that removes another member is a family-domain use case (Step 9).
class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call() => _repository.signOut();
}
