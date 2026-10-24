import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/features/bazar/advances/data/advance_mappers.dart';
import 'package:family_hub/features/bazar/advances/domain/advance_repository.dart';
import 'package:family_hub/features/bazar/advances/domain/member_advance.dart';
import 'package:family_hub/features/bazar/advances/domain/settlement.dart';

/// Read-only Firestore implementation of the advance/settlement port.
///
/// `commitSettlement` arrives with P2-20.
class FirestoreAdvanceRepository implements AdvanceRepository {
  FirestoreAdvanceRepository([this._firestore]);

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<MemberAdvance>> watchOpenAdvances(
    String familyId, {
    String? memberId,
  }) {
    var query = _db.collection(FirestorePaths.memberAdvances(familyId)).where(
      'status',
      whereIn: <String>[AdvanceStatus.pending.name, AdvanceStatus.partial.name],
    );
    if (memberId != null) {
      query = query.where('memberId', isEqualTo: memberId);
    }
    return query
        .orderBy('dateKey', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => <MemberAdvance>[
            for (final document in snapshot.docs)
              AdvanceMappers.advanceFromMap(document.id, document.data()),
          ],
        );
  }

  @override
  Future<Result<MemberAdvance?>> getAdvance(
    String familyId,
    String expenseId,
  ) => guardFirestore(() async {
    final snapshot = await _db
        .doc(FirestorePaths.memberAdvanceDoc(familyId, expenseId))
        .get();
    if (!snapshot.exists) return null;
    return AdvanceMappers.advanceFromMap(expenseId, snapshot.data()!);
  });

  @override
  Stream<List<Settlement>> watchSettlements(
    String familyId, {
    String? advanceId,
  }) {
    var query = _db
        .collection(FirestorePaths.settlements(familyId))
        .where('advanceId', isEqualTo: advanceId ?? '')
        .orderBy('dateKey', descending: true)
        .limit(50);
    if (advanceId == null) {
      query = _db
          .collection(FirestorePaths.settlements(familyId))
          .orderBy('dateKey', descending: true)
          .limit(50);
    }
    return query.snapshots().map(
      (snapshot) => <Settlement>[
        for (final document in snapshot.docs)
          AdvanceMappers.settlementFromMap(document.id, document.data()),
      ],
    );
  }
}
