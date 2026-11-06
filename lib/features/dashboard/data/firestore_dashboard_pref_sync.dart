import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/firebase/firestore_guard.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/features/dashboard/data/dashboard_policy_mappers.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

final class FirestoreDashboardPrefSync implements DashboardPrefsSync {
  FirestoreDashboardPrefSync({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  @override
  Future<Result<void>> push(String uid, DashboardPrefs prefs) {
    if (_auth.currentUser?.uid != uid) {
      return Future<Result<void>>.value(const Failure<void>(NoCurrentUser()));
    }
    return guardWrite(
      () => _db.doc(FirestorePaths.userDoc(uid)).set(<String, dynamic>{
        'preferences': <String, dynamic>{
          'dashboard': DashboardPolicyMappers.dashboardPrefsToMap(prefs),
        },
      }, SetOptions(merge: true)),
    );
  }

  @override
  Stream<DashboardPrefs?> watch(String uid) {
    if (_auth.currentUser?.uid != uid) {
      return const Stream<DashboardPrefs?>.empty();
    }
    return _db.doc(FirestorePaths.userDoc(uid)).snapshots().map((snapshot) {
      final preferences = snapshot.data()?['preferences'];
      if (preferences is! Map) return null;
      final dashboard = preferences['dashboard'];
      if (dashboard is! Map) return null;
      return DashboardPolicyMappers.dashboardPrefsFromMap(
        Map<String, dynamic>.from(dashboard),
      );
    });
  }
}
