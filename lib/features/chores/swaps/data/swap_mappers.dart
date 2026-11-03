import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_write_plan.dart';

/// Pure functions between [SwapRequest] and `swapRequests/{id}`.
///
/// [toMap] is the closed key set of the P3-26 rules (`swapKeys`), checked by
/// `swap_mappers_test.dart`.
abstract final class SwapMappers {
  static Map<String, dynamic> toMap(
    NewSwap swap, {
    required String actorId,
    required DateTime at,
  }) => <String, dynamic>{
    'occurrenceId': swap.occurrenceId,
    'occurrenceDateKey': swap.occurrenceDateKey.toString(),
    'kind': swap.kind.id,
    'fromMemberId': swap.fromMemberId,
    'toMemberId': swap.toMemberId,
    'reason': swap.reason,
    'status': SwapStatus.pending.id,
    'expiresAt': BaseMapper.dateTimeToTimestamp(swap.expiresAt),
    'respondedAt': null,
    'respondedBy': null,
    'responseReason': null,
    'availabilityId': swap.availabilityId,
    'requestedBy': actorId,
    ...BaseMapper.metadataToMap(
      BaseDocumentMetadata(
        createdAt: at,
        createdBy: actorId,
        updatedAt: at,
        updatedBy: actorId,
      ),
    ),
  };

  /// ONLY the keys a status change may touch.
  static Map<String, dynamic> changeMap(
    SwapChange change, {
    required String actorId,
    required DateTime at,
  }) => <String, dynamic>{
    'status': change.status.id,
    'respondedAt': BaseMapper.dateTimeToTimestamp(at),
    'respondedBy': actorId,
    'responseReason': change.responseReason,
    BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(at),
    BaseMapper.keyUpdatedBy: actorId,
  };

  static SwapRequest? fromDoc(String id, Map<String, dynamic>? map) {
    if (map == null) return null;
    final date = DateKey.parse('${map['occurrenceDateKey']}').valueOrNull;
    final expires = BaseMapper.timestampToDateTime(map['expiresAt']);
    final from = map['fromMemberId'];
    final to = map['toMemberId'];
    final occurrenceId = map['occurrenceId'];
    if (date == null || expires == null) return null;
    if (from is! String || to is! String || occurrenceId is! String) return null;
    return SwapRequest(
      id: id,
      occurrenceId: occurrenceId,
      occurrenceDateKey: date,
      kind: SwapKind.fromId(map['kind']),
      fromMemberId: from,
      toMemberId: to,
      reason: '${map['reason'] ?? ''}',
      status: SwapStatus.fromId(map['status']),
      expiresAt: expires,
      requestedBy: map['requestedBy'] is String ? map['requestedBy'] as String : from,
      respondedAt: BaseMapper.timestampToDateTime(map['respondedAt']),
      respondedBy: map['respondedBy'] is String ? map['respondedBy'] as String : null,
      responseReason: map['responseReason'] is String ? map['responseReason'] as String : null,
      availabilityId: map['availabilityId'] is String ? map['availabilityId'] as String : null,
    );
  }
}
