import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';

/// What the next month receives when [month] is closed (P2-21, ADR 0007).
///
/// The opening row of a month is append-only (rule 28) and `open_<yyyy-MM>` is
/// a deterministic id, so it can be written once:
///
/// * no row yet -> [opening] carries the closing balance ([delta] is `null`);
/// * a row already exists (a re-close after a reopen) -> [adjustment] carries
///   `closingBalance - existingOpening`, so the ledger window of the next month
///   still sums to the closing balance.  A zero delta writes nothing;
/// * a zero closing balance with no opening row also writes nothing: a zero
///   ledger row is invalid, and an absent opening already means zero.
///
/// The result never exceeds one row, so the caller can stage it next to the
/// closing document in the same batch.
final class MonthCarryForward {
  const MonthCarryForward({
    required this.nextMonth,
    required this.closingBalance,
    this.existingOpening,
    this.delta,
    this.opening,
    this.adjustment,
  });

  final MonthKey nextMonth;
  final Money closingBalance;

  /// The `open_<next>` row that already exists, if any.
  final Money? existingOpening;

  /// What the next month must add to reach [closingBalance]; `null` when no
  /// opening row exists yet.
  final Money? delta;

  /// The row to write when the next month has no opening row.
  final FundTransaction? opening;

  /// The compensating row to write when it already has one.
  final FundTransaction? adjustment;

  /// `true` when nothing has to be written: the delta is zero.
  bool get isEmpty => opening == null && adjustment == null;

  @override
  String toString() =>
      'MonthCarryForward($nextMonth, closing: $closingBalance, '
      'existing: $existingOpening, delta: $delta)';
}

/// Pure rule used by `CloseMonth`.
abstract final class MonthCarryForwardRules {
  /// [existingOpening] is the amount of the `open_<next>` row, or `null`.
  static MonthCarryForward compute({
    required MonthKey month,
    required Money closingBalance,
    required Money? existingOpening,
    required String actorUid,
    required DateTime at,
    required String eventId,
    String? note,
  }) {
    final next = month.addMonths(1);
    if (existingOpening == null) {
      return MonthCarryForward(
        nextMonth: next,
        closingBalance: closingBalance,
        opening: closingBalance.isZero
            ? null
            : FundTransaction.opening(
                monthKey: next,
                amount: closingBalance,
                createdBy: actorUid,
                createdAt: at,
                note: note,
              ),
      );
    }

    final delta = closingBalance - existingOpening;
    return MonthCarryForward(
      nextMonth: next,
      closingBalance: closingBalance,
      existingOpening: existingOpening,
      delta: delta,
      adjustment: delta.isZero
          ? null
          : FundTransaction.adjustment(
              eventId: eventId,
              amount: delta,
              // The correction belongs to the next month's window.
              dateKey: next.startOfMonth,
              refType: FundRefType.month,
              refId: next.toString(),
              createdBy: actorUid,
              createdAt: at,
              suffix: 'carry',
              note: note,
            ),
    );
  }

  /// The latest closed month in [closings], or `null` when none is closed.
  static MonthKey? latestClosed(Iterable<MonthClosing> closings) {
    MonthKey? latest;
    for (final closing in closings) {
      if (closing.status != MonthStatus.closed) continue;
      if (latest == null || closing.monthKey.compareTo(latest) > 0) {
        latest = closing.monthKey;
      }
    }
    return latest;
  }
}
