import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/doc_watch.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/chores/achievements/data/member_stats_mappers.dart';
import 'package:family_hub/features/chores/achievements/data/public_stats_mappers.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats_repository.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';

final class FirestoreMemberStatsRepository implements MemberStatsRepository {
  FirestoreMemberStatsRepository({
    required this.tx,
    required this.clock,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final TxRunner tx;
  final Clock clock;
  final FirebaseFirestore _db;

  @override
  Stream<MemberStats?> watch(
    String familyId,
    String memberId, {
    required DateKey defaultStartedOn,
  }) => watchKnownDoc(_db.doc(_statsPath(familyId, memberId)))
      .map(
        (map) => map == null
            ? null
            : MemberStatsMappers.fromMap(
                map,
                defaultStartedOn: defaultStartedOn,
              ),
      )
      .distinct();

  @override
  Future<Result<MemberStats?>> get(
    String familyId,
    String memberId, {
    required DateKey defaultStartedOn,
  }) async {
    final loaded = await guardFirestore(
      () => _db.doc(_statsPath(familyId, memberId)).get(),
    );
    final failure = loaded.failureOrNull;
    if (failure != null) return Failure<MemberStats?>(failure);
    final snapshot = loaded.valueOrNull!;
    if (!snapshot.exists && snapshot.metadata.isFromCache) {
      return const Failure<MemberStats?>(Network());
    }
    return Success<MemberStats?>(
      snapshot.exists
          ? MemberStatsMappers.fromMap(
              snapshot.data(),
              defaultStartedOn: defaultStartedOn,
            )
          : null,
    );
  }

  @override
  Future<Result<void>> save(
    String familyId,
    String memberId,
    MemberStats stats, {
    required PublicStats? publicStats,
  }) => guardWrite(() async {
    final privatePath = _statsPath(familyId, memberId);
    final publicPath = _publicPath(familyId, memberId);
    final privateSnapshot = await _db.doc(privatePath).get();
    final publicSnapshot = publicStats == null
        ? null
        : await _db.doc(publicPath).get();
    final privateMetadata = _metadata(privateSnapshot.data(), memberId);
    final publicMetadata = publicSnapshot == null
        ? null
        : _metadata(publicSnapshot.data(), memberId);

    await tx.runBatch((batch) {
      batch.set(
        privatePath,
        MemberStatsMappers.toMap(stats, _updated(privateMetadata, memberId)),
      );
      if (publicStats case final PublicStats publicCard) {
        batch.set(
          publicPath,
          PublicStatsMappers.toMap(
            publicCard,
            _updated(publicMetadata!, memberId),
          ),
        );
      } else {
        batch.delete(publicPath);
      }
    });
  });

  String _statsPath(String familyId, String uid) =>
      FirestorePaths.memberStatsDoc(familyId, uid);

  String _publicPath(String familyId, String uid) =>
      FirestorePaths.memberStatsPublicDoc(familyId, uid);

  BaseDocumentMetadata _metadata(Map<String, dynamic>? map, String uid) =>
      map == null
      ? BaseMapper.createMetadata(uid: uid, clock: clock)
      : BaseMapper.metadataFromMap(map);

  BaseDocumentMetadata _updated(BaseDocumentMetadata current, String uid) =>
      current.copyWith(updatedAt: clock.nowUtc(), updatedBy: uid);
}
