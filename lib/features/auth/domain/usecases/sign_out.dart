import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/auth/domain/auth_repository.dart';

/// Signs the current user out.
///
/// No permission check: signing *yourself* out is always allowed.  Anything
/// that removes another member is a family-domain use case (Step 9).
///
/// [afterSignOut] runs only when the sign-out succeeded (H9): the app uses it
/// to schedule a wipe of the on-disk Firestore cache, so a second person
/// signing in on the same phone never finds the first person's family data.
class SignOut {
  const SignOut(this._repository, {this._afterSignOut});

  final AuthRepository _repository;
  final Future<void> Function()? _afterSignOut;

  Future<Result<void>> call() async {
    final result = await _repository.signOut();
    if (result.isSuccess) await _afterSignOut?.call();
    return result;
  }
}
