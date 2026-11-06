import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/usecases/update_engagement_settings.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/chores/templates/domain/template_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../support/in_memory_backend.dart';

void main() {
  const familyId = 'family';
  const managerId = 'manager';
  const adminId = 'admin';
  final today = DateKey(2026, 11, 5);
  final settings = defaultEngagementSettings(
    startedOn: DateKey(2026, 10, 1),
    graceMinutes: 30,
  );
  late InMemoryBackend families;
  late _SettingsRepository repository;
  late UpdateEngagementSettings useCase;

  setUp(() {
    families = InMemoryBackend()
      ..members[familyId] = <String, Member>{
        managerId: const Member(
          uid: managerId,
          role: MemberRole.moderator,
          status: MembershipStatus.active,
          fullName: 'Manager',
          relationship: 'other',
        ),
        adminId: const Member(
          uid: adminId,
          role: MemberRole.admin,
          status: MembershipStatus.active,
          fullName: 'Admin',
          relationship: 'other',
        ),
      };
    repository = _SettingsRepository();
    var nextId = 0;
    useCase = UpdateEngagementSettings(
      families: families,
      settingsRepository: repository,
      clock: FakeClock(DateTime.utc(2026, 11, 5)),
      newId: () => 'event-${nextId++}',
    );
  });

  test('manager changes scoring and the spec version increments', () async {
    final updated = settings.copyWith(
      scoreSpec: settings.scoreSpec.copyWith(
        pointBases: <Difficulty, int>{
          ...settings.scoreSpec.pointBases,
          Difficulty.normal: 21,
        },
      ),
    );
    final result = await useCase(
      actorUid: managerId,
      familyId: familyId,
      previous: settings,
      updated: updated,
      today: today,
    );

    expect(result.failureOrNull, isNull);
    expect(repository.saved?.scoreSpec.version, settings.scoreSpec.version + 1);
    expect(repository.events, hasLength(1));
  });

  test('privacy changes are audited with the new visibility', () async {
    final result = await useCase(
      actorUid: adminId,
      familyId: familyId,
      previous: settings,
      updated: settings.copyWith(statsVisibility: StatsVisibility.levels),
      today: today,
    );

    expect(result.failureOrNull, isNull);
    expect(repository.events, hasLength(2));
    expect(repository.events.last.params, <String, String>{
      'visibility': 'levels',
    });
  });

  test('manager cannot change stats visibility', () async {
    final result = await useCase(
      actorUid: managerId,
      familyId: familyId,
      previous: settings,
      updated: settings.copyWith(statsVisibility: StatsVisibility.levels),
      today: today,
    );

    expect(result.failureOrNull, isA<PermissionDenied>());
    expect(repository.saved, isNull);
  });

  test('enabled engagement start date cannot be changed', () async {
    final result = await useCase(
      actorUid: adminId,
      familyId: familyId,
      previous: settings,
      updated: settings.copyWith(startedOn: DateKey(2026, 10, 2)),
      today: today,
    );

    expect(result.failureOrNull, isA<Validation>());
    expect(repository.saved, isNull);
  });
}

final class _SettingsRepository implements EngagementSettingsRepository {
  EngagementSettings? saved;
  List<AuditEvent> events = const <AuditEvent>[];

  @override
  Stream<EngagementSettings> watch(
    String familyId, {
    required EngagementSettings defaults,
  }) => Stream<EngagementSettings>.value(saved ?? defaults);

  @override
  Future<Result<EngagementSettings>> get(
    String familyId, {
    required EngagementSettings defaults,
  }) async => Success<EngagementSettings>(saved ?? defaults);

  @override
  Future<Result<EngagementSettings>> save(
    String familyId,
    EngagementSettings settings,
    List<AuditEvent> events,
  ) async {
    saved = settings;
    this.events = events;
    return Success<EngagementSettings>(settings);
  }
}
