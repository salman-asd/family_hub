import 'dart:convert';

import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/dashboard/data/dashboard_policy_mappers.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class LocalDashboardPrefsStore implements DashboardPrefsStore {
  const LocalDashboardPrefsStore(this._preferences);

  final SharedPreferences _preferences;

  String _key(String uid) => 'dashboard_prefs_$uid';

  @override
  DashboardPrefs load(String uid) {
    final encoded = _preferences.getString(_key(uid));
    if (encoded == null) return DashboardPrefs.defaults;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) return DashboardPrefs.defaults;
      return DashboardPolicyMappers.dashboardPrefsFromMap(decoded);
    } on FormatException {
      return DashboardPrefs.defaults;
    }
  }

  @override
  Future<Result<void>> save(String uid, DashboardPrefs prefs) async {
    try {
      final saved = await _preferences.setString(
        _key(uid),
        jsonEncode(DashboardPolicyMappers.dashboardPrefsToMap(prefs)),
      );
      return saved
          ? const Success<void>(null)
          : Failure<void>(
              Unknown(
                StateError('Dashboard preferences were not saved locally.'),
              ),
            );
    } on Exception catch (error) {
      return Failure<void>(Unknown(error));
    }
  }
}
