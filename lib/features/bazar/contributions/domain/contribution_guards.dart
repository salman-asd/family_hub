import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/contributions/domain/contribution.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';

/// Longest note or reject reason (mirrors `contributionOk` in the rules).
const int kMaxContributionNote = 300;
const int kMaxRejectReason = 200;

/// Shared input checks: a positive amount, no future date, a short note.
AppFailure? validateContributionInput({
  required Money amount,
  required DateKey date,
  required DateKey today,
  String? note,
}) {
  if (amount.paisa <= 0) {
    return const Validation('amount', 'amount_not_positive');
  }
  if (date.isAfter(today)) return const Validation('dateKey', 'future_date');
  if ((note ?? '').trim().runes.length > kMaxContributionNote) {
    return const Validation('note', 'too_long');
  }
  return null;
}

/// `Conflict('month_locked')` when any of [months] is closed (rule 31).
///
/// A read failure is returned as it is, so a lock is never skipped silently.
Future<AppFailure?> monthLockFailure(
  FundRepository funds,
  String familyId,
  Iterable<MonthKey> months,
) async {
  for (final month in months.toSet()) {
    final result = await funds.getClosing(familyId, month);
    final failure = result.failureOrNull;
    if (failure != null) return failure;
    if (result.valueOrNull?.status == MonthStatus.closed) {
      return const Conflict(code: 'month_locked');
    }
  }
  return null;
}

/// One audit entry about a contribution (machine params only, rule 18).
AuditEvent contributionEvent({
  required String id,
  required String type,
  required String actorId,
  required Contribution contribution,
  required DateTime at,
  Map<String, String> extra = const <String, String>{},
}) => AuditEvent(
  id: id,
  type: type,
  actorId: actorId,
  refType: AuditRefType.contribution,
  refId: contribution.id,
  at: at,
  params: <String, String>{
    'member': contribution.memberId,
    'amount': contribution.amount.paisa.toString(),
    'month': contribution.monthKey.toString(),
    ...extra,
  },
);

/// The owner of a contribution is the member it belongs to.
bool isOwner(Contribution contribution, String uid) =>
    contribution.memberId == uid && contribution.requestedBy == uid;
