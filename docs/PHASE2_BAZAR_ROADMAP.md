# Family Hub — Phase 2 Detailed Implementation Roadmap (Bazar & Family Finance)

**Version:** 1.0 · written 2026-10-22 against the codebase in `android_2.zip` (Phase 1 + hardening H1–H12 present in the tree).
**Purpose:** a build plan an AI coding tool can follow with almost no design thinking. Every step lists the exact files, names, signatures, data shapes, how the piece plugs into the rest of the app, what it depends on, and when it is done.
**Replaces:** `ROADMAP.md` Steps 12–19 (same goals, but re-cut into smaller steps and aligned to the code that actually exists now). `ROADMAP.md` stays the product source of truth; this file is the engineering source of truth for Phase 2.

---

## 0. How to use this file

1. Work in the order of **§4 (execution plan)**. A step may start only when everything in its **Depends on** line is merged and CI is green.
2. One step = one branch = one prompt = one commit: `P2-07: Bazar settings`. Never start a step on a red CI (CLAUDE.md "Never start the next step with a red CI").
3. Paste into the AI tool: *"Read CLAUDE.md and `docs/PHASE2_BAZAR_ROADMAP.md` §1–§3, then implement step P2-xx exactly as written. List the files you will create before coding. End with: files changed, how to verify, assumptions."*
4. Each step card has the same fields:

| Field | Meaning |
| --- | --- |
| **Type** | `INDEPENDENT` (only needs Phase 1 / earlier foundation), `DEPENDENT` (needs the listed steps), `PARALLEL-SAFE` (can run at the same time as the listed steps, because they touch different files) |
| **Depends on** | Steps that must be merged first. `—` = nothing in Phase 2. |
| **Parallel with** | Steps that can be done by another person/agent at the same time. |
| **Unblocks** | Steps that cannot start without this one. |
| **Files** | `path` — purpose. `NEW` = create, `EDIT` = change an existing file. |
| **Contents** | The names, signatures and rules to implement. |
| **Interacts with** | How the piece syncs with other screens/providers. |
| **Rules / tests** | What must be tested in the same commit. |
| **Done when** | Observable acceptance checks. |

5. Anything marked **[VERIFY]** depends on current Firebase / package behaviour and must be checked against the official docs or an emulator run, not memory.
6. Anything marked **[OWNER]** is a decision only the family owner can make; a default is given so work is never blocked.
7. **Owner decisions already made (2026-10-22), binding on every step:** (a) every member sees every member's contribution amounts (D-P2-5); (b) the week start day is a setting (D-P2-12); (c) fixed bills are a separate seeded category (D-P2-9); (d) members may add/modify contributions but only as requests approved by a **Household Manager** (= the existing `moderator` role, relabelled) or Admin; Admin stays the untouched super power (D-P2-17, D-P2-18).

---

## 1. What the audit of the current code found (and what it changes in the plan)

I read the Phase 1 code that Phase 2 builds on. These facts are *why* the plan looks the way it does.

### 1.1 What already exists and must be reused (do not rebuild)

| Capability | Where | How Phase 2 uses it |
| --- | --- | --- |
| Money / Quantity value objects (integer paisa / milli-units) | `lib/core/utils/money.dart`, `quantity.dart`, `scaled_decimal.dart`; `lineTotal(Quantity, Money)` half-up rounding | All amounts. `no_floating_point_test` forbids `double`/`num` in those three files; Phase 2 money code must follow the same discipline. |
| `Unit` enum: `kg, g, litre, piece, dozen, packet, cylinder` | `quantity.dart` | Item default unit, expense unit. Extended with labels in P2-02. |
| `DateKey`, `MonthKey`, `DateKeyRange`, `monthRange()` | `core/utils/date_key.dart` | Every record's `dateKey` / `monthKey`. |
| `FamilyDateKeys` + `familyDateKeysProvider` + `familyTimezoneProvider` | `core/utils/family_date_keys.dart`, `features/family/presentation/family_providers.dart` | The ONLY way to get "today" / "this month" (CLAUDE.md H12). Never `DateTime.now()`. |
| `Clock` / `FakeClock` / `clockProvider`, `IdGenerator` / `randomId`, `idGeneratorProvider` | `core/utils/` | Injected into every use case. |
| `Result<T>` + sealed `AppFailure` (`PermissionDenied, NotFound, Validation(field, code), Conflict(code), Network, Unknown`) | `core/errors/` | All use cases. New stable codes are listed in §3.6. |
| `TxRunner` (`runBatch`, `runTransaction`), `FirestoreTxRunner`, `FakeTxRunner` (in-memory store, `failNextBatchWith`, `holdNextCommit`), `kMaxBatchWrites = 500` | `core/firebase/tx_runner.dart`, `fake_tx_runner.dart` | Every multi-document write. |
| `guardWrite(commit, {probe, ackWait})`, `guardFirestore`, `serverProbeFor` | `core/firebase/firestore_guard.dart` | `probe` = "needs the server" (D3); no probe = "queue offline". |
| `AuditWriter.write(batch, familyId, AuditEvent)`; `AuditEvent{id,type,actorId,refType,refId,at,params}`; `AuditEventType` constants **mirrored in rules `eventTypes()` / `refTypes()`** | `core/firebase/audit_writer.dart`, `core/audit/` | Every Phase 2 write. New types/refTypes must be added in BOTH places (P2-03). |
| `ServerTime.instance` marker | `core/firebase/server_time.dart` | Already used by `AuditWriter` for `recordedAt`. |
| `BaseMapper` (createdAt/By, updatedAt/By, schemaVersion, deletedAt/By) | `core/firebase/base_mapper.dart` | Every new mapper starts from `BaseMapper.metadataToMap`. |
| `FirestorePaths` (already has `bazarCategories`, `bazarItems`, `expenses`, `bazarTrips`, `budgets`, `contributions`, `contributionPlans`, `fundTransactions`, `memberAdvances`, `settlements`) | `core/firebase/firestore_paths.dart` | Add only what is missing (P2-03). |
| `PermissionPolicy.can(...)`, `Permission` enum (`manageCatalogAndBudgets, addOwnExpense, editOthersExpense, recordContribution, viewAllContributions, viewFamilyReports, exportData` …), `requirePermission(...)`, `ref.can(...)`, `PermissionGate` | `core/permissions/`, `features/family/domain/permission_access.dart`, `features/family/presentation/permission_providers.dart`, `shared/widgets/permission_gate.dart` | Use cases call `requirePermission` FIRST; screens use `ref.can` + `PermissionGate`. `test/architecture/no_role_checks_in_ui_test.dart` bans `isAdmin` etc. in presentation. |
| Family settings docs `settings/{general,modules,permissions,relationships,rotationPolicy,notificationDefaults}` | `FirestoreFamilyRepository.createFamily` | `settings/permissions.moderatorManagesFinance` still gates Household Manager finance actions; `membersViewAllContributions` is **ignored** by Bazar (D-P2-5). |
| `FamilySeeder` + `SeedWrite` + `SeedContext`; `CreateFamily(seeders: …)` | `features/family/domain/family_seeder.dart`, `usecases/create_family.dart` | Catalog seeding (P2-06). |
| Module registry: `FamilyModule.routes`, `dashboardCards`, `reports`, `requiredPermission`; `BazarModule` currently serves `BazarPlaceholderScreen` | `lib/modules/`, `features/bazar/bazar_module.dart` | Bazar sub-routes are added **inside `BazarModule.routes`** (nested under `AppRoutes.bazar`), not in `router.dart`. |
| Shared widgets: `MoneyText`, `ItemThumb`, `AppAvatar`, `StatusChip`, `AppCard`, `EmptyState`, `ErrorView`, `LoadingView`, `SectionHeader`, `ChoiceWrap`, `ProgressRing`, `BusyButton`, `SyncBanner`, `PermissionGate`, `PillBottomBar` | `lib/shared/widgets/` | Reuse. New reusable widgets go in the same folder AND in `lib/app/gallery/gallery_sections.dart` (gives goldens + overflow tests automatically). |
| `newActionProvider()` (auto-dispose busy/failure controller) | `features/family/presentation/action_controller.dart` | Every screen's save/delete button. |
| Global `SyncBanner` driven by `syncStatusProvider` in `AppShell` | `app/shell/app_shell.dart` | Nothing to build: any queued write automatically shows "waiting to sync". |
| Rules scaffold: `canReadFamilyData`, `canWriteOwnRecord`, `moneyOk`, `dateKeyOk`, `monthKeyOk`, `softDeleteOnly`, `isNonNegativeInt`, `creatingFamily(f)`, deny-by-default block for Phase 2 collections | `firebase/firestore.rules` | Compose, do not reinvent. |
| Rules tests, templates, contract fixtures, index checker | `firebase/rules_test/`, `templates/collection.test.mjs.tmpl`, `test/contract/`, `tools/check_indexes.mjs` | Every new collection follows `docs/new_collection_checklist.md`. |
| Architecture tests | `test/architecture/` (`layer_boundaries`, `no_unbounded_queries`, `file_size` (300 lines), `no_role_checks_in_ui`, `no_step_todos`) and `test/core/localization/no_hard_coded_strings_test.dart` | Phase 2 code must pass them → keep files ≤ 300 lines, `.limit()` on every `.collection(...)` query, no `TODO(step-`, no raw colours. |

### 1.2 Gaps and traps found in the current code (each one is handled by a step)

| # | Finding | Consequence if ignored | Handled in |
| --- | --- | --- | --- |
| G-1 | `createFamilyProvider` builds `CreateFamily` **without `seeders`**, and `CreateFamily` only runs for *new* families. The family you already created on `familyhub-dev` will never get a catalog. | Empty catalog on every existing family. | P2-01 (seed seam) + P2-06 (`EnsureCatalogSeeded` backfill) |
| G-2 | Seeders are written in `domain/` as pure Dart, but the documents need Firestore `Timestamp`s (via `BaseMapper`). A domain seeder cannot import them. | Layer test fails. | P2-06: the seeder class lives in `bazar/items_categories/data/`, wired only in `bootstrap.dart` through a new `familySeedersProvider`. |
| G-3 | Rules `eventTypes()` and `refTypes()` are **closed lists**; an audit write with an unknown type is denied. | Every Phase 2 write fails with permission-denied. | P2-03 adds all Phase 2 types in Dart + rules + mirror test. |
| G-4 | `settingsKeys()` in the rules is a closed union. New settings (week start, contribution defaults…) are rejected unless the key list is extended. | Bazar settings cannot be saved. | P2-07 |
| G-5 | `auditLogs` are readable by **admin only**, but the old roadmap wants moderators to see an expense's edit history. | History tab empty/denied for moderators. | P2-10: per-expense `revisions` subcollection instead of reading audit logs. |
| G-6 | `Permission` has no entry for "close month" or "import data". | Manager-only actions would have to abuse `editFamilySettings` / `exportData`. | P2-03 adds `closeBazarMonth`, `importBazarData`, regenerates `docs/permission_matrix.md`. |
| G-7 | The 300-line file cap and "one class per use-case file" mean the old "one repository per feature" habit will fail `file_size_test` (`FirestoreFamilyRepository` is already an allow-listed debt). | CI red. | Each entity gets its own `*_mappers.dart`, `firestore_*_repository.dart`. |
| G-8 | `FirestoreTxRunner.runTransaction` **cannot run offline**; `runBatch` can. | A transaction-based "Add expense" would break the offline-first promise (D3). | Everyday writes (expense, trip, contribution, budget) = **batch + `guardWrite` without probe**; money-integrity writes that must read fresh state (settle advance, close/reopen month, import, restore) = **transaction/batch + probe (server required)**. See §3.4. |
| G-9 | Rules access-call limit (10 per single request, 20 per batch/transaction). A bazar trip of N lines writes N expenses + N fund rows and each rule evaluates membership/month-lock lookups. | A 25-line trip is rejected by the backend. | P2-10 mandatory emulator test with a 30-line trip; fallback in P2-10 §fallback. **[VERIFY]** whether repeated `get()` of the same document is counted once. |
| G-10 | `pubspec.yaml` has no `fl_chart`, `excel`, `csv`, `file_picker`. CLAUDE.md says "Do not add packages not named". | Build breaks or silent unapproved packages. | Added only in the step that needs them (P2-23 `fl_chart`; P2-24 `excel`, `file_picker`) after a `flutter pub add` version check. |
| G-11 | `Bazar.xlsx` mixes **bazar** and **fixed household bills** (rent ৳17,500, electricity, gas ৳3,200, internet ৳500, garbage ৳120) in one "monthly estimate" total, and uses separate categories for onion and potato. | Import would pollute the grocery budget. | Decisions D-P2-8/9, import mapping in P2-24. |
| G-12 | `PROGRESS.md` says Phase 1 hardening was "written statically" (no SDK was available) and H13 (final verification) was not done. | Phase 2 starts on an unverified base. | P2-01 gate. |

---

## 2. Decisions (defaults are used unless you change them)

| # | Decision | Default in this roadmap |
| --- | --- | --- |
| D-P2-1 | Field naming for money/quantity in Firestore | Integer fields with explicit units: `totalPaisa`, `unitPricePaisa`, `amountPaisa`, `qtyMilli`. (The old roadmap said `total`; the explicit suffix prevents unit mistakes and matches `moneyOk`.) |
| D-P2-2 | Offline behaviour | Everyday entries (expense, trip, contribution, budget, item "remember") **queue offline** and show the global sync banner. Integrity operations (settle advance, close/reopen month, import, undo import, seed backfill, settings) **require the server** and fail fast with `Network`. |
| D-P2-3 | Fund balance | Never stored as a mutable number. `balance = sum(fundTransactions with monthKey ≥ M0)` where `M0` = month after the latest **closed** month, else `settings/bazar.fundStartMonth`. Closing a month writes an `opening` row into the next month. Keeps every query bounded. |
| D-P2-4 | Ledger immutability | `fundTransactions`, `settlements`, `expenses/{id}/revisions` are **append-only** (no update, no delete, not even soft). Corrections are new compensating rows. Recorded as ADR 0006 (an explicit, documented exception to "soft delete" because these rows are never removed at all). |
| D-P2-5 | Who sees contributions | **RESOLVED (owner, 2026-10-22): every active member sees every member's contribution amounts.** `contributions` and `contributionPlans` are readable by all active members (`canReadFamilyData`); no `memberId` query filter is needed. The old `settings/permissions.membersViewAllContributions` flag is **ignored by Bazar** (leave Phase 1 UI untouched; note it in `docs/permission_matrix.md`). |
| D-P2-6 | Month lock | `ReopenMonth` (**Admin or Household Manager**, required note) is the only way to change a closed month. No per-record admin override. |
| D-P2-7 | Members may create their own *custom items* from the expense form ("Remember this item"); only managers (`manageCatalogAndBudgets`) create/edit categories and edit/deactivate items. A member can also bump `useCount`/`lastPricePaisa` on items (strictly limited in rules). |
| D-P2-8 | Onion & potato | Items under **Vegetables** (CLAUDE.md default). The importer maps the workbook's separate `পিয়াজ` / `আলু` categories to those items. |
| D-P2-9 | Fixed bills in the workbook (rent, electricity, internet, garbage) | **RESOLVED (owner): a separate seeded category "Fixed bills" (স্থায়ী বিল), key `fixed_bills`, 4 items (flat rent, electricity, internet, garbage).** The importer maps the workbook's `ফ্লাট ভাড়া / ইলেক্ট্রিসিটি / ইন্টারনেট / ময়লার বিল` estimate lines into that category's monthly estimate (Oct-26: 17,500 + 500 + 120 = ৳18,120; electricity is blank → skipped as "no amount"). Gas ৳3,200 stays in Gas. Fixed bills are normal expenses/estimates and count in the monthly total and reports. |
| D-P2-10 | Budget never blocks spending | Alerts at 80% and 100% (configurable list), no hard block. |
| D-P2-11 | Contribution rule | Equal split of the family's monthly target among **active members**, due day configurable (default 5). Remainder paisa goes to the first members in roster order (deterministic). Override per member per month. |
| D-P2-12 | Week start for reports | **RESOLVED (owner): the week start day is a setting**, stored in `settings/bazar.weekStartDay` (1 = Monday … 7 = Sunday), default Saturday (6), editable on the Bazar settings screen by Household Manager/Admin. Every report/range provider **must read it from `bazarSettingsProvider`** — never hard-code `DateTime.saturday` outside the default of `BazarSettings`. |
| D-P2-13 | Receipt photo | Not in Phase 2 (Spark has no free Storage dependency). Category/item images = emoji or small base64 string (≤ 24 KB) only; fallback is the existing `ItemThumb` colour initial. |
| D-P2-14 | Soft-deleted expenses in lists | Filtered **client-side** (`deletedAt == null`) to avoid an index per filter. A "show deleted" toggle (managers) shows them. |
| D-P2-15 | New package versions | Added only in the step that needs them, after `flutter pub add` resolves the current stable version; commit `pubspec.lock`. |
| D-P2-16 | Rules cross-checks | Rules do **not** `getAfter`-cross-check each line of a trip (20 access-call limit). Invariants are enforced by use-case tests, `LedgerIntegrityCheck` and a mandatory 30-line-trip emulator test. Restoring a soft-deleted expense (Undo) is a plain batch with no probe, so it works offline. |
| D-P2-17 | **Household Manager** (owner decision, 2026-10-22) | "Household Manager" (বাংলা: **সংসার ব্যবস্থাপক**) is the **display name of the existing `moderator` role**; it replaces the words "Finance Manager"/"Moderator" everywhere in the UI. The stored role value stays `moderator` (no data migration, no rules change to role checks). The Household Manager operates everything day-to-day: catalog, budgets, expenses of anyone, contributions (approve), advances/settlements, chores (Phase 3). **Admin is untouched and remains the super power** (role changes, family settings, close/reopen month, import, everything a Household Manager can do). Do **not** add a new role, do not change admin permissions. The `moderatorManagesFinance` flag keeps its Phase 1 meaning and default `true`; if an admin switches it off, the Household Manager loses finance actions (documented behaviour). |
| D-P2-18 | Contribution approval (owner decision) | A **member** may add a contribution for **themselves** and may edit it, but it is only a **request** (`status = pending`) until a **Household Manager or Admin approves** it. Pending requests never touch the fund ledger, `received`, or the balance. Approval writes the `con_<id>` ledger row in the same batch. A member who wants to change an **approved** contribution files a **change request** (`pendingChange` on the document); the ledger changes only when a manager approves it (delta `adj_` row). A Household Manager/Admin who records a contribution is auto-approved (no second person needed). Rejection needs a reason; a rejected request stays visible to its owner (history). |

---

## 3. Shared blueprint (every step refers to this section)

### 3.1 Folder layout to create

Names follow CLAUDE.md (snake_case files, `FooRepository` / `FirestoreFooRepository` / `FooMappers` / `FooController` / `FooScreen` / one use case per file). New sub-features `fund`, `settings` are added to the list in CLAUDE.md "Folder structure" in P2-01.

```text
lib/features/bazar/
├── bazar_module.dart                    EDIT  (routes, dashboardCards, requiredPermission stays null)
├── bazar_entries.dart                   NEW   list of Bazar-home entry tiles (each step appends one)
├── presentation/
│   ├── bazar_home_screen.dart           NEW   replaces bazar_placeholder_screen.dart (delete it)
│   ├── bazar_providers.dart             NEW   cross-feature providers (see §3.5)
│   ├── bazar_failure_messages.dart      NEW   extension on AppLocalizations: bazarFailureMessage(AppFailure)
│   └── widgets/                         NEW   bazar-only widgets (not reusable elsewhere)
├── items_categories/{domain,data,presentation}/
├── settings/{domain,data,presentation}/        (Bazar settings: settings/bazar document)
├── fund/{domain,data}/                          (fund ledger, month closings; UI lives in contributions/)
├── expenses/{domain,data,presentation}/
├── budgets/{domain,data,presentation}/
├── contributions/{domain,data,presentation}/
├── advances/{domain,data,presentation}/
├── reports/{domain,presentation}/               (reads through ExpenseRepository; no own collection)
└── import/{domain,data,presentation}/
test/features/bazar/<same tree>/                 mirrors lib/
test/support/in_memory_bazar_backend.dart        NEW (P2-09) in-memory ports for use-case tests
```

Cross-sub-feature imports: a `domain/` may import another bazar sub-feature's `domain/` (the layer test only forbids importing another feature's `presentation/` or `data/`). `presentation/` may import any bazar `domain/` and shared/core, never `data/`.

### 3.2 Collections and document shapes

All documents also carry the `BaseMapper` fields `createdAt, createdBy, updatedAt, updatedBy, schemaVersion` (+ `deletedAt, deletedBy` where soft-deletable). "Key set" = the exact `hasOnly` list in the rules (put each in a `*Keys()` function and mirror it in `test/contract/rules_key_sets_test.dart`).

| Collection (under `families/{f}/…`) | Doc id | Fields (besides base) | Soft-delete | Notes |
| --- | --- | --- | --- | --- |
| `bazarCategories` | `cat_<seedKey>` for seeds, random for custom | `nameBn` (1–60), `nameEn?` (≤60), `colorIndex` (int 0–11 → `placeholderPalette`, **never a hex**), `emoji?` (≤8), `imageData?` (base64 ≤ 24 000 chars), `sortOrder` (int), `active` (bool), `builtIn` (bool), `seedKey?` | via `active=false` (+ `deletedAt` never used) | Deactivate, never delete. |
| `bazarItems` | `item_<seedKey>` or random | `nameBn`, `nameEn?`, `categoryId`, `defaultUnit` (a `Unit.name`), `aliases` (list ≤ 10, each ≤ 40), `emoji?`, `imageData?`, `useCount` (int ≥ 0), `lastPricePaisa?`, `lastUnitPricePaisa?`, `lastUsedAt?`, `active`, `builtIn`, `seedKey?` | `active=false` | Members may create custom items and bump `useCount`/`last*` (rules: D-P2-7). |
| `expenses` | random (trip lines: random) | `dateKey`, `monthKey`, `occurredAt` (UTC ts), `itemId?`, `itemName` (1–80), `categoryId`, `qtyMilli?`, `unit?`, `unitPricePaisa?`, `totalPaisa` (int > 0), `fundingSource` (`fund`\|`member`), `paidByMemberId?` (required iff `member`), `reimbursable` (bool, only meaningful iff `member`), `purchaserId?`, `tripId?`, `shop?` (≤60), `note?` (≤500), `source` (`manual`\|`import`), `importBatchId?` | `deletedAt/By` | `monthKey == dateKey[0:7]` enforced in rules. Linked ledger ids are **deterministic**: fund row `exp_<expenseId>`, advance doc id = `<expenseId>`. |
| `expenses/{id}/revisions` | random | `before` (map of the changed old values), `changedFields` (list ≤ 20), `reason?` | none (append-only) | Written by `UpdateExpense` / `SoftDeleteExpense` / `RestoreExpense`. Read: managers + the expense's creator. |
| `bazarTrips` | random | `dateKey`, `monthKey`, `shop?`, `fundingSource`, `paidByMemberId?`, `reimbursable`, `lineCount` (int 1–40), `totalPaisa`, `note?` | no | Header only; lines are normal expenses with `tripId`. |
| `fundTransactions` | `exp_<expenseId>`, `con_<contributionId>`, `stl_<settlementId>`, `open_<yyyy-MM>`, `adj_<eventId>` | `type` (`contribution`\|`expense`\|`reimbursement`\|`opening`\|`adjustment`), `amountPaisa` (signed int ≠ 0, sign rule below), `dateKey`, `monthKey`, `refType` (`expense`\|`contribution`\|`settlement`\|`month`\|`manual`), `refId`, `note?` | never (append-only) | Sign rule: `contribution` > 0; `expense` < 0; `reimbursement` < 0; `opening` any; `adjustment` any non-zero. **No member id** is stored on ledger rows (the `contributions` document already says who; contributions are visible to all, D-P2-5). |
| `memberAdvances` | the expense id | `expenseId`, `memberId`, `amountPaisa` (original), `settledPaisa` (0…amount), `status` (`pending`\|`partial`\|`settled`\|`voided`), `dateKey`, `monthKey` | via `status=voided` | Updated only by `SettleAdvance` (settled amount), by `UpdateExpense` while `settledPaisa == 0` (amount), and by delete/restore (void/un-void). |
| `settlements` | random | `advanceId`, `memberId`, `amountPaisa` (> 0), `dateKey`, `monthKey`, `method?`, `note?`, `fundTxId` | never | Create-only. |
| `contributionPlans` | `<yyyy-MM>_<memberId>` | `monthKey`, `memberId`, `expectedPaisa` (≥ 0) | no | Manager write. |
| `contributions` | random | `memberId`, `monthKey`, `dateKey`, `amountPaisa` (> 0), `method?` (`cash`\|`bkash`\|`nagad`\|`bank`\|`other`), `note?`, `status` (`pending`\|`approved`\|`rejected`), `requestedBy` (uid), `fundTxId?` (set only when approved; `con_<id>`), `decidedBy?`, `decidedAt?`, `rejectReason?` (≤200), `pendingChange?` (map `{amountPaisa, dateKey, method?, note?, requestedAt}`), `voidedAt?`, `voidedBy?` | `voidedAt/By` (+ compensating `adj_` row) | Read: **all active members** (D-P2-5). Create: member for own `memberId` with `status=pending`; manager with `status=approved` (+ `con_` ledger row in the same batch). See D-P2-18. |
| `budgets` | `<yyyy-MM>` | `monthKey`, `totalEstimatePaisa`, `categoryEstimates` (map `categoryId → paisa`, ≤ 40 keys), `lines` (list ≤ 150 of `{itemId?, name, plannedQtyMilli?, unit?, estimatedRatePaisa?, estimatedTotalPaisa, stockMilli?}`), `alertThresholds` (list ≤ 4 ints 1–200) | no | Rules bound sizes (lists cannot be iterated in rules); the app tolerates ill-formed lines (like `relationships.items`). |
| `monthClosings` | `<yyyy-MM>` | `monthKey`, `status` (`open`\|`closed`), `closedAt?`, `closedBy?`, `closingBalancePaisa?`, `reopenedAt?`, `reopenedBy?`, `reopenNote?` (≤300), `reopenCount` | no | `financeManager(f)` write (Admin or Household Manager). **NEW collection** (P2-03 adds the path; `paths_match_rules_test` `pending` set must not list it). |
| `importBatches` | random | `fileName` (≤120), `rowCount`, `totalPaisa`, `monthKeys` (list ≤ 12), `fundingSource`, `status` (`active`\|`undone`), `undoneAt?` | no | **NEW collection**. `financeManager(f)` write (Admin or Household Manager). |
| `settings/bazar` | doc | `weekStartDay` (1–7), `defaultMonthlyContributionPaisa` (≥ 0), `contributionDueDay` (1–28), `alertThresholds` (list ≤ 4), `fundStartMonth` (`yyyy-MM`) | no | Extends `settingsKeys()`/`settingsOk` (G-4). |

### 3.3 Permissions → use cases (single source: `PermissionPolicy`)

| Use case | Permission checked first (`requirePermission`) | Notes |
| --- | --- | --- |
| `AddCategory`, `UpdateCategory`, `DeactivateCategory`, `UpdateItem`, `DeactivateItem`, `EnsureCatalogSeeded` | `manageCatalogAndBudgets` | |
| `AddItem` | `manageCatalogAndBudgets` when called from the manager screen; `addOwnExpense` when called as "remember this item" from the expense form (separate method `AddCustomItem`). |
| `AddExpense`, `AddBazarTrip`, `CheckDuplicate` | `addOwnExpense` | `ownerId` = actor. |
| `UpdateExpense`, `SoftDeleteExpense`, `RestoreExpense` | `addOwnExpense` if `expense.createdBy == actor`, else `editOthersExpense` (pass `ownerId`) | |
| `SaveBudget`, `CopyLastMonthBudget`, `UpdateBazarSettings` | `manageCatalogAndBudgets` | |
| `SetContributionPlan`, `RecordContribution` (manager records = auto-approved), `ApproveContribution`, `RejectContribution`, `ApproveContributionChange`, `RejectContributionChange`, `VoidContribution`, `RecordOpeningBalance`, `SettleAdvance` | `recordContribution` (Household Manager = moderator, while `moderatorManagesFinance`; Admin always) | Household Manager/Admin only. |
| `RequestContribution`, `EditPendingContribution`, `RequestContributionChange`, `CancelContributionRequest` | **`requestContribution`** (new, any active member; `ownerId` must equal the actor and `contribution.memberId == actor`) | Creates only `pending` data; never writes the ledger. |
| `CloseMonth`, `ReopenMonth` | **`closeBazarMonth`** (new; Admin, or Household Manager while `moderatorManagesFinance`; reopen needs a note) | P2-03 |
| `ImportExpenses`, `UndoImport` | **`importBazarData`** (new; Admin, or Household Manager while `moderatorManagesFinance`) | P2-03 |
| Reading reports | `viewFamilyReports` (all-member views) — members without it still see *their own* contribution report | |
| Reading contributions | any active member (D-P2-5) — no permission check, no `memberId` filter | |

### 3.4 Write patterns (use exactly these)

```text
Domain use case                          Data repository method                      Runner
──────────────────────────────────────   ─────────────────────────────────────────   ───────────────────────────────
validate → plan = pure object            commitPlan(plan, AuditEvent)                guardWrite(commit)           ← queues offline
(ExpenseWritePlan, ContributionPlan…)    one tx.runBatch: set/update docs +          (no probe)  EVERYDAY writes
                                         AuditWriter.write(batch,…)
validate → needs fresh read              commitSettlement(...)                       guardWrite(probe: serverProbeFor(...),
(settle, close, reopen, import, undo)    tx.runTransaction (reads then writes)         () => tx.runTransaction<void>(...))
                                                                                     ← SERVER REQUIRED
```
* Domain code never sees `TxRunner`: a use case builds a **pure write plan** (plain Dart objects) and hands it to a repository method; the repository maps it with its `*Mappers` and stages it. This is what keeps `domain/` Firebase-free and lets `InMemoryBazarBackend` implement the same port.
* Generate ids **once per user intent** (the form controller creates `expenseId`/`eventId` when the screen opens and passes them in; a retry reuses them) — CLAUDE.md rule 15. Use cases take `String? id`/`String? eventId` parameters like `CreateFamily`.
* Audit: every write calls `AuditWriter.write` inside the same batch with a `AuditEvent(type, refType, refId, params)`; `params` ≤ 8 keys, values are machine strings (never display text).
* Reads inside a use case that must work offline (month lock, item lookup, duplicate check) come from the repository's **cache-friendly** `get*` methods (default source), never `Source.server`.

### 3.5 Provider graph — how every screen stays in sync

One Firestore listener per data set, everything else is a pure derived `Provider`. All providers live in `presentation/` (`bazar_providers.dart` or the sub-feature's `*_providers.dart`), keyed on `currentFamilyIdProvider`.

```text
currentFamilyIdProvider ─┬─ categoriesProvider (Stream)  ┐
                         ├─ itemsProvider (Stream)       ├─► catalogIndexProvider (Provider: id→entity maps + ItemSearch)
                         ├─ bazarSettingsProvider (Stream, defaults when absent)
                         ├─ selectedMonthProvider (Notifier<MonthKey>, initial = familyDateKeys.thisMonth())  ← MonthSwitcher widgets
                         ├─ monthExpensesProvider(MonthKey)  (Stream, ≤ kMaxListenerDocs, auto-dispose; keepAlive for the current month)
                         │     ├─► monthSpendSummaryProvider(MonthKey)  = ReportEngine over this list (excludes deleted)
                         │     │         ├─► budgetStatusProvider(MonthKey) = ComputeBudgetStatus(budget, summary) ─► budgetAlertsProvider
                         │     │         └─► Reports tabs, dashboard "this month" card
                         │     └─► expenseListProvider(ExpenseFilters)  (client filter/group; paging by month)
                         ├─ monthBudgetProvider(MonthKey) (Stream)
                         ├─ monthClosingsProvider (Stream, ≤ 24 newest) ─► monthLockedProvider(MonthKey) ─► used by forms (disable + reason)
                         ├─ fundTransactionsProvider (Stream where monthKey ≥ M0) ─► fundBalanceProvider ─► Fund card, dashboard
                         ├─ contributionPlansProvider(MonthKey) + contributionsProvider(MonthKey)
                         │          └─► contributionStatusProvider(MonthKey)  (expected / received / remaining / credit per member)
                         ├─ openAdvancesProvider (Stream status in [pending, partial]) ─► advanceSummaryProvider
                         └─ membersProvider (existing) ─► names/avatars everywhere
```
Interaction rules:
1. A screen never calls a repository directly; it calls a use-case provider (e.g. `addExpenseProvider`) through a `newActionProvider()` and lets the listeners above push the result back. Offline, the local cache makes the new row appear immediately and `SyncBanner` shows "waiting to sync".
2. Changing `selectedMonthProvider` (via `MonthSwitcher`) re-targets Expense list, Budget, Fund and Reports together; each screen may also hold a local override (reports custom range) but defaults to this provider.
3. `monthLockedProvider(month)` is read by the Add/Edit Expense form, Contribution sheet and Settle sheet: a locked month shows the form disabled with the localized reason (icon + text) instead of failing after submit. The use case + rules still enforce it.
4. Derived numbers (spend by category, fund balance, contribution status) are computed in **pure Dart classes** (`ReportEngine`, `FundBalanceCalculator`, `ComputeBudgetStatus`, `ContributionStatusCalculator`) so the dashboard (Phase 4), reports and budgets can never disagree.

### 3.6 Stable failure codes (use these strings; map each in `bazarFailureMessage`)

`Validation(field, code)`: `required`, `too_long`, `invalid_amount`, `amount_not_positive`, `future_date`, `qty_unit_required`, `member_required`, `category_required`, `item_name_required`, `too_many_lines`, `invalid_month`, `invalid_range`, `negative`, `too_many_decimals`, `too_large`.
`Conflict(code)`: `month_locked`, `advance_settled` (advance is partly/fully settled so the expense cannot change), `overpayment`, `already_closed`, `not_closed`, `reopen_note_required`, `catalog_not_empty`, `duplicate_item`, `import_already_undone`, `import_has_locked_month`, `concurrent_edit`.
`NotFound(entity)`: `expense`, `item`, `category`, `advance`, `budget`, `import_batch`.

### 3.7 UI conventions for every Phase 2 screen

* Reads tokens through `context.tokens`; no `Colors.*`, no `Color(0x`. Category colours = `placeholderPalette[colorIndex]` with the foreground from `AppAvatar.foregroundFor` (so contrast is already tested).
* Each stream-backed screen shows `LoadingView` → data / `EmptyState` / `ErrorView(onRetry)`; offline is handled by the global banner. Status is **icon + label + colour**, never colour alone.
* Money is shown only with `MoneyText` (or `appFormattersProvider.money`); quantities with `Quantity.toDecimalString()` + localized unit label; digits follow the user's Bangla-digits switch. Money input accepts Bangla digits (`parseScaledDecimal` already normalises them).
* Touch targets ≥ 48 dp; text must survive text-scale 2.0 in Bangla (the overflow tests iterate the gallery).
* Strings: add keys to **`app_bn.arb` (template) and `app_en.arb`**, run `flutter gen-l10n`, commit the generated files. Key prefixes: `bazar*`, `catalog*`, `expense*`, `budget*`, `fund*`, `contribution*`, `advance*`, `month*`, `report*`, `import*`, `unit*`.
* Permission-dependent buttons: `PermissionGate(allowed: ref.can(...), mode: disable, deniedMessage: …)`.
* Screens that save use a `final _xActionProvider = newActionProvider();` file-private provider, `BusyButton`, and `FailureBanner`-style inline messages with `bazarFailureMessage`.
* File ≤ 300 lines: split into `widgets/` early.

### 3.8 Test pattern for every step

| Layer | Test file | Uses |
| --- | --- | --- |
| Pure domain / engines | `test/features/bazar/<sub>/domain/*_test.dart` | `FakeClock`, plain objects; table-driven |
| Use cases | `test/features/bazar/<sub>/domain/usecases/*_test.dart` | `InMemoryBazarBackend` (P2-09) + `Fixture`-style helper (`test/features/bazar/bazar_test_helpers.dart`, NEW in P2-04, modelled on `test/features/family/family_test_helpers.dart`) |
| Mappers / repositories | `test/features/bazar/<sub>/data/*_test.dart` | `FakeTxRunner` store assertions (`fake.store['families/f1/expenses/e1']`), round-trip `toMap → fromMap` |
| Rules | `firebase/rules_test/<collection>.test.mjs` | Copy `templates/collection.test.mjs.tmpl`; actors `ALICE` admin, `BOB` moderator, `CARA` member, `DAVE` pending, `ERIN` other family; one allowed + one denied per rule |
| Contract | `test/contract/rules_fixtures_test.dart` (EDIT, add each new mapper payload) + `contract.test.mjs` | proves real mapper output passes the rules |
| Widgets | `test/features/bazar/<sub>/presentation/*_test.dart` | provider overrides; text scale 2.0; bn + en; light + dark |
| Goldens | tag `golden`, **generated on Linux CI only** (H1/D5) | |

Run before every commit: `dart format .`, `flutter analyze` (zero issues, infos included), `flutter test --exclude-tags golden`, rules suite (`npm --prefix firebase/rules_test test` under the emulator), `node tools/check_indexes.mjs`.

### 3.9 Audit event vocabulary (added in P2-03)

| `type` | `refType` | `params` keys | Written by |
| --- | --- | --- | --- |
| `bazar.catalog_seeded` | `family` | `categories`, `items` | EnsureCatalogSeeded / seeder |
| `bazar.category_created` / `_updated` / `_deactivated` | `category` | `name` | catalog use cases |
| `bazar.item_created` / `_updated` / `_deactivated` | `item` | `name` | catalog use cases |
| `bazar.expense_created` | `expense` | `item`, `amount`, `funding` | AddExpense |
| `bazar.expense_updated` | `expense` | `item`, `fields` | UpdateExpense |
| `bazar.expense_deleted` / `_restored` | `expense` | `item`, `amount` | Soft/Restore |
| `bazar.trip_created` | `trip` | `lines`, `amount` | AddBazarTrip |
| `bazar.budget_saved` | `budget` | `month`, `amount` | SaveBudget / CopyLastMonth |
| `bazar.settings_updated` | `family` | — | UpdateBazarSettings |
| `bazar.contribution_plan_set` | `contributionPlan` | `month`, `member`, `amount` | SetContributionPlan |
| `bazar.contribution_recorded` / `_voided` | `contribution` | `month`, `member`, `amount` | Record/VoidContribution |
| `bazar.contribution_requested` / `_request_edited` / `_request_cancelled` | `contribution` | `month`, `member`, `amount` | RequestContribution / EditPendingContribution / CancelContributionRequest |
| `bazar.contribution_approved` / `_rejected` | `contribution` | `month`, `member`, `amount` (+ `reason` on reject) | Approve/RejectContribution |
| `bazar.contribution_change_requested` / `_change_approved` / `_change_rejected` | `contribution` | `month`, `member`, `amount` (new), `old` | RequestContributionChange / Approve… / Reject… |
| `bazar.opening_balance_set` | `month` | `month`, `amount` | RecordOpeningBalance |
| `bazar.advance_settled` | `settlement` | `member`, `amount`, `status` | SettleAdvance |
| `bazar.month_closed` / `_reopened` | `month` | `month`, `balance` / `note` | Close/ReopenMonth |
| `bazar.import_completed` / `_undone` | `importBatch` | `rows`, `amount` | Import/UndoImport |

New `refTypes`: `category, item, expense, trip, budget, contribution, contributionPlan, settlement, month, importBatch`.
`amount` / `balance` params are integer-paisa **strings**; `activityText` formats them with `MoneyFormatter`.

### 3.10 Routes to add (all inside `BazarModule.routes`, nested under `AppRoutes.bazar = '/bazar'`)

| Constant in `AppRoutes` | Path | Screen | Step |
| --- | --- | --- | --- |
| `bazar` (exists) | `/bazar` | `BazarHomeScreen` | P2-01 |
| `bazarExpenseNew` | `/bazar/expenses/new` | `AddExpenseScreen` | P2-13 |
| `bazarTripNew` | `/bazar/trip/new` | `BazarTripScreen` | P2-14 |
| `bazarExpenses` | `/bazar/expenses` | `ExpenseListScreen` | P2-15 |
| `bazarExpensePattern` / `bazarExpense(id)` | `/bazar/expenses/:id` | `ExpenseDetailScreen` | P2-15 |
| `bazarExpenseEditPattern` / `bazarExpenseEdit(id)` | `/bazar/expenses/:id/edit` | `AddExpenseScreen(editingId:)` | P2-15 |
| `bazarCatalog` | `/bazar/catalog` | `CatalogManagerScreen` | P2-16 |
| `bazarBudget` | `/bazar/budget` | `BudgetScreen` | P2-18 |
| `bazarFund` | `/bazar/fund` | `FundScreen` | P2-22 |
| `bazarAdvances` | `/bazar/advances` | `AdvancesScreen` | P2-23 |
| `bazarMonthClose` | `/bazar/month-close` | `MonthCloseScreen` | P2-23 |
| `bazarReports` | `/bazar/reports` | `ReportsScreen` | P2-25 |
| `bazarImport` | `/bazar/import` | `ImportWizardScreen` | P2-28 |
| `bazarSettings` | `/bazar/settings` | `BazarSettingsScreen` | P2-07 |

go_router matches in declaration order: declare `expenses/new` **before** `expenses/:id`. The router's disabled-module redirect already uses `module.basePath` prefix matching, so every route above is automatically hidden when the family switches Bazar off.

---

## 4. Execution plan

### 4.1 Dependency table (read this before anything else)

| Step | Title | Type | Depends on | Can run in parallel with |
| --- | --- | --- | --- | --- |
| P2-01 | Preflight gate, Bazar skeleton, seams | INDEPENDENT (gate) | Phase 1 hardening merged | — |
| P2-02 | Pure helpers: money math, units, date ranges | INDEPENDENT | — (start after P2-01 for a green base) | P2-03 |
| P2-03 | Phase 2 vocabulary: audit types, paths, permissions, ARB base | DEPENDENT | P2-01 | P2-02 |
| P2-04 | Catalog domain + ItemSearch | DEPENDENT | P2-02, P2-03 | P2-07, P2-08, P2-12 |
| P2-05 | Catalog data layer, rules, providers | DEPENDENT | P2-04 | P2-07, P2-08, P2-12 |
| P2-06 | Default catalog seed + backfill | DEPENDENT | P2-05 | P2-07, P2-08, P2-09 |
| P2-07 | Bazar settings (domain+data+rules+screen) | DEPENDENT | P2-03 | P2-04…P2-06, P2-08, P2-12 |
| P2-08 | Fund ledger & month-closing domain | DEPENDENT | P2-02, P2-03 | P2-04…P2-07, P2-12 |
| P2-09 | Expense domain + use cases + in-memory backend | DEPENDENT | P2-04, P2-08 | P2-05, P2-06, P2-07, P2-12 |
| P2-10 | Expense/fund/advance data layer + rules | DEPENDENT | P2-05, P2-09 | P2-12, P2-17 |
| P2-11 | Bazar providers (month expenses, spend, fund, locks) | DEPENDENT | P2-10 | P2-12, P2-16, P2-17 |
| P2-12 | Shared widgets + gallery (MonthSwitcher, AmountField, …) | INDEPENDENT | P2-01 | everything in Waves B–D |
| P2-13 | Add Expense screen | DEPENDENT | P2-11, P2-12 | P2-16, P2-17, P2-19, P2-20 |
| P2-14 | Bazar Trip screen | DEPENDENT | P2-13 | P2-15, P2-16, P2-18 |
| P2-15 | Expense list, detail, edit, delete/undo, history | DEPENDENT | P2-13 | P2-14, P2-16, P2-18 |
| P2-16 | Catalog manager screen | DEPENDENT | P2-06, P2-12 | P2-13…P2-15 |
| P2-17 | Budgets domain + data + rules | DEPENDENT | P2-04, P2-07 | P2-09…P2-11 |
| P2-18 | Budget screen + alerts provider | DEPENDENT | P2-17, P2-11, P2-12 | P2-14, P2-15 |
| P2-19 | Contributions domain + data + rules | DEPENDENT | P2-10, P2-07 | P2-20 |
| P2-20 | Advances & settlements domain + data + rules | DEPENDENT | P2-10 | P2-19 |
| P2-21 | Month close / reopen | DEPENDENT | P2-19, P2-20 | P2-22 |
| P2-22 | Fund & contributions screens | DEPENDENT | P2-19, P2-11, P2-12 | P2-21 |
| P2-23 | Advances screen + Month close screen | DEPENDENT | P2-20, P2-21, P2-22 | P2-25 |
| P2-24 | Report engine (pure Dart) | DEPENDENT | P2-09, P2-02 | UI steps |
| P2-25 | Reports screen (fl_chart) | DEPENDENT | P2-24, P2-11, P2-12, P2-17 | P2-23 |
| P2-26 | Import parser + mapping (pure Dart) | DEPENDENT | P2-02, P2-04, P2-09 | P2-25 |
| P2-27 | Import use cases + data | DEPENDENT | P2-26, P2-10, P2-17 | P2-25 |
| P2-28 | Import wizard screen | DEPENDENT | P2-27, P2-12 | — |
| P2-29 | Integration: dashboard cards, activity text, module hooks | DEPENDENT | P2-11, P2-18, P2-22 | P2-26…P2-28 |
| P2-30 | Hardening, performance, acceptance, sign-off | DEPENDENT | all | — |

### 4.2 Recommended order (single developer / single AI)

`P2-01 → P2-02 → P2-03 → P2-04 → P2-05 → P2-06 → P2-07 → P2-08 → P2-09 → P2-10 → P2-11 → P2-12 → P2-13 → P2-14 → P2-15 → P2-16 → P2-17 → P2-18 → P2-19 → P2-20 → P2-21 → P2-22 → P2-23 → P2-24 → P2-25 → P2-26 → P2-27 → P2-28 → P2-29 → P2-30`

**Why this order:** the first working end-to-end slice (catalog → add an expense → see it in a list) lands at P2-15. That is the point where you can already replace the daily part of the spreadsheet. Budgets, fund money, reports and import follow.

### 4.3 Parallel lanes (if you run several agents; each lane touches different folders)

| Lane | Steps in order | Folders touched |
| --- | --- | --- |
| **A — Catalog & expense core** (critical path) | P2-01 → P2-03 → P2-04 → P2-05 → P2-06 → P2-09 → P2-10 → P2-11 → P2-13 → P2-14 → P2-15 | `items_categories/`, `expenses/` |
| **B — Money ledger** | (after P2-03) P2-08 → (after P2-10) P2-19 ∥ P2-20 → P2-21 → P2-22 → P2-23 | `fund/`, `contributions/`, `advances/` |
| **C — Plans & views** | (after P2-03) P2-07 → (after P2-04) P2-17 → P2-18; P2-24 → P2-25 | `settings/`, `budgets/`, `reports/` |
| **D — UI kit** | P2-02, P2-12, then P2-16 | `core/utils`, `shared/widgets`, `app/gallery` |
| **E — Import** | P2-26 → P2-27 → P2-28 | `import/` |

Conflict hot-spots when lanes merge (resolve by appending, never reordering): `firestore.rules`, `firestore.indexes.json`, `firestore_paths.dart`, `app_bn.arb` / `app_en.arb` (+ regenerate l10n), `app_routes.dart`, `bazar_entries.dart`, `gallery_sections.dart`, `bootstrap.dart` provider overrides, `test/contract/rules_fixtures_test.dart`, `audit_event_type.dart`. Merge these one lane at a time and re-run `flutter gen-l10n`.

---

## 5. Step cards — Wave A: foundation (P2-01 … P2-03)

### P2-01 — Preflight gate, Bazar skeleton, seams

| | |
| --- | --- |
| **Type** | INDEPENDENT (gate for everything else) |
| **Depends on** | Phase 1 hardening H1–H12 merged |
| **Parallel with** | — |
| **Unblocks** | every other step |

**Gate (do first, report the result in `PROGRESS.md`; stop if anything is red).** `PROGRESS.md` says the hardening was written without an SDK and H13 was never run, so verify the base: `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test --exclude-tags golden`, the rules suite against the emulator, `node tools/check_indexes.mjs`, `flutter build apk --flavor dev -t lib/main_dev.dart`. Fix failures in a separate commit before continuing. Manually confirm on a real device once: sign up → create family → second account joins → approve (Phase 1 acceptance).

**Files**

| Path | Action | Contents |
| --- | --- | --- |
| `docs/PHASE2_BAZAR_ROADMAP.md` | NEW | a copy of this file |
| `CLAUDE.md` | EDIT | (a) folder structure: add `bazar/fund`, `bazar/settings`; (b) append the "Phase 2 rules" block below |
| `docs/decisions/0006-append-only-ledger.md`, `0007-fund-balance-from-ledger.md`, `0008-bazar-offline-and-rules-cost.md` | NEW | one-page ADRs for D-P2-3/4/2 and the rules access-call decision in P2-10 |
| `lib/features/bazar/bazar_entries.dart` | NEW | `class BazarEntry { final String id; final IconData icon; final String Function(AppLocalizations) label; final String route; final Permission? requires; }` and `final List<BazarEntry> bazarEntries = [];` — **each later step appends one entry** |
| `lib/features/bazar/presentation/bazar_home_screen.dart` | NEW | `ConsumerWidget`. App bar `l10n.navBazar`; body = `ListView` of `AppCard` tiles built from `bazarEntries` (hidden when `requires != null && !ref.can(requires)`); `EmptyState` while the list is empty. Later steps add: month summary card (P2-29), "set up starter catalog" card (P2-06), FAB "Add expense" (P2-13). |
| `lib/features/bazar/bazar_module.dart` | EDIT | route builder → `BazarHomeScreen`; keep `requiredPermission` null (the module switch is the gate). |
| `lib/features/bazar/presentation/bazar_placeholder_screen.dart` | DELETE | |
| `lib/features/family/presentation/family_providers.dart` | EDIT | add `final familySeedersProvider = Provider<List<FamilySeeder>>((ref) => const <FamilySeeder>[]);` and pass `seeders: ref.watch(familySeedersProvider)` in `createFamilyProvider`. (Presentation imports only the domain interface `FamilySeeder`; the concrete seeder is wired in `bootstrap.dart` in P2-06.) |
| `test/features/family/domain/create_family_test.dart` | EDIT | one test proving a provider-supplied seeder's writes reach `InMemoryBackend.seeded`. |
| `test/features/bazar/bazar_home_screen_test.dart` | NEW | renders in bn/en, light/dark; empty list shows `EmptyState`; an entry with an unmet permission is hidden. |

**Phase 2 rules to append to `CLAUDE.md`**
```text
## Phase 2 rules (Bazar & finance)
25. Money fields in Firestore are integer paisa named *Paisa; quantities are integer *Milli. Never double/num.
26. Everyday writes (expense, trip, contribution, budget, custom item) are ONE batch, NO server probe, so they queue offline. Money-integrity writes (settle advance, close/reopen month, import, undo import, catalog backfill, settings) need the server (probe + transaction/batch).
27. A use case builds a pure write plan; the repository stages it. domain/ never sees TxRunner or Firestore types.
28. fundTransactions, settlements and expense revisions are append-only. Corrections are NEW compensating rows. The original expense/ledger row is never edited by a later settlement or correction.
29. Fund balance is never stored as a mutable number; it is computed from the ledger window (ADR 0007).
30. Reports/budgets/dashboards share ONE spend aggregation (MonthSpend/ReportEngine). Soft-deleted expenses are excluded everywhere.
31. A closed month rejects every write dated in it (use case AND rules). Only ReopenMonth (Admin or Household Manager, with a note) changes that.
32. Every new collection follows docs/new_collection_checklist.md in the same commit; new audit types/refTypes go in AuditEventType AND rules eventTypes()/refTypes().
33. Screens read derived providers (bazar_providers.dart); only providers call use cases/repositories.
```

**Interacts with:** nothing yet; it creates the seams (`bazarEntries`, `familySeedersProvider`, home screen) every later step plugs into.
**Done when:** gate green; the Bazar tab shows the new home (empty state); `bazar_placeholder_screen.dart` is gone; CI green.

---

### P2-02 — Pure helpers: money math, unit catalog, date ranges

| | |
| --- | --- |
| **Type** | INDEPENDENT (pure Dart, touches only `core/utils`) |
| **Depends on** | — (schedule after P2-01 for a green base) |
| **Parallel with** | P2-03, P2-12 |
| **Unblocks** | P2-04, P2-08, P2-24, P2-26 |

**Files**

| Path | Action | Contents |
| --- | --- | --- |
| `lib/core/utils/money_math.dart` | NEW | `int? basisPoints(Money part, Money whole)` → `part*10000/whole` rounded half-up, `null` when `whole <= 0` (UI shows "—"); `List<Money> splitEqually(Money total, int parts)` → remainder paisa goes one each to the first `total.paisa % parts` entries (asserts `parts > 0`, `total >= 0`); `Money maxMoney(Money a, Money b)`, `Money minMoney(Money a, Money b)`; `Money? tryLineTotal(Quantity? q, Money? unitPrice)` (null unless both present, else existing `lineTotal`). No `double`/`num`. |
| `lib/core/utils/unit_catalog.dart` | NEW | `extension UnitInfo on Unit { bool get isWeight; bool get isVolume; bool get isCount; }`; `Unit? parseUnit(String raw)` accepts (case-insensitive, trimmed, Bangla or English): `কেজি/kg/kilo` → kg; `গ্রাম/g/gm/gram` → g; `লিটার/l/litre/liter` → litre; `টা/টি/পিস/piece/pcs` → piece; `ডজন/dozen` → dozen; `প্যাকেট/packet/pack` → packet; `সিলিন্ডার/cylinder` → cylinder. Unknown → `null`. |
| `lib/core/utils/date_ranges.dart` | NEW | `enum RangePreset { today, yesterday, last7Days, thisWeek, thisMonth, lastMonth, thisYear, custom }`; `DateKeyRange resolveRange(RangePreset p, {required DateKey today, int weekStartDay = DateTime.saturday, DateKeyRange? custom})` (custom requires `custom != null` and `start <= end`); `DateKey startOfWeek(DateKey d, int weekStartDay)` = `d.addDays(-((d.weekday - weekStartDay + 7) % 7))`; `DateKeyRange previousComparable(DateKeyRange r)` → full calendar month → previous full calendar month, full year → previous year, otherwise same-length range ending the day before `r.start`; `int lengthInDays(DateKeyRange)`; `Iterable<DateKey> daysIn(DateKeyRange)`; `List<MonthKey> monthsIn(DateKeyRange)`. |
| `test/core/utils/money_math_test.dart` | NEW | half-up rounding at `.5`; `basisPoints(80, 100) == 8000`; zero whole → null; `splitEqually(৳100.00, 3)` = `[3334, 3333, 3333]` paisa (sum preserved); parts = 1. |
| `test/core/utils/unit_catalog_test.dart`, `date_ranges_test.dart` | NEW | every preset; `thisWeek` for Wed 2026-10-21 with Saturday start = 2026-10-17…2026-10-23; `lastMonth` from January; leap day; `previousComparable` when previous month is shorter (March → February); year boundary. |
| `test/core/utils/no_floating_point_test.dart` | EDIT | add `lib/core/utils/money_math.dart` to the scanned file list. |

**Interacts with:** nothing at runtime; consumed by catalog (units), budgets (`basisPoints`), contributions (`splitEqually`), reports (ranges).
**Done when:** all tests green; `no_floating_point_test` passes with the new file.

---

### P2-03 — Phase 2 vocabulary: audit types, paths, permissions, localization base

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-01 |
| **Parallel with** | P2-02 |
| **Unblocks** | P2-04, P2-07, P2-08 (everything that writes) |

Why first: every Phase 2 write is rejected until the closed lists in the rules contain its audit `type`/`refType` (G-3), and two manager-only actions have no permission (G-6).

**Files**

| Path | Action | Contents |
| --- | --- | --- |
| `lib/core/audit/audit_event_type.dart` | EDIT | add the constants of §3.9 (`bazarCatalogSeeded = 'bazar.catalog_seeded'`, `bazarCategoryCreated`, … `bazarImportUndone`) and append them to `all`. |
| `firebase/firestore.rules` | EDIT | extend `eventTypes()` with the same strings and `refTypes()` with `category, item, expense, trip, budget, contribution, contributionPlan, settlement, month, importBatch`. Update the header comment. |
| `test/core/audit/audit_event_type_test.dart` | EDIT | keep the Dart↔rules comparison; add a mirror check for `refTypes()` (add `lib/core/audit/audit_ref_type.dart` with constants if refTypes are not mirrored yet). |
| `lib/core/localization/activity_text.dart` | EDIT | one `case` per new type; param keys per §3.9; amounts via `MoneyFormatter` (`Money.paisa(int.tryParse(p('amount')) ?? 0)`). |
| `lib/core/localization/arb/app_bn.arb`, `app_en.arb` | EDIT | keys `activityBazar*` (one per type) + `unitKg, unitG, unitLitre, unitPiece, unitDozen, unitPacket, unitCylinder` + the `bazarErr*` messages + `bazarSettingsTitle` etc. as needed. Run `flutter gen-l10n`. |
| `lib/core/localization/unit_labels.dart` | NEW | `extension UnitLabels on AppLocalizations { String unitLabel(Unit u) }` (pattern of `role_labels.dart`). |
| `lib/features/bazar/presentation/bazar_failure_messages.dart` | NEW | `extension BazarFailureMessages on AppLocalizations { String bazarFailureMessage(AppFailure f) }` — exhaustive `switch` over `AppFailure`; `Validation`/`Conflict` map each code of §3.6 to a key; unknown code → generic message. |
| `lib/core/firebase/firestore_paths.dart` | EDIT | add `monthClosingsSubcollection = 'monthClosings'`, `importBatchesSubcollection = 'importBatches'`; `monthClosings(f)`, `monthClosingDoc(f, MonthKey-string)`, `importBatches(f)`, `importBatchDoc(f, id)`, `expenseRevisions(f, expenseId)`, `expenseRevisionDoc(f, expenseId, revId)`, `bazarSettingsDoc(f) => settingsDoc(f, 'bazar')`. |
| `test/core/firebase/paths_match_rules_test.dart` | EDIT | add `monthClosingsSubcollection` and `importBatchesSubcollection` to the `pending` set (removed in P2-10 / P2-27). |
| `lib/core/permissions/permission.dart` | EDIT | add `closeBazarMonth(PermissionModule.bazar)`, `importBazarData(PermissionModule.bazar)` and **`requestContribution(PermissionModule.bazar)`**. |
| `lib/core/permissions/permission_policy.dart` | EDIT | `closeBazarMonth` and `importBazarData` => same rule as `recordContribution` (Admin; Household Manager/moderator while `moderatorManagesFinance`), `requestContribution => any active member (Bazar module on)`; update the matrix comment. `recordContribution` is unchanged (admin; Household Manager while `moderatorManagesFinance`). |
| `test/core/permissions/permission_policy_test.dart` | EDIT | rows for the three (close/import: admin yes, moderator yes while `moderatorManagesFinance` and no when off, member no; `requestContribution`: admin/moderator/member yes, pending/disabled actor no; denied when Bazar module off). |
| `lib/core/localization/arb/app_bn.arb`, `app_en.arb` (role label) | EDIT | **Rename the display label of the `moderator` role** (find it with `grep -rn -i "moderator" lib/core/localization/arb lib/core/localization/role_labels.dart`) to **"Household Manager" / "সংসার ব্যবস্থাপক"**; change text only, never the stored value `moderator`. Update any golden/test that asserts the old label. Also use this label in every Bazar message (e.g. "Only the Household Manager or Admin can approve"). |
| `docs/permission_matrix.md` | REGENERATE | `UPDATE_PERMISSION_MATRIX=1 flutter test test/core/permissions/permission_matrix_doc_test.dart`. |
| `test/features/bazar/presentation/bazar_failure_messages_test.dart` | NEW | every code listed in §3.6 returns a non-empty string in bn **and** en; no raw code leaks. |

**Interacts with:** `AuditWriter` (types accepted), `activityText` (Phase 4 feed), `PermissionPolicy` (used by P2-19+).
**Rules / tests:** the existing rules suite must stay green (only list literals changed); add one emulator test that a `bazar.expense_created` audit entry by an active member is **allowed** and an unknown type is **denied**.
**Done when:** mirror tests pass, permission matrix doc regenerated and committed, `flutter gen-l10n` produces no diff on a second run.

---

## 6. Step cards — Wave B: catalog (P2-04 … P2-07)

### P2-04 — Catalog domain + `ItemSearch`

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-02, P2-03 |
| **Parallel with** | P2-07, P2-08, P2-12 |
| **Unblocks** | P2-05, P2-09, P2-17, P2-26 |

**Files** (all under `lib/features/bazar/items_categories/domain/` unless noted)

| Path | Contents |
| --- | --- |
| `category.dart` | `final class Category { id, nameBn, nameEn?, colorIndex (0–11), emoji?, imageData?, sortOrder, active, builtIn, seedKey? }` with `==`, `hashCode`, `copyWith`, `String displayName({required bool bangla})` (falls back to the other language). |
| `item.dart` | `final class Item { id, nameBn, nameEn?, categoryId, Unit defaultUnit, List<String> aliases, emoji?, imageData?, int useCount, Money? lastPrice, Money? lastUnitPrice, DateTime? lastUsedAt, active, builtIn, seedKey? }` + same helpers. |
| `text_normalizer.dart` | `String normalizeSearch(String s)`: trim, lower-case, collapse whitespace, remove ZWJ/ZWNJ (U+200C/U+200D), compose Bangla nukta pairs (ড+় → ড়, ঢ+় → ঢ়, য+় → য়), map Bangla digits to English (`toEnglishDigits`). |
| `item_search.dart` | `final class ItemSearch { ItemSearch(Iterable<Item> items); List<Item> search(String query, {String? categoryId, int limit = 8}); }` Ranking key = (`matchTier` asc, `useCount` desc, `builtIn` first, `nameBn`): tier 0 exact name/alias, tier 1 name/alias **prefix**, tier 2 any word-prefix, tier 3 contains. Inactive items excluded. Empty query → items with `useCount > 0` by `useCount` desc, then built-ins in seed order, capped by `limit`. Matches `nameBn`, `nameEn` and every alias — **no romanizer**: Latin queries work through seeded aliases, and a custom item's `nameEn` tokens count as aliases. |
| `catalog_index.dart` | `final class CatalogIndex { CatalogIndex({categories, items}); Map<String, Category> categoriesById; Map<String, Item> itemsById; Map<String, List<Item>> itemsByCategory; List<Category> activeCategories (sorted by sortOrder); late final ItemSearch search; Category? categoryOf(Item); }` — the only thing screens read. |
| `catalog_repository.dart` | `abstract interface class CatalogRepository { Stream<List<Category>> watchCategories(String familyId); Stream<List<Item>> watchItems(String familyId); Future<Result<List<Category>>> getCategories(String familyId); Future<Result<List<Item>>> getItems(String familyId); Future<Result<void>> saveCategory(String familyId, Category c, AuditEvent e, {required bool isNew}); Future<Result<void>> saveItem(String familyId, Item i, AuditEvent e, {required bool isNew}); Future<Result<bool>> isCatalogEmpty(String familyId); /* server read */ Future<Result<void>> seedDefaultCatalog(String familyId, String actorUid, AuditEvent e); }` |
| `usecases/add_category.dart`, `update_category.dart`, `deactivate_category.dart`, `add_item.dart`, `add_custom_item.dart`, `update_item.dart`, `deactivate_item.dart` | Constructor `{required CatalogRepository catalog, required FamilyRepository families, required Clock clock, required IdGenerator newId}`; `call({required String actorUid, required String familyId, …})` → `Result<…>`. `requirePermission` FIRST (§3.3). Validation: names trimmed, 1–60 chars (`Validation('nameBn','required'|'too_long')`), ≤ 10 aliases each ≤ 40, `colorIndex` 0–11, `categoryId` must exist and be active (`NotFound('category')`), duplicate normalized `nameBn` inside the same category among active items → `Conflict('duplicate_item')`. New `sortOrder` = max + 1. `AddCustomItem` requires `addOwnExpense`, forces `builtIn=false`, `useCount=0`. Events per §3.9. |
| `test/features/bazar/bazar_test_helpers.dart` | NEW — `BazarFixture` (backend, `FakeClock(DateTime.utc(2026, 10, 18, 9))`, `SeqIds`, a family `f1` with admin `alice`, moderator `bob`, member `cara`, pending `dave`) modelled on `family_test_helpers.dart`. |
| `test/support/in_memory_bazar_backend.dart` | NEW — implements `CatalogRepository` over maps with live streams and an `events` list; later steps add the other ports to this same class. |

**Interacts with:** `FamilyRepository.getMember/getPermissionSettings` (through `requirePermission`); P2-09 reads `Item`/`CatalogRepository` to resolve and bump items.
**Rules / tests:** search table (`alu` → আলু via alias, Bangla prefix `আ` → আলু first, `potato`, exact beats prefix, frequent beats predefined, inactive hidden, empty query → frequent first, nukta-variant spelling matches); every use case: permission denial for member/pending, validation, duplicate, event written; `normalizeSearch` unit tests.
**Done when:** all pure/use-case tests green; no file imports Firebase; `layer_boundaries_test` green.

---

### P2-05 — Catalog data layer, rules and providers

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-04 |
| **Parallel with** | P2-07, P2-08, P2-12 |
| **Unblocks** | P2-06, P2-09 (item usage rules), P2-10, P2-16 |

**Files**

| Path | Action | Contents |
| --- | --- | --- |
| `…/items_categories/data/catalog_mappers.dart` | NEW | `abstract final class CatalogMappers`: `categoryToMap(Category, BaseDocumentMetadata)`, `categoryFromMap(String id, Map<String,dynamic>)` (tolerant: missing/unknown → defaults; unknown `defaultUnit` → `Unit.piece`), `categoryChangeMap(Category, {actorUid, now})`, `itemToMap`, `itemFromMap`, `itemChangeMap`, `itemUsageMap(ItemUsageBump, {actorUid, now})` (only `useCount`, `lastPricePaisa`, `lastUnitPricePaisa`, `lastUsedAt`, `updatedAt`, `updatedBy`). Money stored as `*Paisa` ints. |
| `…/data/firestore_catalog_repository.dart` | NEW | ctor `{required TxRunner tx, required Clock clock, FirebaseFirestore? firestore}`. Streams: `_db.collection(FirestorePaths.bazarCategories(f)).limit(kMaxCatalogDocs).snapshots()` (and items) — **`.limit(` must be in the same expression** (`no_unbounded_queries_test`). Writes: `guardWrite(() => _tx.runBatch(...))` **without probe** (catalog edits are everyday, queue offline) except `seedDefaultCatalog` (probe). Every write calls `AuditWriter.write`. |
| `lib/core/firebase/query_limits.dart` | EDIT | `const int kMaxCatalogDocs = 500;` |
| `firebase/firestore.rules` | EDIT | inside `match /families/{f}`: new helper `financeManager(f)` = `isAdmin(f) || (isMod(f) && (exists(permissionsPath(f)) ? get(permissionsPath(f)).data.get('moderatorManagesFinance', true) : true))`; `categoryKeys()`, `itemKeys()`, `categoryOk(d)`, `itemOk(d)` (types, lengths, `colorIndex` 0–11, aliases list ≤ 10, `imageData` ≤ 24 000, `useCount` int ≥ 0, money via `isNonNegativeIntOrMissing`). Blocks: `bazarCategories/{c}` — read `canReadFamilyData(f)`; create `verified() && (financeManager(f) || creatingFamily(f)) && createsAsSelf() && categoryOk(...)`; update `financeManager(f) && writesAsSelf() && categoryOk(...)` with `createdAt/createdBy/builtIn/seedKey` unchanged; delete `false`. `bazarItems/{i}` — read members; create `(financeManager(f) || creatingFamily(f) || (isActiveMember(f) && builtIn == false && useCount == 0)) && verified() && createsAsSelf() && itemOk(...)`; update by `financeManager(f)` (same immutables) **or** by any active member when `affectedKeys().hasOnly(['useCount','lastPricePaisa','lastUnitPricePaisa','lastUsedAt','updatedAt','updatedBy'])` and `0 < request.resource.data.useCount - resource.data.useCount <= 40`; delete `false`. |
| `test/core/firebase/paths_match_rules_test.dart` | EDIT | remove `bazarCategoriesSubcollection`, `bazarItemsSubcollection` from `pending`. |
| `firebase/rules_test/catalog.test.mjs` | NEW | copy the template. Cases: member/mod/admin/pending/other-family reads; admin and moderator (finance on) create category; moderator with `moderatorManagesFinance:false` denied; member creates category denied; member creates custom item allowed; member creates a built-in item denied; member bumps `useCount` +1 allowed, +100 denied, bumps `useCount` **and** renames denied; unknown field denied; `colorIndex: 12` denied; hard delete denied; family-creation batch containing 11 categories + 54 items allowed (creatingFamily). |
| `test/contract/rules_fixtures_test.dart`, `firebase/rules_test/contract.test.mjs`, `fixtures/*.json` | EDIT | add fixtures `category`, `item`, `item_usage` produced by the real mappers; commit them. |
| `test/contract/rules_key_sets_test.dart` | EDIT | mirror `categoryKeys()`/`itemKeys()` against the mapper output. |
| `…/items_categories/presentation/catalog_providers.dart` | NEW | `catalogRepositoryProvider` (`throw UnimplementedError`, overridden in `bootstrap.dart`); `categoriesProvider`, `itemsProvider` (`StreamProvider`, empty list when no family); `catalogIndexProvider = Provider<CatalogIndex>` built from both (`AsyncValue.value ?? const []`); one provider per use case (`addCategoryProvider` … pattern of `family_providers.dart`). |
| `lib/app/bootstrap.dart` | EDIT | `final catalog = FirestoreCatalogRepository(tx: tx, clock: clock);` and `catalogRepositoryProvider.overrideWithValue(catalog)`. |
| `test/features/bazar/items_categories/data/*_test.dart` | NEW | mapper round-trip incl. unknown unit; repository through `FakeTxRunner` asserts doc paths, `*Paisa` ints, audit docs in the same batch. |

**Interacts with:** `catalogIndexProvider` is read by the Add Expense form (P2-13), catalog manager (P2-16), budgets (P2-17/18), reports (P2-24/25), import (P2-26).
**Done when:** rules suite green with the new file; the contract fixtures pass; paths test no longer lists the two collections.

---

### P2-06 — Default catalog seed and backfill

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-05 |
| **Parallel with** | P2-07, P2-08, P2-09 |
| **Unblocks** | P2-16, usable data for P2-13 |

**Files**

| Path | Action | Contents |
| --- | --- | --- |
| `…/items_categories/domain/default_catalog.dart` | NEW | pure `const` data: `SeedCategory(key, bn, en, colorIndex, emoji, order)` ×11 and `SeedItem(key, bn, en, categoryKey, unit, aliases)` ×54 exactly as **Appendix A** (ids become `cat_<key>`, `item_<key>`). |
| `…/data/default_catalog_writes.dart` | NEW | `List<SeedWrite> buildDefaultCatalogWrites({required String familyId, required String actorUid, required DateTime now})` — maps through `CatalogMappers` with `BaseDocumentMetadata(createdAt: now, createdBy: actorUid, …)`, `builtIn: true`, `seedKey`. |
| `…/data/default_catalog_seeder.dart` | NEW | `class DefaultCatalogSeeder implements FamilySeeder { List<SeedWrite> seed(SeedContext c) => buildDefaultCatalogWrites(familyId: c.familyId, actorUid: c.actorUid, now: c.now); }` (G-2: lives in `data/`). |
| `lib/app/bootstrap.dart` | EDIT | `familySeedersProvider.overrideWithValue(<FamilySeeder>[DefaultCatalogSeeder()])`. (`lib/app/` may reach `data/` only here — layer test.) |
| `…/domain/usecases/ensure_catalog_seeded.dart` | NEW | `EnsureCatalogSeeded.call({actorUid, familyId})`: `requirePermission(manageCatalogAndBudgets)` → `catalog.isCatalogEmpty` (server read, `limit(1)` on categories) → if not empty `Failure(Conflict(code: 'catalog_not_empty'))` → else `catalog.seedDefaultCatalog(...)` with `bazar.catalog_seeded` event (`categories: '11', items: '54'`). Server required (G-8). |
| `…/data/firestore_catalog_repository.dart` | EDIT | implement `seedDefaultCatalog` (probe + one batch ≤ 500 writes = ~56 docs + 2 audit) and `isCatalogEmpty`. |
| `lib/features/bazar/presentation/bazar_home_screen.dart` | EDIT | when `categoriesProvider` has loaded and is empty: if `ref.can(manageCatalogAndBudgets)` show a card "Set up the starter catalog" + button → `ensureCatalogSeededProvider`; otherwise `EmptyState` "Ask an admin to set up the catalog". **Never seed silently** (offline safety, surprise-free). |
| `test/features/bazar/items_categories/domain/default_catalog_test.dart` | NEW | unique keys; every item's category exists; every unit parses; aliases ≤ 10, names ≤ 60; `cat_*`/`item_*` id pattern; total writes + family docs ≤ `kMaxBatchWrites`. |
| `…/usecases/ensure_catalog_seeded_test.dart`, `create_family_seed_test.dart` | NEW | new family via `CreateFamily(seeders: [fake])` has 11 categories; backfill works once and returns `catalog_not_empty` the second time; member denied; offline (`failNextWrite = Network()`) fails fast and writes nothing. |
| `firebase/rules_test/contract.test.mjs` | EDIT | the **complete real seed** (all categories + items + family docs + audit) in ONE create-family batch is allowed (proves the 500-write and rules limits). |

**Interacts with:** `CreateFamily` (new families), BazarHome (existing families), `catalogIndexProvider` (immediately shows the seeded data through the listener).
**Done when:** a brand-new family has the catalog without any action; the existing dev family gets it with one tap; the seed list matches Appendix A (the owner will review the list later; every category and item is editable afterwards in the catalog manager, so it is only a starting point).

---

### P2-07 — Bazar settings (domain + data + rules + providers; screen is in P2-16)

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-03 |
| **Parallel with** | P2-04…P2-06, P2-08, P2-12 |
| **Unblocks** | P2-17, P2-19, P2-24 |

**Files**

| Path | Action | Contents |
| --- | --- | --- |
| `…/bazar/settings/domain/bazar_settings.dart` | NEW | `final class BazarSettings { int weekStartDay (1–7, default 6); Money defaultMonthlyContribution (default zero); int contributionDueDay (1–28, default 5); List<int> alertThresholds (default [80, 100]); MonthKey? fundStartMonth; static const defaults; copyWith; ==/hashCode }`. |
| `…/settings/domain/bazar_settings_repository.dart` | NEW | `Stream<BazarSettings> watch(String familyId)` (absent document ⇒ `defaults`), `Future<Result<BazarSettings>> get(String familyId)`, `Future<Result<void>> save(String familyId, BazarSettings s, AuditEvent e)`. |
| `…/settings/domain/usecases/update_bazar_settings.dart` | NEW | `requirePermission(manageCatalogAndBudgets)`; validation (weekday 1–7, due day 1–28, thresholds ascending, unique, 1–200, ≤ 4, `fundStartMonth` valid); event `bazar.settings_updated`. |
| `…/settings/data/bazar_settings_mappers.dart`, `firestore_bazar_settings_repository.dart` | NEW | document `settings/bazar` (path `FirestorePaths.bazarSettingsDoc`); `set(..., merge: true)` so the first save creates it; **server required** (probe); `watch` uses `watchKnownDoc` and maps `null` → defaults. |
| `firebase/firestore.rules` | EDIT | `settingsKeys()` += `weekStartDay, defaultMonthlyContributionPaisa, contributionDueDay, alertThresholds, fundStartMonth`; `settingsOk` adds: ints within range (`d.weekStartDay is int && >= 1 && <= 7`), `moneyOk`-style for the contribution, `alertThresholds is list && size() <= 4`, `monthKeyOk(d.fundStartMonth)`. In `match /settings/{s}` allow create/update when `isAdmin(f) || (s == 'bazar' && financeManager(f))` (keep `creatingFamily` path). |
| `firebase/rules_test/bazar_settings.test.mjs` | NEW | admin and finance-moderator can write `settings/bazar`; moderator without finance denied; member denied; moderator cannot write `settings/general`; out-of-range weekday denied; unknown key denied. |
| `test/contract/*` | EDIT | fixture `settings_bazar`. |
| `…/settings/presentation/bazar_settings_providers.dart` | NEW | `bazarSettingsRepositoryProvider` (override in bootstrap), `bazarSettingsProvider` (`Provider<BazarSettings>` = stream value or `defaults`), `updateBazarSettingsProvider`. |
| `lib/app/bootstrap.dart` | EDIT | override. |

**Interacts with:** `weekStartDay` → `resolveRange` in reports; `alertThresholds` → `ComputeBudgetStatus`; `defaultMonthlyContribution`/`contributionDueDay` → contribution plans; `fundStartMonth` → fund window start (P2-08/P2-11).
**Done when:** rules + domain tests green; absent document yields defaults everywhere (no crash for old families).

---

## 7. Step cards — Wave C: money ledger and expense core (P2-08 … P2-11)

### P2-08 — Fund ledger and month-closing domain

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-02, P2-03 |
| **Parallel with** | P2-04…P2-07, P2-12 |
| **Unblocks** | P2-09, P2-19, P2-20, P2-21 |

Pure Dart only (no repository writes yet — those arrive with the use cases that need them).

**Files** (`lib/features/bazar/fund/domain/` and `…/advances/domain/`)

| Path | Contents |
| --- | --- |
| `fund_transaction.dart` | `enum FundTxType { contribution, expense, reimbursement, opening, adjustment }`, `enum FundRefType { expense, contribution, settlement, month, manual }`, `final class FundTransaction { id, type, Money amount (signed), DateKey dateKey, MonthKey monthKey, refType, refId, note?, createdBy, createdAt }` with **named factories that enforce the sign rule**: `FundTransaction.forExpense({expenseId, total, dateKey})` → id `exp_<expenseId>`, amount `-total`; `forContribution({contributionId, amount, …})` → `con_<id>`, `+amount`; `forReimbursement({settlementId, amount, …})` → `stl_<id>`, `-amount`; `opening({monthKey, amount})` → `open_<yyyy-MM>`; `adjustment({eventId, suffix, amount, refType, refId, …})` → `adj_<eventId>[_suffix]` (amount ≠ 0). |
| `fund_balance_calculator.dart` | `abstract final class FundBalanceCalculator { static Money balance(Iterable<FundTransaction>); static FundSummary summarize(Iterable<FundTransaction>); static Money ledgerFor(Iterable<FundTransaction>, String refId); }` — `FundSummary { Money received, spent, reimbursed, opening, adjustments, balance }`. |
| `ledger_integrity_check.dart` | `List<LedgerIssue> checkLedger({required List<Expense>… }` is added in P2-22 (needs `Expense`); here only the `LedgerIssue` value class. |
| `month_closing.dart` | `enum MonthStatus { open, closed }`; `final class MonthClosing { MonthKey monthKey; MonthStatus status; DateTime? closedAt; String? closedBy; Money? closingBalance; DateTime? reopenedAt; String? reopenedBy; String? reopenNote; int reopenCount }`; `abstract final class MonthLocks { static bool isLocked(MonthKey m, Map<MonthKey, MonthClosing> closings); static MonthKey? fundWindowStart(Map<MonthKey, MonthClosing> closings, MonthKey? fundStartMonth); }` — `fundWindowStart` = month **after** the latest `closed` month, else `fundStartMonth`, else `null` (no fund set up yet). |
| `fund_repository.dart` | `abstract interface class FundRepository { Stream<List<FundTransaction>> watchTransactionsFrom(String familyId, MonthKey from); Future<Result<List<FundTransaction>>> getMonthTransactions(String familyId, MonthKey month); Future<Result<List<FundTransaction>>> getTransactionsForRef(String familyId, String refId); Stream<List<MonthClosing>> watchClosings(String familyId); Future<Result<MonthClosing?>> getClosing(String familyId, MonthKey month); }` |
| `…/advances/domain/member_advance.dart` | `enum AdvanceStatus { pending, partial, settled, voided }`; `final class MemberAdvance { expenseId, memberId, Money amount, Money settled, status, DateKey dateKey, MonthKey monthKey; Money get remaining; static AdvanceStatus statusFor(Money amount, Money settled) }` (settled 0 → pending, 0 < settled < amount → partial, == → settled; `settled > amount` is invalid). |
| `…/advances/domain/settlement.dart` | `final class Settlement { id, advanceId, memberId, Money amount, DateKey dateKey, MonthKey monthKey, String? method, String? note, String fundTxId }`. |
| `…/advances/domain/advance_repository.dart` | `Stream<List<MemberAdvance>> watchOpenAdvances(String familyId)` (status pending/partial), `Future<Result<MemberAdvance?>> getAdvance(String familyId, String expenseId)`, `Stream<List<Settlement>> watchSettlements(String familyId, {String? advanceId})`. |
| Tests | calculator on a hand-computed month; every factory sign; window-start cases (no closings + no start → null; latest closed 2026-09 → 2026-10; reopened month no longer closed); advance status transitions and `settled > amount` rejected. |

**Interacts with:** these types are the vocabulary of P2-09 (expense plans), P2-19–P2-23 (contributions, advances, month close) and P2-11 (`fundBalanceProvider`).
**Done when:** pure tests green; no Firebase import; `FundTransaction` can only be built with a correct sign.

---

### P2-09 — Expense domain, use cases and in-memory backend

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-04, P2-08 |
| **Parallel with** | P2-05, P2-06, P2-07, P2-12 (P2-10 needs P2-05) |
| **Unblocks** | P2-10, P2-24, P2-26 |

All money rules are proven here, before any screen exists.

**Files** (`lib/features/bazar/expenses/domain/`)

| Path | Contents |
| --- | --- |
| `funding.dart` | `enum FundingSource { fund, member }`; `enum ExpenseSource { manual, import }`. |
| `expense.dart` | `final class Expense { id, DateKey dateKey, MonthKey monthKey, DateTime occurredAt, String? itemId, String itemName, String categoryId, Quantity? qty, Unit? unit, Money? unitPrice, Money total, FundingSource funding, String? paidByMemberId, bool reimbursable, String? purchaserId, String? tripId, String? shop, String? note, ExpenseSource source, String? importBatchId, DateTime? deletedAt, String? deletedBy, String createdBy, DateTime createdAt; bool get isDeleted }` + `copyWith`, `==`. Invariants asserted in the constructor: `total > 0`; `funding == member ⇔ paidByMemberId != null`; `reimbursable` only with `member`. |
| `expense_draft.dart` | `final class ExpenseDraft { DateKey dateKey; String? itemId; String itemName; String categoryId; Quantity? qty; Unit? unit; Money? unitPrice; Money? typedTotal; FundingSource funding; String? paidByMemberId; bool reimbursable; String? purchaserId; String? shop; String? note; bool rememberItem }` — the validated-but-not-yet-saved input. |
| `expense_totals.dart` | `Result<Money> computeTotal({Quantity? qty, Money? unitPrice, Money? typedTotal})`: both `qty` and `unitPrice` → `lineTotal` (typed total ignored); `qty` xor `unitPrice` → `Validation('unitPrice'|'qty','qty_unit_required')`; else `typedTotal`; result must be `> 0` (`amount_not_positive`). |
| `write_plans.dart` | Pure plan objects the repository stages: `ItemUsageBump { itemId, int increments, Money? lastPrice, Money? lastUnitPrice, DateTime at }`; `ExpenseWritePlan { Expense expense; FundTransaction? fundTx; MemberAdvance? advance; ItemUsageBump? usage; Item? newItem }`; `TripWritePlan { Trip trip; List<ExpenseWritePlan> lines; List<ItemUsageBump> usage (aggregated per item) }`; `ExpenseEditPlan { Expense updated; Map<String,Object?> before; List<String> changedFields; List<FundTransaction> adjustments; AdvanceChange? advanceChange }`; `ExpenseDeletePlan` / `ExpenseRestorePlan { Expense updated; Map<String,Object?> before; List<FundTransaction> adjustments; AdvanceChange? advanceChange }`. `AdvanceChange { MemberAdvance after; }`. |
| `trip.dart` | `final class Trip { id, DateKey dateKey, MonthKey monthKey, String? shop, FundingSource funding, String? paidByMemberId, bool reimbursable, int lineCount, Money total, String? note }`. |
| `month_spend.dart` | `final class MonthSpend { Money total; Map<String, Money> byCategory; Map<DateKey, Money> byDay; int count; factory MonthSpend.of(Iterable<Expense>) }` — **skips soft-deleted**. The single aggregation reused by P2-11/P2-18/P2-24. |
| `expense_filters.dart` | `final class ExpenseFilters { DateKeyRange? range; String? categoryId; String? itemId; String? memberId; FundingSource? funding; bool includeDeleted; String? text }` + `List<Expense> applyFilters(...)` (pure) and `Map<DateKey, List<Expense>> groupByDay(...)`. |
| `expense_repository.dart` | `abstract interface class ExpenseRepository { Future<Result<void>> commitAdd(String familyId, ExpenseWritePlan plan, AuditEvent e); Future<Result<void>> commitTrip(String familyId, TripWritePlan plan, AuditEvent e); Future<Result<void>> commitEdit(String familyId, ExpenseEditPlan plan, AuditEvent e); Future<Result<void>> commitDelete(String familyId, ExpenseDeletePlan plan, AuditEvent e); Future<Result<void>> commitRestore(String familyId, ExpenseRestorePlan plan, AuditEvent e); Future<Result<Expense?>> getExpense(String familyId, String id); Future<Result<List<Expense>>> getByDate(String familyId, DateKey date, {int limit = 50}); Stream<List<Expense>> watchMonth(String familyId, MonthKey month); Future<Result<List<Expense>>> queryRange(String familyId, DateKeyRange range, {String? categoryId, String? itemId, String? purchaserId, FundingSource? funding, int limit = defaultPageSize, Expense? startAfter}); Stream<List<ExpenseRevision>> watchRevisions(String familyId, String expenseId); }` and `ExpenseRevision { id, Map<String,Object?> before, List<String> changedFields, String? reason, DateTime at, String by }`. |
| `usecases/check_duplicate.dart` | `Future<Result<DuplicateWarning?>> call({familyId, ExpenseDraft draft, Money total})` — `getByDate` + a match when same normalized `itemName` (or `itemId`) **and** same total **and** an existing, non-deleted expense created within 10 minutes of `clock.nowUtc()`. A warning, never a failure. |
| `usecases/add_expense.dart` | ctor `{expenses, catalog, funds (FundRepository), advances (AdvanceRepository), families, clock, newId, FamilyDateKeys dateKeys}`. `call({actorUid, familyId, ExpenseDraft draft, String? id, String? eventId, String? newItemId})`: (1) `requirePermission(addOwnExpense, ownerId: actorUid)`; (2) validate (item name 1–80 and category required `category_required`; date ≤ `dateKeys.today()` else `future_date`; funding rules `member_required` / `fund` carries no payer; `shop` ≤ 60, `note` ≤ 500; month **not locked** via `funds.getClosing(draft.dateKey.monthKey)` → `Conflict('month_locked')`); (3) `computeTotal`; (4) plan — funding `fund` → `FundTransaction.forExpense`; `member` + `reimbursable` → `MemberAdvance(status: pending, amount: total, settled: 0)`; `member` + not reimbursable → nothing extra; (5) item: `rememberItem && itemId == null` → `AddCustomItem`-style new `Item` (id `newItemId ?? newId()`, category + default unit from the draft); known `itemId` → `ItemUsageBump(+1, lastPrice/lastUnitPrice)`; (6) event `bazar.expense_created` (`item`, `amount`, `funding`); (7) `expenses.commitAdd`. ids are taken from the parameters so a retry rewrites the same documents. |
| `usecases/add_bazar_trip.dart` | `call({actorUid, familyId, TripDraft header, List<ExpenseDraft> lines, String? tripId, List<String>? lineIds, String? eventId})` — 1–40 lines (`too_many_lines`), each line validated as above, shared date/shop/funding applied; usage bumps **aggregated per item** (`increments` = occurrences); one `TripWritePlan`; event `bazar.trip_created`. |
| `usecases/update_expense.dart` | loads the stored expense (`NotFound('expense')`); permission: `addOwnExpense` if `createdBy == actor` else `editOthersExpense` (`ownerId: stored.createdBy`); month lock checked for the **old and the new** month; if an advance exists with `settled > 0` and funding/amount/payer changes → `Conflict('advance_settled')`. Builds the compensating rows per the table below; stores `before` values of the changed fields; event `bazar.expense_updated` (`fields` = comma list). |
| `usecases/soft_delete_expense.dart` | same permission + lock rules; advance with `settled > 0` → `Conflict('advance_settled')`; pending advance → status `voided`; fund funding → `adjustment` `+total` dated at the expense's own date/month (suffix `del`); sets `deletedAt/By`; writes a revision; event `bazar.expense_deleted`. |
| `usecases/restore_expense.dart` | only when deleted (`NotFound`/`Conflict`); lock check; fund funding → `adjustment` `-total` (suffix `res`); voided advance → `pending` again; clears `deletedAt/By`; event `bazar.expense_restored`. **Batch, cache-read, no probe** so Undo works right after an offline delete. |

**Compensation table for `UpdateExpense`** (never edit the original fund row; each adjustment id is `adj_<eventId>_<a|b>`):

| Before → after | Rows written |
| --- | --- |
| fund → fund, amount `A → B`, same month | one `adjustment` of `-(B - A)` (refType `expense`, refId expense) |
| fund → fund, **date moves to another month** | `adjustment +A` in the old month **and** `adjustment -B` in the new month |
| fund → member (reimbursable) | `adjustment +A`; new `MemberAdvance(pending, B)` |
| fund → member (personal) | `adjustment +A` |
| member (reimbursable, settled 0) → fund | advance `status: voided`; `adjustment -B` |
| member (reimbursable, settled 0) → member, amount/payer changed | advance document updated (`amount`, `memberId`) |
| member (personal) → fund | `adjustment -B` |
| any change when the advance has `settled > 0` | **refused** `Conflict('advance_settled')` |
| only text fields (`note`, `shop`, `itemName`, `purchaserId`, `categoryId`) | no ledger rows; revision only |

**`test/support/in_memory_bazar_backend.dart` (EDIT)** now also implements `ExpenseRepository`, `FundRepository`, `AdvanceRepository` (reads) by *applying the plans to maps* (`expenses`, `fundTx`, `advances`, `revisions`, `items`, `trips`, `closings`, `events`) with live streams and a `failNextWrite` hook, exactly like `InMemoryBackend`.

**Tests (domain level, `FakeClock`, `SeqIds`)**
* `computeTotal` table (qty×rate half-up e.g. 1.5 kg × ৳33.33; typed total; qty without price → error; zero/negative → error).
* Every funding combination (fund / member+reimbursable / member personal) writes exactly the right extra rows.
* **Ledger invariant** (the core acceptance test): after any random sequence of add / edit (all rows of the table) / delete / restore, for every expense `sum(fundTx where refId == expense.id)` equals `-total` for a live fund-funded expense and `0` for deleted, member-funded or personal; `FundBalanceCalculator.balance` equals the hand-computed value; `MonthSpend` totals never change because of ledger adjustments (no double counting).
* The original `exp_<id>` row is byte-for-byte unchanged after edits/deletes (compare maps).
* Duplicate warning (same item+amount within 10 min warns, 11 min doesn't, deleted rows ignored).
* Permission denials: pending/disabled actor, member editing someone else's expense, moderator editing (allowed), future date, locked month on add / edit (old and new month) / delete.
* Trip: 40 lines ok, 41 → `too_many_lines`, aggregated usage, one batch ≤ `kMaxBatchWrites`.
* Retry: same `id`/`eventId` twice produces one document each.

**Interacts with:** P2-10 implements the ports; P2-11/P2-13 call the use cases; `MonthSpend` feeds budgets (P2-17/18) and the report engine (P2-24).
**Done when:** the whole suite above passes and **no UI code exists yet**.

---

### P2-10 — Expense / fund / advance data layer, rules, indexes

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-05, P2-09 |
| **Parallel with** | P2-12, P2-17 |
| **Unblocks** | P2-11, P2-19, P2-20 |

**Files**

| Path | Action | Contents |
| --- | --- | --- |
| `…/expenses/data/expense_mappers.dart` | NEW | `expenseToMap` (`dateKey.toString()`, `monthKey.toString()`, `occurredAt` Timestamp, `totalPaisa`, `qtyMilli`, `unit` name, `unitPricePaisa`, `fundingSource`, …), `expenseFromMap(id, map)` (tolerant), `expenseChangeMap`, `revisionToMap`, `revisionFromMap`, `tripToMap`. |
| `…/fund/data/fund_mappers.dart`, `month_closing_mappers.dart` | NEW | `fundTxToMap/FromMap` (`amountPaisa` signed), `closingToMap/FromMap`. |
| `…/advances/data/advance_mappers.dart` | NEW | `advanceToMap/FromMap`, `advanceChangeMap`, `settlementToMap`. |
| `…/expenses/data/firestore_expense_repository.dart` | NEW | stages each plan in **one** `runBatch` through `guardWrite` **without probe** (offline OK): `commitAdd` = expense + fundTx? + advance? + usage `update`/new item `set` + `AuditWriter.write`; `commitTrip` = trip + all lines + aggregated usage; `commitEdit` = expense `update` + revision `set` + adjustments + advance update/void; `commitDelete`/`commitRestore` likewise. Use `update()` for existing item usage (`itemUsageMap`). Reads: `watchMonth` = `.collection(expenses).where('monthKey', isEqualTo: m).orderBy('dateKey', descending: true).limit(kMaxListenerDocs).snapshots()`; `queryRange` = `where dateKey >= start && <= end [+ equality filters] orderBy dateKey desc limit(n) [startAfterDocument]`; `getByDate`; `getExpense`. `watchRevisions` limit 20. |
| `…/fund/data/firestore_fund_repository.dart` | NEW | `watchTransactionsFrom` = `where monthKey >= from orderBy monthKey` (+ `dateKey`) `.limit(kMaxListenerDocs)`; `getTransactionsForRef` = `where refId == id limit 20`; `watchClosings` = `.orderBy('monthKey', descending: true).limit(24)`; `getClosing`. |
| `…/advances/data/firestore_advance_repository.dart` | NEW | `watchOpenAdvances` = `where status in [pending, partial] limit 100`; `getAdvance`; `watchSettlements`. |
| `lib/core/firebase/query_limits.dart` | EDIT | nothing new unless a constant is needed. |
| `firebase/firestore.rules` | EDIT | New helpers: `monthOpen(f, mk)` (`!exists(closingPath) || get(closingPath).data.get('status','open') != 'closed'`), `canViewAllContributions(f)`, `expenseKeys()`, `expenseOk(d)`, `tripKeys()`, `fundTxKeys()`, `fundTxOk(d, t)`, `advanceKeys()`, `advanceOk(d)`, `settlementKeys()`, `closingKeys()`, `revisionKeys()`. Blocks inside `match /families/{f}`: **expenses** (create: `verified() && isActiveMember(f) && createsAsSelf() && expenseOk(d) && monthOpen(f, d.monthKey)`; update either *soft-delete/restore* (`affectedKeys().hasOnly(['deletedAt','deletedBy','updatedAt','updatedBy'])` + creator-or-manager + `monthOpen(resource.monthKey)`) or *content edit* (creator-or-manager, `expenseOk(new)`, `createdAt/createdBy/source/importBatchId/tripId` unchanged, `monthOpen` for old **and** new month); delete `false`), **expenses/{e}/revisions** (read manager or creator; create active member `createsAsSelf()`; no update/delete), **bazarTrips** (read members; create active member; no update/delete), **fundTransactions** (read members; create: `expense` → active member, `amountPaisa < 0`, `refType == 'expense'`, `t == 'exp_' + refId`; `contribution` → `financeManager`, `> 0`, `t == 'con_' + refId`; `reimbursement` → `financeManager`, `< 0`; `opening` → `isAdmin`; `adjustment` → active member when `refType == 'expense'` else `financeManager`; all require `monthOpen(f, d.monthKey)`; update/delete `false`), **memberAdvances** (read manager or `resource.data.memberId == uid`; create active member `createsAsSelf()`, `status == 'pending'`, `settledPaisa == 0`; update only by the two paths described in §3.2; delete `false`), **settlements** (read manager or own; create `financeManager`; immutable), **monthClosings** (read members; create/update `financeManager(f) && verified()` (Admin or Household Manager), keys `closingKeys()`; delete `false`). `expenseOk` checks: closed key set; lengths (`itemName` 1–80, `shop` ≤ 60, `note` ≤ 500); `moneyOk(d,'totalPaisa') && d.totalPaisa > 0`; `dateKeyOk`, `monthKeyOk`, `d.dateKey[0:7] == d.monthKey`; `fundingSource in ['fund','member']` and `(d.fundingSource == 'fund') == (d.get('paidByMemberId', null) == null)`; optional `qtyMilli`/`unitPricePaisa` ints ≥ 0; `unit` in the `Unit` names; `source in ['manual','import']`. |
| `firebase/firestore.indexes.json` | EDIT | keep existing; **add** `expenses (fundingSource ASC, dateKey DESC)`, `expenses (itemId ASC, dateKey DESC)`, `fundTransactions (monthKey ASC, dateKey DESC)`, `contributions (memberId ASC, monthKey DESC)`, `memberAdvances (status ASC, dateKey DESC)`, `settlements (advanceId ASC, dateKey DESC)`. Run `node tools/check_indexes.mjs` (each entry ≥ 2 fields). |
| `test/core/firebase/paths_match_rules_test.dart` | EDIT | remove `expenses, bazarTrips, fundTransactions, memberAdvances, settlements, monthClosings` from `pending`. |
| `firebase/rules_test/expenses.test.mjs`, `fund_ledger.test.mjs`, `advances.test.mjs`, `month_closings.test.mjs` | NEW | one allowed + one denied per rule. Mandatory cases: member creates own expense allowed; forged `createdBy` denied; `monthKey` ≠ `dateKey` prefix denied; float/negative/zero total denied; `fund` with a payer denied; `member` without payer denied; unknown field denied; member edits **someone else's** expense denied, moderator allowed; delete (hard) denied; soft-delete by creator allowed; **closed month**: create/edit/delete/fundTx all denied, then allowed after the closing doc is set to `open`; fundTx sign rules per type; contribution fundTx by plain member denied; opening fundTx by moderator denied; fundTx update/delete denied; advance settle by moderator (finance on) allowed, finance off denied; settle past `amount` denied; revisions append-only; **a 30-line trip batch** (30 expenses + 30 fund rows + trip + 2 audit docs) is **allowed** (G-9). |
| `test/contract/*` | EDIT | fixtures: `expense_fund`, `expense_member_advance`, `expense_personal`, `expense_edit`, `expense_soft_delete`, `expense_restore`, `revision`, `trip`, `fundtx_*` (one per type), `advance`, `month_closing`. |
| `test/features/bazar/**/data/*_test.dart` | NEW | mapper round trips; every plan staged through `FakeTxRunner` yields the exact documents and ids (`exp_<id>`, `adj_<eventId>_a`); **ledger invariant re-run against the real repository over `FakeTxRunner.store`**; batch size of a 40-line trip ≤ 500. |
| `lib/app/bootstrap.dart` | EDIT | construct and override `expenseRepositoryProvider`, `fundRepositoryProvider`, `advanceRepositoryProvider`. |

**Design decision recorded in ADR 0008 (D-P2-16, G-9):** the rules do **not** cross-check an expense against its ledger row with `getAfter` (that would cost one document access per trip line and exceed the 20-call limit). The pairing is enforced by the use cases, proven by the ledger-invariant tests, and detected at runtime by `LedgerIntegrityCheck` (P2-22) which warns managers. **[VERIFY]** whether repeated `get()` calls to the same document count once; if the 30-line trip test fails anyway, fall back to writing trips in chunks of ≤ 15 lines (header first, `lineCount` = total).

**Interacts with:** providers in P2-11; the contribution/advance/close steps add *write* methods to the fund/advance repositories (P2-19–P2-21) and rely on the rules defined here.
**Done when:** the whole rules suite is green (including the 30-line trip), the contract fixtures pass, `check_indexes` passes, paths test no longer lists these collections.

---

### P2-11 — Bazar providers (the sync layer)

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-10 (and P2-05, P2-07) |
| **Parallel with** | P2-12, P2-16, P2-17 |
| **Unblocks** | P2-13, P2-15, P2-18, P2-22, P2-25, P2-29 |

Implements §3.5 exactly.

**Files**

| Path | Contents |
| --- | --- |
| `lib/features/bazar/presentation/bazar_providers.dart` | `selectedMonthProvider = NotifierProvider<SelectedMonth, MonthKey>` (initial `ref.read(familyDateKeysProvider).thisMonth()`; `next()`, `previous()`, `set(MonthKey)`, `reset()`); `monthLockedProvider = Provider.family<bool, MonthKey>` (from `monthClosingsProvider`); `currentDateKeyProvider` (today via `familyDateKeysProvider`). |
| `…/expenses/presentation/expense_providers.dart` | `expenseRepositoryProvider` (throws, overridden in bootstrap); `monthExpensesProvider = StreamProvider.autoDispose.family<List<Expense>, MonthKey>` (keepAlive for the current month via `ref.keepAlive()` when `month == thisMonth`); `monthSpendProvider = Provider.family<MonthSpend, MonthKey>` (`MonthSpend.of(...)`); `expenseFiltersProvider = NotifierProvider<…, ExpenseFilters>`; `filteredExpensesProvider` (pure `applyFilters`/`groupByDay`); `expenseRevisionsProvider(expenseId)`; `canEditExpenseProvider = Provider.family<bool, Expense>` (own → `ref.can(addOwnExpense)`, else `ref.can(editOthersExpense)`; "own" = `expense.createdBy == currentUid`, no role test); one provider per use case (`addExpenseProvider`, `addBazarTripProvider`, `updateExpenseProvider`, `softDeleteExpenseProvider`, `restoreExpenseProvider`, `checkDuplicateProvider`). |
| `…/fund/presentation/fund_providers.dart` | `fundRepositoryProvider` (throws, overridden); `monthClosingsProvider`; `fundWindowStartProvider = Provider<MonthKey?>` (`MonthLocks.fundWindowStart(...)` using `bazarSettingsProvider.fundStartMonth`); `fundTransactionsProvider = StreamProvider<List<FundTransaction>>` (null window → empty); `fundSummaryProvider`/`fundBalanceProvider` (`FundBalanceCalculator`); `fundWindowOverflowProvider` (true when the listener hit `kMaxListenerDocs` → UI tells managers to close earlier months). |
| `…/advances/presentation/advance_providers.dart` | `advanceRepositoryProvider` (throws, overridden); `openAdvancesProvider`; `advanceSummaryProvider` (open count + remaining total per member). |
| `test/features/bazar/presentation/bazar_providers_test.dart` | overrides with `InMemoryBazarBackend`: switching `selectedMonthProvider` changes the listener; a soft-deleted expense disappears from `monthSpendProvider`; locked month → `monthLockedProvider` true; `fundBalanceProvider` follows contributions/expenses; `fundWindowStartProvider` moves after a month is closed; the providers dispose their listeners when the last watcher leaves (no leaks). |

**Interacts with:** this is the layer every screen in P2-13…P2-25 and the Phase 4 dashboard reads. It is the answer to "how do pages stay in sync": one listener per data set, derived providers pure.
**Done when:** provider tests green; no screen exists yet.

---

## 8. Step cards — Wave D: expense screens (P2-12 … P2-16)

### P2-12 — Shared widgets and gallery entries

| | |
| --- | --- |
| **Type** | INDEPENDENT (needs only the Phase 1 design system) |
| **Depends on** | P2-01 |
| **Parallel with** | every step of Waves B–C |
| **Unblocks** | P2-13, P2-15, P2-16, P2-18, P2-22, P2-25, P2-28 |

Widgets take **plain values** (no Firebase, no feature imports) — `shared/` rules. Each is added to `lib/app/gallery/gallery_sections.dart` with all its states, which automatically gives goldens (tag `golden`, generated on Linux CI) and the text-scale-2.0 Bangla/English overflow test.

| Widget (file in `lib/shared/widgets/`) | API | States to list in the gallery |
| --- | --- | --- |
| `month_switcher.dart` `MonthSwitcher` | `MonthKey month, ValueChanged<MonthKey> onChanged, MonthKey? min, MonthKey? max` — "‹ October 2026 ›" with 48 dp arrows, tap on the label opens a month picker sheet. Label from a new `AppFormatters.monthLabel(MonthKey)` (**EDIT** `lib/core/localization/app_formatters.dart`, honours the Bangla-digits switch). | normal, at min, at max, long Bangla month |
| `amount_field.dart` `AmountField` | `controller, label, errorText?, int scale (2 money / 3 quantity), ValueChanged<String>? onChanged, bool autofocus, FocusNode?` — numeric keypad, accepts Bangla **and** English digits and one decimal separator, `৳` prefix for money; no parsing inside (the controller parses with `Money.parse`/`Quantity.parse`). | empty, filled, error, disabled, Bangla digits |
| `total_display.dart` `TotalDisplay` | `Money? total, String label, bool calculated` — large `MoneyText`, subtitle "calculated from quantity × price" when `calculated`. | empty (—), value, calculated |
| `progress_bar_status.dart` `ProgressBarStatus` | `int? basisPoints, ProgressLevel level (ok/warning/exceeded), String label, String? trailing` — bar clamps visually at 100 % with an overflow tick; icon + label + colour (never colour alone). `enum ProgressLevel` lives in this file (shared must not import a feature). | 0 %, 79 %, 80 %, 100 %, 140 %, no limit (null) |
| `day_section_header.dart` `DaySectionHeader` | `String dateLabel, Money total` | normal, long label |
| `person_picker.dart` `PersonPicker` | `List<PersonOption> options (id, name, avatarKey), String? selectedId, ValueChanged<String?> onChanged, String label, bool allowNone` — horizontal avatars (`AppAvatar`), ≥ 48 dp. | none selected, selected, 1 option, 12 options |
| `category_badge.dart` `CategoryBadge` | `String name, int colorIndex, String? emoji, bool compact` (uses `placeholderPalette[colorIndex]` and `AppAvatar.foregroundFor`) | emoji, no emoji, compact, long name |

Also: `test/shared/widgets/*_test.dart` for behaviour (AmountField accepts `১২৩.৫০`; MonthSwitcher clamps at min/max); update `docs`/CLAUDE.md "Shared widgets" list.
**Interacts with:** used by almost every Phase 2 screen; none depend on Bazar data.
**Done when:** gallery lists all seven widgets, overflow test passes at text scale 2.0 in bn/en/light/dark, golden workflow produces PNGs you commit.

---

### P2-13 — Add Expense screen (the most-used screen)

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-11, P2-12 (catalog data from P2-06 must exist to try it) |
| **Parallel with** | P2-16, P2-17, P2-19, P2-20 |
| **Unblocks** | P2-14, P2-15 |

Goal: record a normal item in ≤ 10 seconds and ≤ 4 taps after choosing the item.

**Files** (`lib/features/bazar/expenses/presentation/`)

| Path | Contents |
| --- | --- |
| `controllers/expense_form_state.dart` | immutable `ExpenseFormState { String expenseId, eventId, newItemId (generated ONCE when the controller is created — retries reuse them); DateKey date; String itemQuery; Item? item; String? customItemName; String? categoryId; bool rememberItem; String qtyText; Unit? unit; String unitPriceText; String totalText; FundingChoice funding; String? paidByMemberId; String shop, note; String? purchaserId; Map<String,String> fieldErrors (field → code); DuplicateWarning? duplicate; bool saving; }` + `enum FundingChoice { fundPool, memberReimbursable, memberPersonal }`. |
| `controllers/expense_form_controller.dart` | `NotifierProvider.autoDispose.family<ExpenseFormController, ExpenseFormState, ExpenseFormArgs>` with `ExpenseFormArgs { String? editingId; }` (edit mode is completed in P2-15). Methods: `selectItem(Item)` (sets category, default unit, hint = last unit price — **a hint, never a value**), `typeItem(String)`, `setCustomName`, `setCategory`, `setQty/Unit/UnitPrice/Total`, `setFunding`, `setPaidBy`, `setDate` (blocks future), `computed` getter (`computeTotal` live → `TotalDisplay`), `Future<ExpenseSaveOutcome?> save({required bool addAnother})`: validates → `CheckDuplicate` → if warning, `duplicate` is set and the sheet decides (`saveConfirmed()`), else `AddExpense`. `addAnother` keeps date, shop, funding, payer and clears item/amount. |
| `screens/add_expense_screen.dart` | order on ONE screen (roadmap 4.1): date chip → item autocomplete → category chips (prefilled, changeable; for a new item a single "Remember this item" checkbox) → amount block (typed total **or** qty + unit + unit price; the total is always shown large via `TotalDisplay`) → funding selector → **Save** / **Save & add another** → collapsed "More" (shop, note, purchaser; no receipt photo). After item selection focus moves to the amount field automatically (`FocusNode`). Disabled with a localized banner when `monthLockedProvider(date.monthKey)`. |
| `widgets/item_autocomplete_field.dart` | uses `catalogIndexProvider.search(query)`; each row = `ItemThumb` + Bangla name + category name; "Add "<text>" as new item" row when nothing matches. |
| `widgets/funding_selector.dart` | `ChoiceWrap<FundingChoice>` with three options ("From family fund" default, "Paid by [member], to be reimbursed", "Paid by [member], personal") + `PersonPicker` over `membersProvider` active members (current user preselected). |
| `widgets/expense_more_section.dart`, `widgets/duplicate_warning_sheet.dart` | collapsed extras; non-blocking "Looks like a duplicate — Save anyway / Cancel". |
| `lib/features/bazar/bazar_module.dart` | EDIT | add `GoRoute(path: AppRoutes.bazar, routes: [GoRoute(path: 'expenses/new', …)])` (declare before `:id` routes). |
| `lib/app/routing/app_routes.dart` | EDIT | constants of §3.10. |
| `lib/features/bazar/bazar_entries.dart` | EDIT | append "Add expense" entry; `BazarHomeScreen` gets a FAB to the same route. |
| ARB bn/en | EDIT | `expense*` keys (labels, hints, errors, funding options, duplicate sheet). |

**Behaviour details**
* Date defaults to `currentDateKeyProvider`; `showDatePicker(lastDate: today)`; the controller rejects future dates too (`future_date`).
* Bangla digits are accepted in every numeric field (`AmountField` + `parseScaledDecimal`).
* The save button uses `BusyButton` + `newActionProvider()`; on success pop (single) or reset (add another) and show a snackbar. When the write is queued offline nothing extra is needed — the global `SyncBanner` already shows "waiting to sync".
* Item chosen → category auto-filled; a **new** item requires the user to pick the category (`category_required` inline).
* Funding `fundPool` + family with no fund set up yet is allowed (balance may go negative; the Fund screen explains it).
* Members can pick any active member as payer; the use case stores `createdBy` = actor regardless.

**Interacts with:** reads `catalogIndexProvider`, `membersProvider`, `monthLockedProvider`, `bazarSettingsProvider`; writes through `addExpenseProvider`; the new row appears in the month list (P2-15), `monthSpendProvider` (budgets/reports/dashboard) and `fundBalanceProvider` through the listeners — no manual refresh anywhere.
**Rules / tests:** controller state-machine table (select item → category/unit filled; qty+price → computed total; typed total; funding switches; future date; locked month; duplicate path; add-another keeps the right fields); widget tests happy path + inline errors in bn and en, light and dark, text scale 2.0; golden (2 themes × 2 languages); **tap-count test**: after item selection `enterText(amount)` + one tap on Save saves (≤ 4 pointer taps); Bangla digits typed; a retry after `failNextWrite` reuses the same `expenseId`.
**Done when:** you can add an item in under 10 seconds on a real phone, offline too (the row shows with the sync banner).

---

### P2-14 — Bazar Trip screen

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-13 |
| **Parallel with** | P2-15, P2-16, P2-18 |
| **Unblocks** | — |

**Files** (`…/expenses/presentation/`)

| Path | Contents |
| --- | --- |
| `controllers/trip_form_controller.dart` | state: header (date, shop, funding choice, payer), `List<TripLineDraft>` (each with its own pre-generated id), `Money total`; methods `addLine`, `updateLine`, `removeLine(index)` (returns the removed line for Undo), `save()` → `addBazarTripProvider`. Max 40 lines (UI disables "Add line" and shows the message at the cap). |
| `screens/bazar_trip_screen.dart` | header block (shared date/shop/funding) + running list with a `TotalDisplay` live total; swipe (`Dismissible`) removes a line with an Undo snackbar; one **Save all**. |
| `widgets/trip_line_sheet.dart` | bottom sheet reusing `ItemAutocompleteField` + `AmountField` (item, qty/unit/price or total, category). |
| Route + entry | `/bazar/trip/new` (`AppRoutes.bazarTripNew`), an entry in `bazar_entries.dart` and a menu item on Add Expense. |

**Interacts with:** same providers as P2-13; one `TripWritePlan` batch → N expenses + N fund rows + trip header; the month list shows the lines grouped by day, each with the trip chip.
**Tests:** controller (add/remove/undo, total, 40-line cap); widget happy path; swipe remove; save with one line and with 40; offline retry keeps ids; golden.
**Done when:** a 12-line trip saves in one tap, produces 12 expenses linked by `tripId`, and the fund balance drops by the trip total.

---

### P2-15 — Expense list, detail, edit, delete / undo, history

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-13 (and P2-11, P2-12) |
| **Parallel with** | P2-14, P2-16, P2-18 |
| **Unblocks** | P2-29 |

**Files** (`…/expenses/presentation/`)

| Path | Contents |
| --- | --- |
| `screens/expense_list_screen.dart` | `MonthSwitcher` (bound to `selectedMonthProvider`) + filter button + **filtered total** at the top (`MoneyText`) + `SliverList` grouped by day (`DaySectionHeader` with the day total). Rows (`widgets/expense_row.dart`): `ItemThumb`, item name, category badge, funding icon, amount, "waiting to sync" glyph for pending-write rows (use the snapshot's `hasPendingWrites` if exposed by the mapper — otherwise omit). One listener (`monthExpensesProvider`); results beyond 30 rows are revealed by an in-memory "Show more" (page = `defaultPageSize`). A custom range spanning other months uses `queryRange` with `startAfter` paging (non-live) and shows a "refresh" action. |
| `widgets/expense_filter_sheet.dart` | `RangePreset` chips (today … this year, custom picker), category chips, item search (reuses `ItemAutocompleteField`), member `PersonPicker`, funding `ChoiceWrap`, "show deleted" switch visible only when `ref.can(editOthersExpense)`. Writes `expenseFiltersProvider`. |
| `screens/expense_detail_screen.dart` | all fields; **ledger line**: "From family fund" / "Paid by Rafiq — ৳… pending reimbursement (or partly/fully settled)" read from `advanceRepository.getAdvance` through `expenseAdvanceProvider(expenseId)`; actions Edit / Delete inside `PermissionGate(allowed: ref.watch(canEditExpenseProvider(expense)), mode: disable, deniedMessage: …)`; **History** section (`widgets/expense_history_section.dart`) lists revisions (who, when, before→after) — shown when the user may edit (managers + creator, matches the rules). |
| `controllers/expense_form_controller.dart` | EDIT | edit mode: `ExpenseFormArgs(editingId)` loads the expense, prefills; `save` calls `UpdateExpense`; `Conflict('advance_settled')` → inline explanation ("this purchase was already partly reimbursed"). |
| `screens/add_expense_screen.dart` | EDIT | title/labels for edit mode; route `/bazar/expenses/:id/edit`. |
| delete flow | confirmation sheet → `SoftDeleteExpense` → snackbar **Undo** (6 s) → `RestoreExpense` (queues offline, so Undo works offline). Deleted rows appear (strike-through + "deleted" label) only with the toggle. |
| Routes + entry | `/bazar/expenses`, `/bazar/expenses/:id`, `/bazar/expenses/:id/edit`; entry "Expenses". |

**Interacts with:** the list reads the same `monthExpensesProvider` as budgets/reports (one listener per month); edit/delete write compensating ledger rows so `fundBalanceProvider` stays exact; a locked month shows rows read-only with a lock icon + label.
**Tests:** widget tests (grouping, totals, filters narrow the list and the total, members see Edit/Delete only on their own rows, moderator on all, locked month read-only, empty/loading/error); undo restores balance (use-case test already covers numbers; here the UI flow); **performance test**: 2,000 fake expenses build + scroll with no frame > budget and `groupByDay` under 50 ms; golden of list and detail.
**Done when:** edit, delete and undo leave the fund balance exactly correct (covered by the P2-09 invariant) and the list stays smooth with 2,000 rows.

### P2-16 — Catalog manager and Bazar settings screens

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-06, P2-07, P2-12 |
| **Parallel with** | P2-13, P2-14, P2-15 |
| **Unblocks** | — |

**Files**

| Path | Contents |
| --- | --- |
| `…/items_categories/presentation/screens/catalog_manager_screen.dart` | two tabs **Categories** / **Items**; search box (reuses `ItemSearch`); items filtered by category chip; inactive rows dimmed with a "hidden" label; FAB "Add"; every mutating control wrapped in `PermissionGate(allowed: ref.can(Permission.manageCatalogAndBudgets), mode: disable, …)`. Read-only for others (they can still open the screen from Bazar home). |
| `…/widgets/category_edit_sheet.dart` | `nameBn`, `nameEn`, colour = a grid of the 12 `placeholderPalette` swatches (stores `colorIndex`, **never a hex**), optional emoji field (≤ 8 chars), active switch; a `ReorderableListView` on the Categories tab saves `sortOrder`. Preview with `CategoryBadge`. |
| `…/widgets/item_edit_sheet.dart` | `nameBn`, `nameEn`, category chooser, default unit (`ChoiceWrap<Unit>` with `unitLabel`), alias chips (≤ 10, ≤ 40 chars each), emoji, active switch. Image upload is **not** in Phase 2 (no picker package, D-P2-13); `imageData` stays in the schema for later; `ItemThumb` shows the coloured initial fallback. |
| `…/items_categories/presentation/controllers/catalog_controllers.dart` | one `newActionProvider()` per sheet; use-case providers from P2-05. |
| `…/bazar/settings/presentation/screens/bazar_settings_screen.dart` | week start (`ChoiceWrap` Saturday…Friday), monthly family contribution target (`AmountField`), due day (1–28 picker), alert thresholds (two number fields: "warn at %" and "exceeded at %", validated ascending), fund start month (read-only once set, shows "set automatically when you record the opening balance"). Save → `UpdateBazarSettings` (**server required**: offline shows the localized `Network` message). |
| `bazar_entries.dart`, `bazar_module.dart`, `app_routes.dart` | entries **Catalog** (`/bazar/catalog`) and **Settings** (`/bazar/settings`, requires `manageCatalogAndBudgets`). |
| ARB bn/en | `catalog*`, `bazarSettings*` keys. |

**Interacts with:** edits flow through `catalogIndexProvider` to the expense form instantly (a deactivated item disappears from autocomplete, a renamed category updates every list); settings feed budgets (thresholds), reports (week start), contributions (target/due day).
**Tests:** widget tests (member sees read-only controls with a reason; moderator with finance off is read-only; admin adds/edits/deactivates; reorder persists `sortOrder`; alias limit; long Bangla names), settings validation messages, goldens.
**Done when:** an admin can fix a typo in an item name and the Add Expense autocomplete shows it immediately.

**Build notes (P2-13 to P2-16, written, not run):** see `PROGRESS.md` section "P2-13..P2-16".  Deviations from the cards: three extra use cases for the catalog manager (`ReactivateCategory`, `ReactivateItem`, `ReorderCategories`); the expense form keeps `saving`/`failure` in its own state instead of `newActionProvider`; custom ranges outside the month use a non-live `rangeExpensesProvider`; the settings screen edits two alert thresholds; the route `bazarSettings` (`/bazar/settings`) was added to `AppRoutes`.


---

## 9. Step cards — Wave E: budgets (P2-17 … P2-18)

### P2-17 — Budgets: domain, data, rules

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-04, P2-07 (P2-03 transitively) |
| **Parallel with** | P2-09 … P2-11, P2-12 |
| **Unblocks** | P2-18, P2-25, P2-27 |

**Files** (`lib/features/bazar/budgets/`)

| Path | Contents |
| --- | --- |
| `domain/budget.dart` | `final class Budget { MonthKey month; Money totalEstimate; Map<String, Money> categoryEstimates; List<BudgetLine> lines; List<int> alertThresholds }`; `final class BudgetLine { String? itemId; String name; Quantity? plannedQty; Unit? unit; Money? estimatedRate; Money estimatedTotal; Quantity? stock }`; `static Money lineEstimate(BudgetLine)` = `lineTotal(plannedQty, rate)` when both exist, otherwise the typed `estimatedTotal`. |
| `domain/budget_status.dart` | `enum BudgetLevel { noLimit, ok, warning, exceeded }`; `final class CategoryBudgetStatus { Money limit, spent, remaining (may be negative); int? percentBp; BudgetLevel level }`; `final class BudgetStatusReport { CategoryBudgetStatus total; Map<String, CategoryBudgetStatus> byCategory }`; `abstract final class ComputeBudgetStatus { static BudgetStatusReport call(Budget? budget, MonthSpend spend, {List<int> thresholds}) }`. Level rule (inclusive): limit ≤ 0 → `noLimit`; `percent >= thresholds.last` → `exceeded`; `percent >= thresholds.first` → `warning`; else `ok`; one threshold → warning at it, exceeded at 100. Uses `basisPoints` (no float). A category with no estimate → `noLimit` (never an alert). |
| `domain/budget_repository.dart` | `Stream<Budget?> watchBudget(String f, MonthKey m)`, `Future<Result<Budget?>> getBudget(String f, MonthKey m)`, `Future<Result<void>> saveBudget(String f, Budget b, AuditEvent e)`. |
| `domain/usecases/save_budget.dart` | `requirePermission(manageCatalogAndBudgets)`; validation (amounts ≥ 0, ≤ 150 lines, ≤ 40 category estimates, thresholds valid, `lines` names ≤ 80); **when `lines` is non-empty the Dry-groceries estimate is set to `sum(lines)` automatically** (`categoryEstimates['cat_dry_groceries']`) so there is one source of truth; if `totalEstimate` is null/zero it defaults to the sum of category estimates; event `bazar.budget_saved` (`month`, `amount`). Everyday write: batch, **no probe** (queues offline). |
| `domain/usecases/copy_last_month_budget.dart` | reads `getBudget(prev)`; missing → `NotFound('budget')`; target already exists → `Conflict('budget_exists')`; copies estimates and lines (stock cleared), keeps thresholds. |
| `data/budget_mappers.dart`, `data/firestore_budget_repository.dart` | doc id = `monthKey` (`FirestorePaths.budgetDoc`); `categoryEstimates` stored as map `categoryId → paisa int`; `lines` as list of maps with `*Paisa`/`*Milli`; `set` (full document) in one batch with `AuditWriter`. |
| `firebase/firestore.rules` | `budgetKeys()`, `budgetOk(d)` (`monthKeyOk`, `request.resource.id == d.monthKey`, `moneyOk(d,'totalEstimatePaisa')`, `categoryEstimates is map && size() <= 40`, `lines is list && size() <= 150`, `alertThresholds is list && size() <= 4`). Block `budgets/{b}`: read `canReadFamilyData(f)`; create/update `verified() && financeManager(f) && writesAsSelf/createsAsSelf && budgetOk`; delete `false`. |
| `firebase/rules_test/budgets.test.mjs`, contract fixture `budget`, paths `pending` update, key-set mirror | one allowed + one denied per rule (member write denied, moderator finance on/off, bad month id, 151 lines denied, negative total denied). |
| `…/presentation/budget_providers.dart` | `budgetRepositoryProvider` (override in bootstrap), `monthBudgetProvider = StreamProvider.family<Budget?, MonthKey>`, use-case providers. (`budgetStatusProvider`/`budgetAlertsProvider` come in P2-18 because they need P2-11.) |

**Tests:** thresholds exactly at 79/80/99/100/101 % (the 80 % and 100 % boundaries), zero budget → `noLimit`, category without an estimate, lines drive the dry-grocery estimate, default total = sum, copy-last-month when last month is missing / target exists / success, permission denials; mapper round trip; rules.
**Done when:** all green; `ComputeBudgetStatus` is pure and has no Firebase import.

---

### P2-18 — Budget screen and alerts provider

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-17, P2-11, P2-12 |
| **Parallel with** | P2-14, P2-15 |
| **Unblocks** | P2-29 |

**Files**

| Path | Contents |
| --- | --- |
| `…/budgets/presentation/budget_providers.dart` | EDIT: `budgetStatusProvider = Provider.family<BudgetStatusReport, MonthKey>` = `ComputeBudgetStatus.call(budget, ref.watch(monthSpendProvider(m)), thresholds: …)`; `budgetAlertsProvider = Provider<List<BudgetAlert>>` for the **current** month: every category/total with `level` warning/exceeded, sorted worst first (consumed by Bazar home and the dashboard card). |
| `…/screens/budget_screen.dart` | `MonthSwitcher`; overall `ProgressBarStatus` (spent / limit, remaining, level label + icon); per-category rows (`CategoryBadge` + `ProgressBarStatus`); a **Dry-grocery estimate** section → `widgets/dry_grocery_table_editor.dart`; **Copy last month** button (`CopyLastMonthBudget`); empty state for a month without a budget ("Plan this month" + Copy last month); note text "A budget is a plan; the fund balance is real money." Editing is `PermissionGate`-d by `manageCatalogAndBudgets`; viewers see read-only progress. |
| `…/widgets/dry_grocery_table_editor.dart` | rows: item (free text or `ItemAutocompleteField`), planned quantity (`AmountField` scale 3) + unit, estimated rate (`AmountField`), **auto total** (`MoneyText`, recalculated with `lineTotal`), optional current stock; add/remove row; a footer with the sum. A `BudgetController` (autoDispose `Notifier`) holds the editable draft and saves once. |
| `bazar_entries.dart`, `bazar_module.dart`, `app_routes.dart` | entry **Budget** (`/bazar/budget`). |

**Interacts with:** spending comes from `monthSpendProvider` (same listener as the expense list) — adding an expense updates the bars immediately; **alerts never block** an expense (the Add Expense form does not read them).
**Tests:** widget tests (bars update when a fake expense is added; thresholds render icon + label; copy-last-month; read-only for members; table total recalculates; empty state), goldens in 2 themes × 2 languages.
**Done when:** a month budget with the workbook's dry-grocery estimate (27 lines, ৳8,640) can be entered, and the bars move as expenses are added.

**Implementation status (P2-17/P2-18):** written, not compiled; deviations and assumptions are listed in `PROGRESS.md` ("Phase 2 - P2-17 and P2-18"). Alert levels read the live `settings/bazar.alertThresholds`; the budget's own list is a snapshot.

---

## 10. Step cards — Wave F: contributions, advances, month close (P2-19 … P2-23)

### P2-19 — Contributions: domain, data, rules

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-10, P2-07 |
| **Parallel with** | P2-20 |
| **Unblocks** | P2-21, P2-22 |

**Files** (`lib/features/bazar/contributions/`)

| Path | Contents |
| --- | --- |
| `domain/contribution.dart` | `enum ContributionMethod { cash, bkash, nagad, bank, other }`; `enum ContributionApproval { pending, approved, rejected }`; `final class ContributionChange { Money amount; DateKey date; ContributionMethod? method; String? note; DateTime requestedAt }`; `final class ContributionPlan { MonthKey month; String memberId; Money expected }` (id `<yyyy-MM>_<memberId>`); `final class Contribution { id, memberId, MonthKey monthKey, DateKey dateKey, Money amount, ContributionMethod? method, String? note, ContributionApproval status, String requestedBy, String? fundTxId, String? decidedBy, DateTime? decidedAt, String? rejectReason, ContributionChange? pendingChange, DateTime? voidedAt, String? voidedBy }`. |
| `domain/contribution_status.dart` | `final class MemberContributionStatus { String memberId; Money expected, received, remaining (never negative), credit (received − expected when positive) }`; `abstract final class ContributionStatusCalculator { static List<MemberContributionStatus> compute({plans, contributions (**only `approved` and not voided count as received**; `pending` is returned separately as `pendingTotal` per member so the UI can show "৳X awaiting approval"), activeMemberIds}); static Money totalExpected/totalReceived }` — a member with no plan has `expected = 0` and any payment is pure credit. |
| `domain/contribution_plan_generator.dart` | `List<ContributionPlan> generateEqualSplit({MonthKey month, Money target, List<String> activeMemberIds (roster order)})` using `splitEqually` (**D-P2-11**: remainder paisa to the first members; deterministic). |
| `domain/contribution_repository.dart` | `Stream<List<ContributionPlan>> watchPlans(f, MonthKey, {String? memberId})`; `Stream<List<Contribution>> watchContributions(f, MonthKey, {String? memberId})` — **no `memberId` filter is required: all active members may read all contributions (D-P2-5)**; the optional `memberId` argument is only for the "my contributions" view; `Future<Result<List<ContributionPlan>>> getPlans(f, MonthKey)`; writes: `savePlans(f, List<ContributionPlan>, AuditEvent)`, `commitContribution(f, ContributionWritePlan{contribution, fundTx?}, AuditEvent)` (`fundTx == null` for a member request), `commitDecision(f, ContributionDecisionPlan{updated contribution, fundTx? (approve), adjustment? (change approval)}, AuditEvent)`, `commitVoid(f, ContributionVoidPlan{voided, adjustment}, AuditEvent)`, `commitOpeningBalance(f, OpeningBalancePlan{MonthKey startMonth, FundTransaction? opening}, AuditEvent)` (writes the opening row **and** `settings/bazar.fundStartMonth`; server required). |
| `domain/usecases/generate_month_plans.dart` | `requirePermission(recordContribution)`; creates plans for active members that have none (never overwrites an override) from `settings.monthlyTarget`; target 0 → `Validation('target','required')`. |
| `domain/usecases/set_contribution_plan.dart` | per member per month override (`expected ≥ 0`); event `bazar.contribution_plan_set`. |
| `domain/usecases/record_contribution.dart` | **manager path** — permission `recordContribution`; amount > 0; member must be an active member; month not locked; ONE batch = `Contribution(status: approved, requestedBy: actor, decidedBy: actor)` + `FundTransaction.forContribution` (`con_<id>`) + audit; id/eventId from parameters; **queues offline**. |
| `domain/usecases/request_contribution.dart` | **member path** — permission `requestContribution`, `memberId` must equal the actor, amount > 0, month not locked, date not in the future; writes `Contribution(status: pending, fundTxId: null)` + audit `bazar.contribution_requested`; **no ledger row**; queues offline. If the actor already holds `recordContribution` the screen calls `RecordContribution` instead (auto-approved). |
| `domain/usecases/edit_pending_contribution.dart`, `cancel_contribution_request.dart` | owner only, only while `status == pending` (else `Conflict(code: 'contribution_not_pending')`); edit changes amount/date/method/note and keeps `pending`; cancel = soft void (`voidedAt/By`, no ledger row). |
| `domain/usecases/approve_contribution.dart` | permission `recordContribution`; contribution must be `pending` and not voided; month not locked; ONE batch = contribution `status: approved, fundTxId: con_<id>, decidedBy/At` + `FundTransaction.forContribution` + audit `bazar.contribution_approved`; **server required** (probe) so two managers cannot approve twice from stale offline state; a second approval fails with `Conflict(code: 'contribution_not_pending')`. |
| `domain/usecases/reject_contribution.dart` | permission `recordContribution`; `reason` required (1–200); sets `status: rejected, rejectReason, decidedBy/At`; no ledger row; audit `bazar.contribution_rejected`. |
| `domain/usecases/request_contribution_change.dart` | owner of an **approved** contribution, month not locked, no existing `pendingChange` (`Conflict(code: 'change_already_pending')`); writes `pendingChange` only; no ledger change; audit `bazar.contribution_change_requested`. |
| `domain/usecases/approve_contribution_change.dart`, `reject_contribution_change.dart` | permission `recordContribution`; approve = ONE batch: contribution gets the new amount/date/method/note and `pendingChange` removed + an `adj_<eventId>` fund row of `(newAmount − oldAmount)` (skipped when zero; refType `contribution`) + audit `bazar.contribution_change_approved`; **server required**; reject only clears `pendingChange` and records the reason in the audit event. |
| `domain/usecases/void_contribution.dart` | permission `recordContribution`; contribution must be `approved` (pending/rejected ones are cancelled/rejected instead); not already voided; month lock; marks `voidedAt/By` and writes an `adjustment` of `-amount` (refType `contribution`) — the original fund row is never edited; event `bazar.contribution_voided`. |
| `domain/usecases/record_opening_balance.dart` | permission; allowed only while `settings.fundStartMonth == null` (else `Conflict('fund_already_started')`); writes the `opening` row (`open_<month>`, skipped when the amount is zero) and sets `fundStartMonth`; **server required**; event `bazar.opening_balance_set`. |
| `data/contribution_mappers.dart`, `data/firestore_contribution_repository.dart` | maps; `watch*` queries `where monthKey == m [and memberId == x] limit(…)` (map missing `status` on legacy docs to `approved`). |
| `firebase/firestore.rules` | `contributionPlanKeys()`, `contributionKeys()` (includes `status, requestedBy, decidedBy, decidedAt, rejectReason, pendingChange`), `contributionOk(d)` (`moneyOk`, `amountPaisa > 0`, `monthKeyOk`, `dateKeyOk`, `method in […]`, `status in [pending, approved, rejected]`, `rejectReason` ≤ 200). `contributionPlans/{p}`: read `canReadFamilyData(f)`; write `verified() && financeManager(f)` with `p == d.monthKey + '_' + d.memberId`. `contributions/{c}`: read `canReadFamilyData(f)`; **create** = (a) member: `d.memberId == request.auth.uid && d.requestedBy == request.auth.uid && d.status == 'pending' && !('fundTxId' in d)` + `monthOpen`; or (b) `financeManager(f)` with `d.status == 'approved' && d.fundTxId == 'con_' + c` + `monthOpen`. **update** = one of: owner edit while `resource.status == 'pending'` and status stays `pending` (`affectedKeys().hasOnly([amountPaisa, dateKey, method, note, updatedAt, updatedBy])`); owner cancel (`voidedAt/By` while pending); owner `pendingChange` set (only on `approved`, `affectedKeys().hasOnly([pendingChange, updatedAt, updatedBy])`); `financeManager` approve (`pending → approved`, sets `fundTxId == 'con_' + c`, `decidedBy == request.auth.uid`, `existsAfter(fundTx con_c)`), reject (`pending → rejected` with `rejectReason`), approve/reject change, or voiding (`approved` only). Members can never set `status` to anything but `pending` and can never touch `fundTxId/decidedBy/decidedAt`. delete `false`; every write needs `monthOpen`. |
| `firebase/rules_test/contributions.test.mjs`, contract fixtures, paths `pending` | admin/moderator(finance on/off)/member/pending/other-family; **every active member can read every contribution and plan** (D-P2-5); member creates own `pending` allowed; member creates for **another** member denied; member creates `approved` or with `fundTxId` denied; member edits own pending allowed / edits approved amount directly denied / sets `pendingChange` on own approved allowed / on someone else's denied; member approves own request denied; moderator approves allowed (and the `con_` ledger row must exist after); moderator with `moderatorManagesFinance:false` denied; reject without reason denied; month-locked create/approve denied. |
| `…/presentation/contribution_providers.dart` | `contributionRepositoryProvider` (override), `contributionPlansProvider(month)` / `contributionsProvider(month)` (**no role-based filter**: everyone reads everything), `contributionStatusProvider(month)` (calculator over both + active members), `pendingContributionsProvider(month)` (status `pending` or `pendingChange != null`; feeds the approval list and the dashboard badge), `myContributionsProvider(month)` (filter by actor), use-case providers. |

**Tests:** equal-split table (৳5,000 / 3 = 1,667.00 / 1,667.00 / 1,666.00 paisa-exact), status (none paid, partial, exact, over → credit, voided ignored, **pending and rejected ignored for `received` but counted in `pendingTotal`**), manager record = approved + ledger row, member request = pending + **no** ledger row, approve writes the row exactly once (second approve → `contribution_not_pending`), reject needs a reason, change request approve writes the delta `adj_` row and the balance moves by exactly the delta, void keeps the balance right, month-lock denial, permission matrix (member cannot approve/record for others), opening balance once, idempotent retry.
**Note (resolved by the owner):** members may add/modify their own contributions, but only as requests that the **Household Manager or Admin approves** (D-P2-18). `docs/permission_matrix.md` must be regenerated to show `requestContribution` for members.
**Done when:** a scripted month of contributions yields the hand-computed expected / received / remaining per member.

**Implementation status (P2-19):** written, not compiled; deviations and assumptions are listed in `PROGRESS.md` ("Phase 2 - P2-19"). The card's `settings.monthlyTarget` is `defaultMonthlyContribution`; `RecordOpeningBalance` needs the admin permission `editFamilySettings` (the rules allow only an admin to write an `opening` row).

---

### P2-20 — Advances and settlements

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-10 |
| **Parallel with** | P2-19 |
| **Unblocks** | P2-21, P2-23 |

**Files** (`lib/features/bazar/advances/`)

| Path | Contents |
| --- | --- |
| `domain/settlement_plan.dart` | `SettlementPlan { Settlement settlement; FundTransaction reimbursement; MemberAdvance advanceAfter }`. |
| `domain/usecases/settle_advance.dart` | `call({actorUid, familyId, expenseId, Money amount, DateKey? date, String? method, String? note, String? settlementId, String? eventId})`: `requirePermission(recordContribution)`; amount > 0; month of the settlement date not locked; then `advances.commitSettlement(familyId, advanceId: expenseId, build: (current) => …, event)` — the repository reads the advance **inside a transaction** and calls `build(current)` (pure, in domain): `NotFound('advance')` if missing, `Conflict` if `voided`, `Conflict('overpayment')` when `amount > remaining`, otherwise returns the `SettlementPlan` (new `settled`, `statusFor(...)`: pending → partial → settled). The **original expense is never touched**. Event `bazar.advance_settled`. **Server required** (probe + transaction, G-8). |
| `domain/advance_repository.dart` | EDIT: `Future<Result<void>> commitSettlement(String familyId, {required String advanceId, required Result<SettlementPlan> Function(MemberAdvance? current) build, required AuditEvent event})`. |
| `data/firestore_advance_repository.dart` | EDIT: `guardWrite(probe: …, () => _tx.runTransaction<void>((t) async { final raw = await t.get(advancePath); final r = build(raw == null ? null : advanceFromMap(...)); stage settlement `set`, fundTx `stl_<id>` `set`, advance `update(settledPaisa,status,updatedAt,updatedBy)`, `AuditWriter` … }))` — failures from `build` are returned as `Failure` without writing. |
| `firebase/rules_test/advances.test.mjs` | EDIT/extend: the settlement transaction (settlement + `reimbursement` fundTx + advance update) allowed for admin and finance-moderator; plain member denied; `settledPaisa` above `amountPaisa` denied; status inconsistent with the amounts denied; settling a `voided` advance denied. |

**Tests (use case, `InMemoryBazarBackend`):** partial then full settlement (status pending → partial → settled), overpayment rejected with `overpayment`, voided advance rejected, two sequential settlements use fresh state (the second sees the first), month-locked settlement date, original expense map byte-identical before/after, balance after settlement equals hand value (reimbursement lowers the fund, expense total unchanged — **no double count**: category totals identical before/after), permission denials, offline → `Network` and nothing written.
**Done when:** all green and the advance status machine is covered in both domain and rules tests.

---

### P2-21 — Month close and reopen

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-19, P2-20 |
| **Parallel with** | P2-22 |
| **Unblocks** | P2-23 |

**Files** (`lib/features/bazar/fund/`)

| Path | Contents |
| --- | --- |
| `domain/fund_repository.dart` | EDIT: `Future<Result<void>> commitClose(String f, MonthClosePlan plan, AuditEvent e)`, `Future<Result<void>> commitReopen(String f, MonthReopenPlan plan, AuditEvent e)`, `Future<Result<List<FundTransaction>>> getTransactionsFromServer(String f, MonthKey from)` (server read, used only by close). |
| `domain/month_plans.dart` | `MonthClosePlan { MonthClosing closing; FundTransaction? nextOpening; FundTransaction? nextAdjustment }`, `MonthReopenPlan { MonthClosing reopened }`. |
| `domain/usecases/close_month.dart` | `requirePermission(closeBazarMonth)`; month must be ≤ the current month (`invalid_month`), not already closed (`already_closed`), and the **next month must not be closed** (`month_locked`); computes `closingBalance` from the server window (`fundWindowStart` … `month`) with `FundBalanceCalculator`; **next-month carry-forward**: no `open_<next>` row yet → create it with `closingBalance`; a row already exists (a re-close after a reopen) → write an `adjustment` of `closingBalance − existingOpening` (the opening row itself is append-only, D-P2-4); sets `monthClosings/<month>` to `closed` (`closedAt/By`, `closingBalance`). One batch, **server required**. Event `bazar.month_closed`. |
| `domain/usecases/reopen_month.dart` | `requirePermission(closeBazarMonth)`; month must be closed (`not_closed`); **note required** (≥ 3 chars, `reopen_note_required`); no *later* month may be closed (`Conflict('later_month_closed')`); sets `status: open`, `reopenedAt/By/Note`, `reopenCount + 1`. Server required. Event `bazar.month_reopened` (`note` truncated to 100 chars). |
| `data/firestore_fund_repository.dart` | EDIT: implement the three methods (batch + probe). |
| tests | close with the next month empty/non-empty; carry-forward equals the closing balance; **balance window start moves** to the next month and the balance is unchanged by closing (no double count); re-close after a reopen + correction writes only the delta adjustment; reopen without note, with a later closed month; future month; permission (moderator denied); locked month then rejects add/edit/delete/contribution/settlement (use-case level, plus rules from P2-10); closing the same month twice. |

**Known limitation (write it in the screen help text and ADR 0007):** the mobile SDK cannot query inside a transaction, so `closingBalance` is computed from a server read just before the write. A fund row created in that instant can be missed; the Fund screen's `LedgerIntegrityCheck` and a recomputed "balance vs closing" comparison show a warning to admins, and **Reopen → fix → Close** repairs it via the delta adjustment.
**Done when:** a scripted month (contributions, fund and member-paid expenses, a partial settlement, close) produces the expected balances and the next month opens with the carried-forward amount.

---

### P2-22 — Fund and contributions screens

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-19, P2-11, P2-12 |
| **Parallel with** | P2-21 |
| **Unblocks** | P2-23, P2-29 |

**Files**

| Path | Contents |
| --- | --- |
| `…/fund/domain/ledger_integrity_check.dart` | finish: `List<LedgerIssue> checkLedger({required List<Expense> expenses, required List<FundTransaction> txs})` — for each live fund-funded expense the rows with `refId == id` must sum to `-total` (else `mismatch`), rows pointing at a missing expense are `orphan`, deleted/member-funded expenses must sum to `0`. Pure; unit-tested. Provider `ledgerIntegrityProvider(month)` (managers only). |
| `…/contributions/presentation/screens/fund_screen.dart` | `MonthSwitcher`; **fund balance card** (`MoneyText` large, chips received / spent / reimbursed from `fundSummaryProvider`); if `fundWindowStartProvider == null` and the user may record contributions → "Set up the fund" card (opening balance dialog → `RecordOpeningBalance`); **per-member list** from `contributionStatusProvider` (expected, received, remaining, credit; **every member sees every member's row** (D-P2-5), with a "৳X awaiting approval" chip when `pendingTotal > 0`); fund transaction history for the month (type icon + label, signed `MoneyText`); a banner for `fundWindowOverflowProvider` and (managers) `ledgerIntegrityProvider` issues; actions: **Add contribution** for everyone (opens the sheet; for a member the button label is "Request contribution" and the result is a *pending* row with a clock icon + "Awaiting approval" label; for a Household Manager/Admin it saves as approved); gated by `PermissionGate(recordContribution)`: **Generate this month's plan**, the **Pending approvals** section (list of pending requests and change requests, each with *Approve* / *Reject (reason sheet)* buttons and the member's name, amount, date, method, note; a change request shows "old → new"); each member sees *Edit* / *Cancel* on their own pending row and *Request change* on their own approved row; a rejected row shows the reason to its owner. |
| `…/widgets/record_contribution_sheet.dart` | `PersonPicker` (active members), `AmountField`, date (default today, not future), method `ChoiceWrap`, note; when `monthLockedProvider(month)` the sheet is disabled with the reason. `PersonPicker` is locked to the actor for members and free for managers. Calls `RecordContribution` (manager) or `RequestContribution` (member), `EditPendingContribution`, or `RequestContributionChange` depending on mode. |
| `…/widgets/plan_edit_sheet.dart`, `…/widgets/contribution_history_list.dart` | per-member override (`SetContributionPlan`); history with **Void** (gated; confirmation; writes the compensating row). |
| `bazar_entries.dart`, `bazar_module.dart`, `app_routes.dart` | entry **Fund** (`/bazar/fund`). |

**Interacts with:** the balance is `fundBalanceProvider` (ledger window), so expenses added in P2-13, settlements and closings all appear here without refresh; closing a month (P2-21/23) moves the window and the screen keeps showing the right number.
**Tests:** widget tests (every member sees every member's row; member Request contribution → pending row, no balance change; manager Approve → received and fund balance move once; Reject needs a reason; Edit/Cancel only on own pending; Request change on own approved; Pending-approvals section visible only to Household Manager/Admin; Record contribution happy path and errors; locked month disabled; opening-balance card appears only when no fund; overflow/integrity banners), a visibility test (a plain member's providers DO read all contributions; the approve/reject buttons are absent for a member), goldens in 2 themes × 2 languages.
**Done when:** the admin can set up the fund, generate an equal-split plan, record contributions, and the per-member remaining amounts match the hand-computed values.

---

### P2-23 — Advances screen and Month-close screen

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-20, P2-21, P2-22 |
| **Parallel with** | P2-25 |
| **Unblocks** | P2-29 |

**Files**

| Path | Contents |
| --- | --- |
| `…/advances/presentation/screens/advances_screen.dart` | open advances grouped by member with "owed to <member> ৳…" totals; each row: expense name/date (tap → expense detail), amount, settled, remaining, status chip (icon + label: Pending / Partly settled / Settled; never colour alone); members see only their own advances (the query is filtered by `memberId` when they lack manager rights — rules); settle action `PermissionGate(recordContribution)`. A "settled" filter shows history. |
| `…/widgets/settle_advance_sheet.dart` | amount prefilled with the remaining value, date, method, note; inline `overpayment` message; shows the member's other open advances; **server required**: offline shows the localized network message and does not queue. |
| `…/fund/presentation/screens/month_close_screen.dart` | list of months (current and past); **preview** card for the selected month (received, spent, reimbursed, closing balance, count of unsettled advances, budget outcome from `budgetStatusProvider`); **Close month** (`PermissionGate(closeBazarMonth)`, confirmation sheet explaining that the month becomes read-only and the balance carries forward); closed months show a lock icon + "Closed on …" and **Reopen** (note field required, validated). |
| `…/widgets/locked_month_banner.dart` | shared banner used by Add/Edit Expense, contribution and settle sheets when `monthLockedProvider` is true. |
| `bazar_entries.dart`, `bazar_module.dart`, `app_routes.dart` | entries **Advances** (`/bazar/advances`) and **Close month** (`/bazar/month-close`, requires `closeBazarMonth`). |

**Interacts with:** settling updates `openAdvancesProvider`, `fundBalanceProvider` and the expense detail ledger line at once; closing flips `monthLockedProvider` which disables forms across the app.
**Tests:** widget tests (grouping/totals, member sees own only, settle partial then full, overpay message, offline message, close and reopen flows, note required, a plain member cannot see Close month; the Household Manager can), goldens.
**Done when:** you can reimburse a member in two instalments and close the month; every locked screen shows the reason.

---

## 11. Step cards — Wave G: reports (P2-24 … P2-25)

### P2-24 — Report engine (pure Dart)

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-09, P2-02 (P2-07 for week start at the provider level) |
| **Parallel with** | all UI steps |
| **Unblocks** | P2-25 |

**Files** (`lib/features/bazar/reports/domain/`)

| Path | Contents |
| --- | --- |
| `report_query.dart` | `final class ReportQuery { RangePreset preset; DateKeyRange? custom; String? categoryId; String? itemId; String? memberId; FundingSource? funding }`. |
| `report_data.dart` | `ReportSummary { Money total; int count; Money averagePerDay (integer division, half-up); DateKeyRange range }`; `CategoryTotal { categoryId, Money total, int count, int? shareBp }` (sorted by total desc); `ItemTotal { String key (itemId ?? normalized itemName), String name, Money total, int count }`; `DayTotal { DateKey day, Money total }` (**every day of the range, zero-filled**); `MemberTotal { memberId, Money total }` — "who spent" = `purchaserId ?? paidByMemberId ?? createdBy`; `DryGroceryComparison { Money estimate, Money actual, List<LineComparison> lines }` (line matched by `itemId`); `PeriodComparison { Money previous, Money delta, int? deltaBp }`; `ReportData` bundling them. |
| `report_engine.dart` | `abstract final class ReportEngine { static ReportData build({required Iterable<Expense> expenses, required DateKeyRange range, Budget? budget, ReportQuery? filters}); static PeriodComparison compare(ReportData current, ReportData previous); }` — excludes soft-deleted expenses, applies the filters, never uses `double`. Reuses `MonthSpend` logic (single aggregation, rule 30). |
| `report_loader.dart` | pure paging helper `Future<Result<List<Expense>>> loadRange(ExpenseRepository, familyId, range, {filters})`: reads pages of 500 up to `kMaxReportDocs = 5000` (`query_limits.dart`, **EDIT**) and returns a `truncated` flag when the cap is reached. |
| tests | totals to the paisa on a fixture; boundary dates (first/last day of range, month rollover, year rollover); previous-period when the previous month is shorter (March vs February 2027, leap day 2028-02-29); soft-deleted excluded; filters narrow every view consistently; zero-filled days; the spec questions as named tests — *eggs this month*, *fish between two dates*, *categories over budget*, *spend each day*, *dry-grocery total*, *this month vs last month*; **5,000-expense performance** (build < 300 ms). |

**Done when:** every spec §4 report question has a passing test with hand-computed expected values.

---

### P2-25 — Reports screen (`fl_chart`)

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-24, P2-11, P2-12, P2-17 |
| **Parallel with** | P2-23 |
| **Unblocks** | P2-29 |

**Preparation:** `flutter pub add fl_chart` (take the current stable version, commit `pubspec.lock`; D-P2-15). Chart colours only from `context.tokens.chart[0..9]` and `chartGrid` (rule 22).

**Files** (`lib/features/bazar/reports/presentation/`)

| Path | Contents |
| --- | --- |
| `report_providers.dart` | `reportQueryProvider` (Notifier, default `thisMonth`); **the week range passes `ref.watch(bazarSettingsProvider).weekStartDay` into `resolveRange`, so changing the setting re-computes "This week" immediately (D-P2-12)**; `reportDataProvider = FutureProvider.autoDispose<ReportData>` — a range inside **one month** reuses `monthExpensesProvider` (zero extra reads); otherwise `loadRange`; the previous period is loaded the same way for the comparison; week start from `bazarSettingsProvider`. |
| `screens/reports_screen.dart` | preset chip row (`ChoiceWrap<RangePreset>`: Today, Yesterday, Last 7 days, This week, This month, Last month, This year, Custom), custom range picker (`showDateRangePicker`, last date = today), `TabBar`: **Summary · Categories · Items · Days · Members · Dry groceries · Contributions**. Requires `viewFamilyReports`; a user without it sees **only the Contributions tab with their own numbers**. A "results truncated" banner when `loadRange` hit the cap. |
| `widgets/report_chart_card.dart`, `category_chart.dart`, `day_chart.dart`, `report_table.dart`, `comparison_row.dart` | every tab = a chart **and** a table beneath it; charts wrapped in `Semantics(label: …)` with a generated text alternative ("Vegetables ৳4,045, 34% of total …"); the comparison row shows `+/- amount` and `%` with icon + label. |
| `bazar_entries.dart`, `bazar_module.dart`, `app_routes.dart` | entry **Reports** (`/bazar/reports`). |

**Tests:** widget tests for each tab (renders table values, chart semantics label present, comparison text), filters change every tab, permission fallback (a member without `viewFamilyReports` still sees the contribution tab because contributions are visible to all), bn/en at text scale 2.0 (tables scroll horizontally instead of overflowing), reduced motion (animations disabled in tests), one golden per theme for the Summary tab.
**Done when:** every report in spec §4 can be produced from this screen and matches the engine tests.

---

## 12. Step cards — Wave H: spreadsheet import (P2-26 … P2-28)

Everything the importer must know about your real file is in **Appendix B** (checked against `Bazar.xlsx`).

### P2-26 — Import parser and mapping (pure Dart + a file adapter)

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-02, P2-04, P2-09 |
| **Parallel with** | P2-25 |
| **Unblocks** | P2-27 |

**Preparation:** `flutter pub add excel` (current stable; commit the lock file). `file_picker` is added in P2-28.

**Files** (`lib/features/bazar/import/`)

| Path | Contents |
| --- | --- |
| `domain/raw_sheet.dart` | `final class RawSheet { String name; List<List<Object?>> rows }` — neutral cell values (`String`, `int`, `String`-ified decimals, `DateTime`); the file adapter converts every numeric cell to its **decimal string immediately**, so no money arithmetic ever happens in a float. |
| `data/xlsx_workbook_reader.dart` | `List<RawSheet> readWorkbook(Uint8List bytes)` using `package:excel`. **Formula cells are ignored** (the library does not evaluate them; the workbook's category totals and day totals are formulas) — the importer recomputes every total itself. |
| `domain/text_cleaning.dart` | `String cleanLabel(String)`: strips leading emoji/symbols and variation selectors, trims, collapses spaces, removes ZWJ/ZWNJ, composes nukta pairs (reuse `normalizeSearch`). `"🧅 পিয়াজ  "` → `"পিয়াজ"`. |
| `domain/column_mapping.dart` | `final class ColumnMapping { int date, item, category, amount }`; `ColumnMapping? suggest(RawSheet)` finds the header row by synonyms (English `date/item/category/price/amount`, Bangla `তারিখ/আইটেম/ক্যাটেগরি/দাম/টাকা`); the workbook's layout (header row 5, columns A–D) is the first test. |
| `domain/expense_row_parser.dart` | `ParsedRows parseExpenseRows(RawSheet, ColumnMapping, {int firstDataRow})`: **date carry-forward** (a blank date cell inherits the previous non-blank one, exactly like the workbook's helper column), rows with a null/zero amount are skipped (the workbook has `0` placeholder rows), amount via `Money.parse(valueString)` (workbook values are whole numbers), invalid rows are collected as `ImportRowIssue` (`bad_date`, `bad_amount`, `no_category`, `future_date`), never thrown. |
| `domain/category_mapping.dart` | default label → category-seed-key table (**Appendix B.2**): `সবজি→vegetables`, `পিয়াজ→vegetables (item onion)`, `আলু→vegetables (item potato)`, `মাছ→fish`, `ফল→fruits`, `গরুর গোস্ত→beef`, `মুরগীর মাংস→chicken`, `ডিম→eggs`, `শুকনা বাজার→dry_groceries`, `গ্যাস→gas`, `মা এর ঔষধ→medicine`, `অন্যান্য→other`; unknown labels become `UnresolvedCategory` for the wizard. Item names map to a catalog item **only on an exact `ItemSearch` hit**; otherwise the row keeps its text as `itemName` with `itemId = null` (generic names like "বাজার"/"সবজি" must not become catalog items). |
| `domain/bangla_quantity_parser.dart` | `ParsedQty parseBanglaQuantity(String)` → `{Quantity? qty, Unit? unit, String raw, bool valueBased}`: Bangla/English digits, fractions `১/২`, mixed `১ ১/২`, units via `parseUnit` (`কেজি, গ্রাম, লিটার, ডজন, প্যাকেট, টা`); `"১০০ টাকার"` is `valueBased` (a purchase worth ৳100, no quantity). Integer arithmetic only (fractions with denominators 2/3/4/8, half-up to milli). |
| `domain/estimate_parser.dart` | `BudgetDraft? parseEstimates(RawSheet, MonthKey?)`: (a) the **dry-grocery table** (header cells `আইটেম / বাজেট / মজুদ / দর / মোট`) → `BudgetLine`s (name, planned qty+unit from `বাজেট`, stock from `মজুদ`, rate from `দর`, `মোট` as the line total — the typed value, not a formula); (b) the **monthly estimate block** headed `মাসের সম্ভাব্য বাজার` → category estimates through the same label table; fixed household bills (`ফ্লাট ভাড়া`, `ইলেক্ট্রিসিটি`, `ইন্টারনেট`, `ময়লার বিল`) become the estimate of the **Fixed bills** category (D-P2-9, `item_flat_rent` etc.; a blank amount such as the Oct-26 electricity cell is listed under `skipped` with reason `no_amount`); `গ্যাস 3,200` becomes the Gas estimate. The month comes from the sheet title cell (`"Oct 2026"`, `"Sept 2026"`) and is shown for confirmation. |
| `domain/import_plan.dart` | `ImportPlan { List<ImportRow> rows (each with a resolution: asIs / mapTo(categoryId) / createCategory / skip); Map<MonthKey, int> rowCountByMonth; BudgetDraft? budget; List<SkippedLine> skipped; ImportReport report }` and `ImportReport { Map<String, Money> sheetTotalsByLabel; Map<String, Money> importTotalsByCategory; Money sheetTotal; Money importTotal; List<ImportRowIssue> issues }`. |
| tests | table-driven on in-code `RawSheet`s plus one real small fixture workbook `test/fixtures/bazar_small.xlsx` read through the adapter. **Reconciliation fixtures from your real file:** Aug-26 = 59 priced rows on 24 dates = **৳12,069.00** (সবজি 3,780 · মাছ 90 · শুকনা বাজার 3,781 · অন্যান্য 870 · পিয়াজ 70 · আলু 195 · ফল 598 · ডিম 140 · মুরগীর মাংস 345 · মা এর ঔষধ 550 · গ্যাস 1,650); Sept-26 = 17 rows on 9 dates = **৳5,015.00** (সবজি 1,500 · মাছ 1,050 · শুকনা বাজার 655 · গ্যাস 1,700 · ফল 110); Oct-26 = **no expense rows**, dry-grocery table 27 lines = **৳8,640.00**, category estimates chicken 1,320 + beef 1,700 + medicine 2,000 + fish 3,000 + raw bazar (vegetables) 5,000 + dry groceries 8,640 + gas 3,200 + fixed bills 17,500 + 500 + 120 = 18,120 → total estimate **৳42,980.00** (of which bazar-only ৳24,860.00; electricity blank). After the onion/potato → Vegetables mapping the app-category totals are Aug: vegetables 4,045 · fish 90 · dry 3,781 · other 870 · fruits 598 · eggs 140 · chicken 345 · medicine 550 · gas 1,650 (= 12,069); Sept unchanged. Also: date carry-forward, `0` rows skipped, formulas ignored, quantity strings (`১/২ কেজি`, `১ ১/২ কেজি`, `৩ লিটার`, `১০০ টাকার`), header synonyms, template sheets ignored. |

**Done when:** the parser produces exactly the totals above from the fixture and reports (not throws) every bad row.

---

### P2-27 — Import use cases and data

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-26, P2-10, P2-17 |
| **Parallel with** | P2-25 |
| **Unblocks** | P2-28 |

**Files**

| Path | Contents |
| --- | --- |
| `…/import/domain/import_batch.dart` | `ImportBatch { id, fileName, rowCount, Money total, List<MonthKey> months, FundingChoice funding, ImportStatus status (active/undone), DateTime? undoneAt }`. |
| `…/import/domain/import_repository.dart` | `commitChunk(String f, {ImportBatch? header, required List<ExpenseWritePlan> plans, AuditEvent? finalEvent})` (≤ 400 writes, staged with `ExpenseStager`), `markUndone`, `getBatch`, `watchBatches` (limit 20), `getBatchExpenses(f, batchId, {startAfter})` (limit 500). |
| `…/import/domain/usecases/import_expenses.dart` | `requirePermission(importBazarData)`; **server required**; validation: ≤ 1,000 rows, no future dates, **no row in a locked month** (`import_has_locked_month`); builds plans with the shared pure `ExpensePlanBuilder` from P2-09 using deterministic ids `imp_<batchId>_<rowIndex>` and `source: import`, `importBatchId`; funding choice limited to **fund (default)** or **member-paid personal** (payer chosen); writes in chunks of ≤ 150 rows (each row = expense + fund row ≤ 2 writes; chunk ≤ 400), the header document with the first chunk and the `bazar.import_completed` event with the last; a progress callback; **resumable and idempotent** (re-running with the same `batchId` rewrites identical documents). Contributions are **never** imported. |
| `…/import/domain/usecases/undo_import.dart` | permission; server; `Conflict('import_already_undone')`; any affected month closed → `import_has_locked_month` ("reopen the month first"); pages through the batch's expenses and soft-deletes each with the **same compensating logic as `SoftDeleteExpense`** (fund rows reversed, original rows untouched), marks the batch `undone`; event `bazar.import_undone`. |
| `…/import/domain/usecases/import_budget.dart` | wraps `SaveBudget` for a confirmed `BudgetDraft` (the wizard calls it per month). |
| `…/expenses/data/expense_stager.dart` | **(created in P2-10; this step only calls it)** — `ExpenseStager.stageAdd/stageEdit/stageDelete(BatchContext, familyId, plan)`. |
| `…/import/data/import_mappers.dart`, `firestore_import_repository.dart` | `importBatches/{id}` mapper; chunk commit = one `runBatch` + `guardWrite(probe)`. |
| `firebase/firestore.rules` | EDIT: in the `expenses` create rule allow `source == 'import'` only when `financeManager(f)` and `importBatchId` is a string (and require `source == 'manual'` ⇒ no `importBatchId`); `importBatchKeys()`; block `importBatches/{b}`: read `isManager(f)`; create/update `financeManager(f) && verified()`; delete `false`. Remove `importBatchesSubcollection` from `pending`. |
| `firebase/rules_test/import.test.mjs`, contract fixtures `expense_import`, `import_batch` | admin and Household Manager (finance on) allowed; moderator with `moderatorManagesFinance:false` and member denied; non-manager `source: 'import'` denied; locked month denied. |
| tests | fixture workbook → plans → `InMemoryBazarBackend`/`FakeTxRunner`: per-category totals reconcile **to the paisa** with Appendix B; every chunk ≤ 400 writes; interrupted run + resume yields no duplicates; **undo returns the fund balance and category totals to their pre-import values exactly**; undo twice refused; locked-month guard; permissions; offline → `Network` and nothing written; budget from Oct-26 estimates saves with the dry-grocery lines (27 lines, ৳8,640). |

**Done when:** Aug-26 and Sept-26 import reconcile to ৳12,069.00 and ৳5,015.00, and Undo restores the previous state exactly.

---

### P2-28 — Import wizard screen

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-27, P2-12 |
| **Parallel with** | — |
| **Unblocks** | P2-30 |

**Preparation:** `flutter pub add file_picker` (current stable; use `withData: true` so no storage permission is needed; restrict to `xlsx`).

**Files** (`lib/features/bazar/import/presentation/`)

| Path | Contents |
| --- | --- |
| `controllers/import_wizard_controller.dart` | `Notifier<ImportWizardState>` with a step enum `pickFile → pickSheets → mapColumns → preview → dryRun → options → importing → done`; parsing runs off the UI thread (`compute`); back navigation keeps every choice. |
| `screens/import_wizard_screen.dart` | one screen hosting the steps: **1** pick file; **2** sheet list (name, priced rows, total, detected month; template sheets hidden; a sheet with estimates but no rows is shown as "budget only"); **3** column mapping (auto-suggested, editable); **4** preview table with a status badge per row (valid / skipped / unknown category / unknown item) and a resolver sheet for each unknown (map to existing · create new · skip); **5** dry run: sheet totals **next to** import totals per category (mismatch blocks Import unless explained by skipped rows); **6** options (funding: family fund default, or member-paid personal + payer; confirm budget months); **7** progress bar per chunk; **8** summary with **Undo this import**, the skipped fixed bills list, and "Budget imported for Oct 2026". |
| `widgets/*` | `import_preview_table.dart`, `category_resolver_sheet.dart`, `dry_run_comparison.dart`, `import_summary_card.dart` (each ≤ 300 lines). |
| `bazar_entries.dart`, `bazar_module.dart`, `app_routes.dart` | entry **Import from spreadsheet** (`/bazar/import`, `requires: Permission.importBazarData`). |

**Interacts with:** the imported rows appear in the expense list/reports through the normal listeners; the budget screen shows the imported estimates; the fund balance reflects imported fund rows (hence "Undo" and month locks).
**Tests:** widget flow with a fake reader (happy path; unknown category resolution; mismatch blocks import; back keeps choices; invalid file shows a friendly error; offline shows the network message before starting), golden of the dry-run step, a full-flow test against the fixture workbook that ends with Aug and Sept totals matching.
**Done when:** you can import your real August and September sheets and the totals match the old sheet to the paisa.

---

## 13. Step cards — Wave I: integration and sign-off (P2-29 … P2-30)

### P2-29 — Integration: dashboard cards, module hooks

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | P2-11, P2-18, P2-22 |
| **Parallel with** | P2-26 … P2-28 |
| **Unblocks** | P2-30 |

**Files**

| Path | Contents |
| --- | --- |
| `…/bazar/presentation/widgets/dashboard/bazar_month_card.dart` | this month's total and top category from `monthSpendProvider(selectedMonth)` (real data; empty state "No expenses yet this month" — **no sample numbers**), taps → `/bazar/expenses`. |
| `…/dashboard/fund_balance_card.dart` | fund balance + "received this month / remaining" from `fundBalanceProvider` and `contributionStatusProvider` (everyone sees the family and every member's remaining; managers also see a **"N contributions awaiting approval"** chip that opens `/bazar/fund` at the pending section), taps → `/bazar/fund`. |
| `…/dashboard/budget_alert_card.dart` | worst alert from `budgetAlertsProvider` (icon + label), hidden when none, taps → `/bazar/budget`. |
| `lib/features/bazar/bazar_module.dart` | EDIT: `dashboardCards => [ (c) => const BazarMonthCard(), (c) => const FundBalanceCard(), (c) => const BudgetAlertCard() ]`; `reports => const ['bazar_month', 'bazar_categories']` (ids for Phase 5 sharing). |
| `lib/features/dashboard/presentation/home_screen.dart` | EDIT (small): list the `dashboardCards` of `visibleModulesProvider` modules above the existing placeholder; when a module is switched off its cards disappear. Phase 4 restyles this screen and replaces the placeholder. |
| `lib/features/bazar/presentation/bazar_home_screen.dart` | EDIT: month summary header using the same cards, alert badge on the Budget tile. |
| `docs/bazar_dashboard_contract.md` | NEW: the providers Phase 4 must read (`monthSpendProvider`, `fundBalanceProvider`, `contributionStatusProvider`, `budgetAlertsProvider`, `openAdvancesProvider`) and their meaning. |

**Tests:** widget tests with provider overrides (data, empty, error, module disabled → no cards, member vs admin view of the fund card), goldens for the three cards in 2 themes × 2 languages.
**Done when:** Home shows this month's spend and the fund balance from real data and hides them when Bazar is off.

---

### P2-30 — Hardening, performance and Phase 2 sign-off

| | |
| --- | --- |
| **Type** | DEPENDENT |
| **Depends on** | all previous steps |
| **Unblocks** | Phase 3 |

Make **no feature changes**; produce evidence.

1. **Full verification on a clean Linux clone:** `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test --exclude-tags golden`, `flutter test --tags golden` (after the golden workflow), the full rules suite under the emulator, `node tools/check_indexes.mjs`, `flutter build apk --flavor dev -t lib/main_dev.dart` and the prod release build. Save counts in `docs/phase2_evidence.md`.
2. **Rules review checklist** (answer each with file/line evidence in `docs/phase2_security_review.md`): every Phase 2 collection has `hasOnly` key sets, money ints, closed enums; no hard deletes; ledger/settlement/revision rows append-only; closed month rejects expense/fund/contribution/settlement writes; a plain member cannot read other members' `contributions`/`contributionPlans`, cannot record contributions, cannot close months or import; a moderator's finance rights follow `moderatorManagesFinance`; another family's data is unreadable; an unverified email cannot write; 30-line trip passes.
3. **Ledger invariant soak:** a randomized test (1,000 operations: add/edit/delete/restore/settle/contribute/close/reopen) asserting the P2-09 invariant, balance = hand model, and `LedgerIntegrityCheck` reports zero issues.
4. **Performance:** 2,000-row expense list, 5,000-expense report build, and a **Firestore reads budget** in `docs/phase2_reads_budget.md` — documents read per cold start (catalog ≈ 60, settings ≈ 3, month expenses ≤ 500, fund window ≤ 500, budgets/plans/advances ≈ 50) × opens per day vs the current Spark daily read quota **[VERIFY on the Firebase pricing-plans page]**; recommend closing months regularly to keep the fund window small.
5. **Screen-state harness:** run `test/support/screen_states.dart` (created in P2-12) over every Phase 2 screen: loading / data / empty / error / offline × light/dark × bn/en × text scale 2.0, plus Flutter's `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`. Fix what it finds (targets ≥ 48 dp, contrast, no overflow).
6. **Manual test script** (generate as a checkbox table in `docs/phase2_manual_test.md`, run it with two real devices — an admin and a plain member — in Bangla and English, light and dark, online and airplane mode):
   - [ ] Existing family: "Set up starter catalog" works once; a new family gets the catalog automatically
   - [ ] Add an expense in ≤ 10 s; Bangla digits accepted; item autocomplete finds `alu` and `আলু`
   - [ ] Airplane mode: add an expense → it appears with the sync banner; reconnect → synced, one document
   - [ ] Bazar trip of 12 lines; swipe-remove one line; Save all
   - [ ] Edit amount, change funding, delete, Undo → fund balance exactly right each time
   - [ ] Member cannot edit someone else's expense; moderator can
   - [ ] Budget with dry-grocery lines; 80 % and 100 % alerts; copy last month
   - [ ] Record opening balance; equal-split plan; contributions; every member sees every member's row, a member's contribution stays *pending* until a Household Manager approves it
   - [ ] Member-paid expense → advance → partial then full settlement; expense total unchanged
   - [ ] Close a month → forms locked with a reason → Reopen with a note → fix → Close again
   - [ ] Reports: every preset; custom range; comparison; chart semantics read by TalkBack
   - [ ] Import Aug-26 + Sept-26 from `Bazar.xlsx` → totals match; Undo; re-import; budget from Oct-26
   - [ ] Module switched off → Bazar tab, deep links and dashboard cards disappear
7. Update `PROGRESS.md` (every step, evidence link, honest known limitations), `CLAUDE.md` (Phase 2 section), regenerate `docs/permission_matrix.md`, finish the ADRs. Tag `phase-2-complete` **only** when everything above is green.

**Phase 2 acceptance gate**
- [ ] One real month imported; per-category totals match the old sheet to the paisa (Aug ৳12,069.00 / Sept ৳5,015.00)
- [ ] A normal expense takes ≤ 10 s and ≤ 4 taps after item selection (test + stopwatch on a real phone)
- [ ] Contribution, advance, settlement and month-close tests pass; ledger invariant soak passes
- [ ] Rules tests, contract fixtures, index check and all architecture tests green in CI
- [ ] Offline script passes; no duplicate documents after reconnect
- [ ] A member **can** see all members' contributions (owner decision) but cannot approve one, cannot close a month, cannot import; a pending request changes neither `received` nor the fund balance until approved

---

## 14. Interaction matrix (how the pages talk to each other)

| Screen / feature | Reads (providers) | Writes (use cases) | Changes that other screens see immediately |
| --- | --- | --- | --- |
| Add Expense (P2-13) | `catalogIndexProvider`, `membersProvider`, `monthLockedProvider`, `bazarSettingsProvider` | `AddExpense` (+ new custom item, item usage bump, fund row / advance) | Expense list, month spend → budget bars, reports, fund balance, dashboard cards |
| Bazar Trip (P2-14) | same | `AddBazarTrip` | same, N rows grouped by day with a trip marker |
| Expense list/detail (P2-15) | `monthExpensesProvider`, `expenseFiltersProvider`, `expenseAdvanceProvider`, `expenseRevisionsProvider` | `UpdateExpense`, `SoftDeleteExpense`, `RestoreExpense` | Fund balance (compensating rows), advance list (void), budgets, reports |
| Catalog manager (P2-16) | `categoriesProvider`, `itemsProvider` | catalog use cases | Autocomplete, category chips, report labels, budget lines |
| Bazar settings (P2-16) | `bazarSettingsProvider` | `UpdateBazarSettings` | Alert thresholds (budgets), week start (reports), plan generation (fund), fund window (opening balance) |
| Budget (P2-18) | `monthBudgetProvider`, `monthSpendProvider`, `budgetStatusProvider` | `SaveBudget`, `CopyLastMonthBudget` | Alerts on Bazar home and dashboard, report "estimate vs actual" |
| Fund (P2-22) | `fundBalanceProvider`, `contributionStatusProvider`, `fundTransactionsProvider`, `ledgerIntegrityProvider` | `RecordContribution`, `RequestContribution`, `Approve/RejectContribution`, `Approve/RejectContributionChange`, `VoidContribution`, `GenerateMonthPlans`, `SetContributionPlan`, `RecordOpeningBalance` | Dashboard fund card, month-close preview |
| Advances (P2-23) | `openAdvancesProvider` | `SettleAdvance` | Fund balance (reimbursement row), expense detail ledger line |
| Month close (P2-23) | `monthClosingsProvider`, fund window, `budgetStatusProvider` | `CloseMonth`, `ReopenMonth` | `monthLockedProvider` → every form; fund window start; next month's opening row |
| Reports (P2-25) | `reportDataProvider` (reuses `monthExpensesProvider` for single-month ranges), `contributionStatusProvider` | — | — |
| Import (P2-28) | `catalogIndexProvider`, parsed `ImportPlan` | `ImportExpenses`, `UndoImport`, `ImportBudget` | Everything that reads expenses, fund, budgets |

---

## Appendix A — Default catalog (starting seed list for P2-06 — 11 categories incl. Fixed bills; **no review needed now**, the owner can edit, add, deactivate or reorder everything later in the catalog manager)

Ids: `cat_<key>` / `item_<key>`. `colorIndex` indexes `placeholderPalette`. Emoji are the ones your workbook already uses.

| Key | বাংলা | English | colorIndex | Emoji |
| --- | --- | --- | --- | --- |
| vegetables | সবজি | Vegetables | 0 | 🫑 |
| fish | মাছ | Fish | 1 | 🐟 |
| fruits | ফল | Fruits | 2 | 🍎 |
| beef | গরুর মাংস | Beef | 3 | 🐄 |
| chicken | মুরগির মাংস | Chicken | 4 | 🐔 |
| eggs | ডিম | Eggs | 5 | 🥚 |
| dry_groceries | শুকনা বাজার | Dry groceries | 6 | 🛒 |
| gas | গ্যাস | Gas | 7 | ⛽ |
| medicine | ঔষধ | Medicine | 8 | 💊 |
| other | অন্যান্য | Other | 9 | 🅾️ |
| fixed_bills | স্থায়ী বিল | Fixed bills | 10 | 🏠 |

Items (54): `unit` is the default unit; aliases are extra search words (every item is also found by its Bangla and English name).

| Category | Key — বাংলা — English — unit — aliases |
| --- | --- |
| Vegetables | `potato` আলু Potato kg — alu, aloo · `onion` পেঁয়াজ Onion kg — peyaj, piyaj, পিয়াজ, পেয়াজ · `garlic` রসুন Garlic kg — roshun, rosun · `ginger` আদা Ginger kg — ada · `tomato` টমেটো Tomato kg — tometo · `eggplant` বেগুন Eggplant kg — begun, brinjal · `cauliflower` ফুলকপি Cauliflower piece — fulkopi · `cabbage` বাঁধাকপি Cabbage piece — badhakopi, bandhakopi · `cucumber` শসা Cucumber kg — shosha, sosha · `green_chili` কাঁচা মরিচ Green chili kg — morich, kacha morich, chili · `bottle_gourd` লাউ Bottle gourd piece — lau · `pointed_gourd` পটল Pointed gourd kg — potol · `spinach` পালং শাক Spinach kg — palong, shak · `lemon` লেবু Lemon piece — lebu · `carrot` গাজর Carrot kg — gajor |
| Fish | `rui` রুই Rui kg · `katla` কাতলা Katla kg · `hilsa` ইলিশ Hilsa kg — ilish · `tilapia` তেলাপিয়া Tilapia kg · `pangas` পাঙ্গাস Pangas kg · `dried_fish` শুটকি Dried fish kg — shutki |
| Fruits | `banana` কলা Banana dozen — kola · `apple` আপেল Apple kg · `pineapple` আনারস Pineapple piece — anarosh · `guava` পেয়ারা Guava kg — peyara · `orange` কমলা Orange kg — komola |
| Beef | `beef` গরুর মাংস Beef kg — goru, mangsho |
| Chicken | `chicken` মুরগি Chicken kg — murgi, broiler |
| Eggs | `egg` ডিম Eggs dozen — dim, egg |
| Dry groceries | `rice` চাল Rice kg — chal · `polao_rice` পোলাও চাল Polao rice kg · `lentil` মসুর ডাল Red lentil kg — dal, masoor · `soybean_oil` সয়াবিন তেল Soybean oil litre — tel, oil · `mustard_oil` সরিষার তেল Mustard oil litre · `flour` আটা Flour kg — ata · `sugar` চিনি Sugar kg — chini · `salt` লবণ Salt kg — lobon, লবন · `chili_powder` মরিচের গুঁড়া Chili powder kg — morich gura · `turmeric_powder` হলুদের গুঁড়া Turmeric powder kg — holud · `coriander_powder` ধনিয়ার গুঁড়া Coriander powder kg — dhonia · `cumin` জিরা Cumin kg — jira · `garam_masala` গরম মশলা Garam masala packet — moshla · `tea` চা পাতা Tea leaves kg — cha · `milk` দুধ Milk litre — dudh · `puffed_rice` মুড়ি Puffed rice kg — muri · `noodles` নুডুলস Noodles packet |
| Gas | `gas_cylinder` গ্যাস সিলিন্ডার Gas cylinder cylinder — gas |
| Medicine | `medicine` ঔষধ Medicine piece — oshudh, medicine |
| Fixed bills | `flat_rent` ফ্লাট ভাড়া Flat rent piece — rent, bhara · `electricity` ইলেক্ট্রিসিটি বিল Electricity bill piece — bidyut, current · `internet` ইন্টারনেট বিল Internet bill piece — wifi · `garbage` ময়লার বিল Garbage bill piece — moyla |
| Other | `dish_bar` ভিমবার Dish-wash bar piece — vim · `hair_oil` প্যারাসুট তেল Hair oil piece — parachute |

The seed is 11 categories + 54 items = 65 documents; with the nine family documents and two audit documents the create-family batch stays far below the 500-write limit (a test asserts it).

---

## Appendix B — What `Bazar.xlsx` actually contains (verified by reading the file)

**B.1 Structure** — sheets `Oct-26`, `Sept-26`, `Aug-26`, `Template-Sheet`, `Template` (all ~25 columns × 137 rows, 4–5 merged ranges each).

| Area | Cells | Content |
| --- | --- | --- |
| Entries | `A5:D…` (header row 5, data from row 6) | `Date`, `Item`, `Category`, `Price`. **The date is written only on the first row of a day**; following rows rely on helper column `F` (`=IF(A6<>"",A6,F5)`). Some rows carry a `0` price placeholder. Dates are real dates (`d-mmm-yy`). |
| Day totals | `E` | formulas — **ignore** |
| Category totals | `G1:K6` | `SUMIF` formulas over the entries — **ignore**, recompute |
| Dry-grocery table | `G11:K38` (header `আইটেম / বাজেট / মজুদ / দর / মোট`) | 27 lines; quantities are text (`৫০ কেজি`, `১/২ কেজি`, `১ ১/২ কেজি`, `৩ লিটার`, `১০০ টাকার`, `২ ডজন`); `দর`/`মোট` are typed numbers; total **৳8,640** |
| Monthly estimate | `M2:O22` (`💹 মাসের সম্ভাব্য বাজার`) | dry groceries (formula over the table), chicken ৳1,320 (৮ কেজি), beef ৳1,700 (২ কেজি), medicine ৳2,000, fish ৳3,000, raw bazar ৳5,000; then `💰 অন্যান্য`: flat rent ৳17,500, electricity (blank), gas ৳3,200, internet ৳500, garbage ৳120. `Q3 =SUM(O4:O25)` therefore mixes bazar and fixed bills; the app keeps them in separate categories (bazar ৳24,860 + Fixed bills ৳18,120 = ৳42,980). |
| Names | `N26:N28` | `Sumon`, `Shafiq`, `Rafiq` — no amounts; **no contribution data exists in the workbook** (so nothing is imported as contributions). |

**B.2 Category label mapping used by the importer** (labels have a leading emoji and sometimes trailing spaces; `cleanLabel` strips them)

| Sheet label | App category | Item hint |
| --- | --- | --- |
| সবজি | Vegetables | — |
| পিয়াজ | Vegetables | Onion (`item_onion`) |
| আলু | Vegetables | Potato (`item_potato`) |
| মাছ | Fish | — |
| ফল | Fruits | — |
| গরুর গোস্ত | Beef | — |
| মুরগীর মাংস | Chicken | — |
| ডিম | Eggs | — |
| শুকনা বাজার | Dry groceries | — |
| গ্যাস | Gas | — |
| মা এর ঔষধ | Medicine | — |
| অন্যান্য | Other | — |
| কাচা বাজার (estimate block) | Vegetables (estimate) | — |
| ফ্লাট ভাড়া | Fixed bills (estimate) | `item_flat_rent` |
| ইলেক্ট্রিসিটি | Fixed bills (estimate; blank in Oct-26 → skipped as "no amount") | `item_electricity` |
| ইন্টারনেট | Fixed bills (estimate) | `item_internet` |
| ময়লার বিল | Fixed bills (estimate) | `item_garbage` |

Item cells are often generic (`বাজার`, `সবজি`, `মাছ`, `মা`, `আধা`): the importer keeps them as free-text `itemName` and links an `itemId` only on an exact catalog match (e.g. `আলু`, `ডিম`, `গ্যাস`, `চাল`).

**B.3 Reconciliation targets (from the real file)**

| Month | Priced rows | Dates | Total | By sheet label |
| --- | --- | --- | --- | --- |
| Aug-26 | 59 | 24 | ৳12,069.00 | সবজি 3,780 · মাছ 90 · শুকনা বাজার 3,781 · অন্যান্য 870 · পিয়াজ 70 · আলু 195 · ফল 598 · ডিম 140 · মুরগীর মাংস 345 · মা এর ঔষধ 550 · গ্যাস 1,650 |
| Sept-26 | 17 | 9 | ৳5,015.00 | সবজি 1,500 · মাছ 1,050 · শুকনা বাজার 655 · গ্যাস 1,700 · ফল 110 |
| Oct-26 | 0 | — | ৳0 (budget only) | dry-grocery table 27 lines ৳8,640; estimates as in B.1 |

**B.4 Import defaults:** imported rows use funding **fund** unless you choose otherwise in the wizard; they never create contributions; they are tagged `source: import` + `importBatchId` so the whole file can be undone.

---

## Appendix C — Prompt template for every step

```text
Read CLAUDE.md and docs/PHASE2_BAZAR_ROADMAP.md (sections 1-3 and the card for step P2-XX).
Confirm that every step in its "Depends on" line is merged; if not, stop and tell me.
List the files you will create or change BEFORE coding. Implement exactly what the card says (names, signatures, rules).
Follow docs/new_collection_checklist.md for any collection. Extend firestore.rules, firebase/rules_test and the Dart->rules contract fixtures in the same commit.
Use requirePermission / ref.can, AuditWriter, guardWrite (offline policy per section 3.4), FamilyDateKeys, newActionProvider.
Add ARB strings in bn and en and run flutter gen-l10n. Keep files <= 300 lines. No raw colours. No TODO(step-.
Write the tests listed on the card. Run dart format, flutter analyze (zero issues), flutter test --exclude-tags golden, the rules suite and tools/check_indexes.mjs.
Finish with: files changed, how to verify, assumptions. Do not start the next step.
```
