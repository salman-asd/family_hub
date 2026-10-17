import 'package:flutter/material.dart';

/// Persisted theme preferences.
///
/// [themeMode] controls whether to follow the device, force light, or force
/// dark.  [themeId] selects the specific colour palette within a brightness
/// (e.g. 'modern_light', 'modern_dark').
@immutable
class ThemePrefs {
  const ThemePrefs({
    this.themeMode = ThemeMode.system,
    this.themeId = _kDefaultId,
  });

  static const String _kDefaultId = 'modern_light';
  static const String _kKeyMode = 'theme_mode';
  static const String _kKeyId = 'theme_id';

  final ThemeMode themeMode;
  final String themeId;

  /// Serialize to a flat map for SharedPreferences storage.
  Map<String, String> toMap() => {
        _kKeyMode: themeMode.name,
        _kKeyId: themeId,
      };

  /// Deserialize from a SharedPreferences-style map.
  /// Unknown values fall back to defaults — never throws.
  factory ThemePrefs.fromMap(Map<String, String?> map) {
    final modeStr = map[_kKeyMode] ?? '';
    final mode = ThemeMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => ThemeMode.system,
    );
    return ThemePrefs(
      themeMode: mode,
      themeId: map[_kKeyId] ?? _kDefaultId,
    );
  }

  ThemePrefs copyWith({ThemeMode? themeMode, String? themeId}) => ThemePrefs(
        themeMode: themeMode ?? this.themeMode,
        themeId: themeId ?? this.themeId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemePrefs &&
          other.themeMode == themeMode &&
          other.themeId == themeId;

  @override
  int get hashCode => Object.hash(themeMode, themeId);

  @override
  String toString() => 'ThemePrefs(mode: ${themeMode.name}, id: $themeId)';
}
