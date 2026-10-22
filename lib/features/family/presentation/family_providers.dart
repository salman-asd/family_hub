import 'package:family_hub/core/utils/clock_provider.dart';
import 'package:family_hub/core/utils/time_zones.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/auth/presentation/auth_providers.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/family_seeder.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/invite_code_generator.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/relationship_catalog.dart';
import 'package:family_hub/features/family/domain/usecases/approve_member.dart';
import 'package:family_hub/features/family/domain/usecases/change_role.dart';
import 'package:family_hub/features/family/domain/usecases/create_family.dart';
import 'package:family_hub/features/family/domain/usecases/create_invitation.dart';
import 'package:family_hub/features/family/domain/usecases/disable_member.dart';
import 'package:family_hub/features/family/domain/usecases/cancel_join_request.dart';
import 'package:family_hub/features/family/domain/usecases/join_with_code.dart';
import 'package:family_hub/features/family/domain/usecases/leave_family.dart';
import 'package:family_hub/features/family/domain/usecases/member_change_runner.dart';
import 'package:family_hub/features/family/domain/usecases/reject_member.dart';
import 'package:family_hub/features/family/domain/usecases/revoke_invitation.dart';
import 'package:family_hub/features/family/domain/usecases/transfer_admin.dart';
import 'package:family_hub/features/family/domain/usecases/update_family_settings.dart';
import 'package:family_hub/features/family/domain/usecases/update_permission_settings.dart';
import 'package:family_hub/features/family/domain/usecases/update_relationship_catalog.dart';
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

final inviteCodeGeneratorProvider = Provider<InviteCodeGenerator>(
  (ref) => InviteCodeGenerator(),
);

/// Starter data written with a new family in the same batch (H12).
///
/// `bootstrap.dart` installs `DefaultCatalogSeeder`; `presentation` only knows
/// the pure-Dart `FamilySeeder` interface.
final familySeedersProvider = Provider<List<FamilySeeder>>(
  (ref) => const <FamilySeeder>[],
);

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

/// The family's IANA time zone (`settings/general.timezone`); Asia/Dhaka while
/// the family is loading, offline or absent (H12).
final familyTimezoneProvider = Provider<String>(
  (ref) =>
      ref.watch(familyProvider.select((f) => f.value?.timezone)) ??
      defaultTimezone,
);

/// Date keys in the family's zone, on the injected clock (H12).  Phase 2 stamps
/// every `dateKey` / `monthKey` through this and nothing else.
final familyDateKeysProvider = Provider<FamilyDateKeys>(
  (ref) => FamilyDateKeys(
    clock: ref.watch(clockProvider),
    timezone: ref.watch(familyTimezoneProvider),
  ),
);

/// The family's relationship list (H10).  Falls back to the built-in defaults
/// while loading, offline, outside a family (profile setup) or on an error, so a
/// screen never has to handle "no catalog".
final relationshipCatalogProvider = StreamProvider<RelationshipCatalog>((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  if (familyId == null) return Stream.value(RelationshipCatalog.defaults);
  return ref.watch(familyRepositoryProvider).watchRelationshipCatalog(familyId);
});

/// Synchronous view of [relationshipCatalogProvider] with the default fallback.
final relationshipCatalogOrDefaultProvider = Provider<RelationshipCatalog>(
  (ref) =>
      ref.watch(relationshipCatalogProvider).value ??
      RelationshipCatalog.defaults,
);

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
    seeders: ref.watch(familySeedersProvider),
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

final approveMemberProvider = Provider<ApproveMember>(
  (ref) => ApproveMember(ref.watch(_runnerProvider)),
);

final rejectMemberProvider = Provider<RejectMember>(
  (ref) => RejectMember(ref.watch(_runnerProvider), ref.watch(clockProvider)),
);

final disableMemberProvider = Provider<DisableMember>(
  (ref) => DisableMember(ref.watch(_runnerProvider)),
);

final changeRoleProvider = Provider<ChangeRole>(
  (ref) => ChangeRole(ref.watch(_runnerProvider)),
);

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

final updatePermissionSettingsProvider = Provider<UpdatePermissionSettings>(
  (ref) => UpdatePermissionSettings(
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final updateRelationshipCatalogProvider = Provider<UpdateRelationshipCatalog>(
  (ref) => UpdateRelationshipCatalog(
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final leaveFamilyProvider = Provider<LeaveFamily>(
  (ref) => LeaveFamily(
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final cancelJoinRequestProvider = Provider<CancelJoinRequest>(
  (ref) => CancelJoinRequest(
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

final revokeInvitationProvider = Provider<RevokeInvitation>(
  (ref) => RevokeInvitation(
    families: ref.watch(familyRepositoryProvider),
    clock: ref.watch(clockProvider),
    newId: ref.watch(idGeneratorProvider),
  ),
);

/// True while the signed-in user is the only active admin, so "Leave family"
/// is explained instead of failing (the use case enforces it too).
final soleAdminProvider = Provider<bool>((ref) {
  final uid = ref.watch(currentUidProvider);
  final members = ref.watch(membersProvider).value;
  if (uid == null || members == null) return false;
  final admins = members.where((m) => m.isActiveAdmin).toList();
  return admins.length == 1 && admins.single.uid == uid;
});
