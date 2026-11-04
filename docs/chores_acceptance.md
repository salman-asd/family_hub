# Chores - acceptance and sign-off (P3-30)

Nothing in this file has been run by the author: the work was written without an SDK. Every "Result" cell is empty until a person fills it in. Do not tag `phase-3` while any row of section 1 is open.

## 1. Gate (run on a machine with the SDK, in this order)

| # | Command | Result |
| --- | --- | --- |
| 1 | `dart format .` | |
| 2 | `flutter gen-l10n` (expect no diff) | |
| 3 | `flutter analyze` (zero issues, infos included) | |
| 4 | `flutter test --exclude-tags golden` | |
| 5 | `npm run test:emulator` in `firebase/rules_test` (includes the parity table and the 400-create batch) | |
| 6 | `node tools/check_indexes.mjs` | |
| 7 | `flutter test --tags golden` on Linux CI only | |
| 8 | After step 1, re-check `test/architecture/file_size_test.dart`: split what is still over 300 lines and delete its allow-list entries | |

## 2. Acceptance criteria (roadmap section 6)

| # | Criterion | Proof | Status |
| --- | --- | --- | --- |
| 1 | Starter pack to today's chores in under 3 minutes | UAT task 1 | open |
| 2 | Two-tap completion; parent/subtask rules | tests, UAT 3 | open |
| 3 | Rotation is calendar-based; absence never shifts it | rotation tests, UAT 6 | open |
| 4 | Every option is data; no literal option lists | `no_hardcoded_options_test` | open |
| 5 | Calendar passes Appendix B.9 with 900 chores | goldens, `month_model_perf_test` (smoke only) | open |
| 6 | Mine / Family and filters cost 0 reads | `docs/chores_read_budget.md` measurement | open |
| 7 | Two devices end in a valid state | `concurrency/two_device_test.dart` + rules parity | open |
| 8 | No self-verification; reopen needs a reason; comments survive | use-case + rules tests | open |
| 9 | Swap/cover needs a reason and acceptance; history kept | swap tests, UAT 7 | open |
| 10 | All chore collections have rules; 400-create batch passes | `chore_rules_carve_out_test`, emulator suite | open |
| 11 | Spark only, no Functions, only Appendix D packages | `pubspec.yaml` review | open |
| 12 | Phase 4 contract matches the data | `docs/chores_phase4_contract.md` | open |

## 3. Manual scripts

### Offline matrix
| Action offline | Expected |
| --- | --- |
| Complete a chore, tick steps | Shows at once, SyncBanner "waiting"; syncs on reconnect |
| Add a comment | Same |
| Request a swap | Queues; the recipient sees it after both are online |
| Accept or decline a swap | Refused with a "needs internet" message |
| Save chore settings, change a rotation, reassign | Refused with "needs internet" |
| Two phones tick different steps offline, then reconnect | Both ticks present, chore completed |

### Accessibility (TalkBack, Bangla)
Calendar grid cell labels; tile swipe actions have non-gesture equivalents; sheets reachable; text scale 2.0; "remove animations" setting; contrast in light and dark.

### Localization
No English text in Bangla mode; Bangla digits everywhere; the starter-pack doubtful lines (roadmap Appendix A, Q1) confirmed by the owner; nth-weekday sentences read by the owner.

## 4. UAT with the family (ten tasks)

| # | Task | Pass / fail | Comment |
| --- | --- | --- | --- |
| 1 | Apply the starter pack | | |
| 2 | Add a weekly chore with steps | | |
| 3 | Complete a chore step by step | | |
| 4 | Verify someone else's chore | | |
| 5 | Report a problem in a comment and reopen with a reason | | |
| 6 | Add a member to the rotation; past weeks unchanged | | |
| 7 | Record a sickness, send and accept a cover | | |
| 8 | Find "who does what next Saturday" in Month, Agenda and Rota | | |
| 9 | Switch language, theme and week start | | |
| 10 | Use the app offline for five minutes | | |

## 5. Ten integration seams (roadmap section 7)

Save a template and see it in Today; change settings and see pickers/calendar follow; change a rotation (past unchanged); complete on a planned day (one document created); record an absence; accept a swap (detail, calendar, workload, inbox agree); pause a template; switch the Chores module off; go offline; switch language and theme. Record each as pass/fail here.
