import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';

/// Whether a month accepts new ledger/expense writes.
enum MonthStatus { open, closed }

/// The close/reopen history for one month (`monthClosings/<yyyy-MM>`).
final class MonthClosing {
  const MonthClosing({
    required this.monthKey,
    required this.status,
    this.closedAt,
    this.closedBy,
    this.closingBalance,
    this.reopenedAt,
    this.reopenedBy,
    this.reopenNote,
    this.reopenCount = 0,
  });

  final MonthKey monthKey;
  final MonthStatus status;
  final DateTime? closedAt;
  final String? closedBy;
  final Money? closingBalance;
  final DateTime? reopenedAt;
  final String? reopenedBy;
  final String? reopenNote;
  final int reopenCount;

  @override
  bool operator ==(Object other) =>
      other is MonthClosing &&
      other.monthKey == monthKey &&
      other.status == status &&
      other.closedAt == closedAt &&
      other.closedBy == closedBy &&
      other.closingBalance == closingBalance &&
      other.reopenedAt == reopenedAt &&
      other.reopenedBy == reopenedBy &&
      other.reopenNote == reopenNote &&
      other.reopenCount == reopenCount;

  @override
  int get hashCode => Object.hash(
    monthKey,
    status,
    closedAt,
    closedBy,
    closingBalance,
    reopenedAt,
    reopenedBy,
    reopenNote,
    reopenCount,
  );

  @override
  String toString() =>
      'MonthClosing($monthKey, ${status.name}, balance: $closingBalance)';
}

/// Pure month-lock and fund-window rules.
abstract final class MonthLocks {
  /// A month is locked only when its document says [MonthStatus.closed].
  static bool isLocked(MonthKey month, Map<MonthKey, MonthClosing> closings) =>
      closings[month]?.status == MonthStatus.closed;

  /// First month whose ledger rows contribute to the current balance.
  ///
  /// This is the month after the latest closed month; when nothing has been
  /// closed it is [fundStartMonth].  A reopened month has status `open`, so it
  /// no longer moves the window.  Returns `null` when the fund is not set up.
  static MonthKey? fundWindowStart(
    Map<MonthKey, MonthClosing> closings,
    MonthKey? fundStartMonth,
  ) {
    MonthKey? latestClosed;
    for (final closing in closings.values) {
      if (closing.status != MonthStatus.closed) continue;
      if (latestClosed == null ||
          closing.monthKey.compareTo(latestClosed) > 0) {
        latestClosed = closing.monthKey;
      }
    }
    return latestClosed?.addMonths(1) ?? fundStartMonth;
  }
}
