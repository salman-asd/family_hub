import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/family/domain/family.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/module_flags.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/membership_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/modules/family_module.dart';
import 'package:family_hub/modules/module_providers.dart';
import 'package:family_hub/modules/module_registry.dart';
import 'package:family_hub/modules/module_visibility_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../family_test_helpers.dart';

/// A module that needs a permission, to prove the shell hook.
class _FinanceModule extends FamilyModule {
  const _FinanceModule();

  @override
  String get id => 'bazar';
  @override
  String get nameBn => 'বাজার';
  @override
  String get nameEn => 'Bazar';
  @override
  String label(AppLocalizations l10n) => l10n.navBazar;
  @override
  IconData get icon => const IconData(0);
  @override
  String get basePath => '/bazar';
  @override
  List<RouteBase> get routes => const <RouteBase>[];
  @override
  Permission? get requiredPermission => Permission.manageCatalogAndBudgets;
}

/// Lets the in-memory streams deliver their values to the providers.
Future<void> settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late Fixture f;

  setUp(() {
    f = Fixture()
      ..seedFamily({
        'admin': (MemberRole.admin, MembershipStatus.active),
        'mod': (MemberRole.moderator, MembershipStatus.active),
        'kid': (MemberRole.member, MembershipStatus.active),
        'wait': (MemberRole.member, MembershipStatus.pending),
      });
  });

  tearDown(() => f.backend.dispose());

  /// A container signed in as [uid]; listening keeps the stream providers hot.
  Future<ProviderContainer> signedInAs(
    String? uid, {
    ModuleRegistry? registry,
  }) async {
    final container = ProviderContainer(
      overrides: [
        currentUidProvider.overrideWithValue(uid),
        membershipRepositoryProvider.overrideWithValue(f.backend),
        membershipProvider.overrideWith(
          (ref) => uid == null
              ? Stream.value(Membership.none)
              : f.backend.watchMembership(uid),
        ),
        familyRepositoryProvider.overrideWithValue(f.backend),
        moduleFlagsRepositoryProvider.overrideWithValue(f.backend),
        if (registry != null) moduleRegistryProvider.overrideWithValue(registry),
      ],
    );
    addTearDown(container.dispose);
    container
      ..listen(membershipProvider, (_, __) {})
      ..listen(permissionSettingsProvider, (_, __) {});
    await container.read(membershipProvider.future);
    await settle();
    return container;
  }

  bool can(ProviderContainer c, Permission p, {String? ownerId}) =>
      c.read(canProvider(PermissionQuery(p, ownerId: ownerId)));

  test('the actor mirrors role and status', () async {
    final admin = await signedInAs('admin');
    expect(
      admin.read(currentActorProvider),
      const PermissionActor(uid: 'admin', role: Role.admin, isActive: true),
    );
    final pending = await signedInAs('wait');
    expect(pending.read(currentActorProvider)?.isActive, isFalse);
    final nobody = await signedInAs(null);
    expect(nobody.read(currentActorProvider), isNull);
  });

  test('canProvider answers from the policy, per role', () async {
    final admin = await signedInAs('admin');
    final mod = await signedInAs('mod');
    final kid = await signedInAs('kid');
    expect(can(admin, Permission.changeRoles), isTrue);
    expect(can(mod, Permission.changeRoles), isFalse);
    expect(can(mod, Permission.inviteMembers), isTrue);
    expect(can(kid, Permission.inviteMembers), isFalse);
    expect(can(kid, Permission.addOwnExpense), isTrue);
  });

  test('a pending member and a signed-out user can do nothing', () async {
    final pending = await signedInAs('wait');
    final nobody = await signedInAs(null);
    for (final p in Permission.values) {
      expect(can(pending, p, ownerId: 'x'), isFalse, reason: p.name);
      expect(can(nobody, p, ownerId: 'x'), isFalse, reason: p.name);
    }
  });

  test('"own" permissions need the owner id', () async {
    final kid = await signedInAs('kid');
    expect(can(kid, Permission.completeOwnChore, ownerId: 'kid'), isTrue);
    expect(can(kid, Permission.completeOwnChore, ownerId: 'mod'), isFalse);
    expect(can(kid, Permission.completeOwnChore), isFalse);
  });

  test('the family switches reach the UI answer live', () async {
    final kid = await signedInAs('kid');
    expect(can(kid, Permission.inviteMembers), isFalse);

    f.backend.permissionSettings['fam'] =
        const PermissionSettings(membersCanInvite: true);
    f.backend.backendNotify();
    await settle();
    expect(can(kid, Permission.inviteMembers), isTrue);
  });

  test('a switched-off module denies its permissions to everybody', () async {
    f.backend.families['fam'] = const Family(
      id: 'fam',
      name: 'Test family',
      modules: ModuleFlags({'bazar': false}),
    );
    final admin = await signedInAs('admin');
    expect(can(admin, Permission.recordContribution), isFalse);
    expect(can(admin, Permission.editFamilySettings), isTrue);
  });

  group('visibleModulesProvider (the shell hook)', () {
    test('a module without a requirement is visible to a member', () async {
      final kid = await signedInAs('kid');
      expect(
        kid.read(visibleModulesProvider).map((m) => m.id),
        ['chores', 'bazar'],
      );
      expect(kid.read(hiddenModulesProvider), isEmpty);
    });

    test('a module that needs a permission is hidden without it', () async {
      final registry = ModuleRegistry(const [_FinanceModule()]);
      final admin = await signedInAs('admin', registry: registry);
      final kid = await signedInAs('kid', registry: registry);
      expect(admin.read(visibleModulesProvider).map((m) => m.id), ['bazar']);
      expect(kid.read(visibleModulesProvider), isEmpty);
      expect(kid.read(hiddenModulesProvider).map((m) => m.id), ['bazar']);
    });
  });
}
