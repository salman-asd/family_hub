# Family Hub - progress

| Step | Status | Notes |
| --- | --- | --- |
| 1 Scaffold, flavors, lints, CI | Done (found in repo) | android/ folder, flavors, analysis_options, CI, placeholder app, tools/setup.sh |
| 2 Core value objects | Done | flutter test 82/82 passes (includes Step 3 tests) |
| 3 Theme tokens | Done | app_tokens, modern_light, modern_dark, theme_registry, theme_builder, dev_tokens_screen; WCAG contrast + no-raw-color tests pass |
| 4 Theme controller and Settings → Theme screen | Done | ThemePrefs + ThemeController (early-load in bootstrap), ThemePreferenceSync no-op, /settings/theme screen; persistence + registry tests pass |
| 5 Localization (Bangla default), fonts, formatting | Done | l10n.yaml + bn/en ARBs, context.l10n, LocaleController + /settings/language screen, Hind Siliguri bundled, formatters, overflow + hard-coded-string tests; flutter test 126/126 |
| 6 Firebase setup (dev and prod) and bootstrap | Done | firebase_core, firebase_auth, cloud_firestore, options per flavor, persistence, emulator routing, paths, TxRunner + FakeTxRunner, BaseMapper, deny-all rules, indexes, README; flutter test 142/142 |
| 7 Authentication feature | Done (verified in Step 8 review) | domain use cases, FirebaseAuthRepository, 5 screens, controllers, fakes; flutter test 234/234 on the author's machine |
| 8 Router, guards, app shell, module registry | Done | guarded GoRouter, 4-tab shell with PillBottomBar, FamilyModule + registry, module flags, placeholder session (TODO(step-9)) |

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

## Step 6 assumptions
- Firebase packages pinned at stable versions: `firebase_core: ^5.0.0`, `firebase_auth: ^7.0.0`, `cloud_firestore: ^7.0.0`.
- Dedicated `FirebaseOptions` classes created for `dev` (`familyhub-dev`) and `prod` (`familyhub-prod`) with platform-specific options for Android, iOS, Web, macOS, Windows, resolved via `firebaseOptionsForFlavor(flavor)`.
- Placeholder `google-services.json` placed in `android/app/src/dev` and `android/app/src/prod` with matching package names `com.familyhub.family_hub.dev` and `com.familyhub.family_hub`, and Google Services gradle plugin added.
- Firestore offline persistence explicitly enabled (`Settings(persistenceEnabled: true)`).
- Passing `--dart-define=USE_EMULATOR=true` connects Firestore (port 8080) and Auth (port 9099) to `10.0.2.2` on Android and `127.0.0.1` elsewhere.
- `FirestorePaths` centralizes all 25+ collection and subcollection path helpers from roadmap 12.2 and 12.5.
- `TxRunner` abstraction provided with `FirestoreTxRunner` for production and `FakeTxRunner` for deterministic in-memory tests.
- `BaseMapper` handles `createdAt`, `createdBy`, `updatedAt`, `updatedBy`, `schemaVersion`, `deletedAt`, `deletedBy` with UTC conversion and Firestore `Timestamp` interop.
- `firebase.json` seeds emulator ports and links `firebase/firestore.rules` (temporary deny-all) and `firebase/firestore.indexes.json` (seeded with composite indexes from roadmap 12.3).

## Step 7 verification findings (made while implementing Step 8)
- **Fixed:** `FirebaseAuthRepository.authStateChanges()` used `FirebaseAuth.authStateChanges()`, which does not fire on `User.reload()`. After "I have verified" the stream would never report `emailVerified == true`, so the Step 8 guard could not leave /verify-email. It now uses `userChanges()`.
- **Fixed:** `auth_providers.dart` lived in `features/auth/domain/` but imports `flutter_riverpod`, breaking "domain has zero imports of flutter". Moved to `features/auth/presentation/`. `test/architecture/layer_boundaries_test.dart` now enforces the layer table.
- **Fixed:** `FamilyHubApp` built a new `GoRouter` inside `build()`, resetting navigation on every theme/language change. The router is now a provider.
- **Open:** `google-services.json` (dev/prod) and `firebase_options_*.dart` still contain placeholder keys (`AIzaSy-dev-android-placeholder-key`, project numbers 1000000000xx). Run `flutterfire configure` for `familyhub-dev` / `familyhub-prod` before testing against real Firebase. The emulator route (`--dart-define=USE_EMULATOR=true`) does not need real keys.
- **Open:** Step 4 asked for a golden test of the theme settings screen and a widget test that switching themes changes the scaffold background instantly; neither exists (only controller/persistence tests).
- **Open:** auth goldens were generated on Windows (`D:/...` in the logs). Linux CI renders fonts differently, so they may fail in CI; regenerate on CI or tag them and exclude from the CI run.
- **Open:** `core/utils/clock.dart` imports `flutter_riverpod` (the `clockProvider`), so anything in domain that imports `Clock` pulls Flutter in transitively. Consider splitting the provider out in Step 9.
- **Housekeeping:** `*.log` files, `android/.gradle`, `android/.kotlin` and `test/**/failures/` should not be committed.

## Step 8 assumptions
- Session phases (loading, failed, signedOut, needsVerification, needsProfile, needsFamily, pending, disabled, active) are derived in `sessionPhaseProvider`; the redirect table is the pure function `resolveRedirect` in `lib/app/routing/redirect_rules.dart`, tested row by row.
- While the first auth/profile/membership event is loading, the app shows `/splash`; a failed read shows a Retry there. A deep link opened while loading or signed out is not remembered (documented simplification).
- Profile and membership data are not in Firestore yet. `lib/app/placeholders/` holds an in-memory `PlaceholderSession` and four temporary gate screens whose buttons ("(temporary)") move you forward so the whole flow can be exercised. **Delete that folder in Step 9** (search `TODO(step-9)`).
- Settings screens (/settings/theme, /settings/language) are full-screen routes above the shell and reachable in every phase (they only touch local preferences). `/dev/tokens` is registered only in the dev flavor.
- The router is rebuilt only when the *set* of enabled modules changes; the last location is remembered so the user stays where they were.
- `FamilyModule.requiredPermission` is a nullable String until Step 10 introduces `Permission`.
- New ARB keys were added by hand to the ARB files AND the checked-in generated l10n classes (no Flutter SDK was available to run gen-l10n). Running `flutter gen-l10n` should produce the same output.

## Step 9 — Profile, family create/join, invitations, approval (written; needs `dart format .`, `flutter analyze`, `flutter test` on your machine)
Done:
- Domain (pure Dart): `UserProfile`, `Family`, `Member`, `Invitation`, `MemberRole`, `Relationship`, `FamilyEvent`, `InviteCodeGenerator`; ports `FamilyRepository`, `UserProfileRepository`.
- Use cases (one class per file, `Result<T>`, activity+audit in the same write): `SaveProfile`, `CreateFamily`, `CreateInvitation`, `JoinWithCode`, `ApproveMember`, `RejectMember`, `DisableMember`, `ChangeRole`, `TransferAdmin`, `UpdateFamilySettings`; last-admin guard returns `Conflict(code: 'last_admin')`.
- Data: `FirestoreFamilyRepository` (every write is one `TxRunner` batch), `FirestoreProfileRepository`, `FirestoreMembershipRepository` (membership + module flags via `users/{uid}.familyId`), `FamilyMappers`, `FirestoreThemePreferenceSync` / `FirestoreLocalePreferenceSync`, `preferenceSyncProvider` (local wins at startup, remote applied once per sign-in, local pushed up if the account has none).
- Screens: ProfileSetup (also edit mode with spouse picker), FamilyChoice, CreateFamily, JoinFamily, Pending, Disabled, Members, Member profile, Invitations, Roles (+ transfer admin), Family settings (name, timezone, currency, module switches). Family tab shows the manager entries by role.
- `lib/app/placeholders/` (Step 8 throwaway) is deleted; the router uses the real screens.
- `firebase/firestore.rules` is now an **interim v0** (users, inviteCodes, families, members, invitations, settings, activity, auditLogs; default deny elsewhere).
- Tests: use cases against `InMemoryBackend` (create family, invitations incl. expired / reused / revoked / pending-cannot-act, approve / reject / disable / role / transfer incl. last-admin guard, profile, settings), mappers, `switchMap`, two widget flows (create family; join -> pending -> approved) plus the rejected-request flow.

Assumptions / limitations:
- Permission matrix (roadmap 2.2) was not readable in ROADMAP.md, so the Step 9 rule is: admin does everything; moderator invites, approves, rejects; Step 10 replaces it with `PermissionPolicy`.
- Rules are interim and **untested** (no emulator tests yet): Step 10 adds `rules_test`, tightens them and adds hard guards (e.g. last admin in rules).
- `saveProfile` re-writes `createdAt` on every save (merge); harmless, tidy in Step 10.
- Relationship list is a constant (not yet admin-editable).
- Spouse picker appears only when editing a profile inside a family (nobody to pick during onboarding).
- Firestore composite indexes: none new are required (single-field `createdAt` ordering on invitations).
- Open from earlier steps: real Firebase keys, Step 4 golden/widget tests, Windows-generated goldens in CI.
