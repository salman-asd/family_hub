import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_balance_calculator.dart';

/// What the Month-close screen shows before a manager commits (P2-23).
///
/// Everything here is DERIVED from the ledger and the contributions of
/// [month] — nothing is stored, so the preview can never drift from the close
/// itself.
final class MonthClosePreview {
  const MonthClosePreview({
    required this.month,
    required this.summary,
    required this.openAdvances,
    required this.expected,
    required this.received,
  });

  final MonthKey month;

  /// Received / spent / reimbursed / balance for the month's own rows.
  final FundSummary summary;

  /// Open (pending or partly settled) advances right now: money still owed to
  /// members after this month closes.
  final int openAdvances;

  final Money expected;
  final Money received;

  /// The closing balance the close will record (the window sum, which equals
  /// this month's balance once the earlier months are closed).
  Money get closingBalance => summary.balance;

  @override
  String toString() =>
      'MonthClosePreview($month, closing: $closingBalance, '
      'openAdvances: $openAdvances)';
}
