import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/person_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Today in the family's time zone (H12).  Never `DateTime.now()`.
final currentDateKeyProvider = Provider<DateKey>(
  (ref) => ref.watch(familyDateKeysProvider).today(),
);

/// The month every Bazar screen shows together (expense list, budget, fund,
/// reports).  A screen may hold a local override, but it starts from this one.
final selectedMonthProvider = NotifierProvider<SelectedMonth, MonthKey>(
  SelectedMonth.new,
);

class SelectedMonth extends Notifier<MonthKey> {
  @override
  MonthKey build() => ref.read(familyDateKeysProvider).thisMonth();

  void next() => state = state.addMonths(1);

  void previous() => state = state.addMonths(-1);

  void set(MonthKey month) => state = month;

  /// Back to the current month ("Today" shortcut).
  void reset() => state = ref.read(familyDateKeysProvider).thisMonth();
}

/// `true` when [month] is closed.  Forms read this to disable themselves with a
/// reason instead of failing after submit; the use cases and the rules still
/// enforce it (CLAUDE.md rule 31).
final monthLockedProvider = Provider.family<bool, MonthKey>(
  (ref, month) =>
      MonthLocks.isLocked(month, ref.watch(monthClosingMapProvider)),
);

/// The active members as picker options (payer, purchaser, filter).
///
/// Sorted by display name so the order is stable between screens.
final bazarMemberOptionsProvider = Provider<List<PersonOption>>((ref) {
  final members = ref.watch(membersProvider).value ?? const <Member>[];
  final options = <PersonOption>[
    for (final member in members)
      if (member.isActive)
        PersonOption(
          id: member.uid,
          name: member.displayName,
          avatarKey: member.avatarKey,
        ),
  ]..sort((a, b) => a.name.compareTo(b.name));
  return options;
});
