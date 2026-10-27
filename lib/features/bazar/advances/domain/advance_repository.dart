import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement_plan.dart';

/// Read port for member advances and their append-only settlements.
abstract interface class AdvanceRepository {
  /// Advances whose status is `pending` or `partial`.
  ///
  /// The rules let a plain member read only their own advances, and a rules
  /// check is not a filter, so a caller without manager rights MUST pass its
  /// own uid as [memberId] or the whole query is denied.
  Stream<List<MemberAdvance>> watchOpenAdvances(
    String familyId, {
    String? memberId,
  });

  Future<Result<MemberAdvance?>> getAdvance(String familyId, String expenseId);

  Stream<List<Settlement>> watchSettlements(
    String familyId, {
    String? advanceId,
  });

  /// Writes ONE settlement, its ledger row and the advance update in one batch.
  ///
  /// [build] receives the advance as read INSIDE the write (the repository
  /// reads it immediately before staging), so overpayment and void checks use
  /// fresh state; a `Failure` from [build] writes nothing.  Needs the server.
  Future<Result<SettlementPlan>> commitSettlement(
    String familyId, {
    required String advanceId,
    required Result<SettlementPlan> Function(MemberAdvance? current) build,
    required AuditEvent event,
  });
}
