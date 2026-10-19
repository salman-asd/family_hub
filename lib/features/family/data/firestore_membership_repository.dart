import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/firebase/doc_watch.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/utils/stream_utils.dart';
import 'package:family_hub/features/family/data/family_mappers.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/membership_repository.dart';
import 'package:family_hub/modules/module_flags.dart';

/// Membership and module flags, both found through `users/{uid}.familyId`.
class FirestoreMembershipRepository
    implements MembershipRepository, ModuleFlagsRepository {
  FirestoreMembershipRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<Membership> watchMembership(String uid) {
    // Unknown (offline, nothing cached) emits nothing, so the session stays in
    // `loading` instead of being routed as "no profile / no family" (rule 14).
    final userDoc = watchKnownDoc(_db.doc(FirestorePaths.userDoc(uid)));
    return switchMap<Map<String, dynamic>?, Membership>(
      userDoc,
      (user) {
        final familyId = user?['familyId'];
        if (familyId is! String || familyId.isEmpty) {
          return Stream<Membership>.value(Membership.none);
        }
        return watchKnownDoc(_db.doc(FirestorePaths.memberDoc(familyId, uid)))
            .map((data) {
          return FamilyMappers.membershipFromMember(
            familyId,
            data == null ? null : FamilyMappers.memberFromMap(data),
          );
        });
      },
    ).distinct();
  }

  @override
  Stream<ModuleFlags> watchModuleFlags(String familyId) => _db
      .doc(FirestorePaths.settingsDoc(familyId, 'modules'))
      .snapshots()
      .map((s) => FamilyMappers.modulesFromMap(s.data()))
      .distinct();
}
