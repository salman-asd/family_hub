import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_hub/app/theme/theme_preference_sync.dart';
import 'package:family_hub/app/theme/theme_prefs.dart';
import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:family_hub/core/localization/locale_preference_sync.dart';
import 'package:family_hub/core/localization/locale_prefs.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show ThemeMode;

/// Reads/writes `users/{uid}.preferences` for the signed-in user.
class _PreferencesDoc {
  _PreferencesDoc({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>>? get _ref {
    final uid = _auth.currentUser?.uid;
    return uid == null ? null : _db.doc(FirestorePaths.userDoc(uid));
  }

  Future<void> merge(Map<String, dynamic> preferences) async {
    final ref = _ref;
    if (ref == null) return;
    await ref.set({'preferences': preferences}, SetOptions(merge: true));
  }

  /// Emits the `preferences` map (or `null` when none is stored yet).
  Stream<Map<String, dynamic>?> watch() {
    final ref = _ref;
    if (ref == null) return const Stream.empty();
    return ref.snapshots().map((s) {
      final p = s.data()?['preferences'];
      return p is Map<String, dynamic> ? p : null;
    });
  }
}

/// Theme preferences: `preferences.themeId` and `preferences.themeMode`.
class FirestoreThemePreferenceSync implements ThemePreferenceSync {
  FirestoreThemePreferenceSync({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _doc = _PreferencesDoc(auth: auth, firestore: firestore);

  final _PreferencesDoc _doc;

  @override
  Future<void> push(ThemePrefs prefs) =>
      _doc.merge({'themeId': prefs.themeId, 'themeMode': prefs.themeMode.name});

  @override
  Stream<ThemePrefs?> watch() => _doc.watch().map((p) {
    if (p == null || p['themeId'] is! String) return null;
    return ThemePrefs(
      themeId: p['themeId'] as String,
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == p['themeMode'],
        orElse: () => ThemeMode.system,
      ),
    );
  });
}

/// Language preferences: `preferences.language` and `preferences.banglaDigits`.
class FirestoreLocalePreferenceSync implements LocalePreferenceSync {
  FirestoreLocalePreferenceSync({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _doc = _PreferencesDoc(auth: auth, firestore: firestore);

  final _PreferencesDoc _doc;

  @override
  Future<void> push(LocalePrefs prefs) => _doc.merge({
    'language': prefs.languageCode,
    'banglaDigits': prefs.useBanglaDigits,
  });

  @override
  Stream<LocalePrefs?> watch() => _doc.watch().map((p) {
    if (p == null || p['language'] is! String) return null;
    return LocalePrefs.fromMap({
      'language_code': p['language'],
      if (p['banglaDigits'] is bool) 'use_bangla_digits': p['banglaDigits'],
    });
  });
}
