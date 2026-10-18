import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/invite_code_generator.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/usecases/approve_member.dart';
import 'package:family_hub/features/family/domain/usecases/change_role.dart';
import 'package:family_hub/features/family/domain/usecases/create_family.dart';
import 'package:family_hub/features/family/domain/usecases/create_invitation.dart';
import 'package:family_hub/features/family/domain/usecases/disable_member.dart';
import 'package:family_hub/features/family/domain/usecases/join_with_code.dart';
import 'package:family_hub/features/family/domain/usecases/member_change_runner.dart';
import 'package:family_hub/features/family/domain/usecases/reject_member.dart';
import 'package:family_hub/features/family/domain/usecases/transfer_admin.dart';
import 'package:family_hub/features/family/domain/usecases/update_family_settings.dart';
import 'package:family_hub/features/family/presentation/membership_providers.dart';
import 'package:family_hub/features/onboarding/presentation/profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Overridden in `bootstrap.dart` and in tests.
final familyRepositoryProvider = Provider<FamilyRepository>(
  (ref) => throw UnimplementedError(
    'familyRepositoryProvider must be overridden (bootstrap.dart / tests).',
  ),
);

final idGeneratorProvider = Provider<IdGenerator>((ref) => randomId);

final inviteCodeGeneratorProvider =
    Provider<InviteCodeGenerator>((ref) => InviteCodeGenerator());

/// uid of the signed-in user, or `null`.
final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider.select((v) => v.value?.uid)),
);

/// Family the user belongs to (active or pending).
final currentFamilyIdProvider = Provider<String?>(
  (ref) => ref.watch(membershipProvider.select((v) => v.value?.familyId)),
);

final membersProvider = StreamProvider<List<Member>>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) return Stream.value(const <Member>[]);
  return ref.watch(familyRepositoryProvider).watchMembers(familyId);
});

final invitationsProvider = StreamProvider<List<Invitation>>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) return Stream.value(const <Invitation>[]);
  return ref.watch(familyRepositoryProvider).watchInvitations(familyId);
});

final familyProvider = StreamProvider<Family?>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) return Stream.value(null);
  return ref.watch(familyRepositoryProvider).watchFamily(familyId);
});

// ── Use cases ─────────────────────────────────────────────────────────────

final _runnerProvider = Provider<MemberChangeRunner>(
  (ref) => MemberChangeRunner(
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final createFamilyProvider = Provider<CreateFamily>(
  (ref) => CreateFamily(
    families: ref.watch(familyRepositoryProvider),
    profiles: ref.watch(userProfileRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final joinWithCodeProvider = Provider<JoinWithCode>(
  (ref) => JoinWithCode(
    families: ref.watch(familyRepositoryProvider),
    profiles: ref.watch(userProfileRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final createInvitationProvider = Provider<CreateInvitation>(
  (ref) => CreateInvitation(
    families: ref.watch(familyRepositoryProvider),
    codes: ref.watch(inviteCodeGeneratorProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final approveMemberProvider =
    Provider<ApproveMember>((ref) => ApproveMember(ref.watch(_runnerProvider)));

final rejectMemberProvider = Provider<RejectMember>(
  (ref) => RejectMember(ref.watch(_runnerProvider), ref.watch(clockProvider)),
);

final disableMemberProvider =
    Provider<DisableMember>((ref) => DisableMember(ref.watch(_runnerProvider)));

final changeRoleProvider =
    Provider<ChangeRole>((ref) => ChangeRole(ref.watch(_runnerProvider)));

final transferAdminProvider = Provider<TransferAdmin>(
  (ref) => TransferAdmin(
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final updateFamilySettingsProvider = Provider<UpdateFamilySettings>(
  (ref) => UpdateFamilySettings(
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);
