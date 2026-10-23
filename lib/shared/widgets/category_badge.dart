import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';

/// A coloured pill for a bazar category (P2-12).
///
/// The colour comes from `placeholderPalette[colorIndex]` — an index, never a
/// hex value — and the text uses [AppAvatar.foregroundFor], which picks the
/// contrast-safe token for that background.  An optional emoji is decorative;
/// the category name is announced once to assistive technology.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    required this.name,
    required this.colorIndex,
    this.emoji,
    this.compact = false,
    super.key,
  });

  /// Localized category name.
  final String name;

  /// Index into `placeholderPalette` (0–11 in the data model; guarded here).
  final int colorIndex;

  final String? emoji;

  /// Dense variant for list rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final palette = t.placeholderPalette;
    final index = colorIndex.abs() % palette.length;
    final background = palette[index];
    final foreground = AppAvatar.foregroundFor(background, t);
    final glyph = emoji;

    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(t.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null && glyph.isNotEmpty) ...[
              Text(
                glyph,
                style: TextStyle(
                  fontSize: compact ? 11 : 13,
                  color: foreground,
                ),
              ),
              SizedBox(width: compact ? 4 : 6),
            ],
            Flexible(
              child: Text(
                name,
                style: TextStyle(
                  color: foreground,
                  fontSize: compact ? 11 : 12,
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
