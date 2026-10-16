# Family Hub — Step-by-Step Build Prompts (Flutter)

Built from `Family_Hub_Project_Roadmap_v2.md`. Work top to bottom: **one step = one prompt = one Git commit.**

## How to use this playbook

- Use an AI coding tool that can see your repo (Claude Code, Cursor, or similar). Paste the **Master Context Prompt** (Part 2) once and save it as `CLAUDE.md` in the project root, so every later prompt inherits it.
- Run the steps in order. Every step has a **Done when** check. Do not move on until `flutter analyze` is clean, `flutter test` passes, and the app runs on an emulator.
- Review every diff. The AI writes the code; you make the decisions.
- Package versions change. Each step that adds packages tells the AI to check pub.dev for current stable versions.
- The roadmap marks `[VERIFY]` items (Firebase Storage on Spark, quotas, WhatsApp). Never let the AI assume these.
- Two files must be re-attached before their steps: `Bazar.xlsx` (Step 19) and `family_chores.pdf` (Step 20).
- If a step goes wrong, use the reusable prompts at the end instead of starting over.

---

## Part 1 — Architecture (settle this before any code)

### 1.1 Style: feature-first Clean Architecture

Each feature owns three layers. Dependencies point inward only.

| Layer | Contains | May import | Must never import |
| --- | --- | --- | --- |
| presentation | screens, widgets, Riverpod controllers | domain, shared, core | data, firebase packages |
| domain | entities, value objects, repository interfaces, use cases, pure rules | Dart core, freezed, core value objects | flutter, firebase, any I/O |
| data | repository implementations, Firestore DTOs and mappers | domain, firebase packages | presentation |

**Why:** the roadmap needs rotation, fund balance, subtask sync and scoring to be pure, unit-tested Dart, and needs future AI features to call the same use cases as the UI (roadmap Sections 11 and 16).

### 1.2 Patterns to use

| Pattern | Where | Why |
| --- | --- | --- |
| Repository (interface in domain, implementation in data) | every feature | UI and rules never know about Firestore; easy to fake in tests |
| Use case (one class per business action: `AddExpense`, `SwapChore`) | domain | permission check + rules + audit in one place; AI features reuse it later |
| DTO and mapper | data | Firestore maps never leak into entities; handles `schemaVersion` |
| Riverpod `AsyncNotifier` controllers | presentation | one controller per screen; loading/error/data states for free |
| Immutable models with `freezed` | domain | equality, `copyWith`, safe state |
| `Result<T>` plus sealed `AppFailure` | use cases | no thrown exceptions crossing layers; UI maps failures to localized text |
| Value objects: `Money`, `Quantity`, `DateKey`, `MonthKey` | core | integer paisa, milli-units, family-timezone dates (roadmap 12.1) |
| `Clock` abstraction | core | deterministic tests for rotation, month boundaries, reminders |
| Policy objects (`PermissionPolicy`) | core/permissions | one permission matrix used by UI, use cases and tests |
| Strategy | rotation engine, recurrence rules | daily / weekly / monthly / N-day behave the same way behind one interface |
| Registry | themes, modules | new theme or module = add one entry, no screen changes |
| Unit of work (`TxRunner` wrapping Firestore batch/transaction) | core/firebase | expense + fund transaction + advance are written atomically (roadmap 12.5) |

### 1.3 Rules the AI must obey

1. `domain/` has zero imports of `flutter` or `firebase`.
2. Screens never call Firestore. Screen → controller → use case → repository interface.
3. All writes go through use cases. No repository write is called directly from UI.
4. Money is integer paisa, quantity is integer milli-units. Never `double`.
5. Dates: store UTC timestamp plus `dateKey` and `monthKey` in the family timezone (default `Asia/Dhaka`).
6. No raw colors outside `lib/app/theme/`. No hard-coded user-visible strings.
7. Every query is bounded by a `monthKey`/`dateKey` range and a `limit`.
8. Every permission is enforced in Firestore Security Rules as well as the UI.
9. Files stay small: a widget file over about 300 lines gets split; one class per use case file.
10. Naming: `snake_case` files, `FooRepository` (interface), `FirestoreFooRepository` (implementation), `FooController`, `FooScreen`, `FooMapper`, `AddFooUseCase`.

### 1.4 Folder structure

```text
lib/
├── main_dev.dart · main_prod.dart
├── app/
│   ├── app.dart · router.dart · bootstrap.dart · flavor.dart
│   └── theme/ app_tokens · theme_registry · theme_builder · theme_controller · themes/
├── core/
│   ├── errors/ (result.dart, app_failure.dart)
│   ├── utils/ (money, quantity, date_key, clock, bangla_numerals)
│   ├── firebase/ (tx_runner, firestore_paths, base_mapper)
│   ├── localization/ · notifications/ · permissions/ · constants/
├── shared/
│   ├── widgets/ (AppAvatar, ItemThumb, StatusChip, EmptyState, MoneyText …)
│   └── services/ (audit, activity, image)
├── modules/ (family_module.dart, module_registry.dart)
└── features/
    ├── auth/ · onboarding/ · family/ · dashboard/ · settings/ · notifications/
    ├── bazar/ { expenses, items_categories, budgets, contributions, advances, reports, import }
    └── chores/ { templates, duty_groups, occurrences, calendar, swaps, availability, comments, achievements }
        (each feature: data/ · domain/ · presentation/)
test/            mirrors lib/
firebase/        firestore.rules · firestore.indexes.json · rules_test/ (emulator tests)
```

### 1.5 Defaults for open decisions (so building is never blocked)

These are placeholders from roadmap Section 20. Change them later; each is cheap to change.

| Decision | Default while building |
| --- | --- |
| Accent color | Teal, as a single token |
| Verification | Off by default; on for deep-cleaning templates |
| Absence policy | A — ask for cover |
| Member report visibility | Members see only their own contributions |
| Contribution rule | Equal split, due day configurable in settings |
| Onion and potato | Items under Vegetables |
| Scoring | Client-side (Spark) |
| Hub Level visual | Plant |
| Platform | Android only for release 1 |
| Plan | Spark only until Phase 6 |

---

## Part 2 — Master Context Prompt (paste once, save as CLAUDE.md)

```text
You are a senior Flutter engineer building 'Family Hub', a Bangla-first household app (bazar and family finance + family chores) for one family. Android first, iOS-ready. Backend: Firebase Auth + Cloud Firestore on the free Spark plan. No Cloud Functions, and no hard dependency on Cloud Storage.

ARCHITECTURE: feature-first Clean Architecture. Each feature has data/, domain/, presentation/. domain is pure Dart (no flutter or firebase imports). presentation never touches Firestore: screen -> Riverpod controller -> use case -> repository interface. data implements repositories and maps Firestore documents to domain entities through mappers.

HARD RULES
1. Money is integer paisa in a Money value object. Quantities are integer milli-units. Never double.
2. Time-based records store a UTC Timestamp plus dateKey (yyyy-MM-dd) and monthKey (yyyy-MM) computed in the family timezone (default Asia/Dhaka). Use an injected Clock; never call DateTime.now() in domain code.
3. All writes go through use cases. A use case checks permission (PermissionPolicy), applies business rules, writes through a repository, and writes audit and activity entries in the same batch/transaction where required.
4. Deterministic IDs: occurrences {templateId}_{yyyyMMdd}; budgets {yyyy-MM}; contribution plans {yyyy-MM}_{memberId}.
5. Soft delete only (deletedAt, deletedBy). Every document has createdAt, createdBy, updatedAt, updatedBy, schemaVersion.
6. No raw Color(0x...) or hex outside lib/app/theme/. Screens read tokens via context.tokens.
7. No hard-coded user-visible strings. Use ARB localization (bn default, en). Test long Bangla strings for overflow.
8. Riverpod (Notifier/AsyncNotifier), freezed immutable models, go_router with auth and family guards.
9. Use cases return Result<T> with a sealed AppFailure. UI maps failures to localized messages. No silent catches.
10. Business rules live in domain with unit tests. Every screen handles loading, empty, error and offline states.
11. Queries are bounded by a monthKey/dateKey range and a limit. One listener per screen; cancel on dispose.
12. Every permission is enforced in Firestore Security Rules as well as the UI.
13. Accessibility: touch targets >= 48dp, status never by color alone (icon + label + color), text scales with system font size.

WORKING METHOD: before coding, list the files you will create or change. Write tests together with the code. Afterwards run dart format, flutter analyze and flutter test and report the results. Do not add packages I did not name without asking. When something depends on current Firebase pricing, quotas, or package versions, check the official docs instead of guessing. If an instruction is ambiguous, state your assumption and continue; ask only when a wrong guess would be expensive. End every task with: files changed, how to verify, anything you assumed.

DEFAULT DECISIONS (until I change them): teal accent token; chore verification off by default; absence policy A (ask for cover); members see only their own contributions; equal-split contributions; onion and potato are items under Vegetables; client-side scoring; Hub Level shown as a plant; Android only; Spark plan only.
```

---

## Part 3 — Phase 1: Foundation

### Step 1 — Project scaffold, flavors, lints, CI

**Goal:** an empty but correctly structured app that builds in `dev` and `prod`.

```text
Create a new Flutter project named family_hub (org: com.familyhub), Android first, iOS-ready, on the current stable Flutter. Check pub.dev and pin current stable versions of every package below.

1. Dependencies: flutter_riverpod, riverpod_annotation, go_router, freezed_annotation, json_annotation, intl, shared_preferences, timezone, flutter_timezone, characters. Add flutter_localizations from the SDK. Dev dependencies: build_runner, freezed, json_serializable, riverpod_generator, flutter_lints, mocktail.
2. Create the exact folder structure from CLAUDE.md (section 1.4) with .gitkeep files where empty.
3. Flavors: Android productFlavors dev and prod (applicationIdSuffix .dev for dev, app label 'Family Hub (dev)' vs 'Family Hub'). Create lib/main_dev.dart and lib/main_prod.dart; both call bootstrap(Flavor.dev|prod) in lib/app/bootstrap.dart, which runs runApp inside a ProviderScope with error zone handling that logs uncaught errors.
4. analysis_options.yaml: include flutter_lints; enable strict-casts, strict-inference, strict-raw-types; add rules always_use_package_imports, avoid_print, prefer_const_constructors, prefer_final_locals, require_trailing_commas, unawaited_futures.
5. A placeholder MaterialApp showing the flavor name, so I can confirm flavors work.
6. README with exact commands: run dev, run prod, run build_runner, run tests, build APK.
7. .github/workflows/ci.yml running on push and pull request: flutter pub get, dart format --set-exit-if-changed, flutter analyze, flutter test, flutter build apk --flavor dev -t lib/main_dev.dart.
Do NOT add Firebase yet.
```

**Done when:** `flutter run --flavor dev -t lib/main_dev.dart` shows the flavor name; `flutter analyze` has zero issues; the CI file is valid.

### Step 2 — Core value objects and utilities (test-first)

**Goal:** the money, quantity, date and error types every later step depends on.

```text
Implement lib/core/ utilities test-first (write the tests, then the code).

1. core/utils/money.dart: immutable Money wrapping an int paisa. Constructors: Money.paisa(int), Money.zero, Money.parse(String) accepting English or Bangla digits, optional taka symbol and commas ('৳১,২৫০.৫০', '12.5', '১২'). Parse with integer/decimal-string logic only; never via double. Operators +, -, unary -, * (int), comparison, isNegative, sum helper. Rejects more than 2 decimal places with a typed failure. MoneyFormatter formats at the edge for a locale: bn gives '৳১২.৫০', en gives '৳12.50'; option to hide '.00'.
2. core/utils/quantity.dart: Quantity in integer milli-units plus a Unit enum (kg, g, litre, piece, dozen, packet, cylinder). Quantity.parse('2.5') = 2500. Helper: lineTotal(Quantity, Money unitPrice) -> Money with explicit half-up rounding to the paisa, documented in a comment.
3. core/utils/date_key.dart: DateKey and MonthKey value objects ('2026-10-14', '2026-10'). Create from a UTC instant plus a timezone name using the timezone package (default Asia/Dhaka). Helpers: addDays, startOfMonth, endOfMonth, monthRange(MonthKey) for Firestore range queries, isLeapYear-safe.
4. core/utils/clock.dart: abstract Clock { DateTime nowUtc(); }, SystemClock, FakeClock (settable/advanceable). A clockProvider in Riverpod.
5. core/utils/bangla_numerals.dart: toBanglaDigits, toEnglishDigits.
6. core/errors/result.dart: sealed Result<T> with Success and Failure, plus map/flatMap/when helpers. core/errors/app_failure.dart: sealed AppFailure with PermissionDenied, NotFound, Validation(field, code), Conflict, Network, Unknown(cause).

Tests must include: 1250 paisa formats as ৳12.50; parse of '১২.৫' = 1250; 2.5 kg x ৳80/kg = ৳200; rounding edge cases; 2026-10-14T19:00Z becomes dateKey 2026-10-15 in Asia/Dhaka (UTC+6); month boundary (31 Oct to 1 Nov); leap day 2028-02-29; monthRange of February in a leap and a non-leap year.
```

**Done when:** all tests pass and no `double` appears in `money.dart` or `quantity.dart`.

### Step 3 — Theme tokens, registry and builder

**Goal:** the extensible theme system from roadmap Section 9; a third theme later is one file.

```text
Implement roadmap Section 9 in lib/app/theme/.

1. app_tokens.dart: ThemeExtension<AppTokens> (immutable, copyWith, lerp) with groups: surfaces (background, surface, surfaceRaised, surfaceSunken, scrim); text (textPrimary, textSecondary, textDisabled, textOnAccent); brand (accent, accentSoft, accentStrong); status for scheduled, inProgress, completed, verified, overdue (each with color, container, onColor); feedback (success, warning, danger, info); lines (divider, outline, focusRing); data viz (chart[0..9], chartGrid); placeholderPalette[0..11]; shape (radiusSm 8, radiusMd 16, radiusLg 24, radiusPill 999, elevation1..3 as BoxShadow lists); motion (durationFast 120ms, durationMedium 240ms, durationSlow 400ms, curveStandard); optional nullable backgroundGradient.
2. themes/modern_light.dart: warm neutral background (not pure white), white cards, soft shadows, teal accent. themes/modern_dark.dart: HAND-TUNED dark neutral (not pure black, not an inverted light theme); raised surfaces get lighter as they elevate; slightly desaturated accent.
3. theme_registry.dart: class AppThemeSpec { id, labelBn, labelEn, brightness, tokens, available } and the list appThemes = [modernLight, modernDark]. themeById(id) falls back to modern_light for unknown ids.
4. theme_builder.dart: buildThemeData(AppThemeSpec) returns a Material 3 ThemeData with ColorScheme derived from tokens, a TextTheme (placeholder font for now), and component themes for Card, InputDecoration, Chip, NavigationBar, Dialog, BottomSheet, FilledButton, OutlinedButton, TextButton, SnackBar, DatePicker. Register AppTokens as a ThemeExtension. Add an extension getter context.tokens.
5. test/app/theme/contrast_test.dart: compute WCAG contrast ratios and loop over EVERY available theme in appThemes so future themes are checked automatically: textPrimary and textSecondary on background, surface, surfaceRaised >= 4.5; textOnAccent on accent >= 4.5; each status onColor on its container >= 4.5; icon/status colors on surface >= 3.
6. A test that scans lib/ and fails if 'Color(0x' appears outside lib/app/theme/.
7. A temporary debug route /dev/tokens that shows every token as a labeled swatch.
```

**Done when:** contrast and no-raw-color tests pass; `/dev/tokens` looks correct in both themes.

### Step 4 — Theme controller and Settings → Theme screen

**Goal:** switch theme instantly, remember it, and keep the picker future-proof.

```text
Implement lib/app/theme/theme_controller.dart and the theme settings screen.

1. ThemePrefs { themeMode: system|light|dark, themeId }. A Riverpod Notifier ThemeController with setThemeId and setThemeMode. Override a sharedPreferencesProvider in bootstrap so preferences are read BEFORE the first frame (no flash of the wrong theme).
2. Define interface ThemePreferenceSync { Future<void> push(ThemePrefs); Stream<ThemePrefs?> watch(); } with a no-op implementation now. The Firestore implementation is added in Step 9 (users/{uid}.preferences).
3. app.dart uses MaterialApp.router with theme and darkTheme built from the registry. When 'Follow device' is on, use the first available light spec for light and the first available dark spec for dark; otherwise use the chosen themeId.
4. Screen at /settings/theme: a 'Follow device' switch and a grid of selectable theme cards (Modern Light, Modern Dark) with a mini preview. Build the grid from appThemes.where(available) so a third theme appears with no screen change. Selected card shows a check icon, not color alone.
5. Tests: persistence round-trip; unknown id falls back to modern_light; a widget test that switches themes and asserts the scaffold background changes instantly; golden test of the settings screen in both themes.
```

**Done when:** switching and restarting keeps the choice; adding a dummy third spec in a test makes a third card appear.

### Step 5 — Localization (Bangla default), fonts, formatting

**Goal:** Bangla-first UI with English optional and a Bangla-numeral setting.

```text
Set up localization and typography.

1. l10n.yaml with ARB files lib/core/localization/arb/app_bn.arb (template, default) and app_en.arb. Generate AppLocalizations. Add extension context.l10n. Seed keys for: app name, auth, navigation tabs (Home, Chores, Bazar, Family), common actions (save, cancel, retry, delete), errors for each AppFailure type, empty states, and theme settings.
2. LocaleController (Riverpod, persisted in shared_preferences, same early-load approach as the theme). Settings screen at /settings/language with Bangla and English options and a separate switch 'Use Bangla digits'.
3. Fonts: bundle a Bangla-first family in the app (offline, no runtime download). Evaluate Hind Siliguri, Noto Sans Bengali and Anek Bangla, check each license, pick one, and explain the choice. Declare it in pubspec and use it in buildThemeData TextTheme with Latin fallback. Body text >= 14sp, small labels >= 12sp.
4. Formatters in core/localization/: date (e.g. '১৪ অক্টোবর ২০২৬' / '14 October 2026'), month name, weekday, number, and Money, all honoring the locale and the Bangla-digits switch.
5. A test that renders key screens with a very long Bangla string and with text scale 2.0 and fails on overflow. Add a script or test that greps lib/ for hard-coded string literals inside Text( widgets.
```

**Done when:** language switches instantly and persists; no overflow at 200% font scale.

### Step 6 — Firebase setup (dev and prod) and bootstrap

**Goal:** Firebase connected, offline persistence on, emulator ready.

**You do manually first:** create two Firebase projects (`familyhub-dev`, `familyhub-prod`), enable Email/Password sign-in, create Firestore in the region nearest your family, and note that the Firestore location is permanent `[VERIFY]` before choosing. Confirm current Spark limits in the Firebase console `[VERIFY]`.

```text
Integrate Firebase for both flavors.

1. Add firebase_core, firebase_auth, cloud_firestore at current stable versions. Use the FlutterFire CLI to generate firebase_options_dev.dart and firebase_options_prod.dart; the correct one is chosen from Flavor in bootstrap. Place google-services.json per flavor in android/app/src/dev and android/app/src/prod.
2. bootstrap.dart: initialize Firebase, enable Firestore offline persistence, and add a debug-only switch (--dart-define=USE_EMULATOR=true) that points Auth and Firestore to the local emulators.
3. Create firebase.json (emulators for auth, firestore, ui), firestore.rules with a temporary deny-all rule, and firestore.indexes.json seeded with the composite indexes from roadmap 12.3.
4. core/firebase/firestore_paths.dart: typed helpers for every collection path in roadmap 12.2 (families/{id}/expenses, etc.) so no path string is written twice.
5. core/firebase/tx_runner.dart: a TxRunner interface (runBatch / runTransaction) with a Firestore implementation and an in-memory fake for tests.
6. core/firebase/base_mapper.dart: helpers for the standard fields (createdAt, createdBy, updatedAt, updatedBy, schemaVersion, deletedAt) so every mapper stays consistent.
7. Document in README how to start the emulators and run the app against them.
```

**Done when:** the dev app starts, connects to Firebase (or the emulator), and a throwaway read/write test passes; remove the throwaway code afterwards.

### Step 7 — Authentication feature

**Goal:** sign-up, login, recovery and email verification, fully tested with a fake repository.

```text
Build features/auth (data / domain / presentation). Do not write to Firestore in this step.

DOMAIN: AppUser {uid, email, emailVerified}. AuthRepository interface: authStateChanges, signUp, signIn, signOut, sendPasswordReset, sendEmailVerification, reloadUser. Use cases SignUp, SignIn, SignOut, SendPasswordReset, SendEmailVerification, each returning Result<T>. Validation (email format, password >= 8 chars) lives in domain and returns AppFailure.Validation.

DATA: FirebaseAuthRepository. Map FirebaseAuthException codes to AppFailure: invalid-credential, user-not-found, email-already-in-use, weak-password, network-request-failed, too-many-requests, anything else -> Unknown.

PRESENTATION: authStateProvider (stream of AppUser?). One AsyncNotifier controller per screen. Screens: Welcome, Login, SignUp, ForgotPassword, VerifyEmail (resend, 'I have verified' reloads the user, sign out). Forms: inline validation, button disabled and spinner while loading, show-password toggle, keyboard next/done actions, autofill hints, every AppFailure shown as a localized message (add the ARB keys in bn and en). All colors and strings from tokens and l10n.

TESTS: FakeAuthRepository; unit tests for every use case and failure mapping; widget tests for login success, wrong password, invalid email, offline; golden tests of Login in light/dark x bn.
```

**Done when:** against the emulator you can sign up, verify, log in, recover a password, and sign out; each failure shows a Bangla message.

### Step 8 — Router, guards, app shell, module registry

**Goal:** navigation that always sends the user to the right place, with the 4-tab shell and the module registry from roadmap Section 10.

```text
Implement navigation and the module skeleton.

1. app/router.dart: a GoRouter provider whose refreshListenable combines auth state, profile existence and membership state. Redirect rules: not signed in -> /welcome; signed in but email unverified -> /verify-email; no user profile -> /profile-setup; no family membership -> /family-choice (create or join); membership pending -> /pending; membership disabled -> /disabled; active -> /home. Unit-test every rule with fake providers (one test per row) and test that deep links respect the guards.
2. App shell: StatefulShellRoute.indexedStack with 4 branches (Home, Chores, Bazar, Family) that preserve each tab's navigation state. Build a floating pill bottom bar in shared/widgets using tokens only: the active tab expands to show its label, inactive tabs show icon only, Semantics labels, 48dp targets, works in Bangla.
3. modules/family_module.dart: abstract class FamilyModule { id; nameBn; nameEn; icon; routes; dashboardCards; reports; requiredPermission; }. modules/module_registry.dart holds the list of registered modules. Create stub ChoresModule and BazarModule with placeholder screens that use EmptyState-style content.
4. moduleFlagsProvider reads families/{id}/settings/modules (default: all on). Disabled modules disappear from navigation. The router builds branches from enabled modules.
5. Settings entry reachable from the Family tab with links to Theme and Language (Steps 4 and 5).
Use placeholder repositories where Firestore data is not ready; mark them clearly with TODO(step-9).
```

**Done when:** every redirect row has a passing test; tab switching keeps each tab's scroll and stack.

### Step 9 — Profile, family create/join, invitations, approval

**Goal:** two real users can end up in one family with different roles.

```text
Build features/onboarding and features/family.

DESIGN DECISION (add to CLAUDE.md as an extension of roadmap 12.2): joining needs a way to find a family from a code without listing families. Create a top-level collection inviteCodes/{code} -> {familyId, role, expiresAt, status}, readable by exact-id get only (never list) by any signed-in user, and mirrored in families/{id}/invitations/{id}.

DOMAIN: UserProfile, Family, Member (role: admin|moderator|member; status: active|pending|disabled; relationship; spouseId), Invitation. Use cases: SaveProfile; CreateFamily (ONE batch: families/{id}, members/{uid} as active admin, settings/general {timezone Asia/Dhaka, currency BDT}, settings/modules, settings/rotationPolicy, settings/notificationDefaults, activity and audit entries); CreateInvitation (8-character code from an unambiguous alphabet, expires in 7 days, role member); JoinWithCode (validates the code, creates members/{uid} with status pending); ApproveMember, RejectMember, DisableMember, ChangeRole, TransferAdmin. A last-admin guard: demoting, disabling or removing the only admin returns AppFailure.Conflict.

SCREENS (roadmap 2.3 and 15): ProfileSetup (preset avatars or initials, full name, nickname, optional gender, relationship from an editable list: Father, Mother, Son, Daughter, Husband, Wife, Housewife, Daughter-in-law, Son-in-law, Other; spouse picker shown only for relationships where it makes sense, can be left empty), FamilyChoice (create or join), CreateFamily, JoinWithCode, Pending (listens to its own member document and moves on automatically when approved), Members list, Member profile, Invitations, Roles screen, Family settings (timezone, currency, module switches).

SYNC: implement FirestoreThemePreferenceSync (Step 4) and a language sync that store users/{uid}.preferences {themeId, themeMode, language}. Local value wins at startup; remote value applies after sign-in.

TESTS: use-case tests with in-memory fakes including the last-admin guard, expired code, reused code, and a pending member trying to act; widget tests for the two main flows.
```

**Done when:** on the emulator, user A creates a family and invites B; B joins as pending; A approves; B lands on Home.

### Step 10 — Permission policy and Firestore rules v1

**Goal:** the permission matrix (roadmap 2.2) exists once as code and once as rules, and both are tested.

```text
Implement permissions and security.

1. core/permissions: enums Role and Permission with one Permission per row of the roadmap 2.2 matrix (inviteMembers, approveMembers, removeMembers, changeRoles, editFamilySettings, manageChoreTemplates, reassignChore, requestSwap, completeOwnChore, commentOnChore, verifyChore, addOwnExpense, editOthersExpense, manageCatalogAndBudgets, recordContribution, viewFamilyReports, exportData). A pure PermissionPolicy.can(member, permission, {ownerId, familySettings, template}) that handles the conditional cells (moderator approve-only, 'if enabled', 'if template allows', 'per family policy'). A table-driven unit test covering every permission x role.
2. A PermissionGate widget (hide or disable with an explanation) and a requirePermission helper that use cases call first.
3. firebase/firestore.rules v1 using helper functions isMember(f), role(f), isAdmin(f), isMod(f) from roadmap Section 13. Cover: users, families, members (a user cannot write their own role or status; join creates only status pending with a valid inviteCodes entry), invitations, inviteCodes (get only), settings, auditLogs and activity (create only, never update or delete). Validate fields: createdBy == request.auth.uid, enums in allowed sets, integers >= 0 for money fields. Block hard deletes on financial and chore data. Block demoting the last admin where rules can express it.
4. firebase/rules_test using @firebase/rules-unit-testing against the emulator: for every rule, one allowed and one denied case. Must include: member cannot make themselves admin; user cannot read another family; pending member cannot read family data; cannot forge createdBy.
5. Add the rules tests to CI (start the emulator, run tests).
6. Add to CLAUDE.md: from now on, every step that adds a collection must extend the rules and rules tests in the same commit.
```

**Done when:** rules tests are green in CI and the Phase 1 acceptance scenario (below) is proven by tests.

### Step 11 — Shared widgets and a component gallery

**Goal:** reusable building blocks so later screens stay consistent.

```text
Build shared/widgets, all token-driven, localized, accessible.

- AppAvatar: image if present, otherwise initials. Use the 'characters' package for the first grapheme cluster (Bangla-safe). Background = placeholderPalette[stableHash(id) % length] with a text color chosen for contrast; same id gives the same color on every screen and launch. Failed image load falls back with no flicker or error text.
- ItemThumb: item image -> category image -> colored initial placeholder (roadmap 9.7).
- StatusChip: status icon + label + color for scheduled, in_progress, completed, verified, overdue.
- EmptyState (illustration slot, title, message, optional primary action), LoadingView (skeleton), ErrorView (message + retry), SectionHeader with 'See all', AppCard, MoneyText (uses MoneyFormatter), ProgressRing, PillBottomBar if not already extracted.
Create a debug-only /dev/gallery route showing every widget in all states. Golden tests: each widget in 2 themes x 2 languages. A test at text scale 2.0 that fails on overflow.
```

**Done when:** the gallery looks right in both themes and both languages.

### Phase 1 acceptance gate

Do not start Phase 2 until all of these are true (roadmap Phase 1):

- Two test users join one family with different roles.
- Rules tests prove a member cannot make themselves admin or read another family.
- Theme and language switch instantly and are remembered.
- CI is green: format, analyze, unit tests, rules tests, APK build.

---

## Part 4 — Phase 2: Bazar and Family Finance

### Step 12 — Categories, items, search, seed data

**Goal:** the catalog that makes expense entry fast.

```text
Build features/bazar/items_categories.

DOMAIN: Category {id, nameBn, nameEn?, color, imageUrl?, sortOrder, active}; Item {id, nameBn, nameEn?, categoryId, defaultUnit, imageUrl?, aliases[], useCount, lastPricePaisa, active}. Repositories, plus use cases AddCategory, UpdateCategory, AddItem, UpdateItem, DeactivateItem (never hard delete). All require manageCatalogAndBudgets.

SEED: a SeedDefaultCatalog use case, idempotent through deterministic ids (cat_vegetables, item_potato ...), called from CreateFamily. Seed the 10 categories from roadmap 4.2 (Vegetables সবজি, Fish মাছ, Fruits ফল, Beef গরুর মাংস, Chicken মুরগির মাংস, Eggs ডিম, Dry groceries শুকনা বাজার, Gas গ্যাস, Medicine ঔষধ, Other অন্যান্য) and about 40 common items with Bangla name, English name, default unit and aliases (for example 'আলু' with aliases 'alu', 'potato'; onion and potato are items under Vegetables). Show me the full seed list in the reply for my review before finalizing it.

SEARCH: a pure-Dart ItemSearch class: normalizes Bangla and English input, matches aliases and transliterations, and ranks results as exact prefix, then the family's frequent items (useCount), then predefined items. Unit tests: 'alu' finds আলু; Bangla prefix works; ranking order; empty query returns frequent items.

DATA/UI: stream categories and items once, cache them in a Riverpod provider (they change rarely); an Items and Categories manager screen for admin/moderator with add, edit, deactivate, sort order, color, optional emoji or small base64 image (no Cloud Storage; roadmap 12.6). Extend Firestore rules and rules tests for bazarCategories and bazarItems.
```

**Done when:** a new family starts with the catalog; search finds items by Bangla and English input.

### Step 13 — Expense domain and use cases (no UI yet)

**Goal:** all money rules proven before any screen exists.

```text
Build features/bazar/expenses domain and data (no UI).

ENTITIES: Expense {id, dateKey, monthKey, itemId?, itemName, categoryId, qty (Quantity?), unit?, unitPrice (Money?), total (Money), fundingSource: fund|member, paidByMemberId?, reimbursable, purchaserId?, tripId?, shop?, note?, source: manual|import, importBatchId?, deletedAt?}, FundTransaction {type: contribution|expense|reimbursement|opening|adjustment, amount signed Money, refType, refId, dateKey}, MemberAdvance {expenseId, memberId, amount, settled, status: pending|partial|settled}.

USE CASES (each returns Result, checks PermissionPolicy, writes audit + activity in the same batch):
- AddExpense: total = qty x unitPrice (half-up to paisa) OR a typed total; future dates rejected; month-locked dates rejected. In ONE batch write the expense, then either a negative FundTransaction of type expense (funding = fund) OR a MemberAdvance with status pending (member-paid and reimbursable) OR nothing extra (member-paid, no reimbursement). If 'remember item' is set, create or update the Item (useCount + 1, lastPricePaisa).
- CheckDuplicate: returns a warning (same date + item + amount within 10 minutes). It is a warning, never a failure.
- AddBazarTrip: many lines sharing date, shop and funding source, saved as separate expense documents linked by a tripId, in one batch.
- UpdateExpense: stores before/after in auditLogs; adjusts the linked fund transaction or advance by writing a compensating entry; refuses with Conflict if the advance is already partly settled. Members may edit only their own expenses; admin/moderator may edit any.
- SoftDeleteExpense: sets deletedAt and deletedBy; writes a compensating adjustment FundTransaction so history stays explainable; never deletes or mutates the original transaction.

TESTS (domain level, with fakes and FakeClock): every funding combination; the original expense is never edited by a later settlement; category totals are never double counted; edit and delete reverse balances correctly; duplicate warning; permission denials; locked month. Extend Firestore rules and rules tests for expenses, fundTransactions, memberAdvances.
```

**Done when:** the full test suite for these use cases passes and no UI code exists yet.

### Step 14 — Expense form (the most-used screen)

**Goal:** record a normal bazar item in 10 seconds or less (roadmap success criteria).

```text
Build the Add Expense screen and the Bazar Trip screen on top of Step 13.

FLOW (roadmap 4.1), in this order on one screen: Date (defaults to today, past allowed, future blocked) -> Item (autocomplete using ItemSearch, results ranked per Step 12) -> Category (auto-filled from the item, changeable; for a new item the user picks a category and a single 'Remember this item' checkbox) -> Amount (either type the total, or type quantity + unit price and the total is calculated and always shown clearly in large text) -> Funding (default 'From family fund'; alternatives 'Paid by [member], to be reimbursed' and 'Paid by [member], personal, no reimbursement') -> Save, and 'Save & add another' which keeps date, shop and funding. A collapsed 'More' section holds shop, note, purchaser and tags (no receipt photo; Storage is not available on Spark).

BEHAVIOR: numeric keypad with Bangla digits accepted; the cursor moves to the next field automatically after an item is chosen; the duplicate warning appears as a non-blocking confirmation; validation errors are inline and localized; an unobtrusive 'waiting to sync' indicator driven by Firestore pending-writes metadata; keep the form state if the app is backgrounded.
BAZAR TRIP SCREEN: running list of lines with a live total, shared date/shop/funding at the top, swipe to remove a line, one Save for all lines.

QUALITY: a controller test for the form state machine, widget tests for the happy path and errors, goldens in 2 themes x 2 languages, and a test that proves a normal item can be saved in at most 4 taps after item selection.
```

**Done when:** you can time yourself adding an item in under 10 seconds on a real phone.

### Step 15 — Expense list, edit, delete, history

**Goal:** find, correct and undo entries safely.

```text
Build the Expense List screen and detail/edit flow.

- Month selector plus filter sheet: date-range presets, category, item, member, funding source. Group rows by day with a day total; show the filtered total at the top. Use Money formatting and ItemThumb.
- Pagination: 30 rows per page, always bounded by monthKey/dateKey range (roadmap 12.4), ONE listener per screen, cancelled on dispose.
- Tap a row to open detail; Edit reuses the Step 14 form prefilled and calls UpdateExpense. Delete shows a confirmation sheet, then a snackbar with Undo that calls a new RestoreExpense use case (writes the compensating fund/advance entries again; tests included).
- Admin/moderator can toggle 'show deleted'. The detail screen has a History section (before/after from auditLogs) visible to admin/moderator.
- Members see edit/delete only on their own expenses (PermissionGate); others are read-only.
- Empty, loading, error and offline states. A performance test that renders 2,000 fake expenses without jank.
```

**Done when:** edit, delete and undo leave the fund balance exactly correct (covered by tests).

### Step 16 — Monthly budgets and dry-grocery estimates

**Goal:** plan the month and see alerts without ever blocking spending.

```text
Build features/bazar/budgets.

DOMAIN: Budget {id = yyyy-MM, totalEstimate, categoryEstimates{categoryId: Money}, lines[BudgetLine{itemId, plannedQty, unit, estimatedRate, estimatedTotal, currentStock?}], alertThresholds default [80, 100]}. Use cases SaveBudget, CopyLastMonthBudget, and a pure ComputeBudgetStatus(budget, spendByCategory) returning per-category and total {spent, remaining, percentUsed, level: ok|warning|exceeded}. Alerts never block an expense.

UI: Budget screen for a selected month: total and per-category progress bars (status = icon + label + color), a Dry-grocery estimate table editor (item, quantity, unit, rate, auto-calculated total, optional current stock), a one-tap 'Copy last month' action, and an empty state for a month with no budget. Expose budgetAlertsProvider for the dashboard.
Note in the UI copy: a budget is a plan, the fund balance is real money.

TESTS: thresholds hit exactly at 80% and 100%; zero budget; category with no estimate; copy-last-month when last month is missing. Extend rules and rules tests for budgets.
```

### Step 17 — Contributions, fund ledger, advances, settlements, month close

**Goal:** trustworthy family money tracking (roadmap 4.4 and 4.5).

```text
Build features/bazar/contributions and features/bazar/advances.

DOMAIN: ContributionPlan {id = yyyy-MM_memberId, expected}, Contribution {memberId, monthKey, amount, dateKey, method?, note?}, Settlement. A pure FundBalanceCalculator: balance = sum(contributions) - sum(fund expenses) - sum(reimbursements) + opening balance +/- adjustments, ignoring nothing silently (compensating entries from deletes already net out).

USE CASES: SetContributionPlan (default from family settings, override per member per month); RecordContribution (contribution + FundTransaction type contribution in ONE batch; requires recordContribution); SettleAdvance (ONE transaction: Settlement + MemberAdvance update + FundTransaction type reimbursement; partial settlement allowed; status pending -> partial -> settled; overpayment rejected; the original expense is NEVER edited); CloseMonth (admin only: lock the month and write an openingBalance transaction into the next month); ReopenMonth (admin with a required audit note). Locked months reject changes except by an admin with a note.

SCREENS: Contributions and Fund (fund balance card; per-member expected, received, remaining, credit; history), Record contribution sheet, Advances and settlements list with settle action, Month close screen. Members see only their own contribution view (default policy).

TESTS: balance after a mixed month equals a hand-computed value; partial then full settlement; overpayment; credit when a member overpays; close then carry forward; locked-month edit denied; no double counting between expenses and reimbursements. Extend rules and rules tests.
```

**Done when:** a scripted month (contributions, fund and member-paid expenses, a partial settlement, month close) produces the expected balances in tests.

### Step 18 — Reports

**Goal:** every report view from roadmap 4.6, correct to the paisa.

```text
Build features/bazar/reports.

ENGINE: a pure ReportEngine that takes expenses (soft-deleted excluded), budget and range, and returns Summary, ByCategory, ByItem, ByDay, ByMember, DryGroceryEstimateVsActual. Presets: Today, Yesterday, Last 7 days, This week, This month, Last month, Custom range, This year. Week start is a family setting (default Saturday; ask me to confirm). Previous-period comparison returns +/- amount and %.

DATA: query expenses by dateKey/monthKey range with a limit and aggregate in the app; no stored summary documents yet (roadmap 12.7).

UI: a Reports screen with a preset chip row, custom range picker, and a tab per view. Each tab has a fl_chart chart (colors from tokens: chart[0..9], chartGrid) AND a table beneath it; charts have text alternatives for screen readers. Requires viewFamilyReports; members see only their own contribution report.

TESTS: totals match fixtures to the paisa; month-boundary ranges; previous-period math when the previous month is shorter; a soft-deleted expense is excluded; 5,000-expense performance test.
```

### Step 19 — Import wizard (re-attach `Bazar.xlsx` first)

**Goal:** bring the existing spreadsheet in without retyping.

```text
I am attaching the real Bazar.xlsx. FIRST, inspect it and report: sheets, header rows, merged cells, date formats, how categories and items appear, the dry-grocery estimate table, and anything unexpected. Do not write code until you have shown me that report and I confirm it.

Then build features/bazar/import (admin only) with the excel and csv packages:
1. Pick file, pick sheet, map columns to date / item / category / amount (auto-suggest by Bangla or English header names).
2. Preview rows with validation. Flag unknown items and categories and let me resolve each: map to existing, create new, or skip.
3. A dry run that shows per-category totals from the sheet next to the totals that will be imported.
4. Import in batches of at most 400 writes. Every imported expense gets source: import and an importBatchId. Ask me which funding source imported rows should use (default: fund).
5. An UndoImport use case that soft-deletes a whole batch with compensating entries.
6. Convert the dry-grocery estimate table into the first monthly Budget.
7. Do NOT import contributions unless the workbook actually contains them.
Tests use a small fixture workbook and prove per-category totals reconcile to the paisa.
```

### Phase 2 acceptance gate

- One real month is imported and per-category totals match the old sheet to the paisa.
- A normal expense takes 10 seconds or less and at most 4 taps after item selection.
- Contribution, advance, settlement and month-close tests pass; rules tests are green in CI.

---

## Part 5 — Phase 3: Chores

### Step 20 — Chore templates and seed data (re-attach `family_chores.pdf` first)

**Goal:** editable templates that carry the family's own wording.

```text
I am attaching family_chores.pdf. FIRST compare it with Appendix A of the roadmap (a draft reconstructed from garbled text). List every difference and every line you cannot read with confidence. Do not guess garbled text: ask me to correct it. Preserve my family's wording and timing rules (breakfast before 9 AM, lunch before 2 PM, dinner cooking done by 8 PM).

Then build features/chores/templates.

DOMAIN: ChoreTemplate (roadmap 5.1): nameBn/nameEn, group, type, Recurrence (sealed: Daily, Weekdays(set), EveryNDays, EveryNWeeks, DaysOfMonth, LastDayOfMonth), dueTime or end-of-day, assigneeStrategy (rotation|fixed|manual), dutyGroupId?, instructions (simple markdown-style text), subtasks[{id, title, required, hint}], estimatedDuration, verification (off|required), reminder overrides, startDate, endDate, active, difficulty (easy|normal|hard). A pure RecurrenceExpander.datesBetween(recurrence, from, to).
USE CASES: CreateTemplate, UpdateTemplate (offer 'future only' or 'also upcoming unstarted occurrences'), PauseTemplate, SeedChoreTemplates (every seed is editable and can be switched off). Requires manageChoreTemplates.
UI: templates list grouped by category with an active switch; a template editor with drag-to-reorder subtasks, a recurrence picker, an instructions editor, difficulty and verification toggles.

TESTS: weekly, every 2 weeks, 31st-of-month in a 30-day month, last day of month, leap year, end date, paused template. Extend rules and rules tests.
```

### Step 21 — Rotation engine and duty groups (pure Dart)

**Goal:** X → Y → Z fairness exactly as roadmap Section 6; built before the generator because the generator depends on it.

```text
Implement the rotation engine in features/chores/duty_groups/domain, test-first, no Firebase.

MODEL: DutyGroup {id, nameBn, templateIds[], rotation}. Rotation {members snapshot M[0..n-1], anchorDate, anchorIndex, cycleUnit: day|week|month|occurrence, version}, with a list of versions each effective from a date.
RULE: planned(date) = M[(anchorIndex + cyclesBetween(anchorDate, date)) mod n]. Handle dates BEFORE the anchor (negative cycles) correctly. It is based on the calendar, never on who completed last; a missed or skipped day shifts nobody.
DAY BUNDLE: a duty group has ONE owner per day; every occurrence of its templates that day gets that person. A single template can also rotate by itself (for example weekly fridge cleaning among three people).
CHANGES: AddMemberToRotation (appended, effective from a chosen date, new version) and RemoveMemberFromRotation (new version from a chosen date; past occurrences untouched). Resolve the correct version by date.
COVER: a pure suggestCover(date, rotation, availability) returns the next AVAILABLE member in rotation order. An accepted cover changes assigneeId only; plannedAssigneeId and all later days stay the same.

TESTS: X->Y->Z for a whole month; a skipped day does not shift; add and remove a member mid-month; month and year boundary; leap year; weekly and monthly cycles; before-anchor dates; cover does not shift later days; nobody available returns a 'needs cover' result.
```

**Done when:** every roadmap Section 18 rotation case has a passing test.

### Step 22 — Occurrence generator (idempotent)

**Goal:** the next 45 days of occurrences always exist, with no duplicates.

```text
Build features/chores/occurrences generation.

1. Pure OccurrenceGenerator: given templates, duty groups, rotations and a date range, produce occurrence drafts with the deterministic id {templateId}_{yyyyMMdd}, snapshots of title, instructions and subtasks, dateKey, monthKey, dueAt, plannedAssigneeId and assigneeId (equal at creation), status scheduled, progress {done 0, total required}.
2. EnsureOccurrences use case: for the next 45 days, create only what is missing. First explain the race between two phones generating at once, then implement the safest approach so a late generator can NEVER overwrite an occurrence someone already progressed (for example reading existing ids for the range first, writing only missing ones, and rules that deny updates to snapshot fields; treat already-exists as success).
3. Trigger when an admin or moderator opens the app, and after a template or rotation change. A template edit affects future occurrences only, unless the admin chose 'also upcoming unstarted'. A rotation change re-plans only future, unstarted occurrences.

TESTS: running it twice creates no duplicates; two simulated devices racing; paused and end-dated templates; rotation change after some occurrences are in progress; snapshots remain unchanged after a template edit. Extend rules and rules tests for choreOccurrences.
```

**Done when:** repeated generation and a two-device race produce exactly one occurrence per template per day.

### Step 23 — Task detail, subtask sync and the status machine

**Goal:** complete a chore in 2 taps, with the exact logic from roadmap 5.3 and 5.4.

```text
Build features/chores/occurrences domain, data and the task detail screen.

DOMAIN (pure Dart): Occurrence entity; status scheduled|in_progress|completed|verified; overdue is DERIVED by isOverdue(occurrence, now) and never stored. A pure SubtaskSync implementing roadmap 5.4 exactly: R = required subtasks, D = completed required subtasks. D=0 -> scheduled; 0<D<|R| -> in_progress with label 'D of |R|'; D=|R| -> completed and completedAt set. Tick parent -> tick all subtasks; untick parent -> untick all (confirmation if it was completed); untick a required subtask on a completed task -> in_progress, completedAt kept in history and cleared on the active record; no subtasks -> the parent checkbox is the whole task; optional subtasks never block completion; completing without required subtasks is blocked unless an admin/moderator records an exception with a note.

USE CASES (each writes an event to occurrences/{id}/events in the same batch): ToggleSubtask, ToggleParent, CompleteOccurrence, VerifyOccurrence (verifiedBy must differ from completedBy; only when the template allows or requires it), ReopenOccurrence (mandatory reason; the original completion stays in history; a verified task can be reopened only by admin/moderator), RecordCompletionException.

UI: Task detail per roadmap 5.7: title, due time, assignee avatar (with a 'covering for X' badge when replaced), progress ring, expandable instructions, subtask checklist, a history timeline (assigned, swapped, completed, verified, reopened), and clearly marked placeholders for the reminder line (Step 28) and comments (Step 24). Completion from a list row takes 2 taps. Status always shows icon + label + color.

TESTS: a table-driven test of every transition above; overdue derivation; self-verification blocked; reopen permissions. Extend rules and rules tests (verifiedBy != completedBy, no client edits to snapshot fields).
```

### Step 24 — Comments

```text
Build features/chores/comments on choreOccurrences/{id}/comments.

Use cases: AddComment (text, optional attachment), MarkNeedsAttention, HideComment (admin/moderator only, requires an audit note; comments are never deleted by members and survive reopening and reassignment). When a comment is marked 'needs attention', highlight the task for the assignee, and if the task is completed offer 'Reopen with this reason', which calls ReopenOccurrence with that comment as the reason.
Attachments: photos are DISABLED while Cloud Storage is not available on Spark [VERIFY]; keep the field optional and hidden behind a flag.
UI: a comment thread on the task detail screen (author avatar, time, needs-attention badge), a composer, one listener for the thread cancelled on dispose, empty state. Extend rules and rules tests.
```

### Step 25 — Availability, swaps, covers, inbox

**Goal:** every change of who does what carries a reason and keeps the rest of the rotation intact (roadmap 6.3 and 6.4).

```text
Build features/chores/availability and features/chores/swaps, plus a basic notificationInbox.

DOMAIN: MemberAvailability {range, type: sick|travel|other, reason (required), status}; SwapRequest {occurrenceId, fromMemberId, toMemberId, reason (required), status: pending|accepted|declined|expired, respondedAt}; InboxItem {toMemberId, type, refId, readAt?}. Family absence policy setting: A ask-for-cover (default), B auto-cover, C skip.

USE CASES: AddAvailability (lists the affected occurrences and applies the family policy: A creates cover requests to the next available member via suggestCover; B assigns the next available member who may decline; C lets an admin mark 'skipped (absence)'); RequestSwap (reason mandatory); AcceptSwap (ONE transaction: occurrence assigneeId, request status, events, inbox item; plannedAssigneeId stays unchanged); DeclineSwap (optional reason); ExpireSwaps (due time minus a configurable buffer; notifies the original assignee; runs on app open); ReassignOccurrence (admin/moderator, reason required, audited). If nobody accepts a cover, the task stays with the absent person, is flagged 'needs cover', and admins get an inbox item before the due time.

UI: Swap bottom sheet from the task detail, Inbox screen with Accept/Decline, Availability screen, 'needs cover' badge on tasks.
Known Spark limitation to show in the UI help text: a recipient whose app is closed learns about a request when they next open the app (roadmap 7.3).

TESTS: accept does not shift any later day; decline; expiry; policies A, B and C; nobody accepts; approved absence is neutral for scoring later. Extend rules and rules tests.
```

### Step 26 — Calendar (the hero screen)

**Goal:** see any month of chores, mine or everyone's, at a glance (roadmap 5.6).

```text
Build features/chores/calendar.

FIRST: build two small prototypes of the month view, one with table_calendar and one with a custom lightweight grid, and compare them for Bangla month/weekday names, status dots, accessibility, theming through tokens and performance. Recommend one, explain why, then implement it.

FEATURES: Month, Week and Agenda views (Agenda is the phone default). The month grid shows status dots only (max 3 plus '+n'), never task text; a selected-day list sits below. A segmented control 'My chores' / 'All family', optional category chips, and the sample-design chip row Today / Yesterday / Next 7 days that filters the list. Each status has an icon, a label and a color. Markers for swap/cover assignments, the viewer's unavailable days (muted hatch) and today (ring). A 'Today' button, swipe month navigation, touch targets of 48dp or more, assignee initials instead of photos, a friendly empty state ('No chores today' with 'Add chore' for admin/moderator).
DATA: read from choreOccurrences only, one listener per visible month by monthKey, no separate schedule store; past months show real occurrences.

TESTS: 28/30/31-day months and a leap February; Bangla weekday and month names; the 'My' vs 'All' filter; golden tests in 2 themes x 2 languages; a test at text scale 2.0.
```

### Phase 3 acceptance gate

- With X, Y, Z in rotation, assignments follow X → Y → Z for a full month.
- An absence plus a cover does not shift later days.
- No duplicate occurrences after repeated generation or two devices racing.
- Subtasks, comments, swaps, reasons and verification are all preserved in history.

---

## Part 6 — Phase 4: Dashboard and Engagement

### Step 27 — Dashboard from real data

```text
Build features/dashboard on top of the module registry.

- Header: greeting, avatar and a notification bell with the unread inbox count.
- Cards, each contributed by a FamilyModule.dashboardCards entry and hidden when the module is off: Today's chores with a progress ring; This month spending vs budget (with budget alerts); Contribution status (a member sees only their own, admins see the family); Upcoming and overdue chores; Recent activity from the activity collection; the budget alert strip.
- Query discipline (roadmap 12.4): only these listeners: this month's expenses, today's occurrences, this month's contributions, a limited activity query. No full-history reads.
- Loading skeletons, per-card error states, pull to refresh, every card tappable to its screen. The Ask-AI entry is a dormant widget behind a feature flag that is OFF.
TESTS: card visibility by role and module flag; a listener-count test; goldens in 2 themes x 2 languages.
```

### Step 28 — Reminders (local notifications) and notification settings

**Goal:** reminders fire on the real phone with the app closed (roadmap Section 7).

```text
Build core/notifications and features/notifications.

DOMAIN: ReminderSettings per member (defaults) with per-template overrides: at due time; before due 5/10/20/30/60 minutes or a custom number; multiple reminders per task; one overdue reminder N minutes after due; a morning summary at a chosen time; quiet hours. Precedence: global master switch -> category (chores/bazar/family) -> template. A reminder fires only if all three are on. Turning a switch off KEEPS the saved timings.
A pure ReminderPlanner(occurrences, settings, now) returns the list of notifications to schedule for the NEXT 7 DAYS only, with deterministic ids, localized title and body, respecting quiet hours and the 7-day cap (iOS allows about 64 pending). A 'why am I (not) getting this?' explanation generator for the task screen.

PLATFORM: a ReminderScheduler adapter using flutter_local_notifications and timezone with Asia/Dhaka. Reschedule on app open, on resume, and whenever assignments or settings change. Android: notification channels; POST_NOTIFICATIONS permission on Android 13+; exact-alarm permission handling on Android 12+ with a clear explanation and a graceful fallback to inexact alarms; reschedule after device reboot and after a timezone change; a battery-optimization warning.
UI: Notification settings with the 3-level switches and explanations; a 'Reminders not working?' help page with diagnostics (permission states, exact-alarm state, number of pending notifications, next scheduled time).

TESTS: planner tests for quiet hours, multiple reminders, overdue reminder, a disabled template suppressing ONLY that template, an assignment change, and the 7-day cap. Document a manual test checklist for two Android brands: app closed, battery saver on, after reboot, after a timezone change.
```

**Done when:** a reminder fires at the configured offset on a real Android device with the app closed; disabling one template's reminders suppresses only that template.

### Step 29 — Badges, Hub Level and the daily celebration

**Goal:** encouragement without star ratings or public ranking (roadmap Section 8).

```text
Build features/chores/achievements.

DOMAIN (pure Dart, test-first):
- ScoreCalculator over occurrence history: completion points = base(difficulty) x (1.0 on time | 0.6 late) x (1.2 if verified without reopening); cover bonus = +50% of base when accepting a cover; an absence or approved swap is neutral (no penalty, no bonus for the absent person). Use placeholder bases easy 10, normal 20, hard 30 as named constants and tell me they are placeholders. Points never decrease: recomputation is deterministic from history, so running it twice never double counts.
- Levels from a configurable threshold list, with Bangla and English level names.
- Badges (earned, never lost): Consistent (7 consecutive days with all assigned chores completed; approved absences pause the streak, they do not break it), Reliable (90% on time in a month), Helper (accepted 3 covers), Detail Champion (10 verified tasks with all subtasks done), Fresh Start (first completed chore).
- memberStats {points, level, streak, lastCelebratedDateKey} written by the owner only (client-side on Spark). Firestore rules must bound increments so tampering is hard; document this limitation (roadmap 13).

UI: a Hub Level visual shown as a growing plant (stages by level) with a progress ring toward the next level; an Achievements screen; privacy-first: a member sees their own level, and a family-wide 'this month's helpers' highlight is optional in family settings.
CELEBRATION: when a member completes all eligible chores for the day, show confetti or a Lottie animation, a localized message and badge/level progress, ONCE per day per member (lastCelebratedDateKey). Respect reduced motion (MediaQuery.disableAnimations).

TESTS: the points table, late vs on time, verified multiplier, cover bonus, absence neutrality, streak pause, badge thresholds, celebration shown once per day. Extend rules and rules tests.
```

### Step 30 — Activity feed and inbox screens

```text
Finish the activity feed and the in-app inbox.

- Activity screen: reads the activity collection (type, actor, summary, refType, refId) with a limit and paging, filter by module and member, tap to open the related screen. Every earlier use case already writes activity; add any missing ones and a test that each use case writes exactly one entry.
- Inbox screen: all InboxItem types (swap request, swap result, needs cover, budget alert, approval), unread badge count provider for the dashboard bell, mark read and mark all read, tap to open the target, empty state. Spark limitation note in help text (roadmap 7.3).
- Extend rules and rules tests for activity and notificationInbox.
```

### Step 31 — Polish, accessibility, tablet layouts

```text
Audit the whole app, then fix. FIRST produce a written list of issues with file and line references, grouped by category; then fix them in small commits.

Checklist: every screen has loading, empty, error and offline states; no information by color alone (status = icon + label + color); touch targets >= 48dp; text scales to 200% without overflow in Bangla; TalkBack labels on avatars, status chips, charts and calendar cells; contrast test passes for every registered theme; reduced-motion respected; long Bangla strings checked everywhere; tablet layouts (NavigationRail from about 840dp wide, two-pane calendar and task detail); chart polish and text alternatives.
Add golden tests for dashboard, calendar and expense form in each registered theme and language.
```

### Phase 4 acceptance gate

- Dashboard shows real data only, with the listener budget respected.
- A reminder fires on a real device with the app closed; the 3-level switches behave exactly as labeled.
- The daily celebration appears once per day and respects reduced motion.

---

## Part 7 — Phase 5: Reports, Sharing, Hardening

### Step 32 — Share reports and export

```text
Build report sharing and export.

1. ReportTextBuilder (pure Dart) producing daily, weekly and monthly report text in Bangla or English following roadmap Appendix B: bazar total with a by-category breakdown, chores completed / remaining / awaiting verification, month budget / spent / fund balance. Values come from the database only, never sample numbers. Plain text that reads well when pasted into WhatsApp. Share through share_plus.
2. CSV export of expenses, contributions and chore history for a chosen range (csv package). PDF export of a report (pdf and printing packages) with the bundled Bangla font embedded so Bangla renders correctly. Both require the exportData permission and share through the system share sheet.
3. Write docs/BACKUP_RESTORE.md explaining how an admin exports and keeps backups, and what a restore would involve.
TESTS: text output for fixture data in both languages; CSV round-trip; PDF generation smoke test.
```

### Step 33 — Hardening and release

```text
Prepare for the closed beta and the first release.

1. Quota audit: add a debug counter for Firestore reads per screen, measure each screen, fix chatty listeners, and write the results to docs/QUOTA_AUDIT.md. Check the current Spark limits in the Firebase console [VERIFY].
2. Offline and sync UX: the 'waiting to sync' indicator everywhere writes happen, conflict behavior documented.
3. Crash reporting (confirm current Firebase options and cost first [VERIFY]).
4. Security review: re-read firestore.rules against roadmap Section 13; add adversarial rules tests (forged createdBy, role self-promotion, cross-family reads, hard deletes, writing another member's stats, self-verification, locked-month edits). Check whether App Check is available on this plan [VERIFY].
5. Concurrency tests: two clients adding expenses, accepting the same swap, generating occurrences, settling the same advance.
6. Account deletion: remove the profile and keep family history attributed to 'former member'. Document the admin-transfer procedure so a family never loses its last admin.
7. Android release: signing keystore kept OUT of git, minify and shrink, versioning, a release checklist in docs/RELEASE.md, and a private distribution path for the beta (store listing later).
8. Run the closed beta with the real family for a full month and keep a fix list.
```

**Done when:** a full month runs on the real family without any data fixes by the developer (roadmap Phase 5).

---

## Part 8 — Later (Phase 6, optional)

Only after the beta is stable and only if you accept the Blaze plan with a budget cap `[VERIFY]`.

- Cloud Functions for scheduled occurrence generation, FCM pushes (swap requests, overdue), scheduled reports and server-trusted scoring.
- WhatsApp: check current official capabilities before any automation. The share sheet from Step 32 is the committed deliverable.
- AI features behind flags, always draft-then-confirm, calling the same use cases as the UI (roadmap Section 11).
- New themes: follow the 5-step checklist in roadmap 9.6. New modules: implement `FamilyModule` and register it.

---

## Part 9 — Reusable prompts

**Fix a bug**

```text
Bug: [what I did, what I expected, what happened, error text]. First find the root cause and explain it in 3 sentences, naming the file and the layer it belongs to. Then write a failing test that reproduces it, fix it in the right layer without breaking the architecture rules in CLAUDE.md, and show that the test now passes.
```

**Review before merging**

```text
Review the diff of this branch as a strict senior Flutter reviewer. Check: layer boundaries (no firebase in domain, no data in presentation), money and date conventions, permissions in the use case AND in the rules, missing tests, hard-coded strings or colors, listener leaks, unbounded queries, accessibility, Bangla overflow. List problems by severity with file and line, then fix the blocking ones.
```

**Add a new theme**

```text
Add a theme called [Rose]: create lib/app/theme/themes/rose_theme.dart with a complete AppTokens instance, register it in appThemes, add bn/en names and a preview swatch. Change no screen code. Run the contrast and golden tests and report any token that fails.
```

**Add a new module later**

```text
Add a module called [Events]: implement FamilyModule with routes, dashboard cards and permissions, register it in module_registry, add a family-level on/off flag, and build it feature-first (data / domain / presentation) using existing shared services (audit, activity, notifications, permissions). Do not touch other features except to register the module.
```

**Find missing tests**

```text
List every use case and domain rule in [feature] that has no unit test, then write the tests, starting with money, rotation and permission rules.
```

---

## Part 10 — Your loop for every step

1. Create a branch named after the step (`step-07-auth`).
2. Paste the step's prompt. Let the AI list its plan and files first.
3. Read the diff. Reject anything that breaks the architecture rules.
4. Run `dart format .`, `flutter analyze`, `flutter test`, and the rules tests when rules changed.
5. Run the app on the emulator (against the Firebase emulator) and try the feature by hand in Bangla and in both themes.
6. Commit. If you made a decision (accent color, absence policy, contribution rule), update the defaults in `CLAUDE.md` so every later prompt uses it.
7. Only then start the next step.
