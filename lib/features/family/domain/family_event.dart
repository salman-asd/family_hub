/// One activity + audit entry, written in the same batch as the change it
/// describes (CLAUDE.md rule 3).
class FamilyEvent {
  const FamilyEvent({
    required this.id,
    required this.type,
    required this.actorId,
    required this.summary,
    required this.refType,
    required this.refId,
    required this.at,
    this.params = const <String, String>{},
  });

  final String id;

  /// Machine type, e.g. `family.created`, `member.approved`.
  final String type;
  final String actorId;

  /// Short English summary for audit readers (the UI localizes by [type]).
  final String summary;
  final String refType;
  final String refId;
  final DateTime at;

  /// Small machine payload (at most 8 keys, enforced by the rules) a screen
  /// localizes: e.g. `{familyName}` or `{memberName, newRole}`.  Never display
  /// text (CLAUDE.md rule 18).
  final Map<String, String> params;
}
