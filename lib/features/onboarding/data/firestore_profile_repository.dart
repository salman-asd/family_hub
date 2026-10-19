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
    required TxRunner tx,
    required Clock clock,
    FirebaseFirestore? firestore,
  })  : _tx = tx,
        _clock = clock,
        _db = firestore ?? FirebaseFirestore.instance;

  final TxRunner _tx;
  final Clock _clock;
  final FirebaseFirestore _db;

  static UserProfile? profileFromMap(String uid, Map<String, dynamic>? d) {
    final name = d?['fullName'];
    if (d == null || name is! String || name.trim().isEmpty) return null;
    return UserProfile(
      uid: uid,
      fullName: name,
      relationship: Relationship.parse(d['relationship'] as String?),
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
        'relationship': p.relationship.name,
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

  @override
  Future<Result<void>> saveProfile(UserProfile profile, {String? familyId}) =>
      // Not server-required: offline the save is queued and syncs later.
      guardWrite(
        () => _tx.runBatch((b) {
          final now = BaseMapper.dateTimeToTimestamp(_clock.nowUtc());
          final stamp = <String, dynamic>{
            BaseMapper.keyUpdatedAt: now,
            BaseMapper.keyUpdatedBy: profile.uid,
          };
          b.set(
            FirestorePaths.userDoc(profile.uid),
            {
              ...profileToMap(profile),
              ...stamp,
              BaseMapper.keyCreatedAt: now,
              BaseMapper.keyCreatedBy: profile.uid,
              BaseMapper.keySchemaVersion: 1,
            },
            merge: true,
          );
          if (familyId != null) {
            b.update(FirestorePaths.memberDoc(familyId, profile.uid), {
              'fullName': profile.fullName,
              'nickname': profile.nickname,
              'relationship': profile.relationship.name,
              'spouseId': profile.spouseId,
              'avatarKey': profile.avatarKey,
              ...stamp,
            });
          }
        }),
      );
}
