import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/settings/presentation/widgets/language_settings_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen at `/settings/language`.
///
/// Shows the two supported languages as selectable rows (check icon, not
/// colour alone) and a separate switch for Bangla digits (০১২৩).  Both choices
/// persist immediately and apply on the first frame after a restart.
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(localeControllerProvider);
    final controller = ref.read(localeControllerProvider.notifier);
    final t = context.tokens;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsLanguageTitle)),
      backgroundColor: t.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LanguageSectionLabel(label: l10n.settingsLanguageSection, tokens: t),
          const SizedBox(height: 8),
          LanguageOptionTile(
            title: l10n.settingsLanguageBangla,
            subtitle: l10n.languageNameBn,
            selected: prefs.languageCode == 'bn',
            tokens: t,
            semanticsLabel: prefs.languageCode == 'bn'
                ? l10n.settingsLanguageSelectedSemantics(l10n.languageNameBn)
                : l10n.languageNameBn,
            onTap: () => controller.setLanguageCode('bn'),
          ),
          const SizedBox(height: 12),
          LanguageOptionTile(
            title: l10n.settingsLanguageEnglish,
            subtitle: l10n.languageNameEn,
            selected: prefs.languageCode == 'en',
            tokens: t,
            semanticsLabel: prefs.languageCode == 'en'
                ? l10n.settingsLanguageSelectedSemantics(l10n.languageNameEn)
                : l10n.languageNameEn,
            onTap: () => controller.setLanguageCode('en'),
          ),
          const SizedBox(height: 24),
          LanguageSectionLabel(label: l10n.settingsBanglaDigits, tokens: t),
          const SizedBox(height: 8),
          DigitsSwitchTile(
            value: prefs.useBanglaDigits,
            tokens: t,
            title: l10n.settingsBanglaDigits,
            subtitle: l10n.settingsBanglaDigitsSubtitle,
            onChanged: controller.setUseBanglaDigits,
          ),
          const SizedBox(height: 16),
          LanguagePreviewCard(
            languageCode: prefs.languageCode,
            useBanglaDigits: prefs.useBanglaDigits,
            tokens: t,
          ),
        ],
      ),
    );
  }
}
