import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/family_date_keys.dart';
import 'package:family_hub/core/utils/id_generator.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_balance_calculator.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_repository.dart';
import 'package:family_hub/features/bazar/fund/domain/fund_transaction.dart';
import 'package:family_hub/features/bazar/fund/domain/month_carry_forward.dart';
import 'package:family_hub/features/bazar/fund/domain/month_closing.dart';
import 'package:family_hub/features/bazar/fund/domain/month_plans.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings_repository.dart';
import 'package:family_hub/features/family/domain/family_repository.dart';
import 'package:family_hub/features/family/domain/permission_access.dart';

/// First month whose rows count towards the balance that [month] closes.
///
/// The month after the latest closed month, or [fundStartMonth] when nothing
/// has been closed yet, or [month] itself for a family that never set up a
/// fund (`MonthLocks.fundWindowStart` plus that fallback).
MonthKey closeWindowStart({
  required MonthKey month,
  required Iterable<MonthClosing> closings,
  required MonthKey? fundStartMonth,
}) {
  final start =
      MonthLocks.fundWindowStart(<MonthKey, MonthClosing>{
        for (final closing in closings) closing.monthKey: closing,
      }, fundStartMonth) ??
      month;
  return start.compareTo(month) > 0 ? month : start;
}

/// Closes one Bazar month and carries its balance into the next one.
///
/// ONE server-required batch: `monthClosings/<month>` becomes `closed` with
/// `closingBalance`, and the next month receives that balance as an `opening`
/// row (`open_<next>`) — or, when that row already exists (a re-close after a
/// reopen), a compensating `adj_<eventId>_carry` row of the difference.  The
/// opening row itself is never edited (rule 28, ADR 0007).
///
/// The balance is computed from a SERVER read of the ledger window just before
/// the write.  The mobile SDK cannot query inside a transaction, so a row
/// created in that instant can be missed; the Fund screen's integrity check
/// shows the difference to a manager, and Reopen -> fix -> Close repairs it
/// through the delta row.
///
/// Permission: `closeBazarMonth` (admin, or a moderator while
/// `moderatorManagesFinance` is on) — the same person the rules let write the
/// `opening` row.
class CloseMonth {
  const CloseMonth({
    required this._funds,
    required this._openingRows,
    required this._settings,
    required this._families,
    required this._clock,
    required this._newId,
    required this._dateKeys,
  });

  final FundRepository _funds;
  final ExistingOpeningLedger _openingRows;
  final BazarSettingsRepository _settings;
  final FamilyRepository _families;
  final Clock _clock;
  final IdGenerator _newId;
  final FamilyDateKeys _dateKeys;

  Future<Result<MonthClosing>> call({
    required String actorUid,
    required String familyId,
    required MonthKey month,
    String? eventId,
    String? note,
  }) async {
    final permitted = await requirePermission(
      _families,
      familyId: familyId,
      actorUid: actorUid,
      permission: Permission.closeBazarMonth,
    );
    final denied = permitted.failureOrNull;
    if (denied != null) return Failure<MonthClosing>(denied);

    if (month.compareTo(_dateKeys.thisMonth()) > 0) {
      return const Failure<MonthClosing>(Validation('month', 'invalid_month'));
    }

    final closings = await _funds.watchClosings(familyId).first;
    final current = closings
        .where((closing) => closing.monthKey == month)
        .firstOrNull;
    if (current != null && current.status == MonthStatus.closed) {
      return const Failure<MonthClosing>(Conflict(code: 'already_closed'));
    }
    final later = MonthCarryForwardRules.latestClosed(closings);
    if (later != null && later.compareTo(month) > 0) {
      return const Failure<MonthClosing>(Conflict(code: 'month_locked'));
    }

    final settings = await _settings.get(familyId);
    final settingsFailure = settings.failureOrNull;
    if (settingsFailure != null) return Failure<MonthClosing>(settingsFailure);

    final start = closeWindowStart(
      month: month,
      closings: closings,
      fundStartMonth: settings.valueOrNull!.fundStartMonth,
    );
    final rows = await _funds.getTransactionsFromServer(familyId, start);
    final loadFailure = rows.failureOrNull;
    if (loadFailure != null) return Failure<MonthClosing>(loadFailure);
    final window = <FundTransaction>[
      for (final row in rows.valueOrNull!)
        if (row.monthKey.compareTo(month) <= 0) row,
    ];

    final existing = await _openingRows.getOpeningAmount(
      familyId,
      month.addMonths(1),
    );
    final existingFailure = existing.failureOrNull;
    if (existingFailure != null) {
      return Failure<MonthClosing>(existingFailure);
    }

    final now = _clock.nowUtc();
    final event = eventId ?? _newId();
    final closingBalance = FundBalanceCalculator.balance(window);
    final carry = MonthCarryForwardRules.compute(
      month: month,
      closingBalance: closingBalance,
      existingOpening: existing.valueOrNull,
      actorUid: actorUid,
      at: now,
      eventId: event,
      note: _cleanNote(note),
    );

    final closing = MonthClosing(
      monthKey: month,
      status: MonthStatus.closed,
      closedAt: now,
      closedBy: actorUid,
      closingBalance: closingBalance,
      reopenCount: current?.reopenCount ?? 0,
    );
    final saved = await _funds.commitClose(
      familyId,
      MonthClosePlan(
        closing: closing,
        nextOpening: carry.opening,
        nextAdjustment: carry.adjustment,
      ),
      AuditEvent(
        id: event,
        type: AuditEventType.bazarMonthClosed,
        actorId: actorUid,
        refType: AuditRefType.month,
        refId: month.toString(),
        at: now,
        params: <String, String>{
          'month': month.toString(),
          'closingBalance': closingBalance.paisa.toString(),
          'nextOpening': carry.opening?.amount.paisa.toString() ?? '',
          'nextAdjustment': carry.adjustment?.amount.paisa.toString() ?? '',
        },
      ),
    );
    final failure = saved.failureOrNull;
    return failure != null
        ? Failure<MonthClosing>(failure)
        : Success<MonthClosing>(closing);
  }

  static String? _cleanNote(String? note) {
    final trimmed = note?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
