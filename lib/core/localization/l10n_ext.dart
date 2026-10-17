import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/locale_controller.dart';
import 'package:family_hub/core/localization/locale_prefs.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Re-export the controller so callers get the provider and prefs in one import.
export 'package:family_hub/core/localization/locale_controller.dart'
    show localeControllerProvider;

/// Convenience access to the generated [AppLocalizations] from any widget:
/// `context.l10n.actionSave`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Provider exposing [AppFormatters] built from the active [LocalePrefs].
///
/// Widgets read it with `ref.watch(appFormattersProvider)`; pure tests build an
/// [AppFormatters] directly.
final appFormattersProvider = Provider<AppFormatters>((ref) {
  final prefs = ref.watch(localeControllerProvider);
  return AppFormatters(
    languageCode: prefs.languageCode,
    useBanglaDigits: prefs.useBanglaDigits,
  );
});

/// A [Locale] list for [MaterialApp.supportedLocales], derived from the
/// single source of truth in [LocalePrefs].
List<Locale> get supportedLocales =>
    LocalePrefs.supportedLanguageCodes.map(Locale.new).toList(growable: false);
