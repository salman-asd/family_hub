import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/firebase/doc_watch.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/firebase/tx_runner.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/features/family/domain/relationship.dart';
import 'package:family_hub/features/onboarding/domain/profile_repository.dart';
import 'package:family_hub/features/onboarding/domain/user_profile.dart';
import 'package:family_hub/features/onboarding/domain/user_profile_repository.dart';

/// `users/{uid}` — profile read/write plus the router's existence check.
///
/// The document can exist before the profile does (preference sync merges
/// `preferences` into it), so "has a profile" means `fullName` is non-empty.
class FirestoreProfileRepository
    implements UserProfileRepository, ProfileRepository {
  FirestoreProfileRepository({
    required this._tx,
    required this._clock,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final TxRunner _tx;
  final Clock _clock;
  final FirebaseFirestore _db;

  static UserProfile? profileFromMap(String uid, Map<String, dynamic>? d) {
    final name = d?['fullName'];
    if (d == null || name is! String || name.trim().isEmpty) return null;
    return UserProfile(
      uid: uid,
      fullName: name,
      relationship: RelationshipId.parse(d['relationship'] as String?),
      nickname: d['nickname'] as String?,
      gender: Gender.tryParse(d['gender'] as String?),
      spouseId: d['spouseId'] as String?,
      avatarKey: d['avatarKey'] as String?,
    );
  }

  static Map<String, dynamic> profileToMap(UserProfile p) => <String, dynamic>{
    'uid': p.uid,
    'fullName': p.fullName,
    'nickname': p.nickname,
    'gender': p.gender?.name,
    'relationship': p.relationship.value,
    'spouseId': p.spouseId,
    'avatarKey': p.avatarKey,
  };

  @override
  Stream<bool> watchHasProfile(String uid) =>
      watchKnownDoc(_db.doc(FirestorePaths.userDoc(uid)))
          .map((data) => profileFromMap(uid, data) != null)
          .distinct();

  @override
  Stream<UserProfile?> watchProfile(String uid) =>
      watchKnownDoc(_db.doc(FirestorePaths.userDoc(uid)))
          .map((data) => profileFromMap(uid, data));

  @override
  Future<Result<UserProfile?>> getProfile(String uid) =>
      guardFirestore(() async {
        final snap = await _db.doc(FirestorePaths.userDoc(uid)).get();
        return profileFromMap(uid, snap.data());
      });

  /// The fields a save writes (H10): the creation stamp is written ONCE, on the
  /// first save; later saves only refresh `updatedAt` / `updatedBy`.
  ///
  /// [existing] is the current `users/{uid}` data (or null when unknown).  A
  /// Firestore transaction would be the textbook tool, but transactions need the
  /// server and a profile save must still be queued offline (rule 15), so the
  /// current document is read first (server, or the cache offline) and the write
  /// stays a normal batch.
  static Map<String, dynamic> profileWriteMap(
    UserProfile profile,
    Map<String, dynamic>? existing,
    DateTime now,
  ) {
    final ts = BaseMapper.dateTimeToTimestamp(now);
    final isFirstSave = existing?[BaseMapper.keyCreatedAt] == null;
    return <String, dynamic>{
      ...profileToMap(profile),
      BaseMapper.keyUpdatedAt: ts,
      BaseMapper.keyUpdatedBy: profile.uid,
      if (isFirstSave) ...<String, dynamic>{
        BaseMapper.keyCreatedAt: ts,
        BaseMapper.keyCreatedBy: profile.uid,
        BaseMapper.keySchemaVersion: 1,
      },
    };
  }

  @override
  Future<Result<void>> saveProfile(UserProfile profile, {String? familyId}) =>
      // Not server-required: offline the save is queued and syncs later.
      guardWrite(() async {
        Map<String, dynamic>? existing;
        try {
          existing =
              (await _db
                      .doc(FirestorePaths.userDoc(profile.uid))
                      .get()
                      .timeout(const Duration(seconds: 4)))
                  .data();
        } on Object {
          // Unknown (offline, nothing cached): treat as a first save; the
          // merge never lowers an existing creation stamp's meaning.
          existing = null;
        }
        final data = profileWriteMap(profile, existing, _clock.nowUtc());
        await _tx.runBatch((b) {
          b.set(FirestorePaths.userDoc(profile.uid), data, merge: true);
          if (familyId != null) {
            b.update(FirestorePaths.memberDoc(familyId, profile.uid), {
              'fullName': profile.fullName,
              'nickname': profile.nickname,
              'relationship': profile.relationship.value,
              'spouseId': profile.spouseId,
              'avatarKey': profile.avatarKey,
              BaseMapper.keyUpdatedAt: data[BaseMapper.keyUpdatedAt],
              BaseMapper.keyUpdatedBy: profile.uid,
            });
          }
        });
      });
}
