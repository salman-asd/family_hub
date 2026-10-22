import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';
import 'package:family_hub/features/bazar/settings/domain/usecases/update_bazar_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../bazar_test_helpers.dart';
import '../../bazar_settings_test_helpers.dart';

void main() {
  late BazarFixture fixture;
  late FakeBazarSettingsRepository settingsRepository;
  late UpdateBazarSettings updateSettings;

  setUp(() {
    fixture = BazarFixture();
    settingsRepository = FakeBazarSettingsRepository();
    updateSettings = UpdateBazarSettings(
      settings: settingsRepository,
      families: fixture.backend,
      clock: fixture.clock,
      newId: fixture.ids.call,
    );
  });

  test('an admin saves and writes exactly one audit entry', () async {
    const settings = BazarSettings(
      weekStartDay: 1,
      defaultMonthlyContribution: Money.paisa(150000),
      contributionDueDay: 10,
      alertThresholds: <int>[70, 90, 100],
    );

    final result = await updateSettings(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      settings: settings,
    );

    expect(result.isSuccess, isTrue);
    expect(settingsRepository.stored, settings);
    expect(settingsRepository.saves, 1);
    expect(settingsRepository.events, hasLength(1));
    final event = settingsRepository.events.single;
    expect(event.id, 'id-1');
    expect(event.type, AuditEventType.bazarSettingsUpdated);
    expect(event.actorId, 'alice');
    expect(event.refType, AuditRefType.family);
    expect(event.refId, BazarFixture.familyId);
    expect(event.at, fixture.clock.nowUtc());
  });

  test('a finance moderator may save', () async {
    final result = await updateSettings(
      actorUid: 'bob',
      familyId: BazarFixture.familyId,
      settings: BazarSettings.defaults.copyWith(weekStartDay: 7),
    );

    expect(result.isSuccess, isTrue);
    expect(settingsRepository.saves, 1);
  });

  test('a moderator without finance is denied before validation', () async {
    fixture.backend.permissionSettings[BazarFixture.familyId] =
        PermissionSettings.defaults.copyWith(moderatorManagesFinance: false);

    final result = await updateSettings(
      actorUid: 'bob',
      familyId: BazarFixture.familyId,
      settings: BazarSettings.defaults.copyWith(weekStartDay: 0),
    );

    expect(result.failureOrNull, const PermissionDenied());
    expect(settingsRepository.saves, 0);
  });

  test('a plain member is denied', () async {
    final result = await updateSettings(
      actorUid: 'cara',
      familyId: BazarFixture.familyId,
      settings: BazarSettings.defaults,
    );

    expect(result.failureOrNull, const PermissionDenied());
    expect(settingsRepository.saves, 0);
  });

  test('rejects every invalid range before writing', () async {
    final cases = <(BazarSettings, String, String)>[
      (
        BazarSettings.defaults.copyWith(weekStartDay: 0),
        'weekStartDay',
        'invalid',
      ),
      (
        BazarSettings.defaults.copyWith(weekStartDay: 8),
        'weekStartDay',
        'invalid',
      ),
      (
        BazarSettings.defaults.copyWith(contributionDueDay: 0),
        'contributionDueDay',
        'invalid',
      ),
      (
        BazarSettings.defaults.copyWith(contributionDueDay: 29),
        'contributionDueDay',
        'invalid',
      ),
      (
        BazarSettings.defaults.copyWith(
          defaultMonthlyContribution: const Money.paisa(-1),
        ),
        'defaultMonthlyContribution',
        'negative',
      ),
      (
        BazarSettings.defaults.copyWith(alertThresholds: const <int>[]),
        'alertThresholds',
        'empty',
      ),
      (
        BazarSettings.defaults.copyWith(
          alertThresholds: const <int>[50, 60, 70, 80, 90],
        ),
        'alertThresholds',
        'too_many',
      ),
      (
        BazarSettings.defaults.copyWith(alertThresholds: const <int>[0, 80]),
        'alertThresholds',
        'out_of_range',
      ),
      (
        BazarSettings.defaults.copyWith(alertThresholds: const <int>[80, 201]),
        'alertThresholds',
        'out_of_range',
      ),
      (
        BazarSettings.defaults.copyWith(alertThresholds: const <int>[80, 80]),
        'alertThresholds',
        'duplicate',
      ),
      (
        BazarSettings.defaults.copyWith(alertThresholds: const <int>[100, 80]),
        'alertThresholds',
        'not_ascending',
      ),
    ];

    for (final (settings, field, code) in cases) {
      final result = await updateSettings(
        actorUid: 'alice',
        familyId: BazarFixture.familyId,
        settings: settings,
      );
      expect(result.failureOrNull, Validation(field, code), reason: code);
    }
    expect(settingsRepository.saves, 0);
  });

  test('passes a repository failure through unchanged', () async {
    settingsRepository.nextFailure = const Network();

    final result = await updateSettings(
      actorUid: 'alice',
      familyId: BazarFixture.familyId,
      settings: BazarSettings.defaults,
    );

    expect(result.failureOrNull, const Network());
    expect(settingsRepository.events, isEmpty);
  });
}
