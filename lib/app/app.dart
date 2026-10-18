import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/app/preference_sync.dart';
import 'package:family_hub/app/router.dart';
import 'package:family_hub/app/theme/theme_builder.dart';
import 'package:family_hub/app/theme/theme_controller.dart';
import 'package:family_hub/core/localization/generated/app_localizations.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The root widget: theme, locale and the guarded router.
///
/// The `GoRouter` is created once by [routerProvider] (it used to be built
/// inside `build`, which threw away the navigation stack on every theme or
/// language change).  Which screen is shown is decided entirely by the router's
/// redirect rules; this widget holds no navigation logic.
class FamilyHubApp extends ConsumerWidget {
  const FamilyHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(flavorProvider);
    final prefs = ref.watch(themeControllerProvider);
    final localePrefs = ref.watch(localeControllerProvider);
    final specs = resolveThemeSpecs(prefs);
    final router = ref.watch(routerProvider);
    // Side effect only: sync theme/language with the account.
    ref.watch(preferenceSyncProvider);

    return MaterialApp.router(
      title: flavor.label,
      debugShowCheckedModeBanner: false,
      theme: buildThemeData(specs.light),
      darkTheme: buildThemeData(specs.dark),
      themeMode: prefs.themeMode,
      locale: localePrefs.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
