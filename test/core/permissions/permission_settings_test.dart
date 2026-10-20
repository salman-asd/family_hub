import 'package:family_hub/core/permissions/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

/// H7: the configurable cells of the matrix follow `settings/permissions`.
void main() {
  bool can(
    Role role,
    Permission permission, {
    PermissionSettings settings = PermissionSettings.defaults,
    bool active = true,
  }) =>
      PermissionPolicy.can(
        PermissionActor(uid: 'me', role: role, isActive: active),
        permission,
        ownerId: 'other',
        settings: settings,
      );

  group('moderatorManagesFinance', () {
    const off = PermissionSettings(moderatorManagesFinance: false);

    test('is on by default: a moderator manages budgets and contributions', () {
      expect(can(Role.moderator, Permission.manageCatalogAndBudgets), isTrue);
      expect(can(Role.moderator, Permission.recordContribution), isTrue);
    });

    test('off: a moderator loses both, an admin keeps them', () {
      expect(
        can(Role.moderator, Permission.manageCatalogAndBudgets, settings: off),
        isFalse,
      );
      expect(
        can(Role.moderator, Permission.recordContribution, settings: off),
        isFalse,
      );
      expect(
        can(Role.admin, Permission.manageCatalogAndBudgets, settings: off),
        isTrue,
      );
      expect(
        can(Role.admin, Permission.recordContribution, settings: off),
        isTrue,
      );
    });

    test('off: a moderator may still add expenses and see everything', () {
      expect(can(Role.moderator, Permission.addOwnExpense, settings: off),
          isTrue);
      expect(can(Role.moderator, Permission.editOthersExpense, settings: off),
          isTrue);
      expect(can(Role.moderator, Permission.viewAllContributions,
          settings: off), isTrue);
    });
  });

  group('membersViewFamilyReports', () {
    const off = PermissionSettings(membersViewFamilyReports: false);

    test('on by default', () {
      expect(can(Role.member, Permission.viewFamilyReports), isTrue);
    });

    test('off: a member loses reports, managers keep them', () {
      expect(can(Role.member, Permission.viewFamilyReports, settings: off),
          isFalse);
      expect(can(Role.moderator, Permission.viewFamilyReports, settings: off),
          isTrue);
      expect(can(Role.admin, Permission.viewFamilyReports, settings: off),
          isTrue);
    });
  });

  group('membersViewAllContributions', () {
    const on = PermissionSettings(membersViewAllContributions: true);

    test('off by default: members see only their own', () {
      expect(can(Role.member, Permission.viewAllContributions), isFalse);
    });

    test('on: a member sees every contribution', () {
      expect(can(Role.member, Permission.viewAllContributions, settings: on),
          isTrue);
    });

    test('a switched-off bazar module still wins', () {
      final bazarOff = on.copyWith(bazarEnabled: false);
      expect(
        can(Role.member, Permission.viewAllContributions, settings: bazarOff),
        isFalse,
      );
    });
  });

  group('membersCanInvite', () {
    const on = PermissionSettings(membersCanInvite: true);

    test('off by default', () {
      expect(can(Role.member, Permission.inviteMembers), isFalse);
    });

    test('on: an ACTIVE member may invite, a pending one may not', () {
      expect(can(Role.member, Permission.inviteMembers, settings: on), isTrue);
      expect(
        can(Role.member, Permission.inviteMembers, settings: on, active: false),
        isFalse,
      );
    });

    test('on: approving requests stays a manager right', () {
      expect(can(Role.member, Permission.approveMembers, settings: on),
          isFalse);
    });
  });

  group('PermissionSettings', () {
    test('defaults follow CLAUDE.md', () {
      const d = PermissionSettings.defaults;
      expect(d.bazarEnabled, isTrue);
      expect(d.choresEnabled, isTrue);
      expect(d.moderatorManagesFinance, isTrue);
      expect(d.membersViewFamilyReports, isTrue);
      expect(d.membersViewAllContributions, isFalse);
      expect(d.membersCanInvite, isFalse);
      expect(d.choreVerificationEnabled, isFalse);
    });

    test('copyWith changes one field and equality sees every field', () {
      const base = PermissionSettings.defaults;
      expect(base.copyWith(), base);
      expect(base.copyWith(membersCanInvite: true), isNot(base));
      expect(base.copyWith(membersCanInvite: true).hashCode,
          isNot(base.hashCode));
      for (final changed in <PermissionSettings>[
        base.copyWith(bazarEnabled: false),
        base.copyWith(choresEnabled: false),
        base.copyWith(moderatorManagesFinance: false),
        base.copyWith(membersViewFamilyReports: false),
        base.copyWith(membersViewAllContributions: true),
        base.copyWith(membersCanInvite: true),
        base.copyWith(choreVerificationEnabled: true),
      ]) {
        expect(changed, isNot(base), reason: changed.toString());
      }
    });
  });
}
