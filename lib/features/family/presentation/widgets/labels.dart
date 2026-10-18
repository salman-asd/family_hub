import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/features/family/domain/invitation.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/relationship.dart';

/// Localized names for the family enums.
extension FamilyLabels on AppLocalizations {
  String relationshipLabel(Relationship r) => switch (r) {
        Relationship.father => relFather,
        Relationship.mother => relMother,
        Relationship.son => relSon,
        Relationship.daughter => relDaughter,
        Relationship.husband => relHusband,
        Relationship.wife => relWife,
        Relationship.housewife => relHousewife,
        Relationship.daughterInLaw => relDaughterInLaw,
        Relationship.sonInLaw => relSonInLaw,
        Relationship.other => relOther,
      };

  String genderLabel(Gender g) => switch (g) {
        Gender.male => genderMale,
        Gender.female => genderFemale,
        Gender.other => genderOther,
      };

  String roleLabel(MemberRole r) => switch (r) {
        MemberRole.admin => roleAdmin,
        MemberRole.moderator => roleModerator,
        MemberRole.member => roleMember,
      };

  String statusLabel(MembershipStatus s) => switch (s) {
        MembershipStatus.active => membersActive,
        MembershipStatus.pending => membersPending,
        MembershipStatus.disabled => membersDisabled,
        MembershipStatus.none => membersDisabled,
      };

  String invitationStatusLabel(Invitation i, DateTime now) {
    if (i.status == InvitationStatus.used) return invStatusUsed;
    if (i.status == InvitationStatus.revoked) return invStatusRevoked;
    return i.isExpiredAt(now) ? invStatusExpired : invStatusActive;
  }
}
