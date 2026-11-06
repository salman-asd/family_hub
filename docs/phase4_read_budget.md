# Phase 4 Firestore read and listener budget

**Status: NOT MEASURED.** This file records the source inventory and a repeatable
measurement plan; it does not claim a read count or compliance with a Firebase
quota. Confirm the current Spark quota from official Firebase documentation
when measurements are taken.

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
data listeners. There is no dedicated test in the current tree proving that
ceiling or that tab changes add none; the inventory above must not be used as
proof of either claim.

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

## Results (fill during P4-25)

| Scenario | Document reads | Peak active data listeners | Runs / cache state | Result / notes |
|---|---:|---:|---|---|
| Cold launch → Home | Not measured | Not measured | — | — |
| All tabs → Home | Not measured | Not measured | — | — |
| Pull-to-refresh | Not measured | Not measured | — | — |
| Activity, two pages | Not measured | Not measured | — | — |
| Achievements open | Not measured | Not measured | — | — |
| First stats sync, finalized prior month | Not measured | Not measured | — | — |
| Normal day, four members | Not measured | Not measured | — | — |

No quota pass/fail conclusion is possible until the table contains measured
results.
