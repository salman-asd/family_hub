import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings_repository.dart';

/// Pure functions between [ChoreSettings] and `settings/chores`.
///
/// The map is the single source of truth for the closed `settingsKeys()` list
/// and the contract fixture. `toMap` writes the WHOLE object, so a later
/// release can add a field without touching the family's saved choices.
///
/// `fromMap` is TOLERANT per field: a missing, ill-typed or out-of-range value
/// falls back to its own default, and a missing or empty catalog falls back to
/// the built-in one. A damaged document therefore never crashes a screen and
/// never loses the rest of the family's settings.
abstract final class ChoreSettingsMappers {
  static Map<String, dynamic> toMap(
    ChoreSettings settings,
    BaseDocumentMetadata meta,
  ) => <String, dynamic>{
    'weekStartDay': settings.weekStartDay,
    'defaultCalendarView': settings.defaultCalendarView.id,
    'defaultScope': settings.defaultScope.id,
    'generationHorizonDays': settings.generationHorizonDays,
    'showProjected': settings.showProjected,
    'projectedMonthsAhead': settings.projectedMonthsAhead,
    'overdueGraceMinutes': settings.overdueGraceMinutes,
    'swapsEnabled': settings.swapsEnabled,
    'swapExpiryBufferMinutes': settings.swapExpiryBufferMinutes,
    'absenceNeedsApproval': settings.absenceNeedsApproval,
    'workloadVisibleToMembers': settings.workloadVisibleToMembers,
    'houseRules': settings.houseRules,
    'dueTimePresets': <Map<String, Object?>>[
      for (final preset in settings.dueTimePresets) preset.toMap(),
    ],
    'groups': <Map<String, Object?>>[
      for (final group in settings.groups) group.toMap(),
    ],
    'absenceReasons': <Map<String, Object?>>[
      for (final reason in settings.absenceReasons) reason.toMap(),
    ],
    ...BaseMapper.metadataToMap(meta),
  };

  static ChoreSettings fromMap(Map<String, dynamic>? map) {
    const base = ChoreSettings.defaults;
    if (map == null) return base;

    return ChoreSettings(
      weekStartDay: _intIn(map['weekStartDay'], 1, 7) ?? base.weekStartDay,
      defaultCalendarView: CalendarViewKind.fromId(map['defaultCalendarView']),
      defaultScope: CalendarScopeKind.fromId(map['defaultScope']),
      generationHorizonDays:
          _intIn(
            map['generationHorizonDays'],
            ChoreSettingsLimits.minGenerationHorizonDays,
            ChoreSettingsLimits.maxGenerationHorizonDays,
          ) ??
          base.generationHorizonDays,
      showProjected: _bool(map['showProjected']) ?? base.showProjected,
      projectedMonthsAhead:
          _intIn(
            map['projectedMonthsAhead'],
            0,
            ChoreSettingsLimits.maxProjectedMonthsAhead,
          ) ??
          base.projectedMonthsAhead,
      overdueGraceMinutes:
          _intIn(
            map['overdueGraceMinutes'],
            0,
            ChoreSettingsLimits.maxOverdueGraceMinutes,
          ) ??
          base.overdueGraceMinutes,
      swapsEnabled: _bool(map['swapsEnabled']) ?? base.swapsEnabled,
      swapExpiryBufferMinutes:
          _intIn(
            map['swapExpiryBufferMinutes'],
            0,
            ChoreSettingsLimits.maxSwapExpiryBufferMinutes,
          ) ??
          base.swapExpiryBufferMinutes,
      absenceNeedsApproval:
          _bool(map['absenceNeedsApproval']) ?? base.absenceNeedsApproval,
      workloadVisibleToMembers:
          _bool(map['workloadVisibleToMembers']) ??
          base.workloadVisibleToMembers,
      houseRules: _string(
        map['houseRules'],
        ChoreSettingsLimits.maxHouseRulesLength,
      ),
      dueTimePresets: _presets(map['dueTimePresets']),
      groups: _groups(map['groups']),
      absenceReasons: _reasons(map['absenceReasons']),
    );
  }

  /// `settings/rotationPolicy` — only `absencePolicy` is read/written here.
  static AbsencePolicy absencePolicyFromMap(Map<String, dynamic>? map) =>
      AbsencePolicy.fromId(map?['absencePolicy']);

  static Map<String, dynamic> absencePolicyToMap(
    AbsencePolicy policy,
    BaseDocumentMetadata meta,
  ) => <String, dynamic>{
    'absencePolicy': policy.id,
    ...BaseMapper.metadataToMap(meta),
  };

  // ── Catalogs ────────────────────────────────────────────────────────────────

  /// An absent or unusable list falls back to the built-in one; individual
  /// malformed rows are skipped rather than rejecting the whole list.
  static List<ChoreGroup> _groups(Object? raw) {
    final rows = _rows(raw);
    if (rows == null) return ChoreSettings.defaults.groups;
    final groups = <ChoreGroup>[];
    final ids = <String>{};
    for (final row in rows) {
      if (groups.length == ChoreSettingsLimits.maxGroups) break;
      final id = _id(row['id']);
      if (id == null || !ids.add(id)) continue;
      final nameBn = _string(row['nameBn'], 40);
      if (nameBn.isEmpty) continue;
      groups.add(
        ChoreGroup(
          id: id,
          nameBn: nameBn,
          nameEn: _nullableString(row['nameEn'], 40),
          colorIndex:
              _intIn(
                row['colorIndex'],
                0,
                ChoreSettingsLimits.paletteLength - 1,
              ) ??
              0,
          iconKey: _nullableString(row['iconKey'], 24) ?? 'other',
          sortOrder: _intIn(row['sortOrder'], 0, 9999) ?? groups.length,
          active: _bool(row['active']) ?? true,
          builtIn: _bool(row['builtIn']) ?? false,
        ),
      );
    }
    return groups.isEmpty ? ChoreSettings.defaults.groups : groups;
  }

  static List<DueTimePreset> _presets(Object? raw) {
    final rows = _rows(raw);
    if (rows == null) return ChoreSettings.defaults.dueTimePresets;
    final presets = <DueTimePreset>[];
    final ids = <String>{};
    for (final row in rows) {
      if (presets.length == ChoreSettingsLimits.maxDueTimePresets) break;
      final id = _id(row['id']);
      if (id == null || !ids.add(id)) continue;
      final labelBn = _string(row['labelBn'], 30);
      final minutes = _intIn(row['minutes'], 0, 1439);
      if (labelBn.isEmpty || minutes == null) continue;
      presets.add(
        DueTimePreset(
          id: id,
          labelBn: labelBn,
          labelEn: _nullableString(row['labelEn'], 30),
          minutes: minutes,
          active: _bool(row['active']) ?? true,
          builtIn: _bool(row['builtIn']) ?? false,
        ),
      );
    }
    return presets.isEmpty ? ChoreSettings.defaults.dueTimePresets : presets;
  }

  static List<AbsenceReason> _reasons(Object? raw) {
    final rows = _rows(raw);
    if (rows == null) return ChoreSettings.defaults.absenceReasons;
    final reasons = <AbsenceReason>[];
    final ids = <String>{};
    for (final row in rows) {
      if (reasons.length == ChoreSettingsLimits.maxAbsenceReasons) break;
      final id = _id(row['id']);
      if (id == null || !ids.add(id)) continue;
      final labelBn = _string(row['labelBn'], 30);
      if (labelBn.isEmpty) continue;
      reasons.add(
        AbsenceReason(
          id: id,
          labelBn: labelBn,
          labelEn: _nullableString(row['labelEn'], 30),
          active: _bool(row['active']) ?? true,
          builtIn: _bool(row['builtIn']) ?? false,
        ),
      );
    }
    return reasons.isEmpty ? ChoreSettings.defaults.absenceReasons : reasons;
  }

  // ── Primitives ──────────────────────────────────────────────────────────────

  /// The list rows that are maps; `null` when the value is not a list at all
  /// (absent, or damaged), which means "use the default catalog".
  static List<Map<String, dynamic>>? _rows(Object? raw) {
    if (raw is! List) return null;
    return <Map<String, dynamic>>[
      for (final item in raw)
        if (item is Map) item.cast<String, dynamic>(),
    ];
  }

  static int? _intIn(Object? value, int min, int max) {
    if (value is! num) return null;
    final asInt = value.toInt();
    return asInt < min || asInt > max ? null : asInt;
  }

  static bool? _bool(Object? value) => value is bool ? value : null;

  static String _string(Object? value, int max) {
    if (value is! String) return '';
    return value.length > max ? value.substring(0, max) : value;
  }

  static String? _nullableString(Object? value, int max) {
    if (value is! String || value.isEmpty) return null;
    return value.length > max ? value.substring(0, max) : value;
  }

  static String? _id(Object? value) {
    if (value is! String) return null;
    return RegExp(r'^[a-z0-9_]{1,24}$').hasMatch(value) ? value : null;
  }
}
