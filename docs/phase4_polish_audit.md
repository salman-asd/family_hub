# Phase 4 polish audit (P4-23)

**Status:** review findings recorded; this is not Phase 4 sign-off. The review
covers the Phase 4 test harness, responsive layouts, and the changed files
described in the findings. It is not a line-by-line audit of every screen in
the app.

## Findings

| # | Severity | Location | Finding | Status |
|---|---|---|---|---|
| 1 | High | `lib/features/chores/calendar/presentation/widgets/agenda_view.dart` | The agenda jump-to-today threshold was referenced but undefined, preventing compilation. | Fixed by defining the existing 240 dp threshold. Calendar view tests pass. |
| 2 | Medium | `test/features/chores/calendar/presentation/calendar_polish_test.dart` | The reduced-motion test asserted that there were no transient callbacks, which was not a reliable assertion of the configured transition duration. | Fixed to assert the transition configuration. Test passes. |
| 3 | Medium | `test/features/chores/calendar/presentation/calendar_views_test.dart` | The filter test left its modal route open while testing chip removal. | Fixed by dismissing the sheet through its Navigator. Test passes. |
| 4 | Medium | `test/features/chores/achievements/presentation/celebration_controller_test.dart` | A server-only celebration claim suppressed the celebration while offline, despite the existing offline expectation. | Fixed: a `Network` failure permits the local once-per-device fallback; online transactions remain the cross-session claim. This cannot guarantee deduplication across devices on an indeterminate network failure. Test passes. |
| 5 | Medium | `lib/features/chores/achievements/presentation/celebration_controller.dart` | The controller exceeded the 300-line project limit. | Fixed by extracting repeated failure logging to `celebration_diagnostics.dart`; the file-size guard passes. |
| 6 | Medium | `test/features/dashboard/perf/` | No test was found proving the dashboard's seven-listener ceiling or that tab changes add no listeners. | Open. Do not treat the dashboard listener budget as verified. |
| 7 | Medium | `test/features/chores/achievements/concurrency/` | The two-session celebration test uses a shared in-memory repository; no Firestore-emulator transaction race or concurrent stats-sync test was found. | Partially covered; emulator/concurrent-sync proof remains open. |
| 8 | Low | `test/features/phase4/phase4_test_support.dart` | The shared state and semantics harness covers eight Phase 4 screens, not every screen or form touched by the whole application. | Eight-screen coverage passes; broader coverage remains open. |
| 9 | Low | Device/UAT evidence | Reminder/push checklists contain procedures but no device records, screenshots, owner copy review, or family UAT results. | Not run; see [phase4_acceptance.md](./phase4_acceptance.md). |
| 10 | Low | Goldens | Phase 4/Linux goldens were not generated or reviewed on this Windows machine. | Not run; generate and inspect on Linux. |

## Automated coverage run for this review

- Celebration controller: 7 tests passed, including online race simulation and
  offline local fallback.
- Stats actions and sync: 7 tests passed.
- Phase 4 screen state matrix: 180 tests passed.
- Phase 4 accessibility audit: 19 tests passed.
- Dashboard grid, tablet shell, achievements responsive layout, and occurrence
  detail responsive layout: 18 tests passed.
- Calendar polish and calendar views: 32 tests passed.
- Architecture file-size guard: 1 test passed.

These are focused automated checks, not evidence for device behavior, Firestore
read counts, emulator rules, or family acceptance. See
[phase4_read_budget.md](./phase4_read_budget.md) and
[phase4_acceptance.md](./phase4_acceptance.md) for the open gates.
