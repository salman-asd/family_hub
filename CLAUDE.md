# Family Hub - project context (read before every task)

You are a senior Flutter engineer building 'Family Hub', a Bangla-first household app (bazar and family finance + family chores) for one family. Android first, iOS-ready. Backend: Firebase Auth + Cloud Firestore on the free Spark plan. No Cloud Functions, and no hard dependency on Cloud Storage.

ARCHITECTURE: feature-first Clean Architecture. Each feature has data/, domain/, presentation/. domain is pure Dart (no flutter or firebase imports). presentation never touches Firestore: screen -> Riverpod controller -> use case -> repository interface. data implements repositories and maps Firestore documents to domain entities through mappers.

## HARD RULES
1. Money is integer paisa in a Money value object. Quantities are integer milli-units. Never double.
2. Time-based records store a UTC Timestamp plus dateKey (yyyy-MM-dd) and monthKey (yyyy-MM) computed in the family timezone (default Asia/Dhaka). Use an injected Clock; never call DateTime.now() in domain code.
3. All writes go through use cases. A use case checks permission (PermissionPolicy), applies business rules, writes through a repository, and writes audit and activity entries in the same batch/transaction where required.
4. Deterministic IDs: occurrences {templateId}_{yyyyMMdd}; budgets {yyyy-MM}; contribution plans {yyyy-MM}_{memberId}.
5. Soft delete only (deletedAt, deletedBy). Every document has createdAt, createdBy, updatedAt, updatedBy, schemaVersion.
6. No raw Color(0x...) or hex outside lib/app/theme/. Screens read tokens via context.tokens.
7. No hard-coded user-visible strings. Use ARB localization (bn default, en). Test long Bangla strings for overflow.
8. Riverpod (Notifier/AsyncNotifier), immutable hand-written models with ==/hashCode/copyWith (no code generation; see docs/decisions), go_router with auth and family guards.
9. Use cases return Result<T> with a sealed AppFailure. UI maps failures to localized messages. No silent catches.
10. Business rules live in domain with unit tests. Every screen handles loading, empty, error and offline states.
11. Queries are bounded by a monthKey/dateKey range and a limit. One listener per screen; cancel on dispose.
12. Every permission is enforced in Firestore Security Rules as well as the UI.
13. Accessibility: touch targets >= 48dp, status never by color alone (icon + label + color), text scales with system font size.

## Layer boundaries
| Layer | May import | Must never import |
| --- | --- | --- |
| presentation | domain, shared, core | data, firebase packages |
| domain | Dart core, freezed, core value objects | flutter, firebase, any I/O |
| data | domain, firebase packages | presentation |

Naming: snake_case files; FooRepository (interface), FirestoreFooRepository (impl), FooController, FooScreen, FooMapper, AddFooUseCase. One class per use case file. Split widget files over ~300 lines.

## Folder structure
lib/ main_dev.dart, main_prod.dart; app/ (app, router, bootstrap, flavor, theme/); core/ (errors, utils, firebase, localization, notifications, permissions, constants); shared/ (widgets, services); modules/; features/ auth, onboarding, family, dashboard, settings, notifications, bazar/{expenses, items_categories, budgets, contributions, advances, reports, import}, chores/{templates, duty_groups, occurrences, calendar, swaps, availability, comments, achievements} (each: data/ domain/ presentation/). test/ mirrors lib/. firebase/ holds firestore.rules, firestore.indexes.json, rules_test/.

## WORKING METHOD
Before coding, list the files you will create or change. Write tests together with the code. Afterwards run dart format, flutter analyze and flutter test and report the results. Do not add packages not named. When something depends on current Firebase pricing, quotas, or package versions, check official docs instead of guessing. If an instruction is ambiguous, state your assumption and continue; ask only when a wrong guess would be expensive. End every task with: files changed, how to verify, anything you assumed.

## DEFAULT DECISIONS (until changed)
Teal accent token; chore verification off by default; absence policy A (ask for cover); members see only their own contributions; equal-split contributions; onion and potato are items under Vegetables; client-side scoring; Hub Level shown as a plant; Android only; Spark plan only.

## Rules extension (from Step 10 onward)
Every step that adds a collection must extend `firebase/firestore.rules` AND the rules tests in `firebase/rules_test/` in the same commit. For every rule there must be one allowed case and one denied case. Run them with:

```
npx firebase emulators:exec --only firestore --project demo-family-hub \
  "npm --prefix firebase/rules_test test"
```
(a JDK 21+ must be on `JAVA_HOME`/`PATH`; CI runs this in the `rules` job).

## Routing and session (from Step 8)
- Navigation is decided only by `lib/app/router.dart` (guards = `resolveRedirect`). Screens never navigate on auth/membership changes themselves.
- Providers live in `presentation/` (or `app/`), never in `domain/`. `test/architecture/layer_boundaries_test.dart` enforces the layer table.
- Anything marked `TODO(step-9)` (placeholder session, gate screens) is throwaway and must be deleted in Step 9.

## Data model additions (from Step 9, extends roadmap 12.2)
- `users/{uid}`: profile fields (`fullName`, `nickname`, `gender`, `relationship`, `spouseId`, `avatarKey`), **`familyId`** (set when the user creates or joins a family), and `preferences {themeId, themeMode, language, banglaDigits}`.  "Has a profile" means `fullName` is non-empty (the document may exist earlier because preferences are merged into it).
- `inviteCodes/{code}` -> `{familyId, role, status active|used|revoked, expiresAt, createdBy, usedBy?}`; **exact-id `get` only, never `list`**.  Mirrored at `families/{id}/invitations/{code}`.  Codes are single-use, 8 characters from `ABCDEFGHJKMNPQRSTUVWXYZ23456789`, valid 7 days, role `member`.
- `families/{id}/members/{uid}` carries denormalised `fullName`, `nickname`, `relationship`, `spouseId`, `avatarKey`, `inviteCode` and `removedAt` (a rejected request is soft-deleted; the person returns to family choice and may join again).
- `families/{id}/settings/{general,modules,rotationPolicy,notificationDefaults}` are created with the family.
- Every family use case writes its activity + audit entry in the same batch (`FamilyEvent`).

## Permissions (from Step 10)
- One matrix, `lib/core/permissions/permission_policy.dart`: `PermissionPolicy.can(actor, permission, {ownerId, settings, template})`. One `Permission` per row of the roadmap 2.2 matrix; `PermissionActor` is the member reduced to `{uid, role, isActive}` so `core/` never imports a feature; `Member.permissionActor` builds it. `PermissionSettings` carries the module switches and the family verification switch, `PermissionTemplate` the per-template switch.
- `Role` lives in `core/permissions/role.dart`; `features/family/domain/member_role.dart` re-exports it and keeps `MemberRole` as a typedef, so old call sites still compile.
- Every mutating use case calls `requirePermission(...)` in `features/family/domain/permission_access.dart` FIRST. `leavesNoActiveAdmin` (same file) is the last-admin guard; rules cannot express it (a subcollection cannot be enumerated).
- The UI uses `PermissionGate` (`lib/shared/widgets/`): `hide` removes the action, `disable` dims it, blocks it and shows a localized reason (icon + label, never colour alone). The gate takes a `bool`, so no Firebase and no feature import reach the widget.
- Backend mirror: `firebase/firestore.rules` v1 with `isMember(f)`, `role(f)`, `isAdmin(f)`, `isMod(f)`. It is tested by `firebase/rules_test/` against the emulator; the roadmap's own permission matrix was never available in this repo, so the table at the top of `permission_policy.dart` is the source of truth.

## Shared widgets and the gallery (from Step 11)
- Every reusable widget lives in `lib/shared/widgets/` and is reachable from the debug-only component gallery at `/dev/gallery` (`lib/app/gallery/`, dev flavour only; entry point next to the theme-tokens tile in the Family tab). Widgets take plain values: no Firebase and no feature import may reach them.
- `lib/app/gallery/gallery_sections.dart` is the single source of truth. A widget is "in the gallery" only by being listed there, and `test/shared/widgets/gallery_golden_test.dart` and `widgets_overflow_test.dart` both iterate that list, so adding a widget (with all of its states) once gives it goldens and overflow coverage.
- A widget that shows a status is announced **once** to assistive tech: `Semantics(label: ...)` with `excludeSemantics: true` (or `ExcludeSemantics` around the visual child), and never by colour alone (rule 13). `MoneyText` and `ProgressRing` replace the platform announcement with a localized label.
- Golden images live in `test/shared/widgets/goldens/` (11 widgets x 2 themes x 2 languages = 44 PNGs). Regenerate after an intentional visual change with `flutter test --update-goldens test/shared/widgets`; the tests skip *with a reason* when the directory is missing, so a fresh clone is green.
- `widgets_overflow_test.dart` renders every section at text scale 2.0 in both themes and both languages (bn/en) and fails on any overflow: this is the mandatory long-Bangla-string check for new widgets.
- Test harness: `test/shared/widgets/shared_widgets_test_support.dart` (`pumpSharedWidget`) - 320dp wide, both themes, `disableAnimations`, plus the `sharedPreferencesProvider` override that Riverpod-backed widgets (`MoneyText`, `ProgressRing`) need. `MoneyText` and `ProgressRing` read the active locale through `appFormattersProvider`, so any test that pumps them needs `SharedPreferences.setMockInitialValues({})` + `sharedPreferencesProvider.overrideWithValue(prefs)`.
- Golden/overflow tests use `createTestImage` inside `tester.runAsync(...)`: it talks to the engine and never completes inside the fake-async zone.
- Gotcha: `flutter analyze` exits **1 on any issue, including info-level lints**, and CI runs it without `--no-fatal-infos`. The tree must be lint-clean, not just error-free.

## Rules added by the Phase 1 hardening (H1-H13)
14. Offline-first: a "does not exist" snapshot that isFromCache is UNKNOWN, never "absent". Routing/guard decisions use only server-confirmed or cached-and-existing data.
15. Writes go through `guardWrite`. A commit that has not been acknowledged after the ack wait is treated as QUEUED (it will sync later), never as a failure. Retries reuse the same document ids (generate ids once per user intent, not once per attempt).
16. Onboarding and administrative actions (create family, join, approve, reject, role change, transfer admin, leave, cancel, revoke, settings) require the server and fail fast with Network when offline.
17. A user belongs to at most ONE family at a time (enforced in use cases AND rules).
18. Audit/activity entries are written ONLY through AuditWriter (H8), in the same batch as the change. They carry a type + params, never display text.
19. UI permission checks use PermissionPolicy (via canProvider / PermissionGate). `presentation/` must not test roles directly (isAdmin, MemberRole.admin ...). A test enforces it (H7).
20. Every rules `create`/`update` validates field types, string lengths and the closed key set (keys().hasOnly). Every rule has one allowed and one denied test, and the Dart mappers' real output is pushed through the rules in a contract test (H5).
21. domain/ and core/ (except core/firebase and core/localization) are pure Dart: no flutter, firebase, riverpod or go_router imports, directly OR transitively. A graph-based test enforces it (H8).
22. No `Colors.*` (except Colors.transparent) and no `Color(0x` outside lib/app/theme/.
23. No TODO(step-N) may survive its step.
24. Goldens are generated on Linux only (Update goldens workflow). Locally run `flutter test --exclude-tags golden`.
