import 'package:family_hub/core/permissions/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

/// The matrix of roadmap 2.2 as implemented by [PermissionPolicy].
///
/// `(permission, admin, moderator, member)` — the answers when *nothing but the
/// role* can block the permission (active actor, modules on, the right owner).
const List<(Permission, bool, bool, bool)> _matrix =
    <(Permission, bool, bool, bool)>[
  // Family administration.
  (Permission.inviteMembers, true, true, false),
  (Permission.approveMembers, true, true, false),
  (Permission.removeMembers, true, false, false),
  (Permission.changeRoles, true, false, false),
  (Permission.editFamilySettings, true, false, false),
  (Permission.viewFamilyReports, true, true, true),
  (Permission.exportData, true, false, false),
  // Bazar and family finance.
  (Permission.manageCatalogAndBudgets, true, true, false),
  (Permission.addOwnExpense, true, true, true),
  (Permission.editOthersExpense, true, true, false),
  (Permission.recordContribution, true, true, false),
  // Chores.
  (Permission.manageChoreTemplates, true, true, false),
  (Permission.reassignChore, true, true, false),
  (Permission.requestSwap, true, true, true),
  (Permission.completeOwnChore, true, true, true),
  (Permission.commentOnChore, true, true, true),
  (Permission.verifyChore, true, true, false),
];

/// A context where only the role can make the answer false.
({String? ownerId, PermissionSettings settings, PermissionTemplate? template})
    _contextFor(Permission permission) {
  const settings = PermissionSettings(choreVerificationEnabled: true);
  return switch (permission) {
    // "Own" permissions: the actor owns the record.
    Permission.requestSwap ||
    Permission.completeOwnChore =>
      (ownerId: 'me', settings: settings, template: null),
    // Verification: family and template both want it, and somebody else did it.
    Permission.verifyChore => (
        ownerId: 'other',
        settings: settings,
        template: const PermissionTemplate(verificationEnabled: true),
      ),
    _ => (ownerId: 'other', settings: settings, template: null),
  };
}

bool _can(
  Role role,
  Permission permission, {
  bool isActive = true,
  String? ownerId = 'other',
  PermissionSettings settings =
      const PermissionSettings(choreVerificationEnabled: true),
  PermissionTemplate? template,
}) =>
    PermissionPolicy.can(
      PermissionActor(uid: 'me', role: role, isActive: isActive),
      permission,
      ownerId: ownerId,
      settings: settings,
      template: template,
    );

bool _canWithContext(Role role, Permission permission) {
  final ctx = _contextFor(permission);
  return _can(
    role,
    permission,
    ownerId: ctx.ownerId,
    settings: ctx.settings,
    template: ctx.template,
  );
}

void main() {
  group('PermissionPolicy.can — the table', () {
    test('covers every permission exactly once', () {
      final listed = _matrix.map((r) => r.$1).toList();
      expect(listed.toSet(), Permission.values.toSet());
      expect(listed.length, Permission.values.length);
    });

    for (final (permission, admin, moderator, member) in _matrix) {
      test(
        '${permission.name}: admin=$admin moderator=$moderator member=$member',
        () {
          expect(_canWithContext(Role.admin, permission), admin,
              reason: 'admin');
          expect(_canWithContext(Role.moderator, permission), moderator,
              reason: 'moderator');
          expect(_canWithContext(Role.member, permission), member,
              reason: 'member');
        },
      );
    }
  });

  group('PermissionPolicy.can — an actor who is not active', () {
    for (final role in Role.values) {
      for (final permission in Permission.values) {
        test('${role.name} may not ${permission.name}', () {
          final ctx = _contextFor(permission);
          expect(
            _can(
              role,
              permission,
              isActive: false,
              ownerId: ctx.ownerId,
              settings: ctx.settings,
              template: ctx.template,
            ),
            isFalse,
          );
        });
      }
    }
  });

  group('module switches', () {
    test('switching bazar off denies every bazar permission, even to an admin',
        () {
      const off = PermissionSettings(bazarEnabled: false);
      final bazar =
          Permission.values.where((p) => p.module == PermissionModule.bazar);
      expect(bazar, isNotEmpty);
      for (final permission in bazar) {
        final ctx = _contextFor(permission);
        expect(
          _can(
            Role.admin,
            permission,
            ownerId: ctx.ownerId,
            settings: off,
            template: ctx.template,
          ),
          isFalse,
          reason: permission.name,
        );
      }
    });

    test('switching bazar off leaves the other modules alone', () {
      const off = PermissionSettings(bazarEnabled: false);
      expect(_can(Role.member, Permission.addOwnExpense, settings: off),
          isFalse);
      expect(_can(Role.admin, Permission.inviteMembers, settings: off), isTrue);
      expect(
        _can(Role.admin, Permission.commentOnChore, settings: off),
        isTrue,
      );
    });

    test('switching chores off denies every chore permission, even to an admin',
        () {
      const off = PermissionSettings(
        choresEnabled: false,
        choreVerificationEnabled: true,
      );
      final chores =
          Permission.values.where((p) => p.module == PermissionModule.chores);
      expect(chores, isNotEmpty);
      for (final permission in chores) {
        final ctx = _contextFor(permission);
        expect(
          _can(
            Role.admin,
            permission,
            ownerId: ctx.ownerId,
            settings: off,
            template: ctx.template,
          ),
          isFalse,
          reason: permission.name,
        );
      }
    });

    test('family administration is never switchable', () {
      const off = PermissionSettings(bazarEnabled: false, choresEnabled: false);
      expect(_can(Role.admin, Permission.editFamilySettings, settings: off),
          isTrue);
    });
  });

  group('own records', () {
    test('requestSwap needs the actor to be the assignee', () {
      expect(_can(Role.member, Permission.requestSwap, ownerId: 'me'), isTrue);
      expect(_can(Role.member, Permission.requestSwap, ownerId: 'other'),
          isFalse);
      expect(_can(Role.admin, Permission.requestSwap, ownerId: 'other'),
          isFalse);
    });

    test('completeOwnChore needs the actor to be the assignee', () {
      expect(
        _can(Role.member, Permission.completeOwnChore, ownerId: 'me'),
        isTrue,
      );
      expect(_can(Role.member, Permission.completeOwnChore, ownerId: 'other'),
          isFalse);
    });

    test('an unknown owner is never "own"', () {
      expect(_can(Role.member, Permission.completeOwnChore, ownerId: null),
          isFalse);
      expect(_can(Role.admin, Permission.requestSwap, ownerId: null), isFalse);
    });
  });

  group('verifyChore is the most conditional cell', () {
    const familyOn = PermissionSettings(choreVerificationEnabled: true);
    const familyOff = PermissionSettings();
    const templateOn = PermissionTemplate(verificationEnabled: true);
    const templateOff = PermissionTemplate();

    test('allowed for a manager when family, template and owner all agree', () {
      expect(
        _can(Role.admin, Permission.verifyChore,
            ownerId: 'other', settings: familyOn, template: templateOn),
        isTrue,
      );
      expect(
        _can(Role.moderator, Permission.verifyChore,
            ownerId: 'other', settings: familyOn, template: templateOn),
        isTrue,
      );
    });

    test('never allowed for a plain member', () {
      expect(
        _can(Role.member, Permission.verifyChore,
            ownerId: 'other', settings: familyOn, template: templateOn),
        isFalse,
      );
    });

    test('denied while the family has verification off', () {
      expect(
        _can(Role.admin, Permission.verifyChore,
            ownerId: 'other', settings: familyOff, template: templateOn),
        isFalse,
      );
    });

    test('denied when the template does not allow it', () {
      expect(
        _can(Role.admin, Permission.verifyChore,
            ownerId: 'other', settings: familyOn, template: templateOff),
        isFalse,
      );
      expect(
        _can(Role.admin, Permission.verifyChore,
            ownerId: 'other', settings: familyOn),
        isFalse,
      );
    });

    test('nobody verifies their own chore', () {
      expect(
        _can(Role.admin, Permission.verifyChore,
            ownerId: 'me', settings: familyOn, template: templateOn),
        isFalse,
      );
    });

    test('an unknown completer cannot be verified', () {
      expect(
        _can(Role.admin, Permission.verifyChore,
            ownerId: null, settings: familyOn, template: templateOn),
        isFalse,
      );
    });
  });

  group('PermissionActor', () {
    test('reports manager and admin for an active actor', () {
      const admin = PermissionActor(uid: 'a', role: Role.admin, isActive: true);
      const moderator =
          PermissionActor(uid: 'b', role: Role.moderator, isActive: true);
      const member =
          PermissionActor(uid: 'c', role: Role.member, isActive: true);
      expect(admin.isAdmin, isTrue);
      expect(admin.isManager, isTrue);
      expect(moderator.isAdmin, isFalse);
      expect(moderator.isModerator, isTrue);
      expect(moderator.isManager, isTrue);
      expect(member.isManager, isFalse);
    });

    test('an inactive actor is never an admin or a manager', () {
      const removed = PermissionActor(
        uid: 'a',
        role: Role.admin,
        isActive: false,
      );
      expect(removed.isAdmin, isFalse);
      expect(removed.isManager, isFalse);
    });

    test('is a value object', () {
      const one = PermissionActor(uid: 'a', role: Role.admin, isActive: true);
      const same = PermissionActor(uid: 'a', role: Role.admin, isActive: true);
      const other = PermissionActor(
        uid: 'a',
        role: Role.member,
        isActive: true,
      );
      expect(one, same);
      expect(one.hashCode, same.hashCode);
      expect(one, isNot(other));
    });
  });

  group('Permission.module', () {
    test('every permission belongs to exactly one module', () {
      final family = Permission.values
          .where((p) => p.module == PermissionModule.family)
          .length;
      final bazar = Permission.values
          .where((p) => p.module == PermissionModule.bazar)
          .length;
      final chores = Permission.values
          .where((p) => p.module == PermissionModule.chores)
          .length;
      expect(family + bazar + chores, Permission.values.length);
    });

    test('the roadmap names are unchanged (they are the contract)', () {
      expect(
        Permission.values.map((p) => p.name).toSet(),
        {
          'inviteMembers',
          'approveMembers',
          'removeMembers',
          'changeRoles',
          'editFamilySettings',
          'manageChoreTemplates',
          'reassignChore',
          'requestSwap',
          'completeOwnChore',
          'commentOnChore',
          'verifyChore',
          'addOwnExpense',
          'editOthersExpense',
          'manageCatalogAndBudgets',
          'recordContribution',
          'viewFamilyReports',
          'exportData',
        },
      );
    });
  });
}
