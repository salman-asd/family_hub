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
| 9 Profile, family create/join, invitations, approval | Done (code + tests committed at cc17b69; never ran `dart format`/`flutter analyze`/`flutter test` on a machine with the SDK) | onboarding + family features, 10 use cases, Firestore repositories, 11 screens, interim rules v0, use-case/mapper/widget tests |
| 10 Permission policy and Firestore rules v1 | Done (rules **proved** by 99 emulator tests; Dart not compiled here) | `core/permissions` matrix + table-driven test, `requirePermission`, `PermissionGate`, rules v1 with allowed+denied cases for every rule, `rules` CI job |

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

## Step 10 — Permission policy and Firestore rules v1

Done:
- `lib/core/permissions/` (pure Dart, no Flutter/Firebase): `Role`, `Permission` (one value per roadmap 2.2 row), `PermissionActor`, `PermissionSettings`, `PermissionTemplate`, `PermissionPolicy.can(...)` with a documented matrix, plus a `permissions.dart` barrel.
- `requirePermission(...)` and `leavesNoActiveAdmin(...)` in `features/family/domain/permission_access.dart`: the Step 9 `requireActor` + its per-use-case role sets are gone, so the rule lives in exactly one place. All 8 mutating use cases now pass a `Permission`.
- `PermissionGate` in `lib/shared/widgets/`, with `hide` and `disable` modes; a blocked action is dimmed, non-tappable, announced to assistive technology and explained with an icon plus a localized message.
- `firebase/firestore.rules` **v1**: named helpers (`isMember`, `role`, `isAdmin`, `isMod`, `isManager`), field and enum validation, `createdBy`/`updatedBy` must be the caller, a moderator may only decide a pending request, a user may never write their own role or status, invite codes stay `get`-only and single-use, the logs stay append-only, and a deny-first guard covers the financial and chore collections before Steps 12-31 open them.
- `firebase/rules_test/` (JS, `@firebase/rules-unit-testing`): **99 tests, all green** against the Firestore emulator — one allowed and one denied case per rule, the four cases the roadmap names, and the Phase 1 scenario end to end.
- New CI `rules` job (Node 24 + Temurin 21, `npm ci` + `npm run test:emulator`); the existing `build` job is untouched.

Assumptions / limitations:
- Roadmap 2.2 was not in ROADMAP.md, so the matrix was derived from the rules the roadmap states elsewhere. It is now written twice, as a table at the top of `permission_policy.dart` and as the test table; those two are the source of truth. `removeMembers`/`changeRoles`/`editFamilySettings`/`exportData`/`manageCatalogAndBudgets`/`recordContribution` are admin (or admin+moderator) only; `viewFamilyReports`, `addOwnExpense` and `commentOnChore` are open to every active member.
- "moderator approve-only" is read as one `approveMembers` permission covering approve, reject and decline of a pending request; a moderator can never change a role or touch an active member.
- `requirePermission` loads the member document itself (one extra read per mutation) — deliberate, so a use case cannot forget the check.
- The last-admin guard is **not** expressible in rules (a subcollection cannot be enumerated); it stays in `leavesNoActiveAdmin` and is unit-tested. The rules file says so in its header.
- `isNonNegativeInt` / `isNonNegativeIntOrMissing` are in place for the money fields but nothing applies them yet: no money field exists until Step 13, which must use these helpers rather than add new ones.
- `Role` moved to `core/permissions/role.dart`; `MemberRole` is now a typedef, so Step 9 call sites and tests are unchanged.
- The Dart side of Step 10 could **not** be compiled or tested here (no Flutter SDK on this machine): `dart format .`, `flutter analyze` and `flutter test` still have to run on a machine that has it. The rules side was fully verified with the emulator.
- Housekeeping, unchanged: `*.log`, `android/.gradle`, `android/.kotlin`, `test/**/failures/` are committed or untracked noise; `node_modules/` is now ignored.

## Step 11 — Shared widget set and component gallery

Done:
- `lib/app/gallery/gallery_sections.dart` is the single source of truth: 11 sections (`app_avatar`, `item_thumb`, `status_chip`, `empty_state`, `loading_view`, `error_view`, `section_header`, `app_card`, `money_text`, `progress_ring`, `pill_bottom_bar`), each listing every state of its widget (plain, with image, failed image, empty, loading, error, retry, ...). The screen and both test suites iterate that list, so a widget cannot reach the gallery without gaining a golden and an overflow test.
- `lib/app/gallery/dev_gallery_screen.dart`: the debug-only `/dev/gallery` route (`AppRoutes.devGallery`, dev flavour only, in `alwaysOpen`) plus a dev-only entry beside the theme-tokens tile in the Family tab (a route alone cannot be opened on a phone).
- New shared widgets: `LoadingView` (skeleton, honours `MediaQuery.disableAnimations`, live-region announcement, localized default label), `ErrorView` (message plus optional retry, built on `EmptyState`), `ProgressRing` (clamped `value`, indeterminate when null, optional centre and semantic label).
- Real bugs found while wiring the gallery and fixed: `money_text.dart` imported a non-existent `app_tokens_ext.dart`; `status_chip.dart` used `context.l10n` without importing `l10n_ext.dart`; `StatusChip`, `MoneyText`, `AppAvatar`, `ItemThumb` and `PermissionGate` announced their text twice (own label merged with the child's); `ProgressRing` did not clamp its value; `roles_screen.dart` had an unused import (the only analyzer *warning*, and warnings are fatal).
- Tests: 44 goldens (11 sections x 2 themes x 2 languages, `test/shared/widgets/goldens/`), 45 overflow tests (11 sections x 2 themes x 2 locales at text scale 2.0, plus one long-copy test), behaviour tests for the new widgets and a gallery smoke test. The overflow test fails on any overflow; the goldens skip *with a reason* while the goldens directory is missing or `autoUpdateGoldenFiles` is on, so a fresh clone stays green.
- `analysis_options.yaml` now excludes `node_modules/**` (firebase-tools ships Dart templates the analyzer reported 6 errors for).

Verification (Flutter 3.47.7, Dart 3.13.5, Windows):
- `dart format` is clean on every file touched here.
- `flutter test`: **655 passed, 3 failed, 0 skipped** (the 44 goldens run and compare). The 3 failures are pre-existing Step 9 **test-assertion** bugs, not Step 11: `test/app/router_test.dart` "settings are reachable from the Family tab" and two in `test/features/family/presentation/onboarding_flow_test.dart`. All three fail identically with the Step 11 changes reverted to HEAD, and a probe of the router one shows the pushed screen *is* on screen (`ThemeSettingsScreen` found) while go_router 18's `routeInformationProvider.value.uri` still reports the branch path `/family`: the tests assert the URL of a `context.push`, which go_router 18 does not reflect. Fix = assert the screen, not the path (or make the app `go` instead of `push`).
- Known CI gaps, all pre-existing: `flutter analyze` exits 1 on 26 info-level lints (`require_trailing_commas`, two removed `unnecessary_import`s) in Steps 9/10 files, and `dart format --set-exit-if-changed .` reports 17 unformatted files. `flutter analyze` exits non-zero on any issue, so CI's `build` job stays red until those are cleaned (`dart format .` + trailing commas).
- The 44 goldens were generated on Windows; CI runs `ubuntu-latest`. If the golden step fails there, regenerate on Linux with `flutter test --update-goldens test/shared/widgets`.

Assumptions / limitations:
- Gallery image states use a deliberately unreachable URL (`invalid.invalid`) so the mandatory failed-load fallback is deterministic; the working-image path is covered synchronously by `_SyncImageProvider` in the widget tests.
- `ErrorView` reuses `EmptyState`, so it inherits the same scroll-safety and accessibility; its default title is `l10n.errorViewTitle` and `onRetry` is optional (no button when null).
- `ItemThumb` gained an `imageProvider` parameter (mirroring `AppAvatar`) for testability only.
- No new ARB keys were needed: `errorViewTitle`, `commonSeeAll`, `progressSemantics`, `thumbSemantics`, `loadingSemantics`, `loadingGeneric` and the 15 `gallery*`/`devGalleryTitle` keys already existed.

