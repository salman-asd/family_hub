import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/domain/availability_write_plan.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';

/// Pure functions between [MemberAvailability] and `memberAvailability/{id}`.
/// [toMap] is the closed key set of the P3-26 rules (`availabilityKeys`).
abstract final class AvailabilityMappers {
  static Map<String, dynamic> toMap(
    NewAvailability record, {
    required String actorId,
    required DateTime at,
  }) => <String, dynamic>{
    'memberId': record.memberId,
    'startDateKey': record.startDate.toString(),
    'endDateKey': record.endDate.toString(),
    'typeId': record.typeId,
    'reason': record.reason,
    'status': record.status.id,
    'decidedBy': null,
    'decidedAt': null,
    ...BaseMapper.metadataToMap(
      BaseDocumentMetadata(
        createdAt: at,
        createdBy: actorId,
        updatedAt: at,
        updatedBy: actorId,
      ),
    ),
  };

  static Map<String, dynamic> changeMap(
    AvailabilityChange change, {
    required String actorId,
    required DateTime at,
  }) => <String, dynamic>{
    'status': change.status.id,
    'decidedBy': actorId,
    'decidedAt': BaseMapper.dateTimeToTimestamp(at),
    BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(at),
    BaseMapper.keyUpdatedBy: actorId,
  };

  static MemberAvailability? fromDoc(String id, Map<String, dynamic>? map) {
    if (map == null) return null;
    final start = DateKey.parse('${map['startDateKey']}').valueOrNull;
    final end = DateKey.parse('${map['endDateKey']}').valueOrNull;
    final member = map['memberId'];
    if (start == null || end == null || member is! String) return null;
    return MemberAvailability(
      id: id,
      memberId: member,
      startDate: start,
      endDate: end,
      typeId: '${map['typeId'] ?? ''}',
      reason: '${map['reason'] ?? ''}',
      status: AvailabilityStatus.fromId(map['status']),
      createdBy: map['createdBy'] is String
          ? map['createdBy'] as String
          : member,
      decidedBy: map['decidedBy'] is String ? map['decidedBy'] as String : null,
      decidedAt: BaseMapper.timestampToDateTime(map['decidedAt']),
    );
  }
}
