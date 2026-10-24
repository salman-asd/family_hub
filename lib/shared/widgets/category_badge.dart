import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// A category as a small coloured pill: optional emoji, then the name.
///
/// The colour is `placeholderPalette[colorIndex]` — an index stored on the
/// category, never a hex — with its foreground chosen by
/// [AppAvatar.foregroundFor], so contrast is the one already tested for avatars.
/// The same category therefore looks the same on every screen and in both themes.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    required this.name,
    required this.colorIndex,
    this.emoji,
    this.compact = false,
    super.key,
  });

  final String name;

  /// 0–11, wraps if larger so a bad stored value can never crash a screen.
  final int colorIndex;
  final String? emoji;

  /// Dense variant for list rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final palette = t.placeholderPalette;
    final background = palette[colorIndex.abs() % palette.length];
    final foreground = AppAvatar.foregroundFor(background, t);
    final glyph = emoji != null && emoji!.isNotEmpty ? emoji : null;

    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 2 : 6,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(t.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[
              Text(glyph, style: TextStyle(fontSize: compact ? 12 : 16)),
              SizedBox(width: compact ? 4 : 6),
            ],
            Flexible(
              child: Text(
                name,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
