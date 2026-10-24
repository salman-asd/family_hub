import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/doc_watch.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/settings/domain/account_repository.dart';

/// `users/{uid}` account lifecycle (H9).
class FirestoreAccountRepository implements AccountRepository {
  FirestoreAccountRepository({
    required this._tx,
    required this._clock,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final TxRunner _tx;
  final Clock _clock;
  final FirebaseFirestore _db;

  /// The fields written by [markDeleted]; shared with the rules tests.
  static Map<String, dynamic> deletedMap(String uid, DateTime now) {
    final ts = BaseMapper.dateTimeToTimestamp(now);
    return <String, dynamic>{
      'deletedAt': ts,
      'deletedBy': uid,
      // PII that history does not need.  `fullName` stays on the member
      // documents (decision D2), so past records keep their author's name.
      'nickname': null,
      'gender': null,
      'spouseId': null,
      'avatarKey': null,
      BaseMapper.keyUpdatedAt: ts,
      BaseMapper.keyUpdatedBy: uid,
    };
  }

  @override
  Future<Result<void>> markDeleted(String uid) => guardWrite(
    // The user is about to disappear: this must reach the server.
    probe: serverProbeFor(_db, uid),
    () => _tx.runBatch((b) {
      b.set(
        FirestorePaths.userDoc(uid),
        deletedMap(uid, _clock.nowUtc()),
        merge: true,
      );
    }),
  );

  @override
  Stream<bool> watchMarkedDeleted(String uid) =>
      watchKnownDoc(_db.doc(FirestorePaths.userDoc(uid)))
          .map((data) => data?['deletedAt'] != null)
          .distinct();
}
