import 'package:family_hub/app/routing/session_phase.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/presentation/membership_providers.dart';
import 'package:family_hub/features/onboarding/presentation/profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Combines auth, profile and membership into one [SessionPhase].
///
/// The first condition that holds wins, in the order of the roadmap's redirect
/// table.  Profile and membership are only watched once the step before them
/// is satisfied, so a signed-out user opens no Firestore listener at all.
final sessionPhaseProvider = Provider<SessionPhase>((ref) {
  final auth = ref.watch(authStateProvider);
  if (!auth.hasValue) {
    return auth.hasError ? SessionPhase.failed : SessionPhase.loading;
  }

  final user = auth.value;
  if (user == null) return SessionPhase.signedOut;
  if (!user.emailVerified) return SessionPhase.needsVerification;

  final hasProfile = ref.watch(hasProfileProvider);
  if (!hasProfile.hasValue) {
    return hasProfile.hasError ? SessionPhase.failed : SessionPhase.loading;
  }
  if (hasProfile.value != true) return SessionPhase.needsProfile;

  final membership = ref.watch(membershipProvider);
  if (!membership.hasValue) {
    return membership.hasError ? SessionPhase.failed : SessionPhase.loading;
  }
  return switch (membership.value!.status) {
    MembershipStatus.none => SessionPhase.needsFamily,
    MembershipStatus.pending => SessionPhase.pending,
    MembershipStatus.disabled => SessionPhase.disabled,
    MembershipStatus.active => SessionPhase.active,
  };
});

/// Re-reads everything the phase depends on (the splash screen's Retry).
void retrySession(WidgetRef ref) {
  ref
    ..invalidate(authStateProvider)
    ..invalidate(hasProfileProvider)
    ..invalidate(membershipProvider);
}
