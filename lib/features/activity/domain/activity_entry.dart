/// One append-only family activity record.
///
/// [type] is intentionally not an enum: newer clients may write values this
/// app does not know, and the localized activity text has a neutral fallback.
final class ActivityEntry {
  ActivityEntry({
    required this.id,
    required this.type,
    required this.actorId,
    required Map<String, String> params,
    required this.refType,
    required this.refId,
    required this.createdAt,
  }) : params = Map<String, String>.unmodifiable(params);

  final String id;
  final String type;
  final String actorId;
  final Map<String, String> params;
  final String refType;
  final String refId;
  final DateTime createdAt;

  ActivityEntry copyWith({
    String? type,
    String? actorId,
    Map<String, String>? params,
    String? refType,
    String? refId,
    DateTime? createdAt,
  }) => ActivityEntry(
    id: id,
    type: type ?? this.type,
    actorId: actorId ?? this.actorId,
    params: params ?? this.params,
    refType: refType ?? this.refType,
    refId: refId ?? this.refId,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) =>
      other is ActivityEntry &&
      other.id == id &&
      other.type == type &&
      other.actorId == actorId &&
      _stringMapsEqual(other.params, params) &&
      other.refType == refType &&
      other.refId == refId &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    type,
    actorId,
    Object.hashAll(
      (params.keys.toList()..sort()).map(
        (key) => Object.hash(key, params[key]),
      ),
    ),
    refType,
    refId,
    createdAt,
  );
}

bool _entryListsEqual(List<ActivityEntry> a, List<ActivityEntry> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

bool _stringMapsEqual(Map<String, String> a, Map<String, String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// A bounded page from the family activity collection.
final class ActivityPage {
  ActivityPage({
    required List<ActivityEntry> entries,
    required this.cursorId,
    required this.hasMore,
  }) : entries = List<ActivityEntry>.unmodifiable(entries);

  ActivityPage.empty()
    : entries = const <ActivityEntry>[],
      cursorId = null,
      hasMore = false;

  final List<ActivityEntry> entries;

  /// The last Firestore document id, retained even if its payload was malformed.
  final String? cursorId;
  final bool hasMore;

  ActivityPage copyWith({
    List<ActivityEntry>? entries,
    String? cursorId,
    bool clearCursor = false,
    bool? hasMore,
  }) => ActivityPage(
    entries: entries ?? this.entries,
    cursorId: clearCursor ? null : cursorId ?? this.cursorId,
    hasMore: hasMore ?? this.hasMore,
  );

  @override
  bool operator ==(Object other) =>
      other is ActivityPage &&
      other.cursorId == cursorId &&
      other.hasMore == hasMore &&
      _entryListsEqual(other.entries, entries);

  @override
  int get hashCode => Object.hash(Object.hashAll(entries), cursorId, hasMore);
}
