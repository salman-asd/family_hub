import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/presentation/availability_index_provider.dart';
import 'package:family_hub/features/chores/calendar/presentation/calendar_items_providers.dart';
import 'package:family_hub/features/chores/occurrences/domain/chore_item.dart';
import 'package:family_hub/features/chores/rota/domain/rota_matrix.dart';
import 'package:family_hub/features/chores/rota/domain/workload_calculator.dart';
import 'package:family_hub/features/chores/rota/domain/workload_summary.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The range the rota board shows.
enum RotaRange { week, month }

class RotaRangeController extends Notifier<RotaRange> {
  @override
  RotaRange build() => RotaRange.week;

  void select(RotaRange range) => state = range;
}

final rotaRangeProvider = NotifierProvider<RotaRangeController, RotaRange>(
  RotaRangeController.new,
);

/// First and last day of the shown range. A week starts on the family's chore
/// week-start day (`ChoreSettings.weekStartDay`, 0 = Sunday ... 6 = Saturday);
/// a month is the calendar month of today.
typedef RotaBounds = ({DateKey from, DateKey to});

RotaBounds rotaBoundsFor({
  required RotaRange range,
  required DateKey today,
  required int weekStartDay,
}) {
  if (range == RotaRange.month) {
    final month = today.monthKey;
    return (from: month.startOfMonth, to: month.endOfMonth);
  }
  // Dart: Monday = 1 ... Sunday = 7, so `% 7` gives Sunday = 0 ... Saturday = 6.
  final weekday = DateTime.utc(today.year, today.month, today.day).weekday % 7;
  final back = (weekday - weekStartDay + 7) % 7;
  final from = today.addDays(-back);
  return (from: from, to: from.addDays(6));
}

final rotaBoundsProvider = Provider.autoDispose<RotaBounds>(
  (ref) => rotaBoundsFor(
    range: ref.watch(rotaRangeProvider),
    today: ref.watch(familyDateKeysProvider).today(),
    weekStartDay: ref.watch(
      choreSettingsProvider.select((s) => s.weekStartDay),
    ),
  ),
);

/// The chore items of the shown range: at most the two month listeners a week
/// can touch (CLAUDE.md rule 11, the calendar's own listeners are reused).
final rotaItemsProvider = Provider.autoDispose<List<ChoreItem>>((ref) {
  final bounds = ref.watch(rotaBoundsProvider);
  final months = <MonthKey>{
    MonthKey(bounds.from.year, bounds.from.month),
    MonthKey(bounds.to.year, bounds.to.month),
  };
  return <ChoreItem>[
    for (final month in months)
      ...(ref.watch(monthItemsProvider(month)).value?.items ??
          const <ChoreItem>[]),
  ];
});

/// The active members, in the family's order.
final rotaMemberIdsProvider = Provider.autoDispose<List<String>>(
  (ref) => <String>[
    for (final member in ref.watch(membersProvider).value ?? const <Member>[])
      if (member.isActive) member.uid,
  ],
);

final rotaWorkloadProvider = Provider.autoDispose<WorkloadSummary>((ref) {
  final bounds = ref.watch(rotaBoundsProvider);
  return WorkloadCalculator.compute(
    items: ref.watch(rotaItemsProvider),
    memberIds: ref.watch(rotaMemberIdsProvider),
    from: bounds.from,
    to: bounds.to,
    availability: ref.watch(availabilityIndexProvider),
  );
});

final rotaMatrixProvider = Provider.autoDispose<RotaMatrix>((ref) {
  final bounds = ref.watch(rotaBoundsProvider);
  return RotaMatrix.build(
    items: ref.watch(rotaItemsProvider),
    memberIds: ref.watch(rotaMemberIdsProvider),
    from: bounds.from,
    to: bounds.to,
  );
});

/// Whether the viewer may see the workload: managers always, members only when
/// the family switched `workloadVisibleToMembers` on (D-P3-22).
final rotaVisibleProvider = Provider<bool>(
  (ref) =>
      ref.watch(
        choreSettingsProvider.select((s) => s.workloadVisibleToMembers),
      ) ||
      ref.can(Permission.manageChoreTemplates),
);
