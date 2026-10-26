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

## Phase 1 hardening - Part A (H1-H4), written statically
**Nothing in Part A was compiled or run by the author** (no Flutter SDK and no Firestore emulator
download in the authoring environment). Before merging run, in this order:
`flutter pub get`, `dart format .`, `flutter analyze`, `flutter test --exclude-tags golden`,
`npx firebase emulators:exec --only firestore --project demo-family-hub "npm --prefix firebase/rules_test test"`,
`node tools/check_indexes.mjs && node tools/check_indexes.test.mjs`, then the *Update goldens* workflow.

| Step | What changed |
| --- | --- |
| H1 | Green-baseline fixes, `golden` tag + Linux-only goldens workflow, pinned Flutter in CI, codegen deps removed (ADR 0004), golden policy (ADR 0005), repo hygiene (.gitignore/.gitattributes, logs and goldens removed), README, CLAUDE.md rules 14-24 |
| H2 | `.firebaserc`, `firebase/README.md`, invalid single-field indexes removed + `tools/check_indexes.mjs`, INTERNET permission, release signing via `android/key.properties` (prod fails without it), placeholder-key guard (`FirebaseNotConfiguredException`), `docs/RELEASE.md` |
| H3 | `DocState` (unknown vs absent) + `watchKnownDoc` in the profile/membership/family listeners, `guardWrite` (server probe + queued-write semantics), pending-write counter, `SyncBanner` in the shell and gallery, splash "waiting for connection", idempotent create/join ids |
| H4 | One family per user (`ensureFreeToJoinAnyFamily`), `LeaveFamily`, `CancelJoinRequest`, `RevokeInvitation`, `Member.leftAt`, rules v1.1 (leave, cancel, revoke, `familyPointerChangeOk`) with 24 new rules tests, UI (leave dialog, cancel request, revoke code), `docs/membership_state_machine.md` |

### Assumptions / deviations
- Repository interfaces still return `Result<void>` (no `WriteOutcome`): a write that is only queued offline returns success and is surfaced by the sync banner.
- "Offline" in the banner = writes pending for more than 10 s (no listener-based detection).
- Leaving sets BOTH `leftAt` and `removedAt` so the existing rejoin rule and routing work unchanged.
- Generated l10n files were edited by hand (`tools` helper); run `flutter gen-l10n` to confirm they are identical.
- `flutterfire configure`, real `google-services.json`, the upload keystore and `firebase deploy` are manual steps (`firebase/README.md`, `docs/RELEASE.md`).


## Phase 1 hardening - Part B (H5-H8), written statically
Not compiled or run (no Flutter SDK / emulator available). Run the Part A checklist above, then
`UPDATE_PERMISSION_MATRIX=1 flutter test test/core/permissions/permission_matrix_doc_test.dart` only if the matrix test reports drift.

- **H5/H6 verified**: rules (validation, closed key sets, log integrity, verified email, invite burn-in-same-batch, adminIds guard) and token refresh are in place. Fixed during verification: contract fixtures lacked `adminIds` (create_family) and a `transfer_admin` fixture; `InMemoryBackend.saveMembers` did not match the H6 interface (`adminIds`); no Dart tests covered adminIds (added `admin_ids_test.dart`).
- **H7**: permission providers (`currentActorProvider`, `canProvider`, `ref.can`), `settings/permissions` (rules, mapper, repository, `UpdatePermissionSettings`), new `viewAllContributions` permission, configurable cells, `Membership.isAdmin/...` removed, screens use `ref.can`/`PermissionGate`, `requiredPermission` is a `Permission?` with `visibleModulesProvider`, generated `docs/permission_matrix.md`, architecture test.
- **H8**: pure `clock.dart` + `clock_provider.dart`, `ModuleFlags` moved to the family domain, `AuditEvent` + `AuditWriter` (`FamilyEvent` deleted), import-graph layer test, TODO cleanup + test + hard CI failure, exhaustive failure mapping + test.

Assumptions: no UI yet for editing the five permission switches (use case and rules exist); `AuditEvent.summary` kept (optional) until H9; `requirePermission` falls back to default settings when the settings read fails.

## Phase 1 hardening - Part C (H9-H12), written statically
Not compiled or run (no Flutter SDK / emulator available). Run the Part A checklist, then `flutter gen-l10n` (confirms the generated l10n files), `dart format .`, and the *Update goldens* workflow (new settings goldens).

| Step | What changed |
| --- | --- |
| H9 | Change password, delete account (soft delete, resumable), `/settings/security`, sign-out Firestore cache wipe, rules for soft-delete, ARB keys, tests |
| H10 | `saveProfile` stamps `createdAt` once, `watchFamily` via `combineLatest3`, auto-disposed action providers, language-neutral events + `activityText`, editable relationships (`RelationshipId`, catalog, rules, screen), `Membership.leftAt` |
| H11 | `placeholderOnLight/Dark` tokens, stricter no-raw-colour test, settings screens split, `file_size_test`, `LoadingView` on list screens, error states, reduced-motion tests, theme/language tests + goldens, `test/support/screen_states.dart` harness (Theme, Language, Security, Relationships) |
| H12 | `FamilyDateKeys` + providers, `FamilySeeder` hook, 500-write batch budget, rules helper scaffold, checklist + test template, `query_limits` + unbounded-query test, paths-vs-rules test, ADRs 0001-0005 |

### Assumptions / deviations
- `saveProfile` reads the current document and writes a batch instead of using a Firestore transaction (transactions fail offline; rule 15 wants the save queued).
- The `FamilySeeder` port returns plain `SeedWrite`s (not `BatchContext`) so the domain stays free of Firebase.
- `AuditEvent.summary` stays as an always-empty field because the rules' closed key set still lists it.
- `firestore_family_repository.dart` is on the file-size allow-list (documented debt).
- The screen-state harness covers only screens that need no Firebase; extend it to the Firebase-backed screens with provider overrides. The offline state is covered by the shell banner (H3).
- Deleting an account as a solo admin leaves the family dormant (its member document stays active).

## Phase 1 hardening - Part D (H13), written statically

H13 makes no feature change. It adds the sign-off tooling and documents; **nothing has been executed** (no Flutter SDK, Node or emulator in the authoring environment), so no result is claimed.

| Deliverable | File |
| --- | --- |
| One-command verification (format, analyze, tests, goldens, indexes, rules, TODO grep, both APKs) writing PASS/FAIL + counts | `tools/phase1_evidence.sh` -> `docs/phase1_evidence.md` |
| Coverage per top-level folder, files under 70% in `core/` and `features/*/domain/` | `tools/coverage_summary.dart` |
| Security review with `file:line` evidence | `docs/phase1_security_review.md` |
| Manual matrix (2 devices, bn/en, light/dark, online/offline) | `docs/phase1_manual_test.md` |
| Guard: the sign-off files exist and the review names every rules collection | `test/architecture/phase1_docs_test.dart` |

Security review result: 11 checklist items pass by reading rules and tests; one low finding **F-31** (`users/{uid}` has no closed key set; fix described in the review, not applied because H13 changes no features).

### Tag `phase-1-complete`: NOT created. Blockers

1. `bash tools/phase1_evidence.sh` has not been run: format, analyze, all tests, goldens, rules suite, indexes check and both APK builds are unverified.
2. Goldens do not exist yet: run the *Update goldens* workflow once, review, commit.
3. Manual matrix (`docs/phase1_manual_test.md`) not executed on real devices against the dev Firebase project.
4. Real Firebase config, upload keystore and `firebase deploy` of rules/indexes are manual (`firebase/README.md`, `docs/RELEASE.md`).
5. Optional before the tag: close F-31.

Create the tag only when 1-4 are green: `git tag phase-1-complete && git push --tags`.

## Phase 2 - P2-01 Preflight gate, Bazar skeleton, seams

Executed on this machine (Flutter 3.47.7 / Dart 3.13.5) on 2026-10-22. The base tree was red on
arrival, so the P2-01 gate included the mechanical baseline fixes below; no Phase 2 feature work
beyond the card was started.

| Gate command | Result |
| --- | --- |
| `dart format --set-exit-if-changed .` | PASS (290 files, 0 changed) |
| `flutter analyze` | PASS (`No issues found!`) |
| `flutter test --exclude-tags golden` | PASS (827 tests) |
| `node tools/check_indexes.mjs` | PASS (`firestore.indexes.json OK`) |
| rules suite (`firebase emulators:exec ...`) | **NOT RUN**: `java -version` cannot spawn; Java is not installed/on PATH |
| `flutter build apk --flavor dev -t lib/main_dev.dart` | **NOT RUN**: `flutter doctor` reports no Android SDK |
| Manual device acceptance (sign up -> create family -> join -> approve) | **NOT RUN**: no device/emulator with Firebase config |

### Baseline fixes required by the gate
- Ran the Dart 3.13 formatter over the tree (large but mechanical diff).
- Fixed all pre-existing analyzer issues (Riverpod `Override` import from `flutter_riverpod/misc.dart`,
  `ActionController.run<void>` call sites, unused/duplicate imports, initializing formals, wildcards,
  null-aware elements, widget keys).
- Fixed pre-existing failing tests without weakening them: map identity in `doc_state_test`, the
  TODO detector matching itself, two files over 300 lines split, the missed `viewAllContributions`
  permission in the contract list, `expect` outside a test in `paths_match_rules_test`, the shell
  test missing a `ProviderScope`, and a missing Cupertino delegate that produced the `bn` locale warning.
- Added the missing semantic labels to the two settings switches.

### P2-01 deliverables
- `docs/PHASE2_BAZAR_ROADMAP.md` (copy) and ADRs 0006-0008.
- `lib/features/bazar/bazar_entries.dart` + `presentation/bazar_home_screen.dart`; placeholder deleted.
- `familySeedersProvider` wired into `createFamilyProvider`.
- bn/en ARB keys for the empty state (`flutter gen-l10n` run).
- CLAUDE.md folder layout (`bazar/fund`, `bazar/settings`) and Phase 2 rules 25-33.
- Tests: provider-seeded family creation and the Bazar home (bn/en, light/dark, empty, permission hiding).

### Assumptions / deviations
- `BazarHomeScreen` takes an optional `entries` list for widget tests; production still reads the shared
  `bazarEntries` list. This keeps the seam testable without a global mutation.
- P2-01 adds no Firestore collection, so rules, indexes and contract fixtures are unchanged.
- The rules suite and APK build remain unverified until Java, the Android SDK and real Firebase config
  are available. H13's own blockers (goldens, manual matrix) are still open.

## Phase 2 - P2-02 Pure helpers: money math, unit catalog, date ranges

Pure Dart only; no Firestore, rules or UI changes.

| Command | Result |
| --- | --- |
| `dart format --set-exit-if-changed .` | PASS |
| `flutter analyze` | PASS (`No issues found!`) |
| `flutter test --exclude-tags golden` | PASS (867 tests; 40 new helper cases) |

### Deliverables
- `lib/core/utils/money_math.dart`: `basisPoints` (integer half-up, `null` for a non-positive whole),
  `splitEqually` (remainder paisa to the first shares), `maxMoney`/`minMoney`, `tryLineTotal`.
- `lib/core/utils/unit_catalog.dart`: `UnitInfo` (`isWeight`/`isVolume`/`isCount`) and Bangla/English
  `parseUnit` aliases from the card.
- `lib/core/utils/date_ranges.dart`: `RangePreset`, `resolveRange`, `startOfWeek`, `previousComparable`,
  `lengthInDays`, `daysIn`, `monthsIn`.
- Tests for every branch above, including the roadmap's Wednesday, leap-day, March->February and year
  boundary cases; `no_floating_point_test` now also scans `money_math.dart`.

### Assumptions
- `basisPoints` uses half-up with ties away from zero for negative parts, matching `lineTotal`.
- `isCount` covers piece, dozen, packet and cylinder; every unit belongs to exactly one kind (tested).
- Custom ranges use assertions for programmer errors, the same convention as `Money`/`Quantity`.
- `thisWeek` is Saturday..Friday by default, with `weekStartDay` overridable.

## Phase 2 - P2-03 Vocabulary: audit types, paths, permissions, ARB base

| Command | Result |
| --- | --- |
| `dart format --set-exit-if-changed .` | PASS (301 files, 0 changed) |
| `flutter analyze` | PASS (`No issues found!`) |
| `flutter test --exclude-tags golden` | PASS (892 tests) |
| `node tools/check_indexes.mjs` | PASS (no index change) |
| `flutter gen-l10n` twice | PASS (no diff on the second run) |
| `UPDATE_PERMISSION_MATRIX=1 flutter test ...` | PASS; `docs/permission_matrix.md` regenerated, second run matches |
| rules suite | **NOT RUN** - Java is not installed (`Could not spawn 'java -version'`) |

### Deliverables
- `lib/core/audit/audit_event_type.dart`: the 31 §3.9 `bazar.*` types appended to `all`.
- `lib/core/audit/audit_ref_type.dart` (new): the 13 `refType` values, mirrored by a new test.
- `firebase/firestore.rules`: both closed lists extended; header updated. One new emulator test
  (`bazar.expense_created` allowed) sits beside the existing unknown-type denial.
- `lib/core/localization/activity_text.dart`: a case for every new type; money params go through
  `MoneyFormatter`; `funding`/advance `status`/`newRole` are localized with a fallback.
- ARB bn/en: 31 `activityBazar*` keys, 7 unit labels, `bazarSettingsTitle`, funding/advance labels,
  and one `bazarErr*` message for every §3.6 code.
- `lib/core/localization/unit_labels.dart` (new): `UnitLabels.unitLabel`.
- `lib/features/bazar/presentation/bazar_failure_messages.dart` (new): exhaustive
  `bazarFailureMessage`, with generic fallbacks for unknown codes.
- `lib/core/firebase/firestore_paths.dart`: `monthClosings`, `importBatches`, expense revisions and
  `settings/bazar`; the two new collections are listed as pending in `paths_match_rules_test`.
- `lib/core/permissions/`: `closeBazarMonth`, `importBazarData` (finance-manager rule) and
  `requestContribution` (any active member), with matrix rows and focused tests.
- The `moderator` **display label** is now "Household Manager" / "সংসার ব্যবস্থাপক"; the stored
  value `moderator` is unchanged.

### Assumptions / deviations
- Unknown `Validation`/`Conflict` codes show `bazarErrUnknown`; `NotFound` shows `bazarErrNotFound`;
  `Network` reuses `errorNetwork`. Raw codes never reach the screen (tested in bn and en).
- `bazarErrNegative` says "below zero" so the natural English sentence does not contain the raw code
  `negative`; the test enforces "no code substring".
- The role label change may invalidate a golden that prints a role; goldens are generated on Linux CI
  only and none was hand-edited. Regenerate with the *Update goldens* workflow if CI reports one.
- The rules emulator test and the rules suite remain unverified on this machine.

## Phase 2 - P2-04 Catalog domain + ItemSearch

Pure Dart domain and use cases only; no Firestore, rules, indexes, ARB, providers or screens.

| Command | Result |
| --- | --- |
| `dart format --set-exit-if-changed .` | PASS (324 files, 0 changed) |
| `flutter analyze` | PASS (`No issues found!`) |
| `flutter test --exclude-tags golden` | PASS (963 tests; 71 new P2-04 cases) |
| `node tools/check_indexes.mjs` | PASS (no index change) |
| rules suite | **NOT RUN** - no rules change in P2-04; Java is still unavailable |
| `flutter gen-l10n` | **NOT RUN** - no user-visible text or ARB change in P2-04 |

### Deliverables
- `lib/features/bazar/items_categories/domain/category.dart` and `item.dart`: immutable hand-written
  entities with `==`, `hashCode`, `copyWith` and `displayName({required bool bangla})` fallback.
- `text_normalizer.dart`: trim/lower-case/collapse, ZWJ/ZWNJ removal, Bangla nukta composition and
  Bangla-to-English digits.
- `item_search.dart`: exact/prefix/word-prefix/contains tiers, frequency then built-in then name ranking,
  inactive filtering, category filter, empty-query frequent + built-in seed order, limit.
- `catalog_index.dart`: by-id maps, items-by-category, sorted active categories and the shared search.
- `catalog_repository.dart`: the catalog port, including the server-read `isCatalogEmpty` and
  `seedDefaultCatalog` contracts.
- Seven use cases under `domain/usecases/`: `AddCategory`, `UpdateCategory`, `DeactivateCategory`,
  `AddItem`, `AddCustomItem`, `UpdateItem`, `DeactivateItem`. Permission is checked first, then
  validation, category/duplicate rules, the event and the write.
- `catalog_validation.dart`: shared name/alias/colour/emoji/image validation, category and item lookup,
  and duplicate normalized-name detection.
- `test/support/in_memory_bazar_backend.dart` and `test/features/bazar/bazar_test_helpers.dart`:
  a catalog-fake with live streams plus the standard `f1` family (alice admin, bob moderator, cara
  member, dave pending).
- 71 tests: normalizer, models, search table, index, every use case (permission denial for
  member/pending, validation, duplicate, events) and `AddCustomItem`.

### Assumptions / deviations
- "Built-ins in seed order" for an empty query means the order supplied to `ItemSearch`; `Item` has no
  seed-order field and P2-06 will supply the Appendix A order. The `CatalogIndex` preserves the
  repository order.
- Aliases are trimmed and blank ones dropped before validation; more than 10 or any alias longer than
  40 code points fails. Name lengths use Unicode code points (`runes`), not UTF-16 units.
- Both `AddItem` and `AddCustomItem` enforce the duplicate rule (active item with the same normalized
  `nameBn` in the same category). `AddCustomItem` never creates a built-in item and always starts at
  `useCount = 0`.
- `UpdateCategory`/`UpdateItem` preserve `active`, `builtIn`, `seedKey`, and for items the usage fields
  (`useCount`, last prices, `lastUsedAt`), regardless of the edit.
- Deactivating an already inactive category/item returns success without a second write or event.
- Existing use-case `copyWith` limits to non-null overrides; edits rebuild the entity directly so a
  `nameEn`/emoji/image can be cleared.
- P2-05 still owns the Firestore mapper/repository, rules, contract fixtures, providers and bootstrap
  wiring; P2-04 adds no collection to the app.

## Phase 2 - P2-05 Catalog data layer, rules and providers

| Command | Result |
| --- | --- |
| `dart format --set-exit-if-changed .` | PASS (329 files, 0 changed after formatting 5) |
| `flutter analyze` | PASS (`No issues found!`) |
| `flutter test --exclude-tags golden` | PASS (979 tests; 16 new P2-05 cases) |
| `node tools/check_indexes.mjs` | PASS (`firestore.indexes.json OK`; no composite index needed) |
| rules suite (`firebase emulators:exec ...`) | **NOT RUN** - `Could not spawn 'java -version'`; Java is still unavailable |
| `flutter gen-l10n` | **NOT RUN** - no user-visible text or ARB change in P2-05 |
| APK build | **NOT RUN** - `flutter doctor` reports no Android SDK |

### Deliverables
- `lib/features/bazar/items_categories/data/catalog_mappers.dart`: category/item `toMap`/`fromMap`
  (tolerant defaults, unknown unit -> `Unit.piece`, clamped palette index and counters), `changeMap`
  for catalog edits and `itemUsageMap` for member purchase bumps.
- `lib/features/bazar/items_categories/data/firestore_catalog_repository.dart`: bounded live streams
  and reads (`kMaxCatalogDocs`), batch writes with `AuditWriter` in the same batch, server-probe
  `seedDefaultCatalog`, server-only `isCatalogEmpty`.
- `lib/features/bazar/items_categories/domain/item_usage_bump.dart`: the P2-09 value object P2-05
  needs, with positive-increment assertion and value equality.
- `lib/core/firebase/query_limits.dart`: `kMaxCatalogDocs = 500`.
- `firebase/firestore.rules`: `financeManager`, `categoryKeys`, `itemKeys`, `categoryOk`, `itemOk`,
  `bazarCategories` and `bazarItems` blocks; reads for active members, manager writes, member custom
  items, 1..40 usage bumps, soft delete only.
- `firebase/rules_test/catalog.test.mjs`: allowed/denied cases for reads, category creation (admin,
  finance-on/off moderator, member), unknown fields, palette range, custom/built-in items, usage
  bumps, hard delete and the 11-category + 54-item family-creation batch.
- `firebase/rules_test/support.mjs`: shared `categoryDoc`, `itemDoc`, `itemUsage` fixtures.
- Contract seam: generated `category.json`, `item.json`, `item_usage.json` from the real mappers;
  `rules_key_sets_test` now checks `categoryKeys()`/`itemKeys()` and the usage subset; the path test
  no longer lists the two catalog collections as pending.
- `lib/features/bazar/items_categories/presentation/catalog_providers.dart`: repository, live
  categories/items, synchronous `CatalogIndex`, and one provider per catalog use case.
- `lib/app/bootstrap.dart`: constructs `FirestoreCatalogRepository` and overrides the provider.
- 16 tests: mapper round-trip/tolerance/change/usage maps and repository batch paths, paisa ints,
  immutable seed fields and atomic failure.

### Assumptions / deviations
- `ItemUsageBump` is defined now under `items_categories/domain/` because the P2-05 mapper needs it;
  P2-09 can import it (or move it into `write_plans.dart`) without changing its shape.
- `seedDefaultCatalog` currently stages the audit entry with the server probe; P2-06 adds the 11
  categories and 54 items to that same batch. `isCatalogEmpty` is a server `limit(1)` read, so offline
  is a failure rather than a false "empty".
- Null `lastPricePaisa`/`lastUnitPricePaisa`/`lastUsedAt` are omitted from maps because
  `isNonNegativeIntOrMissing` accepts a missing key but not an explicit null. A full document has all
  of them.
- `useCount` is written with `FieldValue.increment`, so the rules see the post-increment value and can
  enforce the 1..40 delta; the contract encoder represents it as `{"__increment": n}`.
- `itemChangeMap` deliberately excludes usage counters and last prices, so a catalog edit cannot
  reset them; only `itemUsageMap` changes them.
- `catalogIndexProvider` is a plain synchronous provider and yields an empty index while streams load
  or outside a family; screens do not branch on a second loading state.
- No UI or user-visible text, so no ARB/golden change. The rules suite, APK and device acceptance
  remain unverified for the same environment reasons as P2-01..P2-04.

## Phase 2 - P2-06 Default catalog seed and backfill

| Command | Result |
| --- | --- |
| `dart format --set-exit-if-changed .` | PASS (337 files, 0 changed) |
| `flutter analyze` | PASS (`No issues found!`) |
| `flutter test --exclude-tags golden` | PASS (990 tests; 11 new P2-06 cases) |
| `node tools/check_indexes.mjs` | PASS (`firestore.indexes.json OK`; no index change) |
| `flutter gen-l10n` | PASS (new bn/en setup-card keys generated) |
| contract fixture generator | PASS (`create_family_catalog.json`: 76 writes) |
| rules suite (`firebase emulators:exec ...`) | **NOT RUN** - `java -version` cannot spawn; Java is still unavailable |
| APK build | **NOT RUN** - `flutter doctor` reports no Android SDK |

### Deliverables
- `lib/features/bazar/items_categories/domain/default_catalog.dart`: pure `const` `SeedCategory` x11 and
  `SeedItem` x54 exactly as Appendix A, with deterministic `cat_<key>` / `item_<key>` ids.
- `lib/features/bazar/items_categories/data/default_catalog_writes.dart`: maps the seed through
  `CatalogMappers` with `builtIn: true`, `seedKey` and shared create metadata.
- `lib/features/bazar/items_categories/data/default_catalog_seeder.dart`: the `FamilySeeder` used by
  `CreateFamily`, so a brand-new family gets all 65 catalog documents in its own batch.
- `lib/app/bootstrap.dart`: installs `DefaultCatalogSeeder` in `familySeedersProvider`.
- `lib/features/bazar/items_categories/domain/usecases/ensure_catalog_seeded.dart`: permission ->
  server-only `isCatalogEmpty` -> `catalog_not_empty` conflict or `seedDefaultCatalog`, with a
  `bazar.catalog_seeded` event (`categories: '11'`, `items: '54'`).
- `firestore_catalog_repository.dart`: `seedDefaultCatalog` now writes the real 11 categories + 54 items
  and the audit entry in one probed batch (67 writes, well below 500).
- `bazar_home_screen.dart`: when categories are loaded and empty, a manager sees a "Set up the starter
  catalog" card and button; everyone else sees "Ask an admin to set up the catalog". The button shows
  busy and failure states and never seeds silently.
- bn/en setup-card keys and `flutter gen-l10n`; `BusyButton` gained an optional `busyLabel`.
- Tests: key/unit/name/alias/id/batch-limit checks for the seed, backfill-once + conflict + member denial
  + offline-no-write, `CreateFamily` seed count, and the home-screen manager/member states.
- Contract seam: `create_family_catalog.json` contains the real 9 family documents + 65 catalog
  documents + 2 audit documents (76 writes) in one create-family batch.

### Assumptions / deviations
- The P2-06 card's `~56 docs` note is stale; Appendix A is 11 categories + 54 items = 65 documents.
  The batch test asserts 76 with the nine family documents and two audit entries.
- `SeedCategory` / `SeedItem` use positional constructors (as written in the card) so the single
  `default_catalog.dart` stays under the 300-line file-size limit.
- `seedDefaultCatalog` stamps the catalog documents with the event's `at` time, so the catalog and its
  audit entry share one clock reading; the repository probe still makes the backfill server-only.
- The home-screen setup card appears only after the categories stream has a value and it is empty. While
  loading, erroring or offline, the home keeps its normal body; the tap itself reports `errorNetwork`.
- No new collection, rules or index change; the new contract fixture exercises the existing catalog
  rules with the real seed. Rules emulator, APK and device acceptance remain unverified because Java,
  the Android SDK and a configured device/Firebase project are unavailable.

## Phase 2 - P2-07 Bazar settings (domain, data, rules, providers)

| Command | Result |
| --- | --- |
| `dart format --set-exit-if-changed .` | PASS (347 files, 0 changed) |
| `flutter analyze` | PASS (`No issues found!`) |
| `flutter test --exclude-tags golden` | PASS (1003 tests; 13 new P2-07 cases) |
| `node tools/check_indexes.mjs` | PASS (`firestore.indexes.json OK`; no index change) |
| contract fixture generator | PASS (`settings_bazar.json`: real merge + two audit writes) |
| `flutter gen-l10n` | **NOT RUN** - no user-visible text or ARB change in P2-07 |
| rules suite (`firebase emulators:exec ...`) | **NOT RUN** - `Could not spawn 'java -version'`; Java is still unavailable |
| APK build | **NOT RUN** - `flutter doctor` reports no Android SDK |

### Deliverables
- `lib/features/bazar/settings/domain/bazar_settings.dart`: immutable settings with defaults
  (`weekStartDay` 6, zero contribution, due day 5, thresholds `[80, 100]`, no fund start month),
  `copyWith` including `clearFundStartMonth`, value equality and list-aware hashing.
- `bazar_settings_repository.dart`: `watch` (absent document = defaults), `get`, and `save(familyId,
  settings, event)`.
- `usecases/update_bazar_settings.dart`: permission -> range validation -> one repository write; the
  event is `bazar.settings_updated` with `family` ref.
- `data/bazar_settings_mappers.dart`: integer-paisa and `yyyy-MM` maps, tolerant reads for old/damaged
  documents, and the closed key set used by the contract tests.
- `data/firestore_bazar_settings_repository.dart`: `watchKnownDoc` -> defaults, guarded `get`, and a
  server-required `set(..., merge: true)` plus audit entry in one batch. It preserves an existing
  document's `createdAt`/`createdBy` while updating `updatedAt`/`updatedBy`.
- `presentation/bazar_settings_providers.dart`: `bazarSettingsRepositoryProvider`,
  `bazarSettingsProvider` (synchronous value or defaults), and `updateBazarSettingsProvider`;
  installed in `bootstrap.dart`.
- `firebase/firestore.rules`: `settingsKeys()`/`settingsOk` now cover the five Bazar fields, and
  `settings/bazar` is writable by an admin or a finance moderator (`s == 'bazar' && financeManager(f)`).
- Tests: mapper round-trip/defaults/damaged data, use-case permission and every validation range,
  provider defaults/then-stream update, `rules_key_sets_test`, and
  `firebase/rules_test/bazar_settings.test.mjs`.
- Contract seam: `settings_bazar.json` uses the real mapper merge and both audit-log writes.

### Assumptions / deviations
- The card does not spell out validation codes, so the use case uses `invalid` for the two day ranges,
  `negative`, and `empty`/`too_many`/`out_of_range`/`duplicate`/`not_ascending` for thresholds.
  An empty threshold list is rejected, because downstream budget status reads the first/last values.
- The Bazar settings fields are optional in `settingsOk`, so the one shape function still validates the
  other settings documents created at onboarding.
- `save` reads the existing document after the server probe to preserve `createdAt`/`createdBy`; a first
  save still creates it through `set(..., merge: true)`.
- There is no screen in P2-07: the settings UI is P2-16. No collection, index or user-visible string was
  added. Rules emulator and APK/device acceptance remain unverified (no Java/Android SDK/device).

## Phase 2 - P2-08 Fund ledger and month-closing domain

| Command | Result |
| --- | --- |
| `dart format --set-exit-if-changed .` | PASS (361 files, 0 changed) |
| `flutter analyze` | PASS (`No issues found!`) |
| `flutter test --exclude-tags golden` | PASS (1034 tests; 31 new P2-08 cases) |
| `node tools/check_indexes.mjs` | PASS (`firestore.indexes.json OK`; no index change) |
| `flutter gen-l10n` | **NOT NEEDED** - no user-visible text or ARB change |
| rules suite (`firebase emulators:exec ...`) | **NOT RUN** - P2-08 adds no rules; Java is still unavailable for the earlier pending rules changes |
| APK build | **NOT RUN** - `flutter doctor` reports no Android SDK |

### Deliverables
- `lib/features/bazar/fund/domain/fund_transaction.dart`: `FundTxType`, `FundRefType`, an immutable
  `FundTransaction`, a sign-checking constructor for future mappers, and the five named factories
  (`exp_`, `con_`, `stl_`, `open_`, `adj_` with an optional suffix). The factories derive `monthKey`
  from `dateKey`, except `opening`, which uses the first day of its month.
- `fund_balance_calculator.dart`: `FundBalanceCalculator.balance`, `summarize` (received, spent,
  reimbursed, opening, adjustments, balance) and `ledgerFor(refId)`; `FundSummary` is a value object.
- `ledger_integrity_check.dart`: `LedgerIssueKind` (`mismatch`, `orphan`) and the `LedgerIssue` value
  class. `checkLedger` itself waits for P2-22, when `Expense` exists.
- `month_closing.dart`: `MonthStatus`, `MonthClosing` and `MonthLocks.isLocked` /
  `MonthLocks.fundWindowStart` (month after the latest closed month, else `fundStartMonth`, else null).
- `fund_repository.dart`: the read-only ledger/closing port (`watchTransactionsFrom`,
  `getMonthTransactions`, `getTransactionsForRef`, `watchClosings`, `getClosing`).
- `lib/features/bazar/advances/domain/member_advance.dart`: `AdvanceStatus`, immutable
  `MemberAdvance`, `remaining`, `statusFor`, and a `copyWith` that keeps the status/amount invariant.
- `advances/domain/settlement.dart` and `advance_repository.dart`: the append-only settlement value
  object and the advance read port.
- 31 tests: every factory sign/id/ref, zero and wrong-sign rejection, month consistency, a
  hand-computed summary, `ledgerFor`, booked/reopened/year-boundary windows, advance transitions,
  `settled > amount`, and settlement invariants.

### Assumptions / deviations
- `spent` and `reimbursed` are positive display magnitudes; `opening` and `adjustments` keep their
  signed ledger meaning, and `balance` is always the sum of the signed rows. This matches the fund
  card's positive chips without storing a second balance.
- `opening` and `adjustment` amounts must be non-zero, following the data-shape rule in §3.2. A zero
  opening balance is simply skipped by `RecordOpeningBalance` (P2-21), so it never needs a row.
- The public `FundTransaction` constructor validates sign and `monthKey == dateKey` so a future mapper
  can rehydrate documents without bypassing the invariant; the named factories are still the only
  intended write path.
- `MemberAdvance` also rejects a non-voided status that disagrees with `amount`/`settled`; a voided
  advance may keep any valid settled amount.
- No collection, rules, index, permission, screen or user-visible string is added. All repository
  writes (contributions, settlements, openings, closings) are deferred to the use-case steps.

## Phase 2 - P2-09 Expense domain, use cases and in-memory backend

| Command | Result |
| --- | --- |
| `dart format --set-exit-if-changed .` | PASS (386 files, 0 changed) |
| `flutter analyze` | PASS (`No issues found!`) |
| `flutter test --exclude-tags golden` | PASS (1094 tests; 60 P2-09 cases in `test/features/bazar/expenses/`) |
| `node tools/check_indexes.mjs` | PASS (`firestore.indexes.json OK`; no index change) |
| `flutter gen-l10n` | **NOT NEEDED** - no user-visible text or ARB change |
| rules suite (`firebase emulators:exec ...`) | **NOT RUN** - P2-09 adds no rules; Java is still unavailable for the earlier pending rules changes |
| APK build | **NOT RUN** - `flutter doctor` reports no Android SDK |

### Deliverables
- `expenses/domain/funding.dart`, `expense.dart`, `expense_draft.dart`, `expense_totals.dart`,
  `trip.dart`, `month_spend.dart`, `expense_filters.dart`, `expense_repository.dart`,
  `expense_validation.dart`, `write_plans.dart` and `expense_compensation.dart`.
- `Expense` is immutable, asserts `total > 0`, `member <=> payer`, `reimbursable` only for member
  funding and `monthKey == dateKey`; its `copyWith` uses an `_unset` sentinel so `null` can clear an
  optional field. `spenderId` is `purchaserId ?? paidByMemberId ?? createdBy`.
- `computeTotal` is the single money rule: quantity x unit price wins, a lone quantity or price is
  `qty_unit_required`, and the result must be positive. No `double` is used.
- `MonthSpend` skips soft-deleted rows; `ExpenseFilters` implements the list filters, text
  normalisation and day grouping helpers.
- `ExpenseRepository`, `ExpenseRevision`, `defaultExpensePageSize = 30`, and the pure
  add/trip/edit/delete/restore plan objects.
- Use cases: `CheckDuplicate`, `AddExpense`, `AddBazarTrip`, `UpdateExpense`,
  `SoftDeleteExpense` and `RestoreExpense`. Add/Trip create the fund row (fund), pending advance
  (member + reimbursable), item usage or a remembered item. Edit writes append-only `adj_` rows,
  keeps the original `exp_` row untouched, records revisions, and voids/updates advances. Delete
  adds `+total` and voids a pending advance; restore adds `-total` and reopens the advance.
- `test/support/in_memory_bazar_backend.dart` now also implements `ExpenseRepository`,
  `FundRepository` and `AdvanceRepository` with expenses, trips, ledger, advances, settlements,
  closings, revisions, live streams, idempotent event application and the shared `failNextWrite`
  hook. `fundTx` is an alias for the ledger map.
- `test/features/bazar/bazar_test_helpers.dart` gained the P2-09 use-case factories, a draft
  builder and seeded expense/advance/fund/closing helpers.
- 60 tests: totals, every funding combination, the compensation table, original-row immutability,
  delete/restore, duplicate warning boundaries, permissions (including moderator edit), locked old
  and destination months, 1/40/41-line trips, aggregated usage, retries, and a full
  add/edit/delete/restore ledger invariant (`ledgerFor == -total` for live fund rows, `0` for
  member/personal/deleted rows).

### Assumptions / deviations
- `defaultExpensePageSize` is kept as the repository's explicit page-size name (the card's
  `defaultPageSize`); the data layer will continue to use the shared `defaultPageSize` constant.
- Fund-funded drafts normalise away a stale payer/reimbursable flag; member-funded drafts require
  a non-empty payer. The use cases reject future dates and apply the same validation order to add,
  trip and edit.
- `CheckDuplicate` accepts an optional `actorUid`; permission is checked only when the caller
  supplies one. `ExpenseFilters.memberId` matches `Expense.spenderId`.
- A member trip's remembered line item uses the deterministic id `item_$expenseId`; usage is
  aggregated per item. A zero-line and a 41-line trip both return `too_many_lines`.
- Delete/restore are batch operations without a probe, so the offline undo path works. An advance
  with `settled > 0` blocks delete, restore and funding/amount/payer edits.
- No collection, rules, index, permission, screen or user-visible string is added. The data layer
  (P2-10) still has to implement these ports against Firestore.

## Phase 2 - P2-10 Expense / fund / advance data layer, rules, indexes (audited and completed)

Found already in the tree when audited (not previously recorded here): expense/fund/advance mappers,
`ExpenseWriteStager`, `FirestoreExpenseRepository`, `FirestoreFundRepository`,
`FirestoreAdvanceRepository`, the rules for `expenses` (+`revisions`), `bazarTrips`,
`fundTransactions`, `memberAdvances`, `settlements`, `monthClosings`, the rules tests
(`expenses/fund/advances.test.mjs`), contract fixtures and bootstrap wiring.

Fixed in this audit:
- `queryRange` paging used `startAfter([dateKey])`, which skipped the rest of the last day. It now
  orders by `(dateKey DESC, __name__ DESC)` and resumes after `[dateKey, id]` (same composite indexes).
- A plain member could not read open advances: the rules allow only their own, and a rules check is
  not a filter, so the unfiltered query was denied. `AdvanceRepository.watchOpenAdvances` takes an
  optional `memberId`; new index `memberAdvances (memberId, status, dateKey DESC)`.

## Phase 2 - P2-11 Bazar providers (the sync layer)

- `presentation/bazar_providers.dart`: `currentDateKeyProvider`, `selectedMonthProvider`
  (`next/previous/set/reset`), `monthLockedProvider(month)`.
- `expenses/presentation/expense_providers.dart`: `monthExpensesProvider` (one auto-dispose listener per
  month; current month kept alive), `monthSpendProvider`, `expenseFiltersProvider`,
  `filteredExpensesProvider` (rows, by-day groups, total that never counts deleted rows),
  `expenseRevisionsProvider`, `canEditExpenseProvider`, and one provider per use case.
- `fund/presentation/fund_providers.dart`: `monthClosingsProvider`, `monthClosingMapProvider`,
  `fundWindowStartProvider`, `fundTransactionsProvider`, `fundSummaryProvider`, `fundBalanceProvider`,
  `fundWindowOverflowProvider`.
- `advances/presentation/advance_providers.dart` + `advances/domain/advance_summary.dart`:
  `openAdvancesProvider` (narrowed to own uid without `recordContribution`), `advanceSummaryProvider`.
- Test: `test/features/bazar/presentation/bazar_providers_test.dart` (month switching, deleted rows,
  disposal, filters, lock, fund window moving after a close, advances visibility, edit permission).

## Phase 2 - P2-12 Shared widgets and gallery entries

- New in `lib/shared/widgets/`: `MonthSwitcher` (+ month picker sheet), `AmountField` (+
  `AmountInputFormatter`: Bangla/English digits, one point, max `scale` decimals), `TotalDisplay`,
  `ProgressBarStatus` (+ `ProgressLevel`), `DaySectionHeader`, `PersonPicker` (+ `PersonOption`),
  `CategoryBadge`.
- `AppFormatters.monthLabel(MonthKey)`.
- Gallery: `lib/app/gallery/gallery_sections_p2.dart` (spread into `gallerySections()`), so goldens and
  the 200 % overflow test cover all seven automatically.
- 20 new ARB keys (bn + en) added by hand to the three generated files too.
- Tests: `test/shared/widgets/p2_widgets_test.dart`, `monthLabel` cases in `app_formatters_test.dart`.

### Status of this batch: written, NOT compiled or run
No Flutter/Dart SDK, Java or emulator was available (downloads blocked). Run first:
`flutter pub get`, `dart format .`, `flutter gen-l10n` (must give no diff vs the hand-edited files),
`flutter analyze`, `flutter test --exclude-tags golden`, then the rules suite and
`node tools/check_indexes.mjs` (already passes), then the *Update goldens* workflow (7 new sections).

## Status of every step

"Written" = code and tests exist but were not compiled or run by the author. "Verified" is only claimed where a run produced evidence; today that is none, so every row needs the evidence run.

| Step | Scope | Status | Evidence / notes |
| --- | --- | --- | --- |
| 1 | Scaffold, flavors, lints, CI | Written | `.github/workflows/ci.yml` |
| 2 | Core value objects | Written | `test/core/utils/` |
| 3 | Theme tokens, registry, builder | Written | `test/app/theme/` (contrast, raw colour) |
| 4 | Theme controller + settings | Written; tests/goldens added in H11 | `test/features/settings/` |
| 5 | Localization, fonts, formatting | Written | `test/core/localization/` |
| 6 | Firebase setup, bootstrap | Written; config manual (H2) | `firebase/README.md` |
| 7 | Authentication | Written | `test/features/auth/` |
| 8 | Router, guards, shell, modules | Written | `test/app/` |
| 9 | Profile, family, invitations, approval | Written | `test/features/family/`, `onboarding/` |
| 10 | Permissions + rules v1 | Written; rules v2 in H4-H7, H9-H10 | `firebase/rules_test/` |
| 11 | Shared widgets + gallery | Written | `test/shared/widgets/` |
| H1 | Green baseline, goldens policy | Written | ADR 0004, 0005 |
| H2 | Config, indexes, release signing | Written | `docs/RELEASE.md` |
| H3 | Offline semantics | Written | `test/core/firebase/` |
| H4 | Membership lifecycle | Written | `docs/membership_state_machine.md` |
| H5 | Rules validation, verified email | Written | rules tests `H5 *` |
| H6 | Admin set invariant | Written | rules tests `H6 *` |
| H7 | Permission providers, configurable cells | Written | `docs/permission_matrix.md` |
| H8 | Clean architecture, audit writer | Written | `test/architecture/` |
| H9 | Account lifecycle | Written | `test/features/settings/`, rules `H9 *` |
| H10 | Data consistency, relationships | Written | `test/features/family/domain/relationship_catalog_test.dart` |
| H11 | UI conformance, accessibility | Written | `test/support/screen_states.dart` |
| H12 | Phase 2 foundations | Written | `docs/new_collection_checklist.md` |
| H13 | Sign-off tooling and review | Written; **not executed** | `docs/phase1_*.md` |
| P2-01 | Preflight gate, Bazar skeleton, seams | Done; rules suite and APK unverified | `docs/PHASE2_BAZAR_ROADMAP.md`, `lib/features/bazar/` |
| P2-02 | Pure helpers: money math, units, date ranges | Done | `lib/core/utils/money_math.dart`, `unit_catalog.dart`, `date_ranges.dart` |
| P2-03 | Vocabulary: audit types, paths, permissions, ARB | Done; rules suite unverified | `lib/core/audit/`, `docs/permission_matrix.md`, `firebase/firestore.rules` |
| P2-04 | Catalog domain + `ItemSearch` | Done | `lib/features/bazar/items_categories/domain/`, `test/features/bazar/` |
| P2-05 | Catalog data layer, rules and providers | Done; rules suite unverified | `lib/features/bazar/items_categories/data/`, `presentation/catalog_providers.dart`, `firebase/firestore.rules`, `firebase/rules_test/catalog.test.mjs` |
| P2-06 | Default catalog seed and backfill | Done; rules suite and APK unverified | `default_catalog.dart`, `default_catalog_writes.dart`, `default_catalog_seeder.dart`, `ensure_catalog_seeded.dart`, `bazar_home_screen.dart`, `firebase/rules_test/fixtures/create_family_catalog.json` |
| P2-07 | Bazar settings domain/data/rules/providers | Done; rules suite and APK unverified | `lib/features/bazar/settings/`, `bazar_settings_providers.dart`, `firebase/firestore.rules`, `firebase/rules_test/bazar_settings.test.mjs`, `settings_bazar.json` |
| P2-08 | Fund ledger and month-closing domain | Done | `lib/features/bazar/fund/domain/`, `lib/features/bazar/advances/domain/`, `test/features/bazar/fund/`, `test/features/bazar/advances/` |
| P2-09 | Expense domain, use cases and in-memory backend | Done | `lib/features/bazar/expenses/domain/`, `test/features/bazar/expenses/`, `test/support/in_memory_bazar_backend.dart` |
| P2-10 | Expense/fund/advance data layer, rules, indexes | Done (audited; 2 fixes); rules suite unverified | `lib/features/bazar/*/data/`, `firebase/rules_test/{expenses,fund,advances}.test.mjs` |
| P2-11 | Bazar providers (sync layer) | Written, not run | `lib/features/bazar/**/presentation/*_providers.dart`, `test/features/bazar/presentation/bazar_providers_test.dart` |
| P2-12 | Shared widgets + gallery | Written, not run | `lib/shared/widgets/` (7 new), `lib/app/gallery/gallery_sections_p2.dart` |
| P2-13 | Add/Edit Expense screen | Written, not run | `expenses/presentation/{controllers,screens/add_expense_screen.dart,widgets}`, `expenses/domain/amount_input.dart`, `test/features/bazar/expenses/presentation/` |
| P2-14 | Bazar Trip screen | Written, not run | `controllers/trip_form_controller.dart`, `screens/bazar_trip_screen.dart`, `widgets/trip_line_sheet.dart`, `trip_line_tile.dart` |
| P2-15 | Expense list, detail, edit, delete/undo, history | Written, not run | `screens/expense_{list,detail}_screen.dart`, `expense_detail_providers.dart`, `widgets/expense_{row,filter_sheet,ledger_line,history_section,delete_flow}.dart`, `domain/expense_list_items.dart` |
| P2-16 | Catalog manager + Bazar settings screens | Written, not run | `items_categories/presentation/{screens,widgets,controllers}`, `domain/usecases/{reactivate_category,reactivate_item,reorder_categories}.dart`, `settings/presentation/screens/bazar_settings_screen.dart` |
| P2-17 | Budgets: domain, data, rules | Written, not run | `lib/features/bazar/budgets/{domain,data}`, `firebase/firestore.rules` (`budgetKeys`, `budgetOk`, `match /budgets/{b}`), `firebase/rules_test/budgets.test.mjs`, `fixtures/budget.json` (hand-written, regenerate), `test/features/bazar/budgets/` |
| P2-18 | Budget screen and alerts provider | Written, not run | `budgets/presentation/{budget_providers,controllers/budget_controller,screens/budget_screen,widgets/*}.dart`, route `/bazar/budget`, Bazar home tile |
| P2-19 | Contributions: domain, data, rules | Written, not run | `lib/features/bazar/contributions/{domain,data,presentation/contribution_providers.dart}`, `firebase/firestore.rules` (`contributionKeys`, `contributionPlanKeys`, `contributionOk`, `contributionCreateOk`, `contributionUpdateOk`, `match /contributions`, `match /contributionPlans`), `firebase/rules_test/contributions.test.mjs`, `test/features/bazar/contributions/`, contract fixtures (generated, see below) |

## Phase 2 - P2-13..P2-16 Expense screens, trip, list/detail, catalog manager, settings

Verification before building: P2-01..P2-12 were checked by reading (providers, use cases, shared widgets, ARB, tests helpers) against the code in the upload; nothing was compiled.  Expect a first `dart format` / `flutter analyze` / `flutter test` round.

**What was built**
- P2-13: `AddExpenseScreen` (add and edit) on `expenseFormProvider(ExpenseFormArgs)`; pure `readAmountInput` (domain) shared with the trip line sheet; `ItemAutocompleteField` (inline results, "add as new item" row), `AmountBlock`, `FundingSelector`, `ExpenseMoreSection`, `DateChipField`, duplicate sheet.  Bazar home FAB and four entries (Add expense, Trip, Expenses, Catalog, Settings).
- P2-14: `BazarTripScreen` on `tripFormProvider`; line sheet; swipe or button remove with Undo; 40-line cap (`kMaxTripLines`).
- P2-15: list (month switcher, filter sheet, day groups via pure `buildExpenseListItems`, 30 rows per page, "show more"), detail (ledger line from `expenseAdvanceProvider`, history for people who may edit), delete with Undo (`confirmAndDeleteExpense`), Restore button for managers.
- P2-16: catalog manager (tabs, reorder, edit sheets), `BazarSettingsScreen`.

**Assumptions / deviations**
- Three use cases were missing for the P2-16 card and were added: `ReactivateCategory`, `ReactivateItem`, `ReorderCategories` (audited as category/item *updated*; no rules change).  Reorder writes only the rows whose position changed, one batch each, so a failure part-way leaves a valid, partly re-ordered list.
- The form controller keeps `saving` and `failure` in its own state (not `newActionProvider`) because a save also returns "duplicate warning" and per-field errors.  The catalog sheets and settings use `newActionProvider`.
- On a successful save the form stays "busy" until the screen closes, so a second tap cannot repeat the write.
- Form default for "Remember this item" is OFF (a typo should not create a catalog item).  Edit mode prefills a row that has quantity and unit price with an EMPTY total; the total is recalculated on save like `computeTotal`.
- A custom range that leaves the selected month is read with `rangeExpensesProvider` (`queryRange` + `startAfter`, not live, Refresh button).  Inside the month, filters run on the live month list.
- Detail screen reads the expense once (`getExpense`) and follows the live month list; it re-reads after an edit returns.
- Settings screen edits exactly two thresholds (warn, exceeded).  A stored list with more than two values is replaced by those two on save.
- Added `bazarErrExpenseDeleted` (maps `Conflict('expense_deleted')`) and 132 other ARB keys, written to both ARBs and the three generated files by hand.  Long generated lines are not wrapped the way gen-l10n would; `flutter gen-l10n` may show a whitespace-only diff - keep gen-l10n's output.
- `lib/app/routing/app_routes.dart` gained `bazarSettings`.

**Not done / to check by hand**
- Goldens and the 200 % text-scale overflow tests for the new screens (listed by the cards) are not written; add them with the first green run.
- No test for the filter sheet, catalog manager or settings screen widgets yet (use cases and controllers are covered).
- Checking order on a device: Bangla keyboard digits in `AmountField`, the inline suggestion list with the soft keyboard open, drag-reorder on Android.

## Phase 2 - P2-17 and P2-18 Budgets (domain, data, rules, screen, alerts)

Written without an SDK or emulator; **nothing was compiled or run**. Run first: `flutter pub get`, `dart format .`, `flutter gen-l10n` (keep its output if it differs only in whitespace), `flutter analyze`, `flutter test --exclude-tags golden`, then `flutter test test/contract/rules_fixtures_test.dart` (regenerates `fixtures/budget.json`; `git diff` must show no change, else keep the generated file), the rules suite and `node tools/check_indexes.mjs` (no index change). Then the *Update goldens* workflow if you add goldens (none were added).

**P2-17 built**
- Domain (pure): `Budget`, `BudgetLine` (`lineEstimate` = quantity x rate half-up, else typed total), `BudgetLevel`, `CategoryBudgetStatus`, `BudgetStatusReport`, `ComputeBudgetStatus`, `BudgetAlert` + `buildBudgetAlerts`, `prepareBudget` / `validateAlertThresholds`, `BudgetRepository`, `SaveBudget`, `CopyLastMonthBudget`, plus `BudgetLineDraft` / `readLineDrafts` / `readCategoryTexts` for the editor.
- Data: `BudgetMappers` (tolerant reads), `FirestoreBudgetRepository` (one batch with `AuditWriter`, no probe, so it queues offline), wired in `bootstrap.dart`.
- Rules: `budgetKeys()`, `budgetOk(d, id)`, `match /budgets/{b}` (read active members; create/update `verified() && financeManager(f)`; no delete). Rules tests, contract fixture + seeder, key-set mirror test; `budgets` moved from `pending` to `implemented` in `paths_match_rules_test`.
- Providers: `budgetRepositoryProvider`, `monthBudgetProvider`, `saveBudgetProvider`, `copyLastMonthBudgetProvider`.

**P2-18 built**
- `budgetStatusProvider(month)`, `budgetAlertsProvider` (current month, worst first).
- `BudgetScreen` (`/bazar/budget`): `MonthSwitcher`, whole-month bar, per-category bars (`CategoryBadge` + `ProgressBarStatus`), dry-grocery summary, edit mode (`BudgetEditorForm` + `DryGroceryTableEditor`), empty state with "Plan this month" and "Copy last month", read-only banner for people without `manageCatalogAndBudgets`, the "a budget is a plan" note.
- `BudgetController` (`budgetControllerProvider(month)`, auto-dispose family): holds text drafts, reads them only through the domain readers, saves once; a failed save keeps the draft and the event id.
- 29 ARB keys (`budget*`) in bn + en + the three generated files by hand; `bazarFailureMessage` maps `Conflict('budget_exists')`.

**Assumptions / deviations**
- Alert levels come from the live `settings/bazar.alertThresholds`; the thresholds stored in the budget are a snapshot (copied when the budget is saved or copied), so changing the setting re-levels every month at once.
- `Budget` carries optional `createdAt`/`createdBy` (not part of equality) so a re-save keeps the original author without reading first. Rules do not freeze `createdBy` on update: a forced rejection of a queued offline write would be silent.
- A budget is a plan: a closed month does NOT block saving it (the card names no lock; rule 31 is about dated records).
- Level comparison is exact integer (`spent*100 >= limit*percent`), so 79.99 % stays `ok`; the bar's percent uses `basisPoints` (rounded). With one threshold `t`: warning at `t`, exceeded at 100 (at `t` when `t >= 100`).
- Rules cannot check money inside the `categoryEstimates` map or `lines`; only sizes (40 / 150 / 4) and `totalEstimatePaisa`. The app skips malformed entries when reading.
- `NotFound('budget')` from "Copy last month" is shown with a specific message in the screen (the generic `bazarFailureMessage` text stays generic).
- Dry-grocery rows use a plain name field (no `ItemAutocompleteField`) and keep `itemId` null for new rows.
- `contract/budget.json` was written by hand to match `JsonEncoder.withIndent`; regenerate it with the Dart test to be sure.
- The Dry-groceries category id is `cat_dry_groceries` (seed key `dry_groceries`).
- Not done: goldens for the budget screen, a Bazar-home alert strip (P2-29 consumes `budgetAlertsProvider`), per-category thresholds.

## Phase 2 - P2-19 Contributions (domain, data, rules, providers)

Written without an SDK or emulator; **nothing was compiled or run**. Run first: `flutter pub get`, `dart format .`, `flutter analyze`, `flutter test --exclude-tags golden`, then `flutter test test/contract/rules_fixtures_test.dart` (it WRITES the three new fixtures `contribution_request.json`, `contribution_recorded.json`, `contribution_plan.json`; they were not hand-written this time, so keep the generated files and commit them), the rules suite and `node tools/check_indexes.mjs` (no index change: both queries are equality-only).

**Verified before building:** CLAUDE.md, the P2-19 card, the rules (`fundTxOk` already allows `con_`/`adj_` contribution rows, `monthOpen`, `financeManager`), `AuditEventType`/`AuditRefType` (all contribution types already existed), `Permission.requestContribution`, `FundTransaction` factories, `BazarSettings`. Nothing from earlier steps had to be changed except `paths_match_rules_test.dart` (the two collections moved from `pending` to `implemented`), `bootstrap.dart` (one repository) and the three contract test files.

**Built**
- Domain (pure): `Contribution`, `ContributionChange`, `ContributionPlan`, enums; `ContributionStatusCalculator` (expected / received / remaining / credit / `pendingTotal`); `generateEqualSplit` (D-P2-11); write plans; `ContributionRepository`; shared `contribution_guards.dart`.
- 13 use cases: `RecordContribution` (manager, approved + `con_` row), `RequestContribution` (member, pending, no ledger row), `EditPendingContribution`, `CancelContributionRequest`, `ApproveContribution`, `RejectContribution`, `RequestContributionChange`, `ApproveContributionChange`, `RejectContributionChange`, `VoidContribution`, `SetContributionPlan`, `GenerateMonthPlans`, `RecordOpeningBalance`.
- Data: `ContributionMappers`, `ContributionWriteStager`, `FirestoreContributionRepository` (everyday writes queue offline; approve/reject/change decisions, void and opening balance probe the server; the decision use cases read the contribution fresh from the server).
- Rules: closed key sets, `contributionOk`, one `contributionUpdateOk` listing each allowed transition by its exact changed keys; approve and record require the matching `con_<id>` row in the same batch (`existsAfter`/`getAfter`, amount and date compared); every write needs an open month; no delete. `contributionPlans`: managers write, everyone reads, id must be `<yyyy-MM>_<memberId>`.
- Providers: `contributionPlansProvider(month)`, `contributionsProvider(month)` (one listener each, no role filter), `contributionStatusProvider`, `pendingContributionsProvider`, `myContributionsProvider`, `activeMemberIdsProvider`, one provider per use case. Repository wired in `bootstrap.dart`.
- Tests: `contribution_domain_test`, `contribution_usecases_test` (incl. a scripted month), `contribution_mappers_test`, `contributions.test.mjs` (allowed + denied per rule), key-set mirror tests, contract fixtures.

**Assumptions / deviations from the card (please review)**
1. **Opening balance permission.** The card says only "permission". The P2-10 rules (and their test "denies a moderator writing an opening row") let only an ADMIN write an `opening` row, so `RecordOpeningBalance` requires `Permission.editFamilySettings` (admin). **P2-21 (`CloseMonth`) will hit the same mismatch**: `closeBazarMonth` allows a Household Manager but the carry-forward `opening` row is admin-only in the rules. Decide there: either relax `fundTxOk` for `opening` to `financeManager(f)` (and update that test) or make close admin-only.
2. `settings.monthlyTarget` in the card is `BazarSettings.defaultMonthlyContribution` in code; it is treated as the FAMILY's monthly total, split equally (D-P2-11). The split is computed over all active members, but only members WITHOUT a plan get one written.
3. The card's "৳5,000 / 3 = 1,667.00 / 1,667.00 / 1,666.00" is rounded; the exact paisa split is 166,667 / 166,667 / 166,666 (the test uses this).
4. `Contribution` also carries `createdAt` (needed to re-write the whole document without a read). A changed contribution is written as a full `set`, so removing `pendingChange` is a real removal.
5. The owner edit rule also allows `monthKey` to change (an edit of the date can cross a month); both the old and the new month must be open.
6. `ApproveContributionChange`: same month = ONE row `adj_<eventId>` of `new - old` (none when equal); date moved into another month = `adj_<eventId>_out` (`-old`, old date) + `adj_<eventId>_in` (`+new`, new date), so each month's rows still add up. The rules do not check the adjustment rows of a change approval (they cannot know the delta of the old document); the use case and its tests do.
7. `VoidContribution` also drops a stale `pendingChange`; the compensating row keeps the contribution's own date. `CancelContributionRequest` and `RejectContributionChange` follow the same month-lock rule as every other write (rules need an open month).
8. `RecordContribution` (manager) also refuses a future date and a non-active target member (the rules check the member document too).
9. Reject reasons, change reasons and old/new amounts go into audit `params` as machine values, never display text.
10. A second approval from stale state is stopped three ways: fresh server read + probe, `resource.status == pending` in the rules, and the `con_<id>` row cannot be written twice (ledger rows are create-only).
11. New `Conflict` codes (`contribution_not_pending`, `contribution_not_approved`, `change_already_pending`, `no_pending_change`, `already_voided`, `fund_already_started`) fall back to the generic message in `bazarFailureMessage`; their ARB strings come with the screens in P2-22 (no ARB or generated l10n file was touched here).

**Not done:** screens, ARB strings (P2-22), `ledger_integrity` use of the new rows, goldens.

## Known limitations (honest list)

- Nothing has been compiled or run by the author; expect a first round of `flutter analyze` / format / test fixes.
- Generated l10n files were edited by hand; `flutter gen-l10n` must produce identical output.
- Spark plan: no push notifications (a recipient learns of a request when the app opens), no server-trusted data, no App Check.
- Offline "waiting to sync" is detected by pending writes older than 10 s, not by a connectivity listener.
- F-31: `users/{uid}` lacks a closed key set (low).
- Custom relationship entries have per-item shape checks only in the app, not in the rules (rules bound the list to 40 items).
- Screen-state harness covers 4 screens so far.
- `firestore_family_repository.dart` exceeds 300 lines (allow-listed).
- P2-01..P2-16 exist in code; P2-11..P2-16 and the audit fixes are unverified (no SDK). P2-17/P2-18 (budgets) and P2-19 (contributions) are written and unverified too. Next: P2-20 (Advances & settlements) and P2-22 (fund screens).
- Phase 2 has its P2-01 skeleton (Bazar home + seams), P2-02 pure helpers, P2-03 vocabulary,
  P2-04 catalog domain/search, P2-05 catalog data/rules/providers, P2-06 default seed/backfill,
  P2-07 settings domain/data/rules/providers, P2-08 fund/advance domain and P2-09 expense
  domain/use cases; the Bazar/Chores/Dashboard features and UI are not implemented yet. The
  P2-05/P2-06/P2-07 rules suite has not been run (no Java).
