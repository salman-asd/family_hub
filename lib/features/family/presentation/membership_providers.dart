import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/membership_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` (TODO(step-9): Firestore implementation) and
/// in tests.
final membershipRepositoryProvider = Provider<MembershipRepository>(
  (ref) => throw UnimplementedError(
    'membershipRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// The signed-in user's membership.  Restarts when the uid changes.
final membershipProvider = StreamProvider<Membership>((ref) {
  final uid = ref.watch(authStateProvider.select((v) => v.value?.uid));
  if (uid == null) return Stream.value(Membership.none);
  return ref.watch(membershipRepositoryProvider).watchMembership(uid);
});
