import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/permissions/role.dart';
import 'package:family_hub/features/dashboard/data/dashboard_policy_mappers.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_defaults.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final metadata = BaseDocumentMetadata(
    createdAt: DateTime.utc(2026, 11),
    createdBy: 'admin',
    updatedAt: DateTime.utc(2026, 11),
    updatedBy: 'admin',
  );

  test('dashboard policy mapper round-trips known role cells and version', () {
    final policy = DashboardPolicy(
      version: 4,
      roles: <Role, Map<String, CardAccess>>{
        Role.moderator: <String, CardAccess>{
          'approvals': CardAccess.on,
          'chores_verify': CardAccess.hidden,
        },
        Role.member: <String, CardAccess>{
          'chores_today': CardAccess.required,
          'recent_activity': CardAccess.off,
        },
      },
    );

    final decoded = DashboardPolicyMappers.policyFromMap(
      DashboardPolicyMappers.policyToMap(policy, metadata),
    );
    expect(decoded, policy);
    expect(decoded.hashCode, policy.hashCode);
  });

  test('absent and malformed policy data safely use defaults', () {
    expect(
      DashboardPolicyMappers.policyFromMap(null),
      DashboardPolicy.defaults,
    );
    final policy = DashboardPolicyMappers.policyFromMap(<String, dynamic>{
      'version': 'bad',
      'roles': <String, dynamic>{
        'admin': <String, dynamic>{'chores_today': 'off'},
        'member': <String, dynamic>{
          'removed_card': 'on',
          'chores_today': 'future_access',
          'bazar_fund': 12,
        },
        'unknown_role': <String, dynamic>{'chores_today': 'off'},
      },
    });

    expect(policy.version, 1);
    expect(policy.roles.containsKey(Role.admin), isFalse);
    expect(policy.roles.containsKey(Role.moderator), isFalse);
    expect(
      policy.accessFor(Role.member, 'chores_today'),
      DashboardDefaults.accessFor(Role.member, 'chores_today'),
    );
    expect(policy.accessFor(Role.member, 'removed_card'), CardAccess.hidden);
  });

  test(
    'dashboard preference mapper drops unknown, malformed, and duplicate ids',
    () {
      final prefs = DashboardPolicyMappers.dashboardPrefsFromMap(
        <String, dynamic>{
          'order': <Object?>['chores_today', 'removed', 7, 'chores_today'],
          'hidden': <Object?>['recent_activity', 'x' * 41],
          'shown': 'invalid',
          'futureField': true,
        },
      );
      expect(prefs.order, ['chores_today']);
      expect(prefs.hidden, {'recent_activity'});
      expect(prefs.shown, isEmpty);
      expect(
        DashboardPolicyMappers.dashboardPrefsFromMap(null),
        DashboardPrefs.defaults,
      );
    },
  );

  test('preference mapper bounds output and preserves catalog ids', () {
    final prefs = DashboardPrefs(
      order: <String>[
        'chores_today',
        'unknown',
        ...List<String>.filled(DashboardPrefs.maxPreferenceIds, 'upcoming'),
      ],
      hidden: {'bazar_fund'},
      shown: {'chores_week'},
    );
    final map = DashboardPolicyMappers.dashboardPrefsToMap(prefs);
    expect(map.keys, {'order', 'hidden', 'shown'});
    expect(
      (map['order'] as List<String>).length,
      DashboardPrefs.maxPreferenceIds,
    );
    expect(map['hidden'], ['bazar_fund']);
    expect(map['shown'], ['chores_week']);
  });
}
