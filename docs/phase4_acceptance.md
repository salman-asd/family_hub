# Phase 4 acceptance record

**Status: NOT SIGNED OFF.** This is the P4-25 evidence record. Automated test
results are from this review; `[ ]` manual boxes remain incomplete unless
evidence is linked in the Notes column. Do not infer a device or Firebase
result from a passing widget test.

| # | Acceptance criterion | Status | Notes / evidence required |
|---|---|---|---|
| 1 | Home shows real data; cards respect module, permission, and role policy; a card failure is isolated. | Partial | Phase 4 state matrix passes (180 tests); review/test each registered data card and complete UAT tasks 1–2. |
| 2 | Role-based dashboard policy works across admin, Household Manager, and Member without hiding access controls. | Partial | Existing policy tests are not a substitute for cross-device UAT task 3. |
| 3 | Personal layout persists, required cards stay visible, and move-up/down alternatives work. | Partial | Automated UI coverage exists; re-install/sign-in and role-change checks in UAT task 4 remain. |
| 4 | Dashboard has at most seven data listeners; tab switching adds none. | Not verified | No dashboard listener-budget test or measurement was found. Add the test and record results in [phase4_read_budget.md](./phase4_read_budget.md). |
| 5 | Delivery modes, recommendations, restrictions, and reset behavior are correct. | Partial | Domain/UI tests exist; run the focused suites and complete the admin cross-device check. |
| 6 | Spark push-client behavior works with console messages; no sender is assumed. | Not run on device | Run the applicable rows of [push_manual_test.md](./push_manual_test.md). Sender-only rows are `N/A — Spark` until a sender exists. |
| 7 | Local reminder delivery works on real devices across the listed Android conditions. | Not run on device | Complete [reminders_manual_test.md](./reminders_manual_test.md) on two brands and record model, Android version, result, and screenshot. |
| 8 | Reminder switches and explanations behave as specified. | Partial | Widget/domain tests exist; finish the real-device permission and settings flow checks. |
| 9 | Planner edge cases, limits, and stable identifiers are covered. | Automated tests not re-run here | Run Appendix F.1 planner tests and record the command/result. |
| 10 | Scoring is deterministic and monotonic; concurrent syncs preserve results; finalized months stay frozen. | Partial | Sync and scoring unit tests exist. No concurrent Firestore stats-sync test was found; add/run it before sign-off. |
| 11 | Private stats and points-free sharing are enforced by rules and UI. | Not verified in this review | Run the Firestore emulator rules suite and UAT task 11; emulator could not start here because Java is unavailable. |
| 12 | Daily celebration is once per day, avoids stale cold-start celebration, and respects reduced motion. | Automated partial | Celebration tests pass (7 tests), including a shared in-memory two-session race and offline fallback. Firestore transaction race and device motion checks remain. The offline fallback is device-local and cannot guarantee cross-device deduplication. |
| 13 | No star ratings or rankings appear. | Review pending | Complete a product-wide screen/content review and record the reviewer/date. |
| 14 | Activity types have Bangla/English text; filtering and paging do not grow listeners. | Partial | Run activity localization, paging, and listener tests; no read-budget evidence is recorded here. |
| 15 | Inbox combines stored/derived items and resolves derived items correctly. | Partial | Run the inbox behavior suite and complete UAT task 9. |
| 16 | Accessibility, Bangla at 200%, contrast, and tablet layouts meet the stated criteria. | Automated partial | Accessibility audit passes for eight Phase 4 screens in bn/en; responsive suites pass for covered screens. Full application coverage and Linux goldens remain. |
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
