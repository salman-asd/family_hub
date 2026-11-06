/// Inbox row staged with the transition from pending to active membership.
final class MemberApprovalNotification {
  const MemberApprovalNotification({
    required this.id,
    required this.toMemberId,
    required this.actorId,
    required this.at,
  });

  final String id;
  final String toMemberId;
  final String actorId;
  final DateTime at;
}
