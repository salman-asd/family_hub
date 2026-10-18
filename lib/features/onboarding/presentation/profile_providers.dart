import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/onboarding/domain/profile_repository.dart';
import 'package:family_hub/features/onboarding/domain/usecases/save_profile.dart';
import 'package:family_hub/features/onboarding/domain/user_profile.dart';
import 'package:family_hub/features/onboarding/domain/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` (TODO(step-9): Firestore implementation) and
/// in tests.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => throw UnimplementedError(
    'profileRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// Whether the signed-in user already has a profile document.
final hasProfileProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(authStateProvider.select((v) => v.value?.uid));
  if (uid == null) return Stream.value(false);
  return ref.watch(profileRepositoryProvider).watchHasProfile(uid);
});

/// Read/write port for the profile.  Overridden in `bootstrap.dart` and tests.
final userProfileRepositoryProvider = Provider<UserProfileRepository>(
  (ref) => throw UnimplementedError(
    'userProfileRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

/// The signed-in user's profile (`null` until created).
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(authStateProvider.select((v) => v.value?.uid));
  if (uid == null) return Stream.value(null);
  return ref.watch(userProfileRepositoryProvider).watchProfile(uid);
});

final saveProfileProvider = Provider<SaveProfile>(
  (ref) => SaveProfile(ref.watch(userProfileRepositoryProvider)),
);
