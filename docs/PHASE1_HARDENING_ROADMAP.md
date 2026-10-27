# Family Hub — Phase 1 Hardening Roadmap (Steps H1 – H13)

**Purpose:** make Phase 1 *solid* before Phase 2 (Bazar & Family Finance) starts.
**Same method as `ROADMAP.md`:** one step = one prompt = one Git commit. Work top to bottom. Paste each step's prompt into any AI coding tool that can see the repo (Claude Code, Cursor, Copilot Agent, Codex …). `CLAUDE.md` is the shared context, so every step begins with "Read CLAUDE.md".

Audit basis: `android.zip` (the whole Flutter repo, HEAD `f6fbb6a`), `firebase/firestore.rules`, `firebase/firestore.indexes.json`, `PROGRESS.md`, `CLAUDE.md`, `ROADMAP.md`.

---

## 0. Read this first — what was and was not verified

| Verified by reading the code | Could **not** be verified in this audit |
| --- | --- |
| All of `lib/` (158 Dart files) that matters for Phase 1: bootstrap, router, session, auth, family, onboarding, permissions, core/firebase, shared widgets, settings | `dart format`, `flutter analyze`, `flutter test` — **no Flutter/Dart SDK was reachable** (GitHub, pub.dev and Google storage are blocked in the review sandbox) |
| `firestore.rules` line by line, against what the Dart mappers actually write | The 99/106 rules tests — the Firestore emulator jar could not be downloaded, so the "all green" claim in `PROGRESS.md` is **unconfirmed by me** (the test file itself is good quality) |
| Layer rules, localization parity (224 keys bn = en = generated Dart), Android Gradle/manifest, CI file, repo hygiene | Behaviour on a real device or real Firebase project |

Items marked **[DEVICE]** below are strong suspicions from reading the code that must be confirmed on a phone/emulator. Items marked **[VERIFY]** depend on current Firebase/package behaviour and must be checked against official docs, not memory.

---

## 1. Verdict

**Phase 1 is architecturally sound but is not "done".** The structure is genuinely good — feature-first Clean Architecture is followed, domain/data/presentation are separated, use cases return `Result<T>`, there is one permission matrix, rules have a real test-suite, localization is complete, themes are token-driven with contrast tests. The problems are *not* "the design is wrong"; they are:

1. **The Phase 1 acceptance gate is not met** (CI is red; the app has never talked to a real Firebase project).
2. **Offline behaviour is wrong in ways that can corrupt onboarding** (duplicate families, wrong redirect while offline).
3. **Security rules accept junk and forged log entries**, and a few lifecycle rules are missing (leave family, revoke invite, one-family-per-user).
4. **Two sources of truth for permissions** in the UI, and the domain layer is not truly pure Dart.
5. A handful of **spec features that Phase 1 owns are missing** (leave family, account deletion, configurable relationships, sync/pending indicator).

All of this is cheap to fix now and expensive after money data exists.

### Step-by-step status of the original Phase 1 (Steps 1–11)

| Step | Status | Why |
| --- | --- | --- |
| 1 Scaffold, flavors, lints, CI | ◐ | Works, but CI is red, Flutter version not pinned, logs/`.kotlin` committed, `setup.sh`/README stale |
| 2 Core value objects | ✅ | No `double` in money/quantity; `DateTime.now()` only inside `SystemClock` |
| 3 Theme tokens | ✅ | Contrast + raw-colour tests exist (raw-colour test only catches `Color(0x`) |
| 4 Theme controller + screen | ◐ | Controller fine; the golden + "switch changes scaffold instantly" tests required by Step 4 are missing (PROGRESS says so) |
| 5 Localization | ✅ | 224/224 keys, placeholders match, generated Dart matches ARB |
| 6 Firebase setup | ◐ | **All keys are placeholders** (`AIzaSy-dev-android-placeholder-key`); never connected; `firestore.indexes.json` has two invalid single-field indexes |
| 7 Auth | ◐ | Good code; only ever exercised against fakes/emulator |
| 8 Router, shell, modules | ✅ | Guard table is pure and tested; leftover `TODO(step-9/10)` comments |
| 9 Family create/join/invite/approve | ◐ | Works for the happy path; no leave, no revoke, no cancel request, no one-family guard, offline-unsafe |
| 10 Permissions + rules v1 | ◐ | Rules are strong on identity/roles; weak on field validation, log integrity, invites; UI doesn't use `PermissionPolicy`/`PermissionGate` |
| 11 Shared widgets + gallery | ✅ | 11 widgets × states × 2 themes × 2 languages, overflow tests |

### Phase 1 acceptance gate (from `ROADMAP.md`)

| Gate item | State |
| --- | --- |
| Two test users join one family with different roles | ✅ in tests/emulator · ❌ never on real Firebase / a device |
| Rules tests prove a member cannot self-promote or read another family | ✅ claimed (99 tests) · not re-run by me |
| Theme and language switch instantly and are remembered | ✅ in tests |
| CI green: format, analyze, unit tests, rules tests, APK build | ❌ red (3 failing tests, 26 lint infos, 17 unformatted files, Windows-made goldens vs Linux CI) |

---

## 2. Findings register

Severity: **P0** = fix before Phase 2 · **P1** = fix during Phase 1 hardening · **P2** = nice to have / decide.

| ID | Sev | Finding | Evidence | Fixed in |
| --- | --- | --- | --- | --- |
| F-01 | P0 | CI is red; Step 11 report: 3 failing tests, 26 info lints, 17 unformatted files; goldens made on Windows, CI is `ubuntu-latest`; golden `failures/` diffs exist for auth screens | `PROGRESS.md` Step 11; `test/features/auth/presentation/screens/failures/` | H1 |
| F-02 | P0 | Firebase never connected: every key/app-id in `google-services.json` and `firebase_options_*.dart` is a placeholder; no `.firebaserc` | `android/app/src/dev/google-services.json`, `firebase_options_dev.dart:38-70` | H2 |
| F-03 | P0 | `firestore.indexes.json` has two **single-field** composite indexes (`activity.createdAt`, `auditLogs.createdAt`). Firestore creates single-field indexes automatically; the CLI/API rejects them as "not necessary" [VERIFY with `firebase deploy --only firestore:indexes`] | `firestore.indexes.json` lines 67-80 | H2 |
| F-04 | P0 | Release builds may have **no `INTERNET` permission**: it is declared only in `src/debug` and `src/profile`, not in `src/main` | `android/app/src/main/AndroidManifest.xml` | H2 |
| F-05 | P1 | Release `signingConfig` = debug keystore for **both** flavors; `applicationId` has a template TODO | `android/app/build.gradle.kts` | H2 |
| F-06 | P0 | **Offline mis-routing [DEVICE]:** `watchHasProfile` / `watchMembership` map `snapshots()` without checking `metadata.isFromCache`. A fresh install/relogin while offline gets "document does not exist (from cache)" → router sends a real user to `/profile-setup` or `/family-choice` | `firestore_profile_repository.dart` `watchHasProfile`; `firestore_membership_repository.dart` `watchMembership` | H3 |
| F-07 | P0 | **Offline write timeout creates duplicates [DEVICE]:** `guardFirestore` puts a 30 s `.timeout` on `batch.commit()`. Offline, commit only completes when the server acks, so the UI reports a *failure* while the write stays queued; the user taps again and `CreateFamily` generates a **new** random family id → two families are created when the phone reconnects | `firestore_guard.dart`, `tx_runner.dart` `runBatch`, `create_family.dart` (`_newId()` per call) | H3 |
| F-08 | P1 | No offline / "waiting to sync" indicator anywhere (spec §14; Step 14 depends on it). grep for `hasPendingWrites`, `isFromCache`, `includeMetadataChanges` finds nothing | whole `lib/` | H3 |
| F-09 | P0 | **One-family-per-user is not enforced.** `CreateFamily` never checks existing membership; `JoinWithCode` only checks the *target* family; rules let a user rewrite `users/{uid}.familyId` freely → the old membership is orphaned | `create_family.dart`, `join_with_code.dart`, rules `users/{uid}` | H4 |
| F-10 | P1 | Missing lifecycle use cases: **leave family** (spec §15 "member leaves"), **cancel join request**, **revoke invitation** (status `revoked` exists but nothing and no rule can set it) | `usecases/` folder; rules `inviteCodes` update only allows `→ used` | H4 |
| F-11 | P0 | Rules do not validate member profile fields on **join** and **self-edit** (only the admin path calls `memberDocIsValid`). A pending member can write `fullName: 123` or a 1 MB string; `FamilyMappers.memberFromMap` does `d['fullName'] as String?` → `TypeError` → the admins' member list errors for everyone | rules members #2 and #6; `family_mappers.dart:55` | H5 |
| F-12 | P0 | `activity` / `auditLogs` create only checks `createdBy == uid`. Any active member can append arbitrary audit entries (any `actorId`, `type`, `summary`). The audit log is therefore not trustworthy | rules `activity`, `auditLogs` | H5 |
| F-13 | P1 | Invitation mirror `families/{f}/invitations/{i}` can be updated by **any signed-in user**; `inviteCodes/{code}` can be burned (`active → used`) by anyone who knows the code **without** joining | rules `invitations` update, `inviteCodes` update | H5 |
| F-14 | P1 | Rules never check `request.auth.token.email_verified`. An unverified account can create families and join with a code; only the router blocks it | `firestore.rules` | H5 |
| F-15 | P1 | Rules accept unknown extra keys on members/families/invites/logs/settings (no `keys().hasOnly(...)`) | `firestore.rules` | H5 |
| F-16 | P1 | Audit timestamps are client clock only (`createdAt` from the phone). A wrong device clock rewrites history. (Do **not** bound them with `request.time` — queued offline writes would be rejected.) | `eventMap` in `family_mappers.dart` | H5 |
| F-17 | P2 | "Last admin may not be removed" is client-only; two admins demoting each other at once, or an admin changing their own role, can leave zero admins. Rules *can* guard it with a bounded `adminIds` list on the family doc | rules header comment says "not expressible" | H6 (optional) |
| F-18 | P0 | **Two sources of truth for permissions.** `PermissionPolicy`/`PermissionGate` exist but **no screen uses them**; screens use `Membership.isAdmin` / `canManageMembers` | `family_screen.dart:22-23`, `members_screen.dart:72-73`, `membership.dart` | H7 |
| F-19 | P1 | The permission matrix was *derived* (roadmap 2.2 was never in the repo) and does not model the spec's "moderator: configurable" finance rights or "reports: per family policy" | `permission_policy.dart` header; project spec §6 | H7 |
| F-20 | P1 | Domain is not pure Dart: `core/utils/clock.dart` imports `flutter_riverpod`, `family.dart` imports `lib/modules/module_flags.dart`; `layer_boundaries_test` only checks *direct* imports so it cannot see this | `clock.dart:1`, `family.dart:1` | H8 |
| F-21 | P1 | Audit/activity writing (`_writeEvent`) is private to `FirestoreFamilyRepository`; `shared/services/` is empty. Every Phase 2 repository would copy it | `firestore_family_repository.dart:33` | H8 |
| F-22 | P1 | Leftover `TODO(step-9)` ×3 and `TODO(step-10)` (`FamilyModule.requiredPermission` is still `String?`) although CLAUDE.md says they must be deleted | grep `TODO` | H8 |
| F-23 | P1 | Unused packages: `freezed`, `freezed_annotation`, `json_*`, `riverpod_annotation`, `riverpod_generator`, `build_runner` — zero usages, no generated files; CLAUDE.md rule 8 still says "freezed immutable models" | grep of `lib/` | H1 (decision D1) |
| F-24 | P1 | Spec features owned by Phase 1 but missing: **account deletion** (spec §14; rules say "Closing an account is not a feature"), **change password**, **configurable relationship list** (spec §3), sign-out leaves the previous user's Firestore cache on disk | `firestore.rules` users/delete, `relationship.dart` const list; no `clearPersistence` anywhere | H9, H10 |
| F-25 | P1 | `saveProfile` rewrites `createdAt`/`createdBy` on every save; `watchFamily` only refreshes when the *family* doc changes (works today only because `updateFamily` touches it); `ActionController` providers are global and reset with a `Future.microtask` hack | `firestore_profile_repository.dart`, `firestore_family_repository.dart` `watchFamily`, `create_family_screen.dart` | H10 |
| F-26 | P1 | Activity/audit `summary` strings are hard-coded **English** and stored in Firestore (`'Family "x" created'`) — violates "Bangla default" for any screen that shows activity later | `create_family.dart`, `member_change_runner.dart`, `transfer_admin.dart` | H10 |
| F-27 | P1 | Rule 6 (no raw colours) violated: `Colors.white` / `Colors.black87` in `app_avatar.dart`, `item_thumb.dart`; the guard test only looks for `Color(0x` | `app_avatar.dart:73`, `item_thumb.dart:54` | H11 |
| F-28 | P1 | Two screens exceed the 300-line rule: `theme_settings_screen.dart` (377), `language_settings_screen.dart` (321). Several screens use a bare `CircularProgressIndicator` instead of `LoadingView`, and some streams have no error state (`member_profile_screen`, `family_screen`) | line counts; per-screen scan | H11 |
| F-29 | P1 | Step 4's missing tests (theme-settings golden, "switch changes background instantly", third-theme-adds-a-card) | `PROGRESS.md` | H11 |
| F-30 | P1 | No family-timezone provider; nothing exposes `settings/general.timezone` to code that computes `dateKey`/`monthKey` (Phase 2 needs it on day one) | `date_key.dart` only | H12 |
| F-31 | P1 | Repo hygiene: `*.log` ×4 and `android/.kotlin/errors/*.log` ×4 are tracked; no `.gitattributes` (Windows CRLF working tree vs LF index); CI uses un-pinned `channel: stable` while the author is on Flutter 3.47.7; `tools/setup.sh` and README describe a first-time setup that re-adds packages | `git ls-files`, `ci.yml`, `README.md` | H1 |
| F-32 | P2 | Not yet needed but plan for it: App Check (Play Integrity) to protect the open `inviteCodes` `get`; Crashlytics (free) instead of `developer.log`; API-key restriction in Google Cloud console | — | H2 / Phase 5 |

### What is already good (keep it)

Clean layering and naming; `Result<T>` + sealed `AppFailure`; `TxRunner` with an in-memory fake; `BaseMapper` standard fields; pure `resolveRedirect` guard table; one permission table + `requirePermission` in every mutating use case; rules with named helpers, closed enum sets, soft-delete only, default-deny for future collections; 106 rules test cases with `[roadmap]` tags; token-driven themes with WCAG tests; Hind Siliguri bundled; gallery + goldens + text-scale-2.0 overflow tests; `keys` for Phase-2 collections already in `FirestorePaths`.

---

## 3. Decisions you must make (defaults are used if you don't answer)

| # | Decision | Default used in this roadmap |
| --- | --- | --- |
| D1 | Keep `freezed` + `build_runner`? | **Remove all unused code-gen packages now**; models stay hand-written immutable classes. Re-open at Phase 2 Step 12 if `Expense` (≈20 fields) becomes painful; then adopt `freezed` for *new* entities only |
| D2 | Account deletion: what happens to history? | Soft-delete the user, disable membership, **keep their display name** on historical expenses/chores (financial history must stay explainable); allow "anonymise name" later |
| D3 | Offline policy for admin/onboarding actions | These **require the server** (create family, join, approve/reject, role changes, transfer admin, leave). Everyday Phase-2 entries (expenses, chores) are **queued offline** and show "waiting to sync" |
| D4 | Max admins per family (only for optional H6) | 3 |
| D5 | Golden images | Generated **on Linux in CI** (not Windows), compared exactly |
| D6 | Permission matrix | Owner must **ratify** the table produced in H7 against project spec §6 |

---

## 4. How to use this file

1. Make sure `CLAUDE.md` is in the repo root (it already is).
2. **Append the new rules in §5 to `CLAUDE.md` first** (H1 does it, but you can paste them yourself).
3. For each step: paste the prompt block into your AI tool, review the diff, run the **Done when** checks, commit with message `H<n>: <title>`.
4. Never start the next step with a red CI.
5. After H13, tag `phase-1-complete` and only then start Phase 2 (Step 12).

Dependencies: H1 → H2 → H3 → H4 → H5 (H5 needs H4's new rules) → H7 → H8 → (H9, H10, H11, H12 in any order) → H13. H6 is optional and can run any time after H5.

---

## 5. New hard rules to append to `CLAUDE.md`

```text
## Rules added by the Phase 1 hardening (H1-H13)
14. Offline-first: a "does not exist" snapshot that isFromCache is UNKNOWN, never "absent". Routing/guard decisions use only server-confirmed or cached-and-existing data.
15. Every write returns a WriteOutcome (committed | queuedOffline). Never treat a commit timeout as failure. Retries reuse the same document ids (generate ids once per user intent, not once per attempt).
16. Onboarding and administrative actions (create family, join, approve, reject, role change, transfer admin, leave, revoke) require the server and fail fast with Network when offline.
17. A user belongs to at most ONE family at a time (enforced in use cases AND rules).
18. Audit/activity entries are written ONLY through AuditWriter (core/firebase/audit_writer.dart), in the same batch as the change. They carry a type + params, never display text.
19. UI permission checks use PermissionPolicy (via canProvider / PermissionGate). `presentation/` must not test roles directly (isAdmin, MemberRole.admin ...). A test enforces it.
20. Every rules `create`/`update` validates field types, string lengths and the closed key set (keys().hasOnly). Every rule has one allowed and one denied test, and the Dart mappers' real output is pushed through the rules in a contract test.
21. domain/ and core/ (except core/firebase and core/localization) are pure Dart: no flutter, firebase, riverpod or go_router imports, directly OR transitively. A graph-based test enforces it.
22. No `Colors.*` (except Colors.transparent) and no `Color(0x` outside lib/app/theme/.
23. No TODO(step-N) may survive its step.
```

---

# Part A — Make Phase 1 verifiably green (P0)

## Step H1 — Green baseline, repo hygiene, dependency decision

**Goal:** a fresh clone passes `format`, `analyze`, `test`, rules tests and APK build on Linux CI. Everything after this builds on a green baseline.
**Fixes:** F-01, F-23, F-31.

```text
Read CLAUDE.md, PROGRESS.md and .github/workflows/ci.yml first. Work on a branch hardening/h1.

1. FORMAT + LINT. Run `dart format .` and fix every `flutter analyze` issue (26 info-level lints: require_trailing_commas and two removed unnecessary_import). Run the analyzer with `--fatal-infos` and get zero issues. Do not suppress lints with ignore comments.

2. FIX THE 3 FAILING TESTS. They are test-assertion bugs, not app bugs: test/app/router_test.dart "settings are reachable from the Family tab" and two tests in test/features/family/presentation/onboarding_flow_test.dart assert `routeInformationProvider.value.uri` after a `context.push`, which go_router 18 does not reflect. Change the assertions to check the screen that is on screen (e.g. find.byType(ThemeSettingsScreen)) and, where a path really matters, use `GoRouter.of(context).state`/`routerDelegate.currentConfiguration.last.matchedLocation`. Do NOT change production code to satisfy a test.

3. GOLDENS. Today they were generated on Windows; CI is ubuntu. Decide-by-default (D5): goldens are generated on Linux.
   a. Tag every golden test with @Tags(['golden']) and add dart_test.yaml declaring the `golden` tag.
   b. CI `build` job runs `flutter test --exclude-tags golden`.
   c. Add a new CI job `goldens` (runs on push to main and on workflow_dispatch) that runs `flutter test --tags golden`. Add a second workflow `update-goldens.yml` (workflow_dispatch only) that runs `flutter test --update-goldens --tags golden`, then uploads the changed PNGs as an artifact (zip) for me to download and commit. Document this in README ("never commit goldens made on Windows/macOS").
   d. Delete the Windows-made PNGs in test/**/goldens and the untracked test/**/failures folders; they will be regenerated on Linux by the workflow.

4. PIN THE TOOLCHAIN. In ci.yml replace `channel: stable` with an exact `flutter-version` (use the version in PROGRESS.md, Flutter 3.47.7 / Dart 3.13.5, or whatever `flutter --version` prints on my machine - ask me if unsure) and set the same lower bound in pubspec.yaml (`environment: sdk` and `flutter`). Add `fail-fast: false`.

5. REPO HYGIENE.
   - `git rm --cached` all tracked *.log files in the repo root (auth_test.log, full_test.log, verify_test.log, widget_test.log) and android/.kotlin/errors/*.log.
   - Append to .gitignore: `*.log`, `android/.kotlin/`, `android/.gradle/`, `**/failures/`, `.fvm/`.
   - Add `.gitattributes`: `* text=auto eol=lf`, plus `*.png *.ttf *.jar binary`. Run `git add --renormalize .`.
   - tools/setup.sh and the README "First-time setup" section describe creating android/ios and re-adding packages at "current versions" - that is obsolete and dangerous now. Replace with: prerequisites (Flutter version, JDK 17 for Android, JDK 21 + Node 24 for rules tests), `flutter pub get`, how to run dev/prod/emulator, how to run unit tests, golden policy, rules tests. Delete tools/setup.sh.
   - Remove ios/ from CI/README claims ("Android only") but keep the folder.

6. DEPENDENCY DECISION D1 (default: remove). grep proves freezed, freezed_annotation, json_annotation, json_serializable, riverpod_annotation, riverpod_generator and build_runner are never used. Remove them from pubspec.yaml, remove the build_runner row from README, regenerate pubspec.lock with `flutter pub get`. Change CLAUDE.md hard rule 8 to: "Riverpod (Notifier/AsyncNotifier), immutable hand-written models with ==/hashCode/copyWith, go_router with auth and family guards." Also run `flutter pub outdated` and tell me which direct dependencies have newer stable majors; do NOT upgrade anything in this step.

7. CI additions: in the `build` job add `flutter test --coverage` and print the overall percentage; add a step that fails if `grep -rn "TODO(step" lib` finds anything (will be fixed by H8, so for now make it a warning).

8. Append the rules from section 5 of PHASE1_HARDENING_ROADMAP.md to CLAUDE.md.

Finish with: files changed, exact commands to verify, assumptions.
```

**Done when:** on a fresh clone (Linux) `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test --exclude-tags golden`, the rules job and `flutter build apk --flavor dev -t lib/main_dev.dart` are green; the golden workflow produced PNGs you committed; `git ls-files | grep -E '\.log$|\.kotlin'` prints nothing.

---

## Step H2 — Connect to real Firebase, fix the indexes file, make release builds valid

**Goal:** the Phase 1 scenario works on a **real device against a real `familyhub-dev` project**, rules and indexes deploy cleanly, and a release APK can reach the internet.
**Fixes:** F-02, F-03, F-04, F-05, F-32.

**You do manually first** (the AI cannot do this):
1. In the Firebase console confirm both projects exist (`familyhub-dev`, `familyhub-prod`), plan = **Spark**, Authentication → Email/Password enabled, Firestore created (the location is permanent — pick the region closest to Bangladesh that is offered **[VERIFY in the console]**).
2. Add an Android app to each project: dev = `com.familyhub.family_hub.dev`, prod = `com.familyhub.family_hub`. Add your debug **SHA-1/SHA-256** to the dev app.
3. Install `firebase-tools` and `flutterfire_cli`; run `flutterfire configure` once per project/flavor to regenerate `lib/core/firebase/firebase_options_dev.dart`, `firebase_options_prod.dart` and download the two real `google-services.json` files into `android/app/src/dev/` and `android/app/src/prod/`.
4. In Google Cloud Console → APIs & Services → Credentials, **restrict each Android API key** to its package name + SHA-1.

```text
Read CLAUDE.md. Branch hardening/h2. I have already run flutterfire configure; the real firebase_options_*.dart and google-services.json files are in the tree.

1. .firebaserc: create it with aliases `dev` -> familyhub-dev and `prod` -> familyhub-prod (default dev). Add firebase/README.md with the exact commands:
   firebase deploy --only firestore:rules,firestore:indexes -P dev
   firebase emulators:start --only auth,firestore
   and how to run the rules tests.

2. INDEXES. Edit firebase/firestore.indexes.json: remove the two single-field indexes (collectionGroup `activity` and `auditLogs`, field createdAt) - Firestore creates single-field indexes automatically and the CLI rejects them. Keep every index that has two or more fields. Add tools/check_indexes.mjs (Node, no dependencies) that fails if any entry in `indexes` has fewer than 2 fields, and run it in the CI `rules` job. Then run `firebase deploy --only firestore:indexes -P dev` and paste the output into the PR description. If the CLI complains about anything else, fix it.

3. ANDROID MANIFEST. Add to android/app/src/main/AndroidManifest.xml:
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
   (the debug/profile manifests already have INTERNET; release did not). Build `flutter build apk --release --flavor prod -t lib/main_prod.dart` and verify the merged manifest (android/app/build/intermediates/merged_manifests/prodRelease/**/AndroidManifest.xml or `aapt dump permissions app-prod-release.apk`) contains INTERNET.

4. RELEASE SIGNING. In android/app/build.gradle.kts read signing from android/key.properties (already git-ignored) for the release build type. If key.properties is missing, the DEV flavor may fall back to the debug keystore but the PROD flavor must FAIL the release build with a clear message. Remove the "TODO: Specify your own unique Application ID" comment. Document in docs/RELEASE.md how to create and back up the keystore (never commit it).

5. PLACEHOLDER GUARD. In core/firebase/firebase_bootstrap.dart, when USE_EMULATOR is false, throw a StateError("Run flutterfire configure: firebase options still contain placeholders") if the resolved options' apiKey or appId contains the word "placeholder". Add a unit test for the guard (inject the options).

6. Update the Firestore rules deploy to dev: `firebase deploy --only firestore:rules -P dev`.

7. Do NOT add Crashlytics or App Check in this step, but add a section "Later (Phase 5)" to docs/RELEASE.md listing: App Check with Play Integrity (free on Spark) to protect the inviteCodes get; Crashlytics for crash reports.

Finish with: files changed, how to verify, assumptions.
```

**Manual verification checklist (do it, write the result into `PROGRESS.md`):** install the **dev** debug build on a real Android phone; sign up with a real email → verification mail arrives → verify → profile → create family; check in the Firebase console that `users/{uid}`, `families/{id}`, `members/{uid}`, `settings/*`, `activity`, `auditLogs` exist with the expected fields; install a second account on an emulator, join with the code, approve from the phone; confirm B lands on Home. Then build the **prod release** APK and confirm sign-in works (proves INTERNET).

**Done when:** the checklist above passes; `firebase deploy` of rules and indexes succeeds; `tools/check_indexes.mjs` runs in CI; release prod APK is signed with the release keystore.

---

## Step H3 — Offline correctness and the sync indicator

**Goal:** the app never mis-routes or duplicates data when the network is missing, and it *shows* when something is waiting to sync.
**Fixes:** F-06, F-07, F-08. Implements new rules 14–16.

```text
Read CLAUDE.md (including rules 14-16 added by H1). Branch hardening/h3. Cloud Firestore persistence is enabled; commit() futures only complete when the SERVER acknowledges, and a listener on a document that is not in the local cache emits exists=false with metadata.isFromCache=true. The current code treats both wrongly.

1. UNKNOWN vs ABSENT (core/firebase/doc_state.dart, pure Dart + a tiny Firestore adapter in core/firebase/):
   sealed class DocState<T> { Unknown(); Absent(); Present(T value); }
   Add `Stream<DocState<Map<String,dynamic>>> watchDoc(DocumentReference ref)` that listens with includeMetadataChanges: true and emits Unknown when (!exists && isFromCache), Absent when (!exists && !isFromCache), Present otherwise. Unit-test the mapping with fake snapshots.

2. USE IT. Change FirestoreProfileRepository.watchHasProfile/watchProfile and FirestoreMembershipRepository.watchMembership (both the users/{uid} and the members/{uid} document) to use watchDoc. Domain-facing stream types become `Stream<bool?>` / `AsyncValue`-friendly: Unknown must keep sessionPhaseProvider in `SessionPhase.loading` (never needsProfile / needsFamily). If Unknown lasts more than 8 seconds, SplashScreen must show a localized "Waiting for connection" message with a Retry button and, if cached data exists for the user, keep showing it (do not sign the user out). Add the ARB keys in bn and en.

3. WRITE OUTCOMES. In core/firebase add `enum WriteOutcome { committed, queuedOffline }` and replace guardFirestore for writes with `guardWrite<T>(Future<T> Function() commit, {Duration ackWait = const Duration(seconds: 8), bool requireServer = false})`:
   - requireServer == true: first probe the server with a cheap `get(const GetOptions(source: Source.server))` on `users/{uid}` (timeout 8 s). If the probe fails -> Failure(Network). Never start the batch when offline. Used by: CreateFamily, JoinWithCode, ApproveMember, RejectMember, DisableMember, ChangeRole, TransferAdmin, UpdateFamilySettings, CreateInvitation (rule 16 / D3).
   - requireServer == false: run the commit; if it has not completed after ackWait, return Success(WriteOutcome.queuedOffline) (the SDK keeps the write queued) and keep awaiting in the background (unawaited, errors logged). Used for later Phase 2 data and for SaveProfile.
   Keep guardFirestore (reads) with its 30 s timeout.
   Use cases keep returning Result<T>; the repository interfaces gain `Result<WriteOutcome>` where relevant. UI shows a calm "Saved on this device - will sync when online" snackbar for queuedOffline.

4. IDEMPOTENT RETRIES. CreateFamily/JoinWithCode must be safe to retry: the CreateFamilyScreen/JoinFamilyScreen controllers generate the familyId and eventId ONCE (when the screen's controller is created) and pass them in; a second tap reuses them. Add a unit test: failing the first attempt with Network then retrying produces exactly one family document in InMemoryBackend.

5. SYNC STATUS. Add core/firebase/sync_status.dart:
   - FirestoreTxRunner wraps every commit/transaction in a counter (increment before, decrement in whenComplete). Expose `ValueListenable<int> pendingWrites`.
   - `syncStatusProvider` (Riverpod) = { pendingWrites:int, offlineSince:DateTime? }, where offline = pendingWrites > 0 for more than 10 s OR a watchDoc listener has reported Unknown/isFromCache for more than 10 s after having been synced.
   - shared/widgets/sync_banner.dart: a slim banner (icon + label + count, never colour alone) shown above the pill bottom bar in AppShell only when pendingWrites > 0 or offline. Takes plain values (no Firebase imports). Add it to lib/app/gallery/gallery_sections.dart with all states so it gets goldens + the text-scale-2.0 overflow test automatically. Localized bn/en.
   - FakeTxRunner gets the same counter so widget tests can drive it.

6. TESTS (write with the code): Unknown never routes to /profile-setup or /family-choice; Absent does; commit timeout returns queuedOffline and does not cancel the write; requireServer fails fast when the probe fails and writes nothing; retry creates one family; banner states; overflow test passes; layer_boundaries_test still passes.

Finish with: files changed, how to verify (include a manual airplane-mode script), assumptions.
```

**Done when:** automated tests above pass **and** the manual script passes on a device: (1) log in online, kill app, airplane mode, reopen → you stay on Home (cached) or see "Waiting for connection", **never** the profile/family-choice screens; (2) airplane mode on the Create Family screen → immediate "You're offline" message, no family created; (3) go online and everything works; (4) no duplicate family documents in the console.

---

## Step H4 — Membership lifecycle: one family per user, leave, cancel, revoke

**Goal:** the membership state machine is complete and enforced in domain **and** rules.
**Fixes:** F-09, F-10, F-24 (partly). Implements rule 17.

```text
Read CLAUDE.md. Branch hardening/h4. State machine (write it as a table in docs/membership_state_machine.md and as a unit test that walks it):
  none -> pending (join) -> active (approve) | rejected(removedAt) | cancelled(self removedAt)
  active -> disabled (admin) | left (self, leftAt) ; disabled -> active (admin re-enable)
  left/rejected/cancelled -> may create or join a family again.  disabled (by admin) -> may NOT join elsewhere until re-enabled or the admin releases them.

DOMAIN (pure Dart, one class per file, Result<T>, requirePermission first, audit+activity through the existing event writer in the SAME batch):
 1. ONE-FAMILY GUARD: add `FamilyRepository.getUserFamilyPointer(uid)` (reads users/{uid}.familyId and that member document). CreateFamily and JoinWithCode first call a shared `ensureFreeToJoinAnyFamily` helper that returns Conflict(code:'already_in_family') when the pointer exists and the member is pending/active/admin-disabled (not removed, not left, not cancelled).
 2. LeaveFamily(actorUid, familyId): self only. Sets status=disabled + leftAt=now. If the actor is the only active admin -> Conflict('last_admin') (they must TransferAdmin first). Treat `leftAt != null` as Membership.none for routing (update FamilyMappers.membershipFromMember and its test) so the router sends them to /family-choice.
 3. CancelJoinRequest(actorUid, familyId): pending member only; sets removedAt=now (same field the rejection path uses).
 4. RevokeInvitation(actorUid, familyId, code): permission inviteMembers; only active codes; sets status=revoked on BOTH inviteCodes/{code} and families/{f}/invitations/{code} in one batch.
 5. ReleaseDisabledMember is NOT needed: admin re-enable already exists via ApproveMember; make sure the Members screen offers it for disabled members and that the use case test covers it.

DATA/RULES (edit firebase/firestore.rules AND firebase/rules_test/ in the same commit; one allowed + one denied test per new rule):
 - users/{uid} update: `familyId` may change only if it is absent, unchanged, or the OLD member document is missing, has removedAt != null, or has leftAt != null. (Use get() on the old memberPath inside a helper `familyPointerChangeOk()`.)
 - members self-update path for LEAVE: isSelf(m) && isActiveMember(f) && resulting status == 'disabled' && leftAt == request.time-or-timestamp && affectedKeys().hasOnly(['status','leftAt','updatedAt','updatedBy']) && role unchanged.
 - members self-update path for CANCEL: isSelf(m) && resource.status == 'pending' && affectedKeys().hasOnly(['removedAt','updatedAt','updatedBy']).
 - inviteCodes and invitations update by a MANAGER of that family: only active -> revoked, affectedKeys().hasOnly(['status','updatedAt','updatedBy']).
 - keep every existing rule/test green.

PRESENTATION:
 - Family tab: "Leave family" (confirmation dialog explaining history is kept; disabled with a localized reason + icon via PermissionGate/disabled button while the user is the only admin).
 - Pending screen: "Cancel request" button next to Sign out.
 - Invitations screen: per-code "Revoke" action (manager only) with confirm; revoked/used/expired codes shown with an icon+label status.
 - All new strings in bn and en ARB; update the generated l10n files by running `flutter gen-l10n` (do not hand-edit generated files).

TESTS: use-case tests (InMemoryBackend) for every transition including the last-admin guard, already_in_family on create AND join, cancel, revoke, leave then re-join; widget tests for leave and cancel; rules tests; the Phase 1 acceptance scenario test extended with leave+rejoin.

Finish with: files changed, how to verify, assumptions.
```

**Done when:** all tests green; the state-machine doc matches the code; manually: A leaves, lands on family-choice, joins another family; a user who is already a member cannot create or join (try with a debug button/unit test) and the rules deny a direct `familyId` overwrite.

---

# Part B — Security and architecture hardening

## Step H5 — Firestore rules v2: validation, log integrity, invitations, verified email, contract tests

**Goal:** the rules reject malformed data and forged logs, and the Dart mappers are proven compatible with the rules automatically.
**Fixes:** F-11, F-12, F-13, F-14, F-15, F-16. Implements rules 18 (part) and 20.

```text
Read CLAUDE.md and firebase/firestore.rules. Branch hardening/h5. Rules and rules tests change in the SAME commit; run the emulator suite after every sub-step. Keep all existing tests green; add one allowed + one denied test for every new condition.

A. VALIDATION HELPERS (top of firestore.rules):
   function str(v, lo, hi) { return v is string && v.size() >= lo && v.size() <= hi; }
   function optStr(d, k, hi) { return !(k in d.keys()) || d[k] == null || str(d[k], 0, hi); }
   function memberProfileOk(d) { return str(d.get('fullName',''),1,80) && optStr(d,'nickname',40) && relationshipOk(d) && optStr(d,'spouseId',40) && optStr(d,'avatarKey',40) && optStr(d,'inviteCode',16); }
   Apply memberProfileOk to: family-creation member create, join create, rejoin (#5), self-edit (#6) and the admin update (#3). Apply the same string limits to users/{uid}.fullName/nickname.
   Tests: join with fullName as a number -> denied; with a 5000-char name -> denied; valid -> allowed.

B. CLOSED KEY SETS: add `request.resource.data.keys().hasOnly([...])` (exact lists derived from FamilyMappers) to members, families, inviteCodes, invitations, settings/{s}, activity, auditLogs. A document with an unknown field is denied. Keep the lists in ONE place in the rules file as functions (memberKeys(), familyKeys() ...) and mirror them in the Dart mapper tests (see D).

C. LOG INTEGRITY (activity + auditLogs create):
   - request.resource.data.actorId == request.auth.uid and createdBy == actorId;
   - `type` in a closed list (family.created, member.requested, member.approved, member.rejected, member.disabled, member.role_changed, member.admin_transferred, member.left, member.cancelled, invitation.created, invitation.revoked, family.updated) - the same list as the Dart `AuditEventType` constants (H8 centralises them; for now create `lib/core/audit/audit_event_type.dart` with the constants and a test that compares them to the list parsed from firestore.rules);
   - `refType` in a closed list, `refId` str(0,64), `params` is a map with <= 8 keys;
   - NEW field `recordedAt == request.time` (the data layer writes it with FieldValue.serverTimestamp(); keep the client `createdAt` as the "when it happened on the device"). Do NOT compare createdAt with request.time: queued offline writes would be rejected.
   Data layer: add a `ServerTime` sentinel in core/firebase (pure marker class) that FirestoreTxRunner converts to FieldValue.serverTimestamp() and FakeTxRunner converts to the injected clock; use it for recordedAt.

D. INVITES: 
   - inviteCodes update to `used` must happen in the SAME batch that creates the caller's pending member document: existsAfter(memberPath(familyOf(code), uid)) && getAfter(...).data.inviteCode == code && getAfter(...).data.status == 'pending'.
   - families/{f}/invitations/{i} update: require resource.status == 'active' && new status in ['used','revoked'] and apply the same joiner-batch check for 'used' or isManager(f) for 'revoked'.
   Tests: a stranger cannot burn a code; a stranger cannot flip a mirror; a code cannot be 'used' without a member doc.

E. VERIFIED EMAIL: add `function verified() { return signedIn() && request.auth.token.email_verified == true; }` and require it for: families create, members create/update, inviteCodes get/create/update, invitations create/update, activity/auditLogs create. Leave users/{uid} (profile + preferences) writable by the owner without it, and make preferenceSyncProvider start only after emailVerified so it does not spam denied writes.
   IMPORTANT [VERIFY]: the ID-token claim does not update when the user verifies in the browser. After `reload()` in FirebaseAuthRepository.reloadUser() call `await user.getIdToken(true)` so the claim refreshes; add this to the repository and its fake, and test it. Test helpers: `asUser(uid, {verified = true})`; add a denied test for an unverified user creating a family.

F. CONTRACT TESTS (the Dart <-> rules seam that is untested today):
   - test/contract/rules_fixtures_test.dart (flutter test): builds REAL payloads with FamilyMappers.* (family doc, member join, member change, invitation, invitation used, event map with recordedAt marker, profileToMap) and writes them as JSON to firebase/rules_test/fixtures/*.json (Timestamp -> {"__ts": iso}, ServerTime -> {"__serverTime": true}). Commit the fixtures.
   - firebase/rules_test/contract.test.mjs: loads each fixture, rehydrates Timestamps/serverTimestamp, and asserts it is ALLOWED in the scenario it belongs to (create family batch, join batch, approve, role change, create invite...).
   - CI: run the Dart fixture test first, then `git diff --exit-code firebase/rules_test/fixtures` so a mapper change that is not reflected in the fixtures (or breaks the rules) fails the build.

G. Update the header comment of firestore.rules (it still lists "Collections covered today (roadmap Steps 6-9)") and CLAUDE.md "Permissions" section.

Finish with: files changed, the emulator test output summary, assumptions.
```

**Done when:** `npm run test:emulator` green with the new cases; the fixture drift check is in CI; changing a mapper key without updating rules makes CI fail.

---

## Step H6 (optional, P2) — Make "never zero admins" a rule, not just client code

**Goal:** rules guarantee at least one active admin even under concurrent edits.
**Fixes:** F-17. **Skip if you accept the (small) residual risk and keep the documented client-side guard.**

```text
Read CLAUDE.md and firebase/firestore.rules. Branch hardening/h6. Decision D4: at most 3 admins per family.

Design: families/{f}.adminIds is a list of 1..3 uids of ACTIVE admins, maintained by the same batch that changes a member's role/status.
 - CreateFamily writes adminIds:[creator].
 - Any batch that changes an admin member (role away from admin, status away from active, removedAt set, leftAt set) or promotes someone to admin MUST also update families/{f}.adminIds (extend FirestoreFamilyRepository.saveMembers/LeaveFamily to compute and write it).
 - Rules: on the family document update, every uid in getAfter(family).adminIds must have getAfter(memberPath(f, uid)) with role=='admin' && status=='active' && removedAt==null && leftAt==null (check indices 0,1,2 with a helper adminAfterOk(i)); adminIds.size() between 1 and 3.
 - Rules: on a member update that takes an admin out of the active-admin set, require the family doc to be written in the same batch (existsAfter on the family with updatedAt == request.time marker) so the check above runs.
 - Watch the access-call budget: a batch may use at most 20 document-access calls in total; add an emulator test that runs TransferAdmin (2 member writes + family + logs) and the createFamily batch and proves they pass.
STOP CONDITION: if the TransferAdmin batch cannot be made to pass within the access-call limit, revert this step and keep the client-side guard; document the decision in docs/decisions/.
Tests: two admins demoting each other in two separate batches -> the second is denied; transfer admin allowed; leave as the only admin denied; adminIds forged -> denied.
Finish with: files changed, how to verify, assumptions.
```

---

## Step H7 — One permission source for the UI and a ratified matrix

**Goal:** the UI, use cases and rules share one matrix; the owner signs off the matrix.
**Fixes:** F-18, F-19. Implements rule 19.

```text
Read CLAUDE.md, lib/core/permissions/*, lib/features/family/domain/membership.dart and the screens that call isAdmin / isModerator / canManageMembers. Branch hardening/h7.

1. Provide the UI entry points:
   - `currentActorProvider` (PermissionActor?) derived from the member document (role + status + removed/left) - in features/family/presentation, not in core.
   - `canProvider` as a Riverpod family keyed by a small value class `PermissionQuery(permission, {ownerId})` -> bool, reading PermissionSettings from the family (see 3).
   - an extension `ref.can(Permission p, {String? ownerId})`.
2. Replace EVERY direct role test in presentation/ (family_screen, members_screen, roles_screen, invitations_screen, family_settings_screen, member_profile_screen ...) with `ref.watch(canProvider(...))` or the existing PermissionGate widget (use `disable` mode with the localized reason where the action is visible-but-blocked, `hide` where it is irrelevant). Delete Membership.isAdmin / isModerator / canManageMembers (keep `role` as data).
3. SETTINGS: create the document families/{f}/settings/permissions at CreateFamily with defaults { moderatorManagesFinance: true, membersViewFamilyReports: true, membersViewAllContributions: false, membersCanInvite: false, choreVerificationEnabled: false } and a rules block (read: active members; write: admin). Load it into PermissionSettings through a provider; PermissionPolicy uses it. Extend the table-driven test (every permission x role x each setting) and the rules tests.
4. MODULE HOOK: change FamilyModule.requiredPermission from String? to Permission? and make the shell hide a tab when !can. Remove the TODO(step-10).
5. NEW TEST test/architecture/no_role_checks_in_ui_test.dart: scans lib/features/*/presentation and lib/shared for `.isAdmin`, `.isModerator`, `canManageMembers`, `MemberRole.admin`, `MemberRole.moderator`, `Role.admin` and fails if found.
6. RATIFICATION DOCUMENT: generate docs/permission_matrix.md = a table of every Permission x admin/moderator/member (+ which family setting changes it) produced FROM the code by a test (so it cannot drift), and a column "Project spec section 6" with the spec's wording next to it. Flag every cell where the code differs from the spec ("Manage budgets/contributions: moderator Configurable", "View reports: according to family policy", "Manage family and invitations: moderator Limited", "Change family settings: moderator Limited").
Finish with: files changed, how to verify, assumptions, and the list of cells I must decide.
```

**You do:** read `docs/permission_matrix.md`, tick/change each flagged cell (decision D6), tell the AI to apply them (one small follow-up commit).
**Done when:** the architecture test passes, no screen tests roles directly, `PermissionGate` is used by at least the Family tab and Members screen, and the matrix doc is generated by a test.

---

## Step H8 — Pure domain, one audit writer, TODO cleanup

**Goal:** `domain/` is really pure Dart (provable), Phase 2 repositories can write audit/activity in one line, no leftover step TODOs.
**Fixes:** F-20, F-21, F-22. Implements rules 18, 21, 23.

```text
Read CLAUDE.md. Branch hardening/h8.

1. CLOCK: move `clockProvider` out of core/utils/clock.dart into core/utils/clock_provider.dart (the only file in core/utils that may import flutter_riverpod). clock.dart becomes pure Dart. Update imports.
2. MODULE FLAGS: move ModuleFlags + ModuleFlagsRepository from lib/modules/module_flags.dart to lib/features/family/domain/module_flags.dart (they describe family settings). lib/modules/ may import the family domain; the family domain must not import lib/modules/.
3. AUDIT: create lib/core/audit/audit_event.dart (AuditEvent {id, type, actorId, refType, refId, params: Map<String,String>, at}) and audit_event_type.dart (constants from H5). Move FamilyEvent to it (keep a typedef FamilyEvent = AuditEvent for one release if it reduces churn, then delete). Create lib/core/firebase/audit_writer.dart: `AuditWriter.write(BatchContext b, String familyId, AuditEvent e)` writes BOTH families/{f}/activity/{id} and families/{f}/auditLogs/{id} using the mapper, including the recordedAt ServerTime marker. FirestoreFamilyRepository._writeEvent is replaced by it. Document in CLAUDE.md: every Phase 2 repository must use AuditWriter.
4. STRONGER LAYER TEST: rewrite test/architecture/layer_boundaries_test.dart to build the import graph of lib/ (parse `import`/`export` lines, resolve package:family_hub paths) and assert:
   a) nothing reachable (transitively) from lib/features/*/domain/**, lib/core/permissions/**, lib/core/errors/**, lib/core/utils/** (except clock_provider.dart), lib/core/audit/** imports package:flutter*, flutter_riverpod, go_router, firebase_*, cloud_firestore;
   b) presentation/, shared/, modules/ never import data/ or Firebase (existing check);
   c) lib/app/ reaches data/ only from bootstrap.dart;
   d) no feature's domain imports another feature's presentation or data.
   Keep the detector self-tests. core/localization and core/firebase are documented exceptions (they are Flutter/Firebase adapters); core/localization/locale_prefs.dart should import `dart:ui` Locale instead of material if possible.
5. Delete the TODO(step-9) comments in module_providers.dart, membership_providers.dart, profile_providers.dart and the TODO(step-10) in family_module.dart (the latter is replaced in H7). Add test/architecture/no_step_todos_test.dart that fails if `TODO(step-` appears in lib/ or test/. Turn the CI warning from H1 into a hard failure.
6. Add the sealed-failure exhaustiveness check: a test that every AppFailure subtype has a localized message mapping (switch without default) so adding a failure type cannot be forgotten.
Finish with: files changed, how to verify, assumptions.
```

**Done when:** the graph test passes; mutating `family.dart` to import `package:flutter/material.dart` or `clock.dart` to import riverpod makes it fail; no `TODO(step-` in the tree.

---

# Part C — Complete the Phase 1 feature set and polish (P1)

## Step H9 — Account lifecycle and privacy

**Goal:** the account features the spec lists under "Family & Settings" and "Security" exist.
**Fixes:** F-24 (account deletion, change password, sign-out hygiene). Uses decisions D2, D3.

```text
Read CLAUDE.md. Branch hardening/h9. Hard rule 5 still applies: soft delete only for app data; the Firebase Auth user itself may be deleted.

1. CHANGE PASSWORD: ReauthenticateWithPassword + ChangePassword use cases (domain Result<T>), FirebaseAuthRepository methods (map `requires-recent-login`, `wrong-password`/`invalid-credential`, `weak-password`), screen /settings/security reachable from the Family tab (full-screen route like the theme/language screens, reachable only when signed in). Min 8 chars (same validator as sign-up).
2. DELETE ACCOUNT (D2 default: keep display name in history):
   DeleteAccount use case: (a) refuse with Conflict('last_admin_has_members') if the user is the only admin of a family that still has other active members (tell them to transfer admin first); (b) re-authenticate; (c) in ONE batch: LeaveFamily semantics (if a member), set users/{uid}.deletedAt/deletedBy, clear profile PII fields that are not needed for history (keep fullName on member docs); (d) delete the Firebase Auth user; (e) sign out and wipe local state. If (d) fails after (c), the app must be able to resume (retry deletion on next launch when users/{uid}.deletedAt is set but Auth still exists).
   Rules: users/{uid} stays non-deletable; allow the owner to set deletedAt/deletedBy; update the rules comment "Closing an account is not a feature" and add tests.
   UI: "Delete my account" at the bottom of /settings/security, two-step confirmation, explains what is kept.
3. SIGN-OUT HYGIENE: on sign-out (and on deletion) write a SharedPreferences flag `wipeFirestoreCacheOnNextStart=true`; in bootstrap, BEFORE Firestore is used, if the flag is set call `FirebaseFirestore.instance.clearPersistence()` and clear the flag. [VERIFY in the current cloud_firestore docs whether terminate()+clearPersistence() can be used immediately at sign-out without restarting; if yes, do it at sign-out as well.] Reason: a second person signing in on the same phone must not find the first person's cached family data on disk. Also stop and cancel the preference-sync listeners (already done by the uid listener) and make sure ThemeController/LocaleController do not leak the previous user's remote prefs (remote applies once per sign-in - add a test for user A -> sign out -> user B).
4. Add the ARB keys (bn + en), update `flutter gen-l10n`, add screens to the dev gallery only if they introduce new shared widgets.
TESTS: use-case tests (including last-admin-with-members, resume-after-partial-failure), widget tests for both flows, rules tests, fake auth repository extended.
Finish with: files changed, how to verify, assumptions.
```

**Done when:** you can delete a throw-away test account on a device and its family history remains intact; a second account signing in on the same phone sees none of the first account's data after a restart.

---

## Step H10 — Data consistency and quality

**Goal:** fix the small data-layer defects and make the audit trail language-neutral.
**Fixes:** F-24 (relationships), F-25, F-26.

```text
Read CLAUDE.md. Branch hardening/h10.

1. saveProfile: stop rewriting createdAt/createdBy. In FirestoreProfileRepository.saveProfile use a transaction: read users/{uid}; if the document has no createdAt write createdAt/createdBy/schemaVersion once, otherwise only updatedAt/updatedBy and the profile fields. Test with FakeTxRunner (first save sets createdAt, second save does not change it).
2. watchFamily: replace the asyncMap-with-extra-gets by a combineLatest of the three document streams (families/{f}, settings/general, settings/modules). Add `combineLatest3` to core/utils/stream_utils.dart with unit tests (emits after all have emitted once; propagates errors; cancels all on cancel). Remove the reliance on updateFamily touching the family document.
3. ActionController: make the per-screen providers `NotifierProvider.autoDispose` (flutter_riverpod 3 API) so state is dropped when the screen leaves; delete every `Future.microtask(() => ...reset())` workaround; keep `run()` semantics. Update tests.
4. LANGUAGE-NEUTRAL EVENTS: AuditEvent already carries type + params (H8). Remove every hard-coded English `summary` string from use cases; params example: {familyName}, {memberName}, {newRole}. Add `AppLocalizations.activityText(type, params)` (bn + en) used by any screen that shows activity (none yet; add the function + test now so Phase 2 uses it). Update the rules `summary` limit to `params` (done in H5) and the mapper/fixtures.
5. CONFIGURABLE RELATIONSHIPS (spec section 3: "Keep the list configurable"):
   - `families/{f}/settings/relationships` = { items: [ {id, labelBn, labelEn, spouseRelevant, builtIn} ] }, created at CreateFamily with the 10 built-in entries (father ... other, incl. housewife).
   - Family settings screen: admin can add/rename/disable custom entries (never delete built-ins; ids are lowercase [a-z][a-zA-Z0-9_]{1,30}).
   - ProfileSetupScreen and MemberProfile read the list from a provider (fall back to the built-ins when offline/unknown); stored value stays the id; an unknown id renders as "Other".
   - Rules: relationshipOk becomes a pattern/length check on the id (no longer a closed enum) and the new settings doc has admin-only write + tests.
   - `Relationship` enum in domain becomes `RelationshipId` value object + `RelationshipCatalog`; update mappers, fixtures (H5 contract), and tests.
6. Membership model: carry `leftAt` and the member status so UI does not need the full Member for simple checks (follow-up to H4).
Finish with: files changed, how to verify, assumptions.
```

---

## Step H11 — UI conformance, accessibility and the missing Step 4 tests

**Goal:** the shared design system is enforced by tests, every Phase 1 screen has loading/empty/error/offline states and passes accessibility checks.
**Fixes:** F-27, F-28, F-29.

```text
Read CLAUDE.md. Branch hardening/h11.

1. COLOURS (rule 22): replace Colors.white/Colors.black87 in shared/widgets/app_avatar.dart and item_thumb.dart by two new tokens `placeholderOnLight` and `placeholderOnDark` in AppTokens (both themes, hand-tuned), choose per background luminance, and extend test/app/theme/contrast_test.dart so EVERY placeholderPalette entry reaches >= 4.5:1 with the chosen foreground in every available theme. Extend test/app/theme/no_raw_color_test.dart to also fail on `Colors.` (except `Colors.transparent`) and `Color.fromRGBO/fromARGB` outside lib/app/theme/.
2. FILE SIZE: split theme_settings_screen.dart (377 lines) and language_settings_screen.dart (321) so every widget file is <= 300 lines (extract ThemePreviewCard, ThemeGrid, LanguageOptionTile, DigitsSwitchTile into the same feature's presentation/widgets/). Add test/architecture/file_size_test.dart: fail when any non-generated lib/ file (except lib/app/gallery/gallery_sections.dart, lib/app/theme/app_tokens.dart, lib/app/theme/theme_builder.dart and the l10n generated files) exceeds 300 lines.
3. SCREEN STATES (rule 10): every Phase 1 screen that reads a stream shows LoadingView (skeleton), EmptyState, ErrorView with retry, and (from H3) the offline banner via AppShell. Replace bare CircularProgressIndicator in members_screen, roles_screen, invitations_screen, family_settings_screen with LoadingView; add error handling to member_profile_screen and family_screen; keep messages localized.
4. SCREEN HARNESS: test/support/screen_states.dart pumps each Phase 1 screen with provider overrides for {loading, data, empty, error, offline} in {modern_light, modern_dark} x {bn, en} at text scale 2.0, and asserts: no overflow, no unlocalized text (reuse the existing hard-coded string guard), and the Flutter accessibility guidelines `meetsGuideline(androidTapTargetGuideline)`, `meetsGuideline(labeledTapTargetGuideline)`, `meetsGuideline(textContrastGuideline)`. Fix whatever it finds (touch targets >= 48dp).
5. REDUCED MOTION: confirm every animation (LoadingView, ProgressRing, PillBottomBar, page transitions) honours MediaQuery.disableAnimations; add a test per animated widget.
6. STEP 4 DEBT: (a) golden test for ThemeSettingsScreen in 2 themes x 2 languages (tagged golden), (b) widget test: tapping the dark card changes Scaffold backgroundColor in the next frame, (c) test: registering a third AppThemeSpec in a test makes a third card appear, (d) golden for LanguageSettingsScreen.
7. Auth goldens: regenerate on Linux through the workflow from H1.
Finish with: files changed, how to verify, assumptions.
```

---

## Step H12 — Phase 2 foundations (small, cheap, prevents rework)

**Goal:** the things Step 12-14 will need on day one exist and are tested.
**Fixes:** F-30 and prepares rules 11 and 20 for new collections.

```text
Read CLAUDE.md and ROADMAP.md Steps 12-14. Branch hardening/h12. Do NOT implement any Bazar feature.

1. FAMILY TIME: `familyTimezoneProvider` (String, from familyProvider / settings/general, default Asia/Dhaka) and a `FamilyDateKeys` service in core/utils (pure Dart, takes Clock + timezone): today(), dateKeyOf(DateTime utc), monthKeyOf(...), monthRange(MonthKey). Providers wire it to the family timezone and the clockProvider. Unit tests around Dhaka midnight (UTC 18:00), month boundary, leap day, and a family that changes timezone.
2. SEED HOOK: CreateFamily accepts `List<FamilySeeder> seeders` (interface: `void seed(BatchContext b, String familyId, SeedContext ctx)`), default empty; they run inside the same batch (Firestore batch limit is 500 writes - assert it in the runner). Step 12's SeedDefaultCatalog will plug in without editing CreateFamily. Test with a fake seeder.
3. RULES SCAFFOLD: in firestore.rules add reusable helpers `canReadFamilyData(f)` (active member), `canWriteOwnRecord(f)` (active + createdBy==uid), `moneyOk(data, key)` (uses isNonNegativeInt), `monthKeyOk(s)`/`dateKeyOk(s)` (regex on the string), `softDeleteOnly()` (update may only set deletedAt/deletedBy/updatedAt/updatedBy). Keep the default-deny block. Add docs/new_collection_checklist.md (rules + tests + indexes + FirestorePaths + AuditWriter + permission + gallery/golden if widgets) and a template firebase/rules_test/templates/collection.test.mjs.tmpl.
4. QUERY DISCIPLINE (rule 11): add core/firebase/query_limits.dart (default page sizes, `kMaxListenerDocs`) and a grep test test/architecture/no_unbounded_queries_test.dart: in every lib/features/**/data/*.dart, each `.snapshots()` / `.get()` call on a collection must be preceded in the same expression by `.limit(` (allow-list for single-document reads).
5. DOCS: docs/decisions/0001-offline-policy.md (D3), 0002-one-family-per-user.md, 0003-audit-writer.md, 0004-no-codegen.md (D1), 0005-golden-policy.md (D5). Update README, CLAUDE.md "Folder structure", PROGRESS.md (mark H-steps).
6. Make sure `FirestorePaths` has a unit test that every path used in firestore.rules and in FirestorePaths agree (parse the rules `match` lines and compare collection names).
Finish with: files changed, how to verify, assumptions.
```

---

# Part D — Re-acceptance

## Step H13 — Final verification and sign-off

**Goal:** prove the Phase 1 acceptance gate end to end, then freeze.

```text
Read CLAUDE.md and PHASE1_HARDENING_ROADMAP.md. Branch hardening/h13. Make NO feature changes. Produce evidence.

1. Run on a clean clone (Linux): dart format --set-exit-if-changed ., flutter analyze, flutter test --exclude-tags golden, flutter test --tags golden, the full rules suite (npm run test:emulator), tools/check_indexes.mjs, flutter build apk --flavor dev and --flavor prod --release. Save the summaries (counts only) in docs/phase1_evidence.md.
2. Print a coverage summary per top-level folder (core, features/auth, features/family, features/onboarding, app, shared). Anything under 70 percent in core/ or features/*/domain must be listed with the untested public functions.
3. Security review checklist (answer each with file/line evidence in docs/phase1_security_review.md): every collection in firestore.rules has hasOnly key sets and type checks; no rule uses get() on user-controlled ids without an existence guard; logs append-only and actor-bound; invites single-use, revocable, same-batch; one family per user; email_verified required; no hard deletes anywhere; unauthenticated access denied; cross-family reads denied (tests listed).
4. Manual test matrix (I will execute it; generate it as a checkbox table in docs/phase1_manual_test.md) with TWO real devices/accounts, Bangla and English, light and dark, online and airplane mode: sign-up -> verify -> profile -> create family -> invite -> join -> pending -> approve -> roles -> disable/re-enable -> transfer admin -> leave -> cancel request -> revoke invite -> change password -> delete account -> offline create-family -> offline cold start -> theme/language persistence across restart and across a second sign-in.
5. Update PROGRESS.md: every Step 1-11 and H1-H13 with status, evidence link, and remaining known limitations (honest list).
6. Tag `phase-1-complete` ONLY if everything above is green; otherwise list the blockers.
```

**Done when (re-acceptance gate):**

- [ ] CI fully green on Linux (format, analyze, tests, goldens, rules, indexes check, dev APK, prod release APK)
- [ ] Phase 1 scenario passes on **real devices against the real dev Firebase project** (manual matrix in H13)
- [ ] Offline script from H3 passes
- [ ] Rules v2 + contract fixtures green; Dart mappers proven compatible with rules
- [ ] UI contains no direct role checks; matrix ratified by you
- [ ] `grep -rn "TODO(step" lib test` is empty; domain purity test green
- [ ] `PROGRESS.md` honest and current; tag `phase-1-complete`

---

## 6. Hand-off to Phase 2 (what changes in `ROADMAP.md` Step 12–14 after this)

| Phase 2 step | Use this from the hardening |
| --- | --- |
| Step 12 Categories/items/seed | `FamilySeeder` hook (H12), `AuditWriter` (H8), rules scaffold + checklist (H12), `canProvider(Permission.manageCatalogAndBudgets)` (H7) |
| Step 13 Expense domain | `WriteOutcome`/queuedOffline (H3), `FamilyDateKeys` (H12), `moneyOk` rules helper (H12), `ServerTime` `recordedAt` for audit (H5), `settings/permissions` (H7: moderator finance toggle) |
| Step 14 Expense form | `SyncBanner` + `syncStatusProvider` (H3), idempotent ids per attempt (H3), screen-state test harness (H11) |

Keep adding one rule to the end of every Phase 2 step prompt: *"Extend firestore.rules, firebase/rules_test and the Dart→rules contract fixtures in the same commit; use AuditWriter; use canProvider/PermissionGate; handle offline via WriteOutcome."*
