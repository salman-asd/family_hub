# Phase 4 polish audit (P4-23)

**Status:** every High finding is closed. The two Medium findings that stay open
are measurements, not guesses: Home's listener count and the unguarded stats
write. Neither is a Phase 4 gate, and both are handed to Phase 5 with the test
that pins it. This is the audit of the Phase 4 test harness, the screens touched
by Waves A–E and the changed files; it is not a line-by-line audit of every
screen in the app.

## Findings

| # | Category | Severity | Location | Issue | Status |
|---|---|---|---|---|---|
| 1 | Compile | High | `lib/features/chores/calendar/presentation/widgets/agenda_view.dart` | The agenda jump-to-today threshold was referenced but undefined, preventing compilation. | Fixed by defining the existing 240 dp threshold. Calendar view tests pass. |
| 2 | Test | Medium | `test/features/chores/calendar/presentation/calendar_polish_test.dart` | The reduced-motion test asserted that there were no transient callbacks, which was not a reliable assertion of the configured transition duration. | Fixed to assert the transition configuration. Test passes. |
| 3 | Test | Medium | `test/features/chores/calendar/presentation/calendar_views_test.dart` | The filter test left its modal route open while testing chip removal. | Fixed by dismissing the sheet through its Navigator. Test passes. |
| 4 | Offline | Medium | `test/features/chores/achievements/presentation/celebration_controller_test.dart` | A server-only celebration claim suppressed the celebration while offline, despite the existing offline expectation. | Fixed: a `Network` failure permits the local once-per-device fallback; online transactions remain the cross-session claim. This cannot guarantee deduplication across devices on an indeterminate network failure. Test passes. |
| 5 | Architecture | Medium | `lib/features/chores/achievements/presentation/celebration_controller.dart` | The controller exceeded the 300-line project limit. | Fixed by extracting repeated failure logging to `celebration_diagnostics.dart`; the file-size guard passes. |
| 6 | Read budget | Medium | `test/features/dashboard/perf/home_listener_census_test.dart` | No test proved the dashboard's listener ceiling or that tab changes add no listeners. | Measured, not assumed: 13 live sources, one subscription each; a rebuild adds none; a cold re-entry doubles none of the ten session-wide sources. The ceiling of seven in D-P4-14 is **not** met — open item 21 below. |
| 7 | Concurrency | Medium | `test/features/chores/achievements/concurrency/stats_sync_concurrency_test.dart`, `test/features/notifications/concurrency/two_phone_reminder_plan_test.dart` | No concurrent stats-sync test existed and nothing pinned two phones planning reminders; the only two-session test was the celebration claim. | Written and passing: two phones over one document converge, the second writes nothing, and a late phone adds a chore once (item 22 covers the stale read). The reminder half is 3 tests: both phones end on the same pending set, a re-plan cancels only its own alarms, and a sign-out clears only that device. Firestore-emulator transaction races still need Java. |
| 8 | Harness scope | Low | `test/features/phase4/phase4_test_support.dart` | The shared state and semantics harness covers eight Phase 4 screens, not every screen or form touched by the whole application. | Eight-screen coverage passes; broader coverage remains open by design. |
| 9 | Evidence | Low | Device/UAT checklists | Reminder and push checklists contain procedures but no device records, screenshots, owner copy review, or family UAT results. | Not run; see [phase4_acceptance.md](./phase4_acceptance.md). |
| 10 | Evidence | Low | Goldens | Phase 4/Linux goldens were not generated or reviewed on this Windows machine. | Not run; generate and inspect on Linux. |
| 11 | Layout | High | `lib/features/chores/presentation/today_screen.dart` | The header, progress and helpers were a fixed `Column` above an `Expanded` list: at 2.0x text the top part alone was taller than the screen, so the list overflowed and the header controls could be pushed off. | Fixed — the whole screen is one `ListView` now, so every part scrolls. Two `today_screen_test` overflow cases pass. |
| 12 | Layout | High | `lib/features/chores/swaps/presentation/swap_status_banner.dart` | The answer/cancel button shared one `Row` with the message, leaving the text zero width at 2.0x or with a long Bangla label. | Fixed — the action sits under the message (still a 48 dp target). The banner tests in `swap_ui_test.dart` pass; the banner is not in the Phase 4 semantics harness, which is what row 8 still flags. |
| 13 | States | Medium | `lib/features/chores/swaps/presentation/swap_sheet.dart` | The sheet read `membersProvider` before it opened, so a family list that had not arrived yet was reported as "nobody is available". | Fixed — the sheet watches the list and shows the loading state instead of a wrong empty state, with a test that holds the list back and asserts no `swap_nobody`, no send button, one `LoadingView`. |
| 14 | Layout | Medium | `lib/features/chores/availability/presentation/availability_card.dart`, `lib/features/chores/rota/presentation/widgets/on_duty_strip.dart`, `lib/features/chores/starter_packs/presentation/widgets/starter_pack_pick_step.dart` | Fixed-width text in a `Row`: the availability status label overflowed its card by a pixel and the duty-strip count and starter-pack chip labels had no room at 2.0x Bangla. | Fixed with `Flexible` + maxLines/ellipsis; the labels truncate instead of pushing the row off. |
| 15 | A11y | Medium | `lib/features/chores/settings/presentation/chore_settings_screen_parts.dart`, `lib/features/chores/templates/presentation/widgets/editor_section_card.dart` | Section cards were a bare `DecoratedBox`, so a `Switch` or tile inside them painted no ink and the tap gave no visible feedback. | Fixed — wrapped in a transparent `Material`; the splash reaches the control. |
| 16 | Correctness | Low | `lib/features/chores/rota/presentation/rota_providers.dart` | Month bounds were built as `DateKey(year, month + 1, 1)`, which is invalid in December. | Fixed to `monthKey.startOfMonth` / `endOfMonth`; rota bounds tests pass. |
| 17 | Data | Medium | `lib/features/chores/occurrences/domain/occurrence_write_plan.dart` | `OccurrencePatch` compared its nested `fields` map by identity, so two patches carrying the same writes were unequal — the write plan could not recognise its own result. | Fixed — `sameValue`/`hashValue` in `lib/core/utils/value_equality.dart` compare maps and lists by content, with six unit tests. The extraction also returns the file to 289 lines, inside the 300-line guard. |
| 18 | Test | High | `test/support/in_memory_chores_backend.dart` | `watchRange` was an `async*` generator driven by `await for`; a generator parked on a broadcast stream does not run its `finally` when the consumer cancels, so the fake's live-listener counter never fell and every D-01 "released the month" assertion failed. | Fixed — an explicit `StreamController(onListen:, onCancel:)`, which is told the moment its last listener leaves. The assertions were kept, not loosened. |
| 19 | Test | Medium | `test/features/chores/swaps/domain/swap_use_cases_test.dart` | A swapped-back-after-starting case expected `concurrent_edit`; `AcceptSwap` checks ownership before start, so the code is `occurrence_started`. | Fixed the expectation against the documented check order in `accept_swap.dart:89` (ownership) before `:92` (start); the rule itself is unchanged. |
| 20 | Test | Medium | `test/features/chores/occurrences/presentation/occurrence_providers_test.dart` | The app-open hook tests asserted after one `pump()` and armed their failure after `listen`, so one passed vacuously and another read a run that had not finished. | Fixed — the failure is armed before the provider is read and the provider future is awaited. |

## Open items handed to Phase 5

| # | Category | Severity | Location | Issue | Status |
|---|---|---|---|---|---|
| 21 | Read budget | Medium | `test/features/dashboard/perf/home_listener_census_test.dart`, `docs/phase4_read_budget.md` | Home keeps 13 live data listeners where D-P4-14 planned seven: budget, categories, fund transactions, contribution plans, availability and member stats each read their own source. Flat in family size, but above the plan. | Open. The test pins the ceiling at 13, so a new listener fails rather than passing silently. |
| 22 | Concurrency | Medium | `lib/features/chores/achievements/data/firestore_member_stats_repository.dart` (`save`) | The write is a blind batch `set`, so a phone that syncs from a read taken before the other phone wrote replaces its document — the second phone's finalised month is gone. Pinned by the third test in `stats_sync_concurrency_test.dart`. | Open. Needs a guarded (compare-and-set / transaction) write in Phase 5. |

## Automated coverage run for this review

- Celebration controller: 7 tests passed, including online race simulation and
  offline local fallback.
- Stats actions and sync: 7 tests passed.
- Stats sync from two phones: 3 tests passed.
- Two phones planning reminders: 3 tests passed.
- Home listener census: 5 tests passed.
- `value_equality`: 6 tests passed.
- Phase 4 screen state matrix: 180 tests passed.
- Phase 4 accessibility audit: 19 tests passed.
- Dashboard grid, tablet shell, achievements responsive layout, and occurrence
  detail responsive layout: 18 tests passed.
- Calendar polish and calendar views: 32 tests passed.
- Architecture file-size guard: 1 test passed.
- Swap UI (banner answers, sheet waits for the family list): 6 tests passed.
- Whole suite: 3275 passed, 0 failed, 0 skipped (`flutter test --exclude-tags
  golden`, 2026-11-07). `flutter analyze` reports no issues, `dart format .` is
  clean and `node tools/check_indexes.mjs` passes.

These are focused automated checks, not evidence for device behavior, Firestore
read counts, emulator rules, or family acceptance. See
[phase4_read_budget.md](./phase4_read_budget.md) and
[phase4_acceptance.md](./phase4_acceptance.md) for the open gates.
