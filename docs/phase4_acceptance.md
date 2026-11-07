# Phase 4 acceptance record

**Status: NOT SIGNED OFF.** This is the P4-25 evidence record. The automated
half of the gate is green on 2026-11-07: `flutter test --exclude-tags golden`
3275 passed / 0 failed / 0 skipped, `flutter analyze` no issues, `dart format .`
clean, `node tools/check_indexes.mjs` OK. `[ ]` manual boxes remain incomplete
unless evidence is linked in the Notes column. Do not infer a device or Firebase
result from a passing widget test, and do not read this record as acceptance:
the rules emulator, real devices, family UAT, owner copy review and Linux
goldens have not been run.

| # | Acceptance criterion | Status | Notes / evidence required |
|---|---|---|---|
| 1 | Home shows real data; cards respect module, permission, and role policy; a card failure is isolated. | Partial | Phase 4 state matrix passes (180 tests); review/test each registered data card and complete UAT tasks 1–2. |
| 2 | Role-based dashboard policy works across admin, Household Manager, and Member without hiding access controls. | Partial | Existing policy tests are not a substitute for cross-device UAT task 3. |
| 3 | Personal layout persists, required cards stay visible, and move-up/down alternatives work. | Partial | Automated UI coverage exists; re-install/sign-in and role-change checks in UAT task 4 remain. |
| 4 | Dashboard has at most seven data listeners; tab switching adds none. | Measured — ceiling not met | `test/features/dashboard/perf/home_listener_census_test.dart` (5 tests) counts 13 live sources for a Home showing every card, one subscription per source. Tab switches and rebuilds add none, and a cold re-entry doubles none of the ten session-wide sources. Results and the six extra sources are in [phase4_read_budget.md](./phase4_read_budget.md); reducing 13 to 7 is Phase 5 work. Document reads are still not measured. |
| 5 | Delivery modes, recommendations, restrictions, and reset behavior are correct. | Partial | Domain/UI tests exist; run the focused suites and complete the admin cross-device check. |
| 6 | Spark push-client behavior works with console messages; no sender is assumed. | Not run on device | Run the applicable rows of [push_manual_test.md](./push_manual_test.md). Sender-only rows are `N/A — Spark` until a sender exists. |
| 7 | Local reminder delivery works on real devices across the listed Android conditions. | Not run on device | Complete [reminders_manual_test.md](./reminders_manual_test.md) on two brands and record model, Android version, result, and screenshot. |
| 8 | Reminder switches and explanations behave as specified. | Partial | Widget/domain tests exist; finish the real-device permission and settings flow checks. |
| 9 | Planner edge cases, limits, and stable identifiers are covered. | Automated | 23 planner tests run inside the green full-suite run above (quiet hours, per-template suppression, overdue, nudge, morning summary, push-excluded types, the 60-notification cap, stable sorted ids). The device half is row 7. |
| 10 | Scoring is deterministic and monotonic; concurrent syncs preserve results; finalized months stay frozen. | Partial | Sync and scoring unit tests exist. `test/features/chores/achievements/concurrency/stats_sync_concurrency_test.dart` (3 tests) now covers two phones of one member: they converge, the second writes nothing, and a late phone adds a chore once. Its last test records the one case that is **not** preserved — a phone writing from a read taken before the other wrote, because `MemberStatsRepository.save` is a blind set. Guarding that write is Phase 5; see [phase4_polish_audit.md](./phase4_polish_audit.md) item 22. |
| 11 | Private stats and points-free sharing are enforced by rules and UI. | Not verified in this review | UI and domain tests exist; the rules themselves are unproven here. Run `npx firebase emulators:exec --only firestore --project demo-family-hub "npm --prefix firebase/rules_test test"` (needs JDK 21+ on `PATH`) and UAT task 11 — Java is not installed on this machine, so the emulator could not start. |
| 12 | Daily celebration is once per day, avoids stale cold-start celebration, and respects reduced motion. | Automated partial | Celebration tests pass (7 tests), including a shared in-memory two-session race and offline fallback. Firestore transaction race and device motion checks remain. The offline fallback is device-local and cannot guarantee cross-device deduplication. |
| 13 | No star ratings or rankings appear. | Review pending | Complete a product-wide screen/content review and record the reviewer/date. |
| 14 | Activity types have Bangla/English text; filtering and paging do not grow listeners. | Partial | Run activity localization, paging, and listener tests; no read-budget evidence is recorded here. |
| 15 | Inbox combines stored/derived items and resolves derived items correctly. | Partial | Run the inbox behavior suite and complete UAT task 9. |
| 16 | Accessibility, Bangla at 200%, contrast, and tablet layouts meet the stated criteria. | Automated partial | Accessibility audit passes for eight Phase 4 screens in bn/en; responsive suites pass for covered screens. The High layout findings in [phase4_polish_audit.md](./phase4_polish_audit.md) (Today screen, swap banner, availability/duty-starter labels, swap sheet cold list, section-card ink) are fixed with tests. Full application coverage and Linux goldens remain. |
| 17 | Dependencies and Spark-only operation match the roadmap. | Review pending | Review the complete dependency diff and confirm no sender, Blaze dependency, or `functions/` deployment was introduced. |
| 18 | Phase 5 data contract matches persisted Phase 4 data. | Documented, review pending | See [phase5_contract.md](./phase5_contract.md); owner/reviewer must confirm it against the implementation. |

## Required manual evidence

For UAT, use the fourteen tasks in Appendix G.3 of
[the roadmap](./PHASE4.1_DASHBOARD_ENGAGEMENT_ROADMAP.md). Record the tester,
date, app version/flavor, device details, pass/fail, and a screenshot or
reproducible note for each task. Include notification-copy owner review and
the offline/reconnect scenario. Do not paste FCM tokens or other secrets.

For every failed or skipped item, record the reason and the follow-up owner.
P4-26 remains optional and deferred; it is not a sign-off dependency on Spark.
