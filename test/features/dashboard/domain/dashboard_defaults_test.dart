import 'package:family_hub/core/permissions/role.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_defaults.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedIds = <String>[
    'budget_alert',
    'approvals',
    'chores_today',
    'chores_overdue',
    'chores_verify',
    'bazar_month',
    'bazar_fund',
    'upcoming',
    'chores_week',
    'hub_level',
    'recent_activity',
  ];

  test('catalog is closed and sorted by the specified default order', () {
    expect(CardCatalog.cards.map((card) => card.id).toList(), expectedIds);
    expect(CardCatalog.cards.map((card) => card.defaultOrder).toList(), [
      10,
      15,
      20,
      30,
      40,
      50,
      60,
      70,
      80,
      90,
      100,
    ]);
    expect(CardCatalog.find('removed_card'), isNull);
  });

  test('catalog records size, module, and permission requirements', () {
    expect(CardCatalog.find('budget_alert')?.size, DashboardCardSize.strip);
    expect(CardCatalog.find('chores_overdue')?.size, DashboardCardSize.half);
    expect(CardCatalog.find('chores_today')?.moduleId, 'chores');
    expect(
      CardCatalog.find('chores_verify')?.requiredPermission?.name,
      'verifyChore',
    );
    expect(
      CardCatalog.find('approvals')?.anyRequiredPermissions
          .map((permission) => permission.name),
      ['approveMembers', 'recordContribution'],
    );
  });

  test('default policy follows the recommended access for every role/card', () {
    final member = <String, CardAccess>{
      'budget_alert': CardAccess.off,
      'approvals': CardAccess.hidden,
      'chores_today': CardAccess.required,
      'chores_overdue': CardAccess.on,
      'chores_verify': CardAccess.hidden,
      'bazar_month': CardAccess.on,
      'bazar_fund': CardAccess.on,
      'upcoming': CardAccess.on,
      'chores_week': CardAccess.off,
      'hub_level': CardAccess.on,
      'recent_activity': CardAccess.off,
    };

    for (final role in Role.values) {
      for (final id in expectedIds) {
        final expected = role == Role.member ? member[id]! : CardAccess.on;
        expect(
          DashboardDefaults.accessFor(role, id),
          expected,
          reason: '${role.name} / $id',
        );
        expect(
          DashboardPolicy.defaults.accessFor(role, id),
          expected,
          reason: 'policy: ${role.name} / $id',
        );
      }
    }
    expect(
      DashboardDefaults.accessFor(Role.member, 'unknown'),
      CardAccess.hidden,
    );
  });

  test('admin policy cells cannot override the always-on admin access', () {
    final policy = DashboardPolicy(
      roles: <Role, Map<String, CardAccess>>{
        Role.admin: <String, CardAccess>{
          for (final access in CardAccess.values) 'chores_today': access,
        },
      },
    );
    expect(policy.accessFor(Role.admin, 'chores_today'), CardAccess.on);
    expect(policy.roles, isEmpty);
    expect(DashboardDefaults.accessFor(Role.admin, 'unknown'), CardAccess.on);
  });

  test('unknown access values use the caller supplied catalog default', () {
    for (final role in Role.values) {
      for (final id in expectedIds) {
        final fallback = DashboardDefaults.accessFor(role, id);
        expect(CardAccess.parse('future_value', fallback: fallback), fallback);
      }
    }
    expect(CardAccess.parse('off', fallback: CardAccess.on), CardAccess.off);
  });

  test('policy and nested role maps are immutable value objects', () {
    final cells = <String, CardAccess>{'chores_today': CardAccess.off};
    final roles = <Role, Map<String, CardAccess>>{Role.member: cells};
    final policy = DashboardPolicy(roles: roles);
    cells['chores_today'] = CardAccess.hidden;
    roles.clear();

    expect(policy.accessFor(Role.member, 'chores_today'), CardAccess.off);
    expect(
      () => policy.roles[Role.member]!['new'] = CardAccess.on,
      throwsUnsupportedError,
    );
    final equivalent = DashboardPolicy(
      roles: <Role, Map<String, CardAccess>>{
        Role.member: <String, CardAccess>{'chores_today': CardAccess.off},
      },
    );
    expect(policy, equivalent);
    expect(policy.hashCode, equivalent.hashCode);
    expect(policy.copyWith(version: 2).version, 2);
  });
}
