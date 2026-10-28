import 'package:family_hub/features/chores/settings/domain/chore_catalog_entries.dart';
import 'package:family_hub/features/chores/settings/domain/default_chore_settings.dart';

/// The family's chore preferences (`settings/chores`), road map 3.2.
///
/// An ABSENT document means [defaults] (D-P3-4): there is no seeder and no
/// backfill, so an old family simply gets the built-in catalogs until somebody
/// saves a change. Every field falls back on its own in the mapper, so a later
/// release can add a field without overwriting a family's existing choices.
///
/// The catalog lists are DATA (the family edits them); the three enums are the
/// only closed sets, because screens switch on them.
final class ChoreSettings {
  const ChoreSettings({
    this.weekStartDay = 6,
    this.defaultCalendarView = CalendarViewKind.agenda,
    this.defaultScope = CalendarScopeKind.mine,
    this.generationHorizonDays = 30,
    this.showProjected = true,
    this.projectedMonthsAhead = 3,
    this.overdueGraceMinutes = 0,
    this.swapsEnabled = true,
    this.swapExpiryBufferMinutes = 120,
    this.absenceNeedsApproval = false,
    this.workloadVisibleToMembers = false,
    this.houseRules = '',
    this.dueTimePresets = defaultDueTimePresets,
    this.groups = defaultGroups,
    this.absenceReasons = defaultAbsenceReasons,
  });

  /// What every family gets before the document exists (Appendix A.3).
  static const ChoreSettings defaults = ChoreSettings();

  /// 1 = Monday … 7 = Sunday. Saturday (6) is the Bangladeshi week start and
  /// is deliberately separate from `settings/bazar.weekStartDay` (C-18).
  final int weekStartDay;

  final CalendarViewKind defaultCalendarView;
  final CalendarScopeKind defaultScope;

  /// How far ahead occurrences are generated: 14 … 90 days (D-P3-10).
  final int generationHorizonDays;

  /// Show projected (not yet written) occurrences on the calendar (D-P3-6).
  final bool showProjected;

  /// How many months of projections: 0 … 12.
  final int projectedMonthsAhead;

  /// Minutes after the due time before a chore counts as overdue: 0 … 240.
  final int overdueGraceMinutes;

  final bool swapsEnabled;

  /// How long a swap request stays open: 0 … 1440 minutes.
  final int swapExpiryBufferMinutes;

  /// A new absence needs a manager's decision (D-P3-13).
  final bool absenceNeedsApproval;

  /// Members may open the workload board (D-P3-20).
  final bool workloadVisibleToMembers;

  /// Mini-markdown, at most 2000 characters (P3-02 parser renders it).
  final String houseRules;

  final List<DueTimePreset> dueTimePresets;
  final List<ChoreGroup> groups;
  final List<AbsenceReason> absenceReasons;

  ChoreSettings copyWith({
    int? weekStartDay,
    CalendarViewKind? defaultCalendarView,
    CalendarScopeKind? defaultScope,
    int? generationHorizonDays,
    bool? showProjected,
    int? projectedMonthsAhead,
    int? overdueGraceMinutes,
    bool? swapsEnabled,
    int? swapExpiryBufferMinutes,
    bool? absenceNeedsApproval,
    bool? workloadVisibleToMembers,
    String? houseRules,
    List<DueTimePreset>? dueTimePresets,
    List<ChoreGroup>? groups,
    List<AbsenceReason>? absenceReasons,
  }) => ChoreSettings(
    weekStartDay: weekStartDay ?? this.weekStartDay,
    defaultCalendarView: defaultCalendarView ?? this.defaultCalendarView,
    defaultScope: defaultScope ?? this.defaultScope,
    generationHorizonDays: generationHorizonDays ?? this.generationHorizonDays,
    showProjected: showProjected ?? this.showProjected,
    projectedMonthsAhead: projectedMonthsAhead ?? this.projectedMonthsAhead,
    overdueGraceMinutes: overdueGraceMinutes ?? this.overdueGraceMinutes,
    swapsEnabled: swapsEnabled ?? this.swapsEnabled,
    swapExpiryBufferMinutes:
        swapExpiryBufferMinutes ?? this.swapExpiryBufferMinutes,
    absenceNeedsApproval: absenceNeedsApproval ?? this.absenceNeedsApproval,
    workloadVisibleToMembers:
        workloadVisibleToMembers ?? this.workloadVisibleToMembers,
    houseRules: houseRules ?? this.houseRules,
    dueTimePresets: dueTimePresets ?? this.dueTimePresets,
    groups: groups ?? this.groups,
    absenceReasons: absenceReasons ?? this.absenceReasons,
  );

  @override
  bool operator ==(Object other) =>
      other is ChoreSettings &&
      other.weekStartDay == weekStartDay &&
      other.defaultCalendarView == defaultCalendarView &&
      other.defaultScope == defaultScope &&
      other.generationHorizonDays == generationHorizonDays &&
      other.showProjected == showProjected &&
      other.projectedMonthsAhead == projectedMonthsAhead &&
      other.overdueGraceMinutes == overdueGraceMinutes &&
      other.swapsEnabled == swapsEnabled &&
      other.swapExpiryBufferMinutes == swapExpiryBufferMinutes &&
      other.absenceNeedsApproval == absenceNeedsApproval &&
      other.workloadVisibleToMembers == workloadVisibleToMembers &&
      other.houseRules == houseRules &&
      _sameList(other.dueTimePresets, dueTimePresets) &&
      _sameList(other.groups, groups) &&
      _sameList(other.absenceReasons, absenceReasons);

  @override
  int get hashCode => Object.hash(
    weekStartDay,
    defaultCalendarView,
    defaultScope,
    generationHorizonDays,
    showProjected,
    projectedMonthsAhead,
    overdueGraceMinutes,
    swapsEnabled,
    swapExpiryBufferMinutes,
    absenceNeedsApproval,
    workloadVisibleToMembers,
    houseRules,
    Object.hashAll(dueTimePresets),
    Object.hashAll(groups),
    Object.hashAll(absenceReasons),
  );

  /// Order-sensitive comparison: the lists are ORDERED (sortOrder matters),
  /// so `[a, b]` and `[b, a]` are different settings.
  static bool _sameList<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'ChoreSettings(weekStartDay: $weekStartDay, '
      'view: ${defaultCalendarView.id}, scope: ${defaultScope.id}, '
      'horizon: $generationHorizonDays, groups: ${groups.length}, '
      'presets: ${dueTimePresets.length}, reasons: ${absenceReasons.length})';
}
