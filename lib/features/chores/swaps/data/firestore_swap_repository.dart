import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/features/chores/occurrences/data/occurrence_write_stager.dart';
import 'package:family_hub/features/chores/swaps/data/swap_mappers.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_repository.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_request.dart';
import 'package:family_hub/features/chores/swaps/domain/swap_write_plan.dart';

/// Firestore implementation of [SwapRepository].
///
/// Every read is bounded by [kMaxSwapDocs]. A write stages the occurrence part
/// through the shared [OccurrenceWriteStager], then the request documents, in
/// ONE batch; [integrity] probes the server first (offline accepts must not
/// queue, road map 3.4).
class FirestoreSwapRepository implements SwapRepository {
  FirestoreSwapRepository({required this._tx, this._firestore, this._probe});

  final TxRunner _tx;
  final FirebaseFirestore? _firestore;
  final ServerProbe? _probe;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String familyId) =>
      _db.collection(FirestorePaths.swapRequests(familyId));

  static List<SwapRequest> _read(QuerySnapshot<Map<String, dynamic>> s) {
    final list = <SwapRequest>[
      for (final doc in s.docs) ?SwapMappers.fromDoc(doc.id, doc.data()),
    ]..sort((a, b) => b.expiresAt.compareTo(a.expiresAt));
    return list;
  }

  @override
  Stream<List<SwapRequest>> watchPending(String familyId) =>
      _col(familyId)
          .where('status', isEqualTo: SwapStatus.pending.id)
          .limit(kMaxSwapDocs)
          .snapshots()
          .map(_read);

  @override
  Future<Result<SwapRequest?>> get(String familyId, String requestId) =>
      guardFirestore(() async {
        final doc = await _col(familyId).doc(requestId).get();
        return SwapMappers.fromDoc(doc.id, doc.data());
      });

  @override
  Future<Result<List<SwapRequest>>> listPendingForOccurrence(
    String familyId,
    String occurrenceId,
  ) => guardFirestore(() async {
    final snapshot = await _col(familyId)
        .where('occurrenceId', isEqualTo: occurrenceId)
        .where('status', isEqualTo: SwapStatus.pending.id)
        .limit(kMaxSwapDocs)
        .get();
    return _read(snapshot);
  });

  @override
  Future<Result<List<SwapRequest>>> listPending(String familyId) =>
      guardFirestore(() async {
        final snapshot = await _col(familyId)
            .where('status', isEqualTo: SwapStatus.pending.id)
            .limit(kMaxSwapDocs)
            .get();
        return _read(snapshot);
      });

  @override
  Future<Result<List<SwapRequest>>> listExpired(
    String familyId,
    DateTime now,
  ) => guardFirestore(() async {
    final snapshot = await _col(familyId)
        .where('status', isEqualTo: SwapStatus.pending.id)
        .where(
          'expiresAt',
          isLessThanOrEqualTo: BaseMapper.dateTimeToTimestamp(now),
        )
        .limit(kMaxSwapDocs)
        .get();
    return _read(snapshot);
  });

  @override
  Future<Result<void>> stage(
    String familyId,
    SwapWritePlan plan, {
    required bool integrity,
  }) {
    Future<void> commit() => _tx.runBatch((batch) {
      OccurrenceWriteStager.stage(batch, familyId, plan.occurrence);
      for (final swap in plan.creates) {
        batch.set(
          FirestorePaths.swapRequestDoc(familyId, swap.id),
          SwapMappers.toMap(swap, actorId: plan.actorId, at: plan.at),
        );
      }
      for (final change in plan.changes) {
        batch.update(
          FirestorePaths.swapRequestDoc(familyId, change.requestId),
          SwapMappers.changeMap(change, actorId: plan.actorId, at: plan.at),
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
