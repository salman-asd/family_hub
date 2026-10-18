import 'package:characters/characters.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Circular avatar: a preset colour (`avatarKey` like `p3`) or, without one, a
/// colour derived from [id] so a person looks the same on every screen and
/// every launch.  Shows the first grapheme cluster of [name] (Bangla-safe).
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.id,
    required this.name,
    this.avatarKey,
    this.size = 40,
    super.key,
  });

  final String id;
  final String name;
  final String? avatarKey;
  final double size;

  /// Number of preset avatars (matches `placeholderPalette`).
  static const int presetCount = 12;

  /// Stable (cross-run) hash: Dart's `String.hashCode` is not guaranteed so.
  static int stableHash(String s) {
    var h = 2166136261;
    for (final unit in s.codeUnits) {
      h = ((h ^ unit) * 16777619) & 0x7fffffff;
    }
    return h;
  }

  /// `p3` -> 3, otherwise `null`.
  static int? presetIndex(String? key) {
    if (key == null || !key.startsWith('p')) return null;
    final i = int.tryParse(key.substring(1));
    return (i != null && i >= 0 && i < presetCount) ? i : null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.tokens.placeholderPalette;
    final index = presetIndex(avatarKey) ?? stableHash(id) % palette.length;
    final background = palette[index];
    final foreground =
        ThemeData.estimateBrightnessForColor(background) == Brightness.dark
            ? Colors.white
            : Colors.black87;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.characters.first;

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Text(
          initial,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.42,
          ),
        ),
      ),
    );
  }
}
