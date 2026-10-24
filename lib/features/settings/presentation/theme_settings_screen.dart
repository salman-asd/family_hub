import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/app/theme/theme_registry.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/settings/presentation/widgets/theme_settings_widgets.dart';
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
  const ThemeSettingsScreen({this.specs, super.key});

  /// The themes to offer; `null` means every available registered theme.  Tests
  /// pass a longer list to prove the grid needs no screen change for a new one.
  final List<AppThemeSpec>? specs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);
    final t = context.tokens;
    final l10n = context.l10n;
    final isFollowDevice = prefs.themeMode == ThemeMode.system;

    final availableThemes =
        specs ?? appThemes.where((s) => s.available).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsThemeTitle)),
      backgroundColor: t.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Follow device toggle ───────────────────────────────────────
          SettingsSectionLabel(label: l10n.settingsThemeMode, tokens: t),
          const SizedBox(height: 8),
          FollowDeviceTile(
            value: isFollowDevice,
            tokens: t,
            title: l10n.settingsFollowDevice,
            subtitle: l10n.settingsFollowDeviceSubtitle,
            onChanged: (v) => controller.setThemeMode(
              v ? ThemeMode.system : _defaultModeForId(prefs.themeId),
            ),
          ),
          const SizedBox(height: 24),

          // ── Theme picker grid ──────────────────────────────────────────
          SettingsSectionLabel(label: l10n.settingsColourPalette, tokens: t),
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
              return ThemeCard(
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
    return spec.brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
  }
}

// ── Exposed for tests ─────────────────────────────────────────────────────────

/// Extension for golden/widget tests to access the theme card key.
extension ThemeSettingsTestKeys on ThemeSettingsScreen {
  static Key cardKey(String themeId) => ValueKey('theme_card_$themeId');
}
