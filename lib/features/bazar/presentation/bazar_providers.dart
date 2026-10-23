import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/presentation/fund_providers.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The month every Bazar screen is looking at (roadmap §3.5).
///
/// `MonthSwitcher` writes it; the expense list, budgets, fund and reports read
/// it, so one tap re-targets all of them together.  A screen with its own
/// range (reports) keeps a local override instead of writing this provider.
final selectedMonthProvider = NotifierProvider<SelectedMonth, MonthKey>(
  SelectedMonth.new,
);

/// `selectedMonthProvider`'s state: the current month by default.
class SelectedMonth extends Notifier<MonthKey> {
  @override
  MonthKey build() => ref.read(familyDateKeysProvider).thisMonth();

  void next() => state = state.addMonths(1);

  void previous() => state = state.addMonths(-1);

  void set(MonthKey month) => state = month;

  /// Back to the family's current month (after a screen-local range, say).
  void reset() => state = ref.read(familyDateKeysProvider).thisMonth();
}

/// "Today" in the family's time zone, for the Add Expense date default.
final currentDateKeyProvider = Provider<DateKey>(
  (ref) => ref.watch(familyDateKeysProvider).today(),
);

/// Whether [month] has a `closed` closing document.
///
/// Forms read it to disable themselves with a localized reason instead of
/// failing after submit; the use case and the security rules enforce the same
/// rule for a write that races the closing.
final monthLockedProvider = Provider.family<bool, MonthKey>(
  (ref, month) =>
      MonthLocks.isLocked(month, ref.watch(monthClosingsByMonthProvider)),
);
