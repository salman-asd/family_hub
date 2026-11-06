# Phase 3 state, as Phase 4 reads it (written in P4-01)

Phase 3 is implemented but was **never compiled as a whole**: P3-29 and P3-30 (and several earlier steps) were written without an SDK. This page is NOT a re-spec of Phase 3. It lists what Phase 4 reads and what is known about each piece.

**Status column.** `not gated` means the P4-01 gate has not been run yet. After you run the gate (`PROGRESS.md`, "P4-01 gate"), replace each cell with **works**, **compile-fixed** (a P4-00 repair touched it) or **broken** (then fix it as `P3-fix-xx` before Phase 4 continues). Do not mark a row from reading the code.

| Piece Phase 4 reads | Where | Read by (Phase 4 step) | Known risk (from `PROGRESS.md`) | Status |
| --- | --- | --- | --- | --- |
| Inbox: `InboxRepository`, `inboxRepositoryProvider`, `inboxProvider`, `unreadInboxCountProvider`, `MarkInboxRead`, `ArchiveInboxItem`, `InboxScreen`, `InboxBell`; real `ChoresInboxPort` (replaces `NoopInboxPort` in `bootstrap.dart`) | `lib/features/notifications/`, `firebase/firestore.rules` (`notificationInbox`) | P4-04, P4-07 (bell), P4-11, P4-17 (derived items, foreground bridge), P4-15 (push trigger) | P3-26: null-aware elements `?row?.withId(...)`, `NewInboxItem.withId` usage; the default provider is an empty repository, bootstrap overrides it | not gated |
| Swaps: `SwapRepository`, `swapRepositoryProvider`, `AcceptSwap` and siblings, `expireSwapsOnOpenProvider` | `lib/features/chores/swaps/` | P4-09 (types `swap_request`, `swap_result`), P4-15 (push), P4-17 | P3-26: in-memory occurrence backend rejecting a patch it does not know; `rulesList('...Keys')` parsing in tests | not gated |
| Availability: `AvailabilityIndex`, `availabilityIndexProvider` (the one absence seam) | `lib/features/chores/availability/` | P4-10 (planner skips absent days), P4-18 (streak pauses, absence neutral) | P3-26: only ACTIVE absences enter the index; the default repository returns no absences | not gated |
| Needs cover: `needsCoverItemsProvider`, `needsCoverCountProvider` | `lib/features/chores/swaps/presentation/needs_cover_providers.dart` | P4-09 (type `needs_cover`), P4-17 | P3-29: derives from `monthItemsProvider(thisMonth)`, so it inherits the month listener | not gated |
| Today: `todayItemsProvider`, `todayProgressProvider`, `verifyQueueCountProvider`, `nowTickProvider` | `lib/features/chores/occurrences/presentation/today_providers.dart` | P4-07, P4-10, P4-12, P4-21 (celebration trigger) | P3-29: test harness `pumpP3Screen` with a `Scaffold` home; 15:00 Dhaka clock making the default occurrence overdue in the cards test | not gated |
| Month: `monthItemsProvider(MonthKey)` | `lib/features/chores/calendar/presentation/calendar_items_providers.dart` | P4-07, P4-10, P4-18 | P3-25: `Override` and `monthOccurrencesProvider.overrideWith((ref, month) => ...)` were not checked against the resolved Riverpod 3 API; adjust the override, not the screen | not gated |
| Chore dashboard cards: `choresDashboardCards`, `dashboardTodayProgressProvider`, `dashboardOverdueProvider`, `dashboardWeekProvider`; `ChoresModule.dashboardCards` (4 cards) | `lib/features/chores/presentation/dashboard/` | P4-07 (wrapped into `DashboardCardSpec`s) | P3-29: week-card key format `'chores_week_2026-10-24'` (`DateKey.toString`) | not gated |
| Reminder config on templates: `ReminderConfig` | `lib/features/chores/templates/domain/template_parts.dart` | P4-10 (third switch level) | P3-16: stored by the editor, consumed by nobody yet | not gated |
| Phase 4 contract | `docs/chores_phase4_contract.md` | all of Wave C and D | none: a document | n/a |
| Rules and indexes for the above | `firebase/firestore.rules`, `firebase/firestore.indexes.json`, `tools/check_indexes.mjs` | P4-06, P4-11, P4-19 | P3-26/30: the emulator suite and the parity table were never run in this tree | not gated |

## Also not gated (from P3-30)

Emulator rules matrix, read-budget measurement, device performance run, TalkBack pass, offline script and UAT (`docs/chores_acceptance.md`, empty result cells). `phase-3` must not be tagged until the P4-01 gate is green and these are done or consciously deferred.

## P4-01 file-size split (done, needs the gate to confirm)

The ten over-300-line files were split into `part` files with no behaviour change (`PROGRESS.md`, "P4-01"). Two kinds of structural edit go beyond moving a block, so look at them first if a test fails: `recurrence_picker_sheet.dart` (two field builders became top-level functions in `recurrence_picker_parts.dart`) and `template_editor_controller.dart` (the draft setters became the `TemplateDraftSetters` mixin; `_plan` became the top-level `_planAfterSave(ref, ...)`).
