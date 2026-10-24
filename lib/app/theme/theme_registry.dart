import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/app/theme/themes/modern_dark.dart';
import 'package:family_hub/app/theme/themes/modern_light.dart';
import 'package:flutter/material.dart';

/// Describes one available theme in the app.
@immutable
class AppThemeSpec {
  const AppThemeSpec({
    required this.id,
    required this.labelBn,
    required this.labelEn,
    required this.brightness,
    required this.tokens,
    this.available = true,
  });

  /// Stable identifier persisted to SharedPreferences / Firestore.
  final String id;
  final String labelBn;
  final String labelEn;
  final Brightness brightness;
  final AppTokens tokens;

  /// Set to false to hide from the picker without removing the spec.
  final bool available;
}

// ── Registered themes ─────────────────────────────────────────────────────────

/// All known themes.  The picker builds from `appThemes.where((s) => s.available)`.
const String kModernLightId = 'modern_light';
const String kModernDarkId = 'modern_dark';

final AppThemeSpec modernLightSpec = AppThemeSpec(
  id: kModernLightId,
  labelBn: 'আধুনিক (আলো)',
  labelEn: 'Modern Light',
  brightness: Brightness.light,
  tokens: modernLightTokens,
);

final AppThemeSpec modernDarkSpec = AppThemeSpec(
  id: kModernDarkId,
  labelBn: 'আধুনিক (অন্ধকার)',
  labelEn: 'Modern Dark',
  brightness: Brightness.dark,
  tokens: modernDarkTokens,
);

/// The ordered list of all registered themes.
final List<AppThemeSpec> appThemes = [modernLightSpec, modernDarkSpec];

/// Look up a spec by [id].  Falls back to [modernLightSpec] for unknown ids.
AppThemeSpec themeById(String id) {
  return appThemes.firstWhere((s) => s.id == id, orElse: () => modernLightSpec);
}

/// First available light spec — used by "Follow device" mode.
AppThemeSpec get defaultLightSpec => appThemes.firstWhere(
  (s) => s.available && s.brightness == Brightness.light,
  orElse: () => modernLightSpec,
);

/// First available dark spec — used by "Follow device" mode.
AppThemeSpec get defaultDarkSpec => appThemes.firstWhere(
  (s) => s.available && s.brightness == Brightness.dark,
  orElse: () => modernDarkSpec,
);
