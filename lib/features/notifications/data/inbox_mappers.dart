import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/features/notifications/domain/inbox_item.dart';

/// Reads `notificationInbox/{id}`. The document is CREATED by
/// `OccurrenceWriteStager` (another member's batch); the owner only changes
/// `readAt`/`archivedAt`, which [readMap] and [archiveMap] write.
abstract final class InboxMappers {
  static Map<String, dynamic> readMap({
    required String actorId,
    required DateTime at,
  }) => <String, dynamic>{
    'readAt': BaseMapper.dateTimeToTimestamp(at),
    BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(at),
    BaseMapper.keyUpdatedBy: actorId,
  };

  static Map<String, dynamic> archiveMap({
    required String actorId,
    required DateTime at,
  }) => <String, dynamic>{
    'archivedAt': BaseMapper.dateTimeToTimestamp(at),
    BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(at),
    BaseMapper.keyUpdatedBy: actorId,
  };

  static InboxItem? fromDoc(String id, Map<String, dynamic>? map) {
    if (map == null) return null;
    final to = map['toMemberId'];
    final type = map['type'];
    final refType = map['refType'];
    final refId = map['refId'];
    if (to is! String || type is! String) return null;
    if (refType is! String || refId is! String) return null;
    final raw = map['params'];
    return InboxItem(
      id: id,
      toMemberId: to,
      type: type,
      refType: refType,
      refId: refId,
      createdAt:
          BaseMapper.timestampToDateTime(map[BaseMapper.keyCreatedAt]) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      params: raw is Map
          ? <String, String>{
              for (final e in raw.entries) '${e.key}': '${e.value}',
            }
          : const <String, String>{},
      readAt: BaseMapper.timestampToDateTime(map['readAt']),
      archivedAt: BaseMapper.timestampToDateTime(map['archivedAt']),
    );
  }
}
