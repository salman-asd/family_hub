/// One notification of one member (`notificationInbox/{id}`, D-P3-19).
///
/// Module-neutral: [type] is one of `InboxType.all`, [refType]/[refId] say what
/// it is about (an occurrence, a swap request, an availability record) and
/// [params] carry the few strings the text needs (names, dates, a count).
final class InboxItem {
  const InboxItem({
    required this.id,
    required this.toMemberId,
    required this.type,
    required this.refType,
    required this.refId,
    required this.createdAt,
    this.params = const <String, String>{},
    this.readAt,
    this.archivedAt,
  });

  final String id;
  final String toMemberId;
  final String type;
  final String refType;
  final String refId;
  final DateTime createdAt;
  final Map<String, String> params;
  final DateTime? readAt;
  final DateTime? archivedAt;

  bool get isUnread => readAt == null && archivedAt == null;
  bool get isArchived => archivedAt != null;

  InboxItem copyWith({DateTime? readAt, DateTime? archivedAt}) => InboxItem(
    id: id,
    toMemberId: toMemberId,
    type: type,
    refType: refType,
    refId: refId,
    createdAt: createdAt,
    params: params,
    readAt: readAt ?? this.readAt,
    archivedAt: archivedAt ?? this.archivedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is InboxItem &&
      other.id == id &&
      other.toMemberId == toMemberId &&
      other.type == type &&
      other.refType == refType &&
      other.refId == refId &&
      other.createdAt == createdAt &&
      other.readAt == readAt &&
      other.archivedAt == archivedAt;

  @override
  int get hashCode =>
      Object.hash(id, toMemberId, type, refId, readAt, archivedAt);

  @override
  String toString() => 'InboxItem($id $type to $toMemberId)';
}
