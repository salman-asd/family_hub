import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';

// ── Section label ─────────────────────────────────────────────────────────────

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel({
    super.key,
    required this.label,
    required this.tokens,
  });
  final String label;
  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: tokens.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Follow-device tile ────────────────────────────────────────────────────────

class FollowDeviceTile extends StatelessWidget {
  const FollowDeviceTile({
    super.key,
    required this.value,
    required this.tokens,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });
  final bool value;
  final AppTokens tokens;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: tokens.divider),
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
          child: Row(
            children: [
              Icon(
                Icons.brightness_auto_rounded,
                color: value ? tokens.accent : tokens.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label: title,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: tokens.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Theme card ────────────────────────────────────────────────────────────────

class ThemeCard extends StatelessWidget {
  const ThemeCard({
    super.key,
    required this.spec,
    required this.isSelected,
    required this.tokens,
    required this.onTap,
  });
  final AppThemeSpec spec;
  final bool isSelected;
  final AppTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected ? tokens.accent : tokens.divider;
    final borderWidth = isSelected ? 2.0 : 1.0;
    final l10n = context.l10n;
    final label =
        spec.labelBn.isNotEmpty &&
            Localizations.localeOf(context).languageCode == 'bn'
        ? spec.labelBn
        : spec.labelEn;

    return Semantics(
      label: isSelected
          ? l10n.settingsThemeSelectedSemantics(label)
          : l10n.settingsThemeUnselectedSemantics(label),
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: tokens.durationFast,
          curve: tokens.curveStandard,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: isSelected ? tokens.elevation2 : tokens.elevation1,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusMd - 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mini preview — half the card height
                Expanded(child: ThemeMiniPreview(spec: spec)),
                // Label row
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: tokens.accent,
                          size: 18,
                          semanticLabel: l10n.settingsThemeSelected,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mini preview ──────────────────────────────────────────────────────────────

/// A miniature colour swatch preview of the theme's tokens.
/// Rendered entirely from the spec's own tokens — no Theme.of context needed.
class ThemeMiniPreview extends StatelessWidget {
  const ThemeMiniPreview({super.key, required this.spec});
  final AppThemeSpec spec;

  @override
  Widget build(BuildContext context) {
    // Build a mini ThemeData just to access the tokens, without polluting the
    // widget tree's inherited theme.
    final t = spec.tokens;
    return Container(
      color: t.background,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simulated card
          Container(
            height: 22,
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: t.divider),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: t.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: t.textSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Simulated accent button
          Container(
            height: 14,
            width: 48,
            decoration: BoxDecoration(
              color: t.accent,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          const SizedBox(height: 6),
          // Colour swatches row
          Row(
            children: [
              _Dot(t.statusCompleted),
              const SizedBox(width: 3),
              _Dot(t.statusOverdue),
              const SizedBox(width: 3),
              _Dot(t.statusInProgress),
              const SizedBox(width: 3),
              _Dot(t.info),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
