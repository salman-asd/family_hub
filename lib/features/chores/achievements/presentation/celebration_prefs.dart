import 'dart:developer' as developer;

import 'package:family_hub/core/utils/date_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class CelebrationPrefs {
  const CelebrationPrefs(this._preferences);

  final SharedPreferences _preferences;

  DateKey? lastCelebrated(String familyId, String memberId) {
    final stored = _preferences.getString(_key(familyId, memberId));
    if (stored == null) return null;
    final result = DateKey.parse(stored);
    final date = result.valueOrNull;
    if (date == null) {
      developer.log(
        'Ignoring malformed local celebration date',
        name: 'family_hub',
        level: 900,
      );
    }
    return date;
  }

  Future<bool> markCelebrated(String familyId, String memberId, DateKey date) =>
      _preferences.setString(_key(familyId, memberId), date.toString());

  String _key(String familyId, String memberId) =>
      'celebrated_date:${Uri.encodeComponent(familyId)}:${Uri.encodeComponent(memberId)}';
}
