# Family Hub - progress

| Step | Status | Notes |
| --- | --- | --- |
| 1 Scaffold, flavors, lints, CI | Done (found in repo) | android/ folder, flavors, analysis_options, CI, placeholder app, tools/setup.sh |
| 2 Core value objects | Done | flutter test 82/82 passes (includes Step 3 tests) |
| 3 Theme tokens | Done | app_tokens, modern_light, modern_dark, theme_registry, theme_builder, dev_tokens_screen; WCAG contrast + no-raw-color tests pass |
| 4 Theme controller and Settings → Theme screen | Done | ThemePrefs + ThemeController (early-load in bootstrap), ThemePreferenceSync no-op, /settings/theme screen; persistence + registry tests pass |
| 5 Localization (Bangla default), fonts, formatting | Done | l10n.yaml + bn/en ARBs, context.l10n, LocaleController + /settings/language screen, Hind Siliguri bundled, formatters, overflow + hard-coded-string tests; flutter test 126/126 |

## Step 2 assumptions
- Money.parse, Quantity.parse, DateKey.parse and MonthKey.parse return Result (no exceptions).
- Money formatting: bn uses lakh grouping (১২,৩৪,৫৬৭), en uses international grouping. Change in MoneyFormatter._group if unwanted.
- No freezed in core value objects (plain Dart), so no build_runner is needed for Step 2.
- DateKey.fromInstant loads the timezone database lazily (ensureTimeZonesInitialized).
- Unit enum has no ml; add later if a bazar item needs it.

## Step 3 assumptions
- Light theme accent changed from teal 600 (#00897B) to teal 800 (#00574B) so white text on accent meets WCAG AA 4.5:1.
- Light statusInProgressOn changed to #6A1900 (very dark) so it meets 4.5:1 on the peach container #FFE0B2.
- Dark theme textOnAccent changed to #00201C (very dark teal) because teal 300 accent is too light for white text.
- theme_builder.dart has two unavoidable Color() literals in SnackBar for the inverted fg/bg (they are inside lib/app/theme/ so the no-raw-color test allows them).
- The /dev/tokens route is intentionally left in until Step 4/8 replaces app.dart; it is debug-only and gated by the dev flavor in practice.

## Step 4 assumptions
- The theme controller reads SharedPreferences synchronously (loaded before runApp in bootstrap) so the first frame already has the saved theme — no flash.
- `ThemePreferenceSync` ships as a no-op; the Firestore implementation lands in Step 9 (users/{uid}.preferences).
- `/settings/theme` shows "Follow device" plus a grid built from `appThemes.where(available)`, so adding a third theme needs no screen change. Selection uses a check icon, not colour alone.
- `test/app/app_test.dart` was updated: `FamilyHubApp` is now a Riverpod consumer and the app bar shows the localized app name, so the test wraps it in a `ProviderScope`.

## Step 5 assumptions
- **Font choice: Hind Siliguri** (SIL OFL 1.1, free to bundle). Evaluated against Noto Sans Bengali (also OFL, heavier/more neutral) and Anek Bangla (OFL, variable, more display-oriented). Hind Siliguri won on UI weight coverage (Light→Bold, weights 300–700), a humanist look that stays legible at 12–14sp, complete Bengali + Latin coverage from one family, and small file size. Files live in `assets/fonts/` with `OFL.txt`; declared in `pubspec.yaml` as family `HindSiliguri` and used in `buildThemeData` via `kAppFontFamily`.
- Bangla is the **default** locale (`LocalePrefs.defaultLanguageCode = 'bn'`); English is optional. The `bn` ARB is the gen-l10n template.
- Generated localizations are checked into `lib/core/localization/generated/` (not a synthetic package) so `flutter analyze` and CI work without running codegen. `flutter: generate: true` is set in pubspec; `l10n.yaml` has no deprecated `synthetic-package` key.
- The "Use Bangla digits" switch is independent of the language, so an English reader can still see ০১২৩ and vice-versa. It drives `AppFormatters` and `MoneyFormatter`.
- Dates are formatted manually in `AppFormatters` (Bengali Gregorian month names, lakh grouping for bn) rather than through `intl`'s locale data, to keep the exact strings the roadmap specifies ('১৪ অক্টোবর ২০২৬').
- The hard-coded-string guard is a **test** (`test/core/localization/no_hard_coded_strings_test.dart`) that scans `lib/` for `Text('…')` literals, with `lib/app/theme/dev_tokens_screen.dart` allow-listed (its labels are developer token names, not copy). A line may opt out with a `// i18n-exempt` comment.
- `context.l10n` is provided by `lib/core/localization/l10n_ext.dart`, which also exposes `appFormattersProvider` and `supportedLocales`.
