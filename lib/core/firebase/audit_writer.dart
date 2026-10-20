import 'package:family_hub/core/audit/audit_event.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/server_time.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';

/// The ONE place that writes audit and activity entries (CLAUDE.md rule 18).
///
/// Every repository calls [write] inside the same batch as the change it
/// describes, so the log can never disagree with the data.  The same map goes
/// to `families/{f}/activity/{id}` and `families/{f}/auditLogs/{id}`; the rules
/// require `actorId == auth.uid`, a known `type`/`refType` and a SERVER
/// `recordedAt` (the client `createdAt` is the device clock only).
abstract final class AuditWriter {
  /// Stages the activity and audit documents for [event] on [batch].
  static void write(BatchContext batch, String familyId, AuditEvent event) {
    final data = toMap(event);
    batch
      ..set(FirestorePaths.activityDoc(familyId, event.id), data)
      ..set(FirestorePaths.auditLogDoc(familyId, event.id), data);
  }

  /// The document shape, shared with the contract fixtures.
  static Map<String, dynamic> toMap(AuditEvent e) => <String, dynamic>{
        'type': e.type,
        'actorId': e.actorId,
        'summary': e.summary,
        'refType': e.refType,
        'refId': e.refId,
        'params': e.params,
        // The server clock: the rules require recordedAt == request.time.
        'recordedAt': ServerTime.instance,
        BaseMapper.keyCreatedAt: BaseMapper.dateTimeToTimestamp(e.at),
        BaseMapper.keyCreatedBy: e.actorId,
        BaseMapper.keyUpdatedAt: BaseMapper.dateTimeToTimestamp(e.at),
        BaseMapper.keyUpdatedBy: e.actorId,
        BaseMapper.keySchemaVersion: 1,
      };
}
