/// One activity + audit entry, written in the same batch as the change it
/// describes (CLAUDE.md rules 3 and 18).
///
/// Pure Dart: every feature builds one and hands it to its repository, which
/// writes it through `AuditWriter` (`core/firebase/audit_writer.dart`).
class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.type,
    required this.actorId,
    required this.refType,
    required this.refId,
    required this.at,
    this.summary = '',
    this.params = const <String, String>{},
  });

  final String id;

  /// Machine type, one of the `AuditEventType` constants.
  final String type;
  final String actorId;

  /// The kind of record the event is about: `family`, `member`, `invitation`.
  final String refType;
  final String refId;

  /// When it happened on the device (the server time is `recordedAt`).
  final DateTime at;

  /// Always empty since H10: the document keeps an (empty) `summary` field only
  /// because the closed key set in the rules still lists it.  Never put display
  /// text here; a screen localizes by [type] + [params] (`activityText`).
  final String summary;

  /// Small machine payload (at most 8 keys, enforced by the rules) a screen
  /// localizes: e.g. `{familyName}` or `{memberName, newRole}`.  Never display
  /// text (CLAUDE.md rule 18).
  final Map<String, String> params;
}
