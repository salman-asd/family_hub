import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/month_carry_forward.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/domain/month_plans.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// Shortest reopen note; mirrors rule 31 (never reopen without a reason).
const int kMinReopenNote = 3;

/// A note longer than this is truncated in the audit entry only.
const int kMaxReopenNote = 300;
const int kMaxAuditNote = 100;

/// Reopens a closed month so it can be corrected, then closed again.
///
/// Checks, in order: permission (`closeBazarMonth`), a note of at least
/// [kMinReopenNote] characters (`reopen_note_required`), the month is closed
/// (`not_closed`) and no LATER month is closed (`later_month_closed` —
/// reopening an earlier month would move the balance window under an already
/// closed one).  The month document becomes `open` with `reopenedAt/By/Note`
/// and `reopenCount + 1`; no ledger row changes.
///
/// Needs the server (the rules and the close flow rely on a fresh answer).
class ReopenMonth {
  const ReopenMonth({
    required this._funds,
    required this._families,
    required this._clock,
    required this._newId,
  });

  final FundRepository _funds;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;

  Future<Result<MonthClosing>> call({
    required String actorUid,
    required String familyId,
    required MonthKey month,
    required String note,
    String? eventId,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.closeBazarMonth,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<MonthClosing>(denied);

    final cleaned = note.trim();
    if (cleaned.runes.length < kMinReopenNote) {
      return const Failure<MonthClosing>(
        Conflict(code: 'reopen_note_required'),
      );
    }

    final closings = await _funds.watchClosings(familyId).first;
    final current = closings
        .where((closing) => closing.monthKey == month)
        .firstOrNull;
    if (current == null || current.status != MonthStatus.closed) {
      return const Failure<MonthClosing>(Conflict(code: 'not_closed'));
    }
    final later = MonthCarryForwardRules.latestClosed(closings);
    if (later != null && later.compareTo(month) > 0) {
      return const Failure<MonthClosing>(Conflict(code: 'later_month_closed'));
    }

    final now = _clock.nowUtc();
    final reopened = MonthClosing(
      monthKey: month,
      status: MonthStatus.open,
      closedAt: current.closedAt,
      closedBy: current.closedBy,
      closingBalance: current.closingBalance,
      reopenedAt: now,
      reopenedBy: actorUid,
      reopenNote: _clip(cleaned, kMaxReopenNote),
      reopenCount: current.reopenCount + 1,
    );
    final saved = await _funds.commitReopen(
      familyId,
      MonthReopenPlan(reopened: reopened),
      AuditEvent(
        id: eventId ?? _newId(),
        type: AuditEventType.bazarMonthReopened,
        actorId: actorUid,
        refType: AuditRefType.month,
        refId: month.toString(),
        at: now,
        params: <String, String>{
          'month': month.toString(),
          // Audit params stay bounded; the document keeps the full note.
          'note': _clip(cleaned, kMaxAuditNote),
          'reopenCount': reopened.reopenCount.toString(),
        },
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<MonthClosing>(failure)
        : Success<MonthClosing>(reopened);
  }

  static String _clip(String text, int max) =>
      text.runes.length <= max
      ? text
      : String.fromCharCodes(text.runes.take(max));
}
