import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';

/// Everything `CloseMonth` writes, staged by the repository in ONE batch.
///
/// * [closing] is the `monthClosings/<month>` document, `closed`, with the
///   balance computed from the server ledger window;
/// * [nextOpening] is the `open_<next>` row, written only when the next month
///   has no opening row yet;
/// * [nextAdjustment] is the compensating `adj_<eventId>` row written instead
///   when that row already exists (a re-close after a reopen): the opening row
///   is append-only (rule 28), so a correction is a NEW row of the delta.
///
/// At most one of [nextOpening] and [nextAdjustment] is set.
final class MonthClosePlan {
  const MonthClosePlan({
    required this.closing,
    this.nextOpening,
    this.nextAdjustment,
  });

  final MonthClosing closing;
  final FundTransaction? nextOpening;
  final FundTransaction? nextAdjustment;
}

/// `ReopenMonth` writes the month document back to `open`, with its note.
final class MonthReopenPlan {
  const MonthReopenPlan({required this.reopened});

  final MonthClosing reopened;
}
