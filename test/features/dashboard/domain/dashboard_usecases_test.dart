import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permission_settings.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy_repository.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs_repository.dart';
import 'package:family_hub/features/dashboard/domain/usecases/save_dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/usecases/update_dashboard_policy.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../family/family_test_helpers.dart';

void main() {
  group('UpdateDashboardPolicy', () {
    late Fixture fixture;
    late _PolicyRepository policies;
    late UpdateDashboardPolicy update;

    setUp(() {
      fixture = Fixture()
        ..seedFamily({
          'admin': (MemberRole.admin, MembershipStatus.active),
          'manager': (MemberRole.moderator, MembershipStatus.active),
          'member': (MemberRole.member, MembershipStatus.active),
        });
      policies = _PolicyRepository();
      update = UpdateDashboardPolicy(
        families: fixture.backend,
        policies: policies,
        clock: fixture.clock,
        newId: fixture.ids.call,
      );
    });

    test(
      'manager saves validated roles with an audit event and next version',
      () async {
        policies.current = DashboardPolicy(
          version: 3,
          roles: const <Role, Map<String, CardAccess>>{},
        );
        final result = await update(
          actorUid: 'manager',
          familyId: 'fam',
          roles: const <String, Map<String, String>>{
            'member': {'chores_today': 'required', 'bazar_fund': 'on'},
          },
        );

        expect(result.valueOrNull?.version, 4);
        expect(
          result.valueOrNull?.accessFor(Role.member, 'chores_today'),
          CardAccess.required,
        );
        expect(policies.event?.type, 'family.dashboard_policy_updated');
        expect(policies.event?.refType, 'dashboardSettings');
        expect(policies.event?.actorId, 'manager');
      },
    );

    test('checks permission before validating input', () async {
      final result = await update(
        actorUid: 'member',
        familyId: 'fam',
        roles: const <String, Map<String, String>>{
          'admin': {'unknown': 'bad'},
        },
      );
      expect(result.failureOrNull, isA<PermissionDenied>());
      expect(policies.event, isNull);
    });

    test(
      'rejects admin, unknown role, unknown card, and invalid access',
      () async {
        final invalid = <Map<String, Map<String, String>>>[
          const {'admin': <String, String>{}},
          const {'owner': <String, String>{}},
          const {
            'member': {'missing_card': 'on'},
          },
          const {
            'member': {'chores_week': 'sometimes'},
          },
        ];
        final expectedCodes = [
          'admin_not_allowed',
          'invalid_role',
          'unknown_card',
          'invalid_access',
        ];

        for (var index = 0; index < invalid.length; index++) {
          final result = await update(
            actorUid: 'admin',
            familyId: 'fam',
            roles: invalid[index],
          );
          expect(result.failureOrNull, isA<Validation>());
          expect(
            (result.failureOrNull! as Validation).code,
            expectedCodes[index],
          );
        }
        expect(policies.event, isNull);
      },
    );

    test(
      'rejects a card access that would grant an unavailable permission',
      () async {
        final result = await update(
          actorUid: 'admin',
          familyId: 'fam',
          roles: const <String, Map<String, String>>{
            'member': {'chores_verify': 'on'},
          },
        );
        expect(
          result.failureOrNull,
          const Validation('access', 'permission_unavailable'),
        );
        expect(policies.event, isNull);
      },
    );

    test(
      'uses the live moderator finance switch in the permission check',
      () async {
        fixture.backend.permissionSettings['fam'] =
            (fixture.backend.permissionSettings['fam'] ??
                    PermissionSettings.defaults)
                .copyWith(moderatorManagesFinance: false);
        final result = await update(
          actorUid: 'manager',
          familyId: 'fam',
          roles: const <String, Map<String, String>>{},
        );
        expect(result.failureOrNull, isA<PermissionDenied>());
      },
    );
  });

  group('SaveDashboardPrefs', () {
    test('persists locally before mirroring remotely', () async {
      final events = <String>[];
      final store = _PrefsStore(events);
      final sync = _PrefsSync(events);
      final save = SaveDashboardPrefs(store: store, sync: sync);
      final prefs = DashboardPrefs(order: ['upcoming']);

      final result = await save.call(uid: 'one', prefs: prefs);

      expect(result.isSuccess, isTrue);
      expect(events, ['local:one', 'remote:one']);
      expect(store.values['one'], prefs);
      expect(sync.pushed, prefs);
    });

    test('retains the local value and returns remote sync failure', () async {
      final events = <String>[];
      final store = _PrefsStore(events);
      final sync = _PrefsSync(events)..failure = const Network();
      final save = SaveDashboardPrefs(store: store, sync: sync);
      final prefs = DashboardPrefs(hidden: {'bazar_fund'});

      final result = await save.call(uid: 'one', prefs: prefs);

      expect(result.failureOrNull, const Network());
      expect(store.values['one'], prefs);
      expect(events, ['local:one', 'remote:one']);
    });

    test('rejects oversized and overlong ids without writing', () async {
      final events = <String>[];
      final store = _PrefsStore(events);
      final save = SaveDashboardPrefs(store: store, sync: _PrefsSync(events));

      final tooMany = await save.call(
        uid: 'one',
        prefs: DashboardPrefs(
          order: List<String>.generate(
            DashboardPrefs.maxPreferenceIds + 1,
            (index) => '$index',
          ),
        ),
      );
      final tooLong = await save.call(
        uid: 'one',
        prefs: DashboardPrefs(order: ['x' * 41]),
      );

      expect(
        (tooMany.failureOrNull! as Validation).code,
        'too_many_preferences',
      );
      expect((tooLong.failureOrNull! as Validation).code, 'id_too_long');
      expect(events, isEmpty);
    });
  });
}

final class _PolicyRepository implements DashboardPolicyRepository {
  DashboardPolicy current = DashboardPolicy.defaults;
  AuditEvent? event;

  @override
  Stream<DashboardPolicy> watchPolicy(String familyId) =>
      Stream<DashboardPolicy>.value(current);

  @override
  Future<Result<DashboardPolicy>> savePolicy(
    String familyId,
    Map<Role, Map<String, CardAccess>> roles,
    AuditEvent event,
  ) async {
    this.event = event;
    current = DashboardPolicy(roles: roles, version: current.version + 1);
    return Success<DashboardPolicy>(current);
  }
}

final class _PrefsStore implements DashboardPrefsStore {
  _PrefsStore(this.events);

  final List<String> events;
  final Map<String, DashboardPrefs> values = <String, DashboardPrefs>{};

  @override
  DashboardPrefs load(String uid) => values[uid] ?? DashboardPrefs.defaults;

  @override
  Future<Result<void>> save(String uid, DashboardPrefs prefs) async {
    events.add('local:$uid');
    values[uid] = prefs;
    return const Success<void>(null);
  }
}

final class _PrefsSync implements DashboardPrefsSync {
  _PrefsSync(this.events);

  final List<String> events;
  DashboardPrefs? pushed;
  AppFailure? failure;

  @override
  Future<Result<void>> push(String uid, DashboardPrefs prefs) async {
    events.add('remote:$uid');
    pushed = prefs;
    final error = failure;
    return error == null ? const Success<void>(null) : Failure<void>(error);
  }

  @override
  Stream<DashboardPrefs?> watch(String uid) => const Stream.empty();
}
