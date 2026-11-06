import 'package:family_hub/core/permissions/permission.dart';
import 'package:family_hub/core/permissions/role.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const modules = <String, bool>{'bazar': true, 'chores': true};
  bool allowAll(Permission _) => true;
  List<String> ids(DashboardLayout layout) =>
      layout.visible.map((card) => card.definition.id).toList();

  DashboardLayout resolve({
    Role role = Role.member,
    DashboardPolicy? policy,
    DashboardPrefs? prefs,
    Map<String, bool> modulesEnabled = modules,
    DashboardCan? can,
  }) => DashboardResolver.resolve(
    role: role,
    policy: policy ?? DashboardPolicy.defaults,
    prefs: prefs ?? DashboardPrefs.defaults,
    modulesEnabled: modulesEnabled,
    can: can ?? allowAll,
  );

  test('default member layout matches Appendix A', () {
    final layout = resolve();
    expect(ids(layout), [
      'chores_today',
      'chores_overdue',
      'bazar_month',
      'bazar_fund',
      'upcoming',
      'hub_level',
    ]);
    expect(layout.optionalHidden.map((card) => card.definition.id), [
      'budget_alert',
      'chores_week',
      'recent_activity',
    ]);
    expect(layout.required.map((card) => card.definition.id), ['chores_today']);
    expect(layout.required.single.canHide, isFalse);
  });

  test('every access state resolves for each non-admin role', () {
    for (final role in <Role>[Role.member, Role.moderator]) {
      for (final access in CardAccess.values) {
        final policy = DashboardPolicy(
          roles: <Role, Map<String, CardAccess>>{
            role: <String, CardAccess>{'chores_today': access},
          },
        );
        final layout = resolve(role: role, policy: policy);
        final isVisible = ids(layout).contains('chores_today');
        expect(
          isVisible,
          access == CardAccess.on || access == CardAccess.required,
        );
        if (access == CardAccess.off) {
          expect(
            layout.optionalHidden.any(
              (card) => card.definition.id == 'chores_today',
            ),
            isTrue,
          );
        }
        if (access == CardAccess.required) {
          expect(layout.required.single.definition.id, 'chores_today');
        }
      }
    }
  });

  test('hidden access cannot be overridden by shown preferences', () {
    final policy = DashboardPolicy(
      roles: <Role, Map<String, CardAccess>>{
        Role.member: <String, CardAccess>{'bazar_fund': CardAccess.hidden},
      },
    );
    final layout = resolve(
      policy: policy,
      prefs: DashboardPrefs(shown: {'bazar_fund'}),
    );
    expect(ids(layout), isNot(contains('bazar_fund')));
    expect(
      layout.optionalHidden.map((card) => card.definition.id),
      isNot(contains('bazar_fund')),
    );
  });

  test('off cards appear only when shown and on cards hide when requested', () {
    final policy = DashboardPolicy(
      roles: <Role, Map<String, CardAccess>>{
        Role.member: <String, CardAccess>{
          'chores_week': CardAccess.off,
          'bazar_fund': CardAccess.on,
        },
      },
    );
    expect(
      ids(resolve(policy: policy, prefs: DashboardPrefs())),
      isNot(contains('chores_week')),
    );
    expect(
      ids(
        resolve(
          policy: policy,
          prefs: DashboardPrefs(shown: {'chores_week'}),
        ),
      ),
      contains('chores_week'),
    );
    expect(
      ids(
        resolve(
          policy: policy,
          prefs: DashboardPrefs(hidden: {'bazar_fund'}),
        ),
      ),
      isNot(contains('bazar_fund')),
    );
  });

  test('module switches remove all cards from the switched-off module', () {
    for (final moduleId in <String>['bazar', 'chores']) {
      final layout = resolve(
        role: Role.admin,
        modulesEnabled: <String, bool>{moduleId: false},
      );
      expect(
        layout.visible.any((card) => card.definition.moduleId == moduleId),
        isFalse,
        reason: moduleId,
      );
    }
    expect(
      resolve(modulesEnabled: const <String, bool>{}).visible
          .where((card) => card.definition.moduleId == 'core'),
      isNotEmpty,
    );
  });

  test('single and alternative permissions gate cards independently', () {
    final policy = DashboardPolicy(
      roles: <Role, Map<String, CardAccess>>{
        Role.member: <String, CardAccess>{
          'approvals': CardAccess.on,
          'chores_verify': CardAccess.on,
        },
      },
    );
    final none = resolve(policy: policy, can: (_) => false);
    expect(ids(none), isNot(contains('approvals')));
    expect(ids(none), isNot(contains('chores_verify')));

    final memberApprovals = resolve(
      policy: policy,
      can: (permission) => permission == Permission.recordContribution,
    );
    expect(ids(memberApprovals), contains('approvals'));
    expect(ids(memberApprovals), isNot(contains('chores_verify')));
  });

  test('role changes apply the new policy without deleting dormant prefs', () {
    final prefs = DashboardPrefs(
      order: ['approvals', 'chores_today'],
      shown: {'approvals'},
    );
    final manager = resolve(role: Role.moderator, prefs: prefs);
    final member = resolve(role: Role.member, prefs: prefs);
    expect(ids(manager).first, 'approvals');
    expect(ids(member), isNot(contains('approvals')));
    expect(prefs.order, contains('approvals'));
    expect(prefs.shown, contains('approvals'));
  });

  test(
    'preference ordering ignores stale ids and places new required first',
    () {
      final policy = DashboardPolicy(
        roles: <Role, Map<String, CardAccess>>{
          Role.member: <String, CardAccess>{
            'bazar_month': CardAccess.on,
            'upcoming': CardAccess.on,
            'chores_today': CardAccess.required,
            'chores_overdue': CardAccess.required,
          },
        },
      );
      final layout = resolve(
        policy: policy,
        prefs: DashboardPrefs(
          order: ['removed_card', 'upcoming', 'bazar_month'],
        ),
      );
      expect(ids(layout).take(4), [
        'chores_today',
        'chores_overdue',
        'upcoming',
        'bazar_month',
      ]);
    },
  );

  test('manager ordering follows stored ids before default order', () {
    final layout = resolve(
      role: Role.moderator,
      prefs: DashboardPrefs(order: ['upcoming', 'chores_today']),
    );
    expect(ids(layout).take(2), ['upcoming', 'chores_today']);
    expect(ids(layout).length, CardCatalog.cards.length);
  });

  test('admin access policy cannot lock out any permitted catalog card', () {
    final policy = DashboardPolicy(
      roles: <Role, Map<String, CardAccess>>{
        for (final role in Role.values)
          role: <String, CardAccess>{
            for (final card in CardCatalog.cards) card.id: CardAccess.hidden,
          },
      },
    );
    final layout = resolve(role: Role.admin, policy: policy);
    expect(layout.visible.length, CardCatalog.cards.length);
    expect(layout.optionalHidden, isEmpty);
  });

  test('unknown policy ids are ignored and resolution is deterministic', () {
    final policy = DashboardPolicy(
      roles: <Role, Map<String, CardAccess>>{
        Role.member: <String, CardAccess>{'unknown_card': CardAccess.on},
      },
    );
    final prefs = DashboardPrefs(order: ['unknown_card', 'upcoming']);
    final first = resolve(policy: policy, prefs: prefs);
    final second = resolve(policy: policy, prefs: prefs);
    expect(first, second);
    expect(ids(first), isNot(contains('unknown_card')));
    expect(ids(first).first, 'chores_today');
    expect(ids(first)[1], 'upcoming');
  });

  test(
    'preferences move, show, hide, reset, and retain immutable collections',
    () {
      final original = DashboardPrefs(
        order: ['a', 'b', 'c'],
        hidden: {'b'},
        shown: {'x'},
      );
      final moved = original.moveCard('c', 0);
      expect(moved.order, ['c', 'a', 'b']);
      expect(original.order, ['a', 'b', 'c']);
      expect(original.moveCard('missing', 0), same(original));
      expect(
        moved.setVisible('b', true, access: CardAccess.on).hidden,
        isNot(contains('b')),
      );
      expect(
        moved.setVisible('x', true, access: CardAccess.off).shown,
        contains('x'),
      );
      expect(
        moved.setVisible('a', false, access: CardAccess.on).hidden,
        contains('a'),
      );
      expect(
        moved.setVisible('a', false, access: CardAccess.required),
        same(moved),
      );
      expect(moved.reset(), DashboardPrefs.defaults);
      expect(() => moved.order.add('d'), throwsUnsupportedError);
      expect(() => moved.hidden.add('d'), throwsUnsupportedError);
    },
  );
}
