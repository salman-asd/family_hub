import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';

/// Runs a Firestore call and converts failures into [AppFailure]; nothing
/// thrown by Firestore crosses the data layer.
Future<Result<T>> guardFirestore<T>(Future<T> Function() call) async {
  try {
    return Success<T>(await call().timeout(const Duration(seconds: 30)));
  } on FirebaseException catch (e) {
    return Failure<T>(mapFirestoreCode(e.code));
  } on TimeoutException {
    return Failure<T>(const Network());
  } on Object catch (e) {
    return Failure<T>(Unknown(e));
  }
}

/// Firestore error code -> failure.
AppFailure mapFirestoreCode(String code) => switch (code) {
      'permission-denied' || 'unauthenticated' => const PermissionDenied(),
      'not-found' => const NotFound(),
      'already-exists' || 'aborted' => const Conflict(),
      'unavailable' || 'deadline-exceeded' || 'cancelled' => const Network(),
      _ => Unknown(code),
    };
