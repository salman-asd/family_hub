import 'package:family_hub/features/family/domain/membership.dart';

/// Read port for the signed-in user's family membership.
///
/// The Firestore implementation listens to `users/{uid}.familyId` and then
/// `families/{id}/members/{uid}`.
abstract interface class MembershipRepository {
  /// Emits the current membership immediately, then every change.
  Stream<Membership> watchMembership(String uid);
}
