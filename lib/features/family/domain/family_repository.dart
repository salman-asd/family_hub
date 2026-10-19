import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/domain/family_event.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/membership.dart';

/// Port for family data.  Every mutating method is atomic (one batch) and
/// writes its [FamilyEvent] in the same batch.
abstract interface class FamilyRepository {
  /// ONE batch: family, owner member, settings docs, user `familyId`, event.
  Future<Result<void>> createFamily({
    required Family family,
    required Member owner,
    required FamilyEvent event,
  });

  /// The invitation behind `inviteCodes/{code}`, or `null`.
  Future<Result<Invitation?>> findInvitation(String code);

  /// Writes the invitation (code index + family mirror) and the event.
  Future<Result<void>> saveInvitation(Invitation invitation, FamilyEvent event);

  /// ONE batch: pending member, user `familyId`, invitation marked used, event.
  Future<Result<void>> requestToJoin({
    required Invitation invitation,
    required Member member,
    required FamilyEvent event,
  });

  /// The family the user currently belongs to, read from the SERVER:
  /// `users/{uid}.familyId` plus that member document.  `Membership.none` when
  /// there is no pointer or the member left / was rejected / cancelled.  Fails
  /// with `Network` when the server cannot be reached (rule 16).
  Future<Result<Membership>> getUserFamilyPointer(String uid);

  /// Marks the invitation revoked on BOTH `inviteCodes/{code}` and the family
  /// mirror, plus the event, in one batch.
  Future<Result<void>> revokeInvitation(Invitation invitation, FamilyEvent event);

  Future<Result<Member?>> getMember(String familyId, String uid);

  /// Members that are not removed.
  Future<Result<List<Member>>> getMembers(String familyId);

  /// ONE batch updating [members] (status / role / removal) plus the event.
  Future<Result<void>> saveMembers(
    String familyId,
    List<Member> members,
    FamilyEvent event,
  );

  Future<Result<void>> updateFamily(Family family, FamilyEvent event);

  Stream<List<Member>> watchMembers(String familyId);
  Stream<List<Invitation>> watchInvitations(String familyId);
  Stream<Family?> watchFamily(String familyId);
}
