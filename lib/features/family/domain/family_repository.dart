import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/membership.dart';

/// Port for family data.  Every mutating method is atomic (one batch) and
/// writes its [AuditEvent] in the same batch.
abstract interface class FamilyRepository {
  /// ONE batch: family, owner member, settings docs, user `familyId`, event.
  Future<Result<void>> createFamily({
    required Family family,
    required Member owner,
    required AuditEvent event,
  });

  /// The invitation behind `inviteCodes/{code}`, or `null`.
  Future<Result<Invitation?>> findInvitation(String code);

  /// Writes the invitation (code index + family mirror) and the event.
  Future<Result<void>> saveInvitation(Invitation invitation, AuditEvent event);

  /// ONE batch: pending member, user `familyId`, invitation marked used, event.
  Future<Result<void>> requestToJoin({
    required Invitation invitation,
    required Member member,
    required AuditEvent event,
  });

  /// The family the user currently belongs to, read from the SERVER:
  /// `users/{uid}.familyId` plus that member document.  `Membership.none` when
  /// there is no pointer or the member left / was rejected / cancelled.  Fails
  /// with `Network` when the server cannot be reached (rule 16).
  Future<Result<Membership>> getUserFamilyPointer(String uid);

  /// Marks the invitation revoked on BOTH `inviteCodes/{code}` and the family
  /// mirror, plus the event, in one batch.
  Future<Result<void>> revokeInvitation(Invitation invitation, AuditEvent event);

  Future<Result<Member?>> getMember(String familyId, String uid);

  /// Members that are not removed.
  Future<Result<List<Member>>> getMembers(String familyId);

  /// ONE batch updating [members] (status / role / removal) plus the event.
  ///
  /// When the active-admin set changes (H6) the caller passes the new
  /// [adminIds]; the family document is written in the SAME batch so the rules
  /// can prove the family never loses its last admin.  `null` means the set is
  /// unchanged and the family document is left alone (a moderator may still
  /// approve or reject without being an admin).
  Future<Result<void>> saveMembers(
    String familyId,
    List<Member> members,
    AuditEvent event, {
    List<String>? adminIds,
  });

  Future<Result<void>> updateFamily(Family family, AuditEvent event);

  /// `families/{f}/settings/permissions` (H7); the defaults while the document
  /// does not exist.  An unreadable document is a failure, never a guess.
  Future<Result<PermissionSettings>> getPermissionSettings(String familyId);

  /// Writes the permission switches plus the event in ONE batch.
  Future<Result<void>> updatePermissionSettings(
    String familyId,
    PermissionSettings settings,
    AuditEvent event,
  );

  /// The family's permission switches; module switches are NOT part of it
  /// (they come from `settings/modules`).
  Stream<PermissionSettings> watchPermissionSettings(String familyId);

  Stream<List<Member>> watchMembers(String familyId);
  Stream<List<Invitation>> watchInvitations(String familyId);
  Stream<Family?> watchFamily(String familyId);
}
