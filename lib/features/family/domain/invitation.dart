import 'package:family_hub/features/family/domain/member_role.dart';

enum InvitationStatus {
  active,
  used,
  revoked;

  static InvitationStatus parse(String? v) => InvitationStatus.values
      .firstWhere((s) => s.name == v, orElse: () => InvitationStatus.revoked);
}

/// An invitation code (`inviteCodes/{code}` mirrored in
/// `families/{id}/invitations/{code}`).
class Invitation {
  const Invitation({
    required this.code,
    required this.familyId,
    required this.role,
    required this.expiresAt,
    required this.createdBy,
    required this.createdAt,
    this.status = InvitationStatus.active,
    this.usedBy,
  });

  /// Length of generated codes.
  static const int codeLength = 8;

  final String code;
  final String familyId;
  final MemberRole role;
  final DateTime expiresAt;
  final String createdBy;
  final DateTime createdAt;
  final InvitationStatus status;
  final String? usedBy;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  Invitation markUsed(String uid) => Invitation(
    code: code,
    familyId: familyId,
    role: role,
    expiresAt: expiresAt,
    createdBy: createdBy,
    createdAt: createdAt,
    status: InvitationStatus.used,
    usedBy: uid,
  );

  Invitation markRevoked() => Invitation(
    code: code,
    familyId: familyId,
    role: role,
    expiresAt: expiresAt,
    createdBy: createdBy,
    createdAt: createdAt,
    status: InvitationStatus.revoked,
    usedBy: usedBy,
  );
}
