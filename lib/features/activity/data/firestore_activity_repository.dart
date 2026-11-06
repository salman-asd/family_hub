import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/features/activity/data/activity_mappers.dart';
import 'package:family_hub/features/activity/domain/activity_entry.dart';
import 'package:family_hub/features/activity/domain/activity_repository.dart';

/// Firestore reader for `families/{familyId}/activity`.
///
/// Page one is the only listener. Snapshots returned by this repository are
/// retained so later pages can use Firestore's document cursor without
/// exposing Firebase types to the domain layer.
class FirestoreActivityRepository implements ActivityRepository {
  FirestoreActivityRepository({this.firestore});

  final FirebaseFirestore? firestore;
  final Map<String, DocumentSnapshot<Map<String, dynamic>>> _cursors =
      <String, DocumentSnapshot<Map<String, dynamic>>>{};

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  String _cursorKey(String familyId, String? actorId, String documentId) =>
      '$familyId/${actorId ?? ''}/$documentId';

  Query<Map<String, dynamic>> _query(
    String familyId, {
    String? actorId,
    required int limit,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection(FirestorePaths.activity(familyId))
        .limit(limit);
    if (actorId != null) query = query.where('actorId', isEqualTo: actorId);
    return query
        .orderBy(BaseMapper.keyCreatedAt, descending: true)
        .orderBy(FieldPath.documentId, descending: true);
  }

  ActivityPage _page(
    String familyId,
    QuerySnapshot<Map<String, dynamic>> snapshot,
    int limit,
    String? actorId,
  ) {
    if (snapshot.docs.isNotEmpty) {
      final cursor = snapshot.docs.last;
      _cursors[_cursorKey(familyId, actorId, cursor.id)] = cursor;
    }
    return ActivityPage(
      entries: <ActivityEntry>[
        for (final doc in snapshot.docs)
          ?ActivityMappers.fromDoc(doc.id, doc.data()),
      ],
      cursorId: snapshot.docs.isEmpty ? null : snapshot.docs.last.id,
      hasMore: snapshot.docs.length == limit,
    );
  }

  @override
  Stream<List<ActivityEntry>> watchRecent(
    String familyId, {
    required int limit,
  }) => _query(familyId, limit: limit.clamp(1, kMaxDashboardActivity).toInt())
      .snapshots()
      .map(
        (snapshot) => <ActivityEntry>[
          for (final doc in snapshot.docs)
            ?ActivityMappers.fromDoc(doc.id, doc.data()),
        ],
      );

  @override
  Stream<ActivityPage> watchFirstPage(
    String familyId, {
    String? actorId,
    required int limit,
  }) {
    final boundedLimit = limit.clamp(1, kMaxActivityPage).toInt();
    return _query(familyId, actorId: actorId, limit: boundedLimit)
        .snapshots()
        .map((snapshot) => _page(familyId, snapshot, boundedLimit, actorId));
  }

  @override
  Future<Result<ActivityPage>> readOlderPage(
    String familyId, {
    String? actorId,
    required String afterDocumentId,
    required int limit,
  }) => guardFirestore(() async {
    final cursor = _cursors[_cursorKey(familyId, actorId, afterDocumentId)];
    if (cursor == null || cursor.id != afterDocumentId) {
      throw StateError('Activity cursor is no longer available.');
    }
    final boundedLimit = limit.clamp(1, kMaxActivityPage).toInt();
    final snapshot = await _query(
      familyId,
      actorId: actorId,
      limit: boundedLimit,
    ).startAfterDocument(cursor).get();
    return _page(familyId, snapshot, boundedLimit, actorId);
  });
}
