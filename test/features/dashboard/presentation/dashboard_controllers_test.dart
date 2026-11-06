import 'package:family_hub/core/permissions/permission_settings.dart';
import 'package:family_hub/core/permissions/role.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_access_preview.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual reorder and drag reorder produce the same final order', () {
    const ids = <String>['a', 'b', 'c'];

    expect(
      DashboardPrefsOrder.move(DashboardPrefs.defaults, ids, 1, 1).order,
      <String>['a', 'c', 'b'],
    );
    expect(
      DashboardPrefsOrder.reorder(DashboardPrefs.defaults, ids, 0, 2).order,
      <String>['b', 'c', 'a'],
    );
  });

  test('required cards cannot be hidden in personal preferences', () {
    final next = DashboardPrefs.defaults.setVisible(
      'chores_today',
      false,
      access: CardAccess.required,
    );
    expect(next, DashboardPrefs.defaults);
  });

  test('visibility controls preserve the four dashboard access states', () {
    final visible = DashboardPrefs.defaults.setVisible(
      'budget_alert',
      true,
      access: CardAccess.off,
    );
    expect(visible.shown, contains('budget_alert'));

    final hidden = visible.setVisible(
      'bazar_fund',
      false,
      access: CardAccess.on,
    );
    expect(hidden.hidden, contains('bazar_fund'));
    expect(hidden.shown, contains('budget_alert'));
  });

  test('access-by-role preview uses catalog resolver and permissions', () {
    final settings = PermissionSettings.defaults.copyWith(
      choreVerificationEnabled: true,
    );
    final verifyCard = CardCatalog.find('chores_verify')!;

    expect(
      DashboardAccessPreview.canRoleSeeCard(
        Role.moderator,
        verifyCard,
        settings,
      ),
      isTrue,
    );
    expect(
      DashboardAccessPreview.canRoleSeeCard(Role.member, verifyCard, settings),
      isFalse,
    );

    final memberPreview = DashboardAccessPreview.resolve(
      role: Role.member,
      policy: DashboardPolicy.defaults,
      modulesEnabled: const <String, bool>{'bazar': true, 'chores': true},
      settings: settings,
    );
    expect(
      memberPreview.visible.map((card) => card.definition.id),
      containsAll(<String>['chores_today', 'bazar_fund', 'upcoming']),
    );
    expect(
      memberPreview.visible.map((card) => card.definition.id),
      isNot(contains('chores_verify')),
    );
  });
}
