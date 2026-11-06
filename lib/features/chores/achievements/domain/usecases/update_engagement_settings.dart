import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permission.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/engagement_settings_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/levels/level_table.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

final class UpdateEngagementSettings {
  const UpdateEngagementSettings({
    required this.families,
    required this.settingsRepository,
    required this.clock,
    required this.newId,
  });

  final FamilyRepository families;
  final EngagementSettingsRepository settingsRepository;
  final Clock clock;
  final IdGenerator newId;

  Future<Result<EngagementSettings>> call({
    required String actorUid,
    required String familyId,
    required EngagementSettings previous,
    required EngagementSettings updated,
    required DateKey today,
  }) async {
    final manager = await requirePermission(
      families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.manageEngagement,
    );
    final managerFailure = manager.failureOrNull;
    if (managerFailure != null) {
      return Failure<EngagementSettings>(managerFailure);
    }
    if (updated.statsVisibility != previous.statsVisibility) {
      final admin = await requirePermission(
        families,
        familyId: familyId,
        actorUid: actorUid,
        permission: Permission.editFamilySettings,
      );
      final adminFailure = admin.failureOrNull;
      if (adminFailure != null) {
        return Failure<EngagementSettings>(adminFailure);
      }
    }

    final validation = _validate(updated);
    if (validation != null) {
      return Failure<EngagementSettings>(validation);
    }
    if ((previous.enabled || !updated.enabled) &&
        updated.startedOn != previous.startedOn) {
      return const Failure<EngagementSettings>(
        Validation('startedOn', 'invalid_started_on'),
      );
    }
    if (!previous.enabled &&
        updated.enabled &&
        updated.startedOn.isAfter(today)) {
      return const Failure<EngagementSettings>(
        Validation('startedOn', 'invalid_started_on'),
      );
    }

    final scoringChanged = _scoringChanged(previous, updated);
    final effective = updated.copyWith(
      startedOn: !previous.enabled && updated.enabled
          ? today
          : previous.startedOn,
      scoreSpec: updated.scoreSpec.copyWith(
        version: scoringChanged
            ? previous.scoreSpec.version + 1
            : previous.scoreSpec.version,
      ),
    );
    final at = clock.nowUtc();
    final events = <AuditEvent>[
      AuditEvent(
        id: newId(),
        type: AuditEventType.engagementSettingsUpdated,
        actorId: actorUid,
        refType: AuditRefType.engagementSettings,
        refId: familyId,
        at: at,
      ),
      if (effective.statsVisibility != previous.statsVisibility)
        AuditEvent(
          id: newId(),
          type: AuditEventType.engagementPrivacyUpdated,
          actorId: actorUid,
          refType: AuditRefType.engagementSettings,
          refId: familyId,
          at: at,
          params: <String, String>{'visibility': effective.statsVisibility.id},
        ),
    ];
    return settingsRepository.save(familyId, effective, events);
  }

  AppFailure? _validate(EngagementSettings settings) {
    final spec = settings.scoreSpec;
    if (spec.pointBases.values.any((value) => value < 0 || value > 1000) ||
        spec.latePermille < 0 ||
        spec.latePermille > 2000 ||
        spec.verifiedPermille < 0 ||
        spec.verifiedPermille > 2000 ||
        spec.coverBonusPermille < 0 ||
        spec.coverBonusPermille > 2000 ||
        settings.levels.length > 12 ||
        settings.badgeThresholds.consistentDays > 365 ||
        settings.badgeThresholds.reliablePercent > 100 ||
        settings.badgeThresholds.reliableMinDone > 1000 ||
        settings.badgeThresholds.helperCovers > 1000 ||
        settings.badgeThresholds.detailCount > 1000) {
      return const Validation('settings', 'out_of_range');
    }
    try {
      LevelTable(settings.levels);
    } on ArgumentError {
      return const Validation('levels', 'invalid_levels');
    }
    if (settings.levels.any(
      (level) =>
          level.id.length > 32 ||
          level.nameBn.length > 40 ||
          level.nameEn.length > 40,
    )) {
      return const Validation('levels', 'invalid_level_text');
    }
    return null;
  }

  bool _scoringChanged(
    EngagementSettings previous,
    EngagementSettings updated,
  ) =>
      !_sameBases(
        previous.scoreSpec.pointBases,
        updated.scoreSpec.pointBases,
      ) ||
      previous.scoreSpec.latePermille != updated.scoreSpec.latePermille ||
      previous.scoreSpec.verifiedPermille !=
          updated.scoreSpec.verifiedPermille ||
      previous.scoreSpec.coverBonusPermille !=
          updated.scoreSpec.coverBonusPermille ||
      !_sameLevels(previous.levels, updated.levels) ||
      previous.badgeThresholds != updated.badgeThresholds;

  bool _sameBases<K>(Map<K, int> first, Map<K, int> second) {
    if (first.length != second.length) return false;
    return first.entries.every((entry) => second[entry.key] == entry.value);
  }

  bool _sameLevels(List<EngagementLevel> first, List<EngagementLevel> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      final a = first[index];
      final b = second[index];
      if (a.id != b.id ||
          a.minPoints != b.minPoints ||
          a.nameBn != b.nameBn ||
          a.nameEn != b.nameEn) {
        return false;
      }
    }
    return true;
  }
}
