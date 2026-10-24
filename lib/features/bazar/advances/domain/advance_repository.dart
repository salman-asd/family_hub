import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement.dart';

/// Read port for member advances and their append-only settlements.
///
/// P2-20 extends this interface with `commitSettlement`.
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
}
