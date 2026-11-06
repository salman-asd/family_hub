import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/notifications/data/device_token_mappers.dart';
import 'package:family_hub/core/notifications/domain/device_token.dart';
import 'package:firebase_auth/firebase_auth.dart';

final class FirestoreDeviceTokenRepository implements DeviceTokenRepository {
  FirestoreDeviceTokenRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<Result<void>> register({
    required String uid,
    required String deviceId,
    required DeviceTokenRegistration registration,
  }) {
    if (_auth.currentUser?.uid != uid) {
      return Future<Result<void>>.value(const Failure<void>(NoCurrentUser()));
    }
    return guardWrite(
      () => _firestore
          .doc(FirestorePaths.deviceDoc(uid, deviceId))
          .set(DeviceTokenMappers.toMap(uid, registration)),
    );
  }

  @override
  Future<Result<void>> remove({required String uid, required String deviceId}) {
    if (_auth.currentUser?.uid != uid) {
      return Future<Result<void>>.value(const Failure<void>(NoCurrentUser()));
    }
    return guardWrite(
      () => _firestore.doc(FirestorePaths.deviceDoc(uid, deviceId)).delete(),
      probe: serverProbeFor(_firestore, uid),
    );
  }
}
