import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/app/theme/theme_prefs.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen at `/settings/theme`.
///
/// Shows:
/// - A "Follow device" switch (ThemeMode.system).
/// - A grid of available theme cards, each with a mini colour preview.
///   The grid is built from `appThemes.where((s) => s.available)` so a
///   future theme shows up here with zero screen changes.
/// - The selected card carries a check icon (not just a colour highlight).
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final t = context.tokens;
    final isFollowDevice = prefs.themeMode == ThemeMode.system;

    final availableThemes = appThemes.where((s) => s.available).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      backgroundColor: t.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Follow device toggle ───────────────────────────────────────
          _SectionLabel(label: 'Theme Mode', tokens: t),
          const SizedBox(height: 8),
          _FollowDeviceTile(
            value: isFollowDevice,
            tokens: t,
            onChanged: (v) => controller.setThemeMode(
              v ? ThemeMode.system : _defaultModeForId(prefs.themeId),
            ),
          ),
          const SizedBox(height: 24),

          // ── Theme picker grid ──────────────────────────────────────────
          _SectionLabel(label: 'Colour Palette', tokens: t),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: availableThemes.length,
            itemBuilder: (context, index) {
              final spec = availableThemes[index];
              final isSelected = prefs.themeId == spec.id;
              return _ThemeCard(
                spec: spec,
                isSelected: isSelected,
                tokens: t,
                onTap: () async {
                  await controller.setThemeId(spec.id);
                  // When picking a specific theme, also exit system mode so
                  // the choice is honoured immediately.
                  if (prefs.themeMode == ThemeMode.system) {
                    await controller.setThemeMode(
                      spec.brightness == Brightness.dark
                          ? ThemeMode.dark
                          : ThemeMode.light,
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// When leaving "Follow device" mode, pick light or dark based on the
  /// chosen spec's brightness.
  static ThemeMode _defaultModeForId(String id) {
    final spec = themeById(id);
    return spec.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.tokens});
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

class _FollowDeviceTile extends StatelessWidget {
  const _FollowDeviceTile({
    required this.value,
    required this.tokens,
    required this.onChanged,
  });
  final bool value;
  final AppTokens tokens;
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
                      'Follow device',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Uses your system light / dark setting',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: tokens.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Theme card ────────────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
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

    return Semantics(
      label: '${spec.labelEn} theme${isSelected ? ', selected' : ''}',
      button: true,
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
                Expanded(child: _MiniPreview(spec: spec)),
                // Label row
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          spec.labelEn,
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
                          semanticLabel: 'Selected',
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
class _MiniPreview extends StatelessWidget {
  const _MiniPreview({required this.spec});
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

// ── Exposed for tests ─────────────────────────────────────────────────────────

/// Extension for golden/widget tests to access the theme card key.
extension ThemeSettingsTestKeys on ThemeSettingsScreen {
  static Key cardKey(String themeId) => ValueKey('theme_card_$themeId');
}

