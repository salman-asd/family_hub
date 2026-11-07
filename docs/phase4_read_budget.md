# Phase 4 Firestore read and listener budget

**Status: LISTENERS MEASURED, DOCUMENT READS NOT MEASURED.** This file records
the source inventory, the repeatable measurement plan, and the part of it that
has been measured. It does not claim a read count or compliance with a Firebase
quota; counting documents still needs the emulator run in step 5 below, which
has not been possible on this machine (no Java). Confirm the current Spark
quota from official Firebase documentation when measurements are taken.

## Dashboard source inventory

The card-to-provider mapping below is from Appendix A.2 of the Phase 4
roadmap. Provider names identify data sources, not a measured number of
Firestore reads or active listeners.

| Card | Data providers |
|---|---|
| `budget_alert` | `budgetAlertsProvider` |
| `approvals` | members and contribution providers |
| `chores_today` | `todayProgressProvider`, `todayItemsProvider` |
| `chores_overdue` | `overdueItemsProvider` |
| `chores_verify` | `verifyQueueProvider` |
| `bazar_month` | `monthSpendProvider`, `budgetStatusProvider` |
| `bazar_fund` | `fundBalanceProvider`, `contributionStatusProvider` |
| `upcoming` | `todayItemsProvider`, `monthItemsProvider` |
| `chores_week` | `weekModelProvider` |
| `hub_level` | `memberStatsProvider`, `levelProvider` |
| `recent_activity` | `recentActivityProvider(5)` |

The roadmap expects shared occurrence providers and a maximum of seven Home
data listeners. That ceiling is now measured rather than assumed — and the
measurement is above it: see the results table and
[../test/features/dashboard/perf/home_listener_census_test.dart](../test/features/dashboard/perf/home_listener_census_test.dart),
which counts one Home showing every card in the catalog.

## Measurement procedure

1. Use a disposable Firebase project/emulator and a representative four-member
   family. Instrument repository reads and stream subscriptions at the data
   boundary; count returned documents and active subscriptions separately.
2. Reset counters before each scenario. Record cold-cache and warm-cache
   results separately, and state whether local cache reads are included.
3. Measure:
   - cold launch through the settled Home tab;
   - switching through every tab and back to Home;
   - pull-to-refresh;
   - Activity through two pages;
   - Achievements open;
   - the first stats sync with one finalized previous month;
   - a normal day for four active members.
4. Repeat enough times to catch duplicate subscription creation. Capture
   listener count after Home settles and after each tab transition; check the
   Home limit of seven and zero additional listeners from tab switching.
5. Compare daily read totals with the then-current official Spark allowance.
   Record the source URL/date and the measured family workload; do not infer
   production usage solely from emulator results.

## Results (measured 2026-11-07, Windows, `flutter test`)

The listener column is measured, not planned. It comes from
`test/features/dashboard/perf/home_listener_census_test.dart`, which pumps the
real `HomeScreen` with every provider replaced by a stream that stays open until
the reader leaves and counts `onListen`/`onCancel` at the boundary. A Riverpod
`StreamProvider` holds exactly one subscription, so this is the number of
Firestore listeners Home would hold; it is **not** a document-read count, which
still needs the emulator.

| Scenario | Document reads | Peak active data listeners | Runs / cache state | Result / notes |
|---|---|---:|---|---|
| Cold launch → Home (all cards) | Not measured | 13 | 1 run, stubbed streams, one `ProviderScope` | Over the plan of seven. The seven planned sources are members, templates, month occurrences, month expenses, contributions, activity, inbox; the six more are budget, categories, fund transactions, contribution plans, availability and the member's own stats. |
| All tabs → Home | Not measured | 13 | 1 run | A rebuild adds nothing: 13 before, 13 after, and no source opened twice (`StatefulShellRoute.indexedStack` keeps Home mounted). |
| Home unmounted, then re-opened | Not measured | 13 | 1 run | None of the ten session-wide sources double. The auto-disposing reads (activity, engagement settings, member stats) do re-subscribe — measured, and they are bounded reads. |
| Pull-to-refresh | Not measured | Not measured | — | Needs the emulator run. |
| Activity, two pages | Not measured | Not measured | — | Needs the emulator run. |
| Achievements open | Not measured | Not measured | — | Needs the emulator run. |
| First stats sync, finalized prior month | Not measured | Not measured | — | The sync test counts repository calls, not Firestore reads: 2 writes and 1 month read for a first sync, 0 further writes for a repeat. |
| Normal day, four members | Not measured | Not measured | — | Needs the emulator run. |

No quota pass/fail conclusion is possible until the document-read column has
measured results. The ceiling in the census test is pinned at the measured 13,
so any new listener fails the test rather than passing silently — lowering it
back towards seven means giving the six extra cards a shared source, which is
Phase 5 work.

