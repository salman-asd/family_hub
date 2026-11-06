import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/availability/data/availability_mappers.dart';
import 'package:family_hub/features/chores/availability/domain/availability_repository.dart';
import 'package:family_hub/features/chores/availability/domain/availability_write_plan.dart';
import 'package:family_hub/features/chores/availability/domain/member_availability.dart';
import 'package:family_hub/features/chores/occurrences/data/occurrence_write_stager.dart';
import 'package:family_hub/features/chores/swaps/data/swap_mappers.dart';

/// Firestore implementation of [AvailabilityRepository].
///
/// Reads are bounded by [kMaxAvailabilityDocs] and ordered by `endDateKey`
/// descending, which the `(status, endDateKey)` and `(memberId, endDateKey)`
/// indexes serve. A write is one batch: the availability documents, the cover
/// requests of policy B, and the inbox rows and audit entries.
class FirestoreAvailabilityRepository implements AvailabilityRepository {
  FirestoreAvailabilityRepository({
    required this._tx,
    this._firestore,
    this._probe,
  });

  final TxRunner _tx;
  final FirebaseFirestore? _firestore;
  final ServerProbe? _probe;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String familyId) =>
      _db.collection(FirestorePaths.memberAvailability(familyId));

  static List<MemberAvailability> _read(
    QuerySnapshot<Map<String, dynamic>> s,
  ) => <MemberAvailability>[
    for (final doc in s.docs) ?AvailabilityMappers.fromDoc(doc.id, doc.data()),
  ];

  @override
  Stream<List<MemberAvailability>> watchLive(String familyId, DateKey since) =>
      _col(familyId)
          .where('status', whereIn: <String>['pending', 'active'])
          .where('endDateKey', isGreaterThanOrEqualTo: since.toString())
          .orderBy('endDateKey', descending: true)
          .limit(kMaxAvailabilityDocs)
          .snapshots()
          .map(_read);

  @override
  Future<Result<MemberAvailability?>> get(String familyId, String id) =>
      guardFirestore(() async {
        final doc = await _col(familyId).doc(id).get();
        return AvailabilityMappers.fromDoc(doc.id, doc.data());
      });

  @override
  Future<Result<List<MemberAvailability>>> listLiveFor(
    String familyId,
    String memberId,
  ) => guardFirestore(() async {
    final snapshot = await _col(familyId)
        .where('memberId', isEqualTo: memberId)
        .orderBy('endDateKey', descending: true)
        .limit(kMaxAvailabilityDocs)
        .get();
    return <MemberAvailability>[
      for (final record in _read(snapshot))
        if (record.isLive) record,
    ];
  });

  @override
  Future<Result<List<MemberAvailability>>> listActive(
    String familyId,
    DateKey since,
  ) => guardFirestore(() async {
    final snapshot = await _col(familyId)
        .where('status', isEqualTo: 'active')
        .where('endDateKey', isGreaterThanOrEqualTo: since.toString())
        .orderBy('endDateKey', descending: true)
        .limit(kMaxAvailabilityDocs)
        .get();
    return _read(snapshot);
  });

  @override
  Future<Result<void>> stage(
    String familyId,
    AvailabilityWritePlan plan, {
    required bool integrity,
  }) {
    Future<void> commit() => _tx.runBatch((batch) {
      OccurrenceWriteStager.stage(batch, familyId, plan.occurrence);
      for (final record in plan.creates) {
        batch.set(
          FirestorePaths.memberAvailabilityDoc(familyId, record.id),
          AvailabilityMappers.toMap(record, actorId: plan.actorId, at: plan.at),
        );
      }
      for (final change in plan.changes) {
        batch.update(
          FirestorePaths.memberAvailabilityDoc(familyId, change.availabilityId),
          AvailabilityMappers.changeMap(
            change,
            actorId: plan.actorId,
            at: plan.at,
          ),
        );
      }
      for (final swap in plan.swaps) {
        batch.set(
          FirestorePaths.swapRequestDoc(familyId, swap.id),
          SwapMappers.toMap(swap, actorId: plan.actorId, at: plan.at),
        );
      }
    });
    if (!integrity) return guardWrite(commit);
    return guardWrite(
      commit,
      probe: _probe ?? serverProbeFor(_db, plan.actorId),
    );
  }
}
