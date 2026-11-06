import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/features/activity/domain/activity_entry.dart';

abstract final class ActivityMappers {
  static ActivityEntry? fromDoc(String id, Map<String, dynamic> data) {
    final type = data['type'];
    final actorId = data['actorId'];
    final refType = data['refType'];
    final refId = data['refId'];
    final createdAt = BaseMapper.timestampToDateTime(
      data[BaseMapper.keyCreatedAt],
    );
    if (type is! String ||
        type.isEmpty ||
        actorId is! String ||
        actorId.isEmpty ||
        refType is! String ||
        refType.isEmpty ||
        refId is! String ||
        refId.isEmpty ||
        createdAt == null) {
      return null;
    }

    final rawParams = data['params'];
    final params = <String, String>{
      if (rawParams is Map)
        for (final entry in rawParams.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
    };
    return ActivityEntry(
      id: id,
      type: type,
      actorId: actorId,
      params: params,
      refType: refType,
      refId: refId,
      createdAt: createdAt,
    );
  }
}
