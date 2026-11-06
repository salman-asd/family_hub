# Phase 5 data contract

This contract describes Phase 4 data that a later phase may consume. It does
not grant permission to broaden visibility or change existing write semantics.
The implementation and the applicable Firestore rules remain authoritative.

## Stable inputs Phase 5 may consume

- **Chore occurrences:** use the occurrence domain model and
  `monthItemsProvider` for the displayed month. It combines stored and
  projected occurrences by deterministic id (stored wins), applies display
  status, and is the shared source for calendar/dashboard consumers. Do not
  create a second unbounded occurrence listener or recompute status in widgets.
- **Activity:** consume bounded, paged activity entries (`type`, actor uid,
  reference, params, recorded time). Resolve names through the established
  presentation/localization path. Do not treat localized summary text as
  persisted data or add personal details to audit params.
- **Chore completion and covers:** use the existing occurrence state and
  `CoverCounter`/domain calculation. A cover represents who completed the work;
  skipped work counts for nobody. Do not infer cover totals from UI labels.
- **Member stats:** `memberStats/{uid}` is private to its owner, including
  against administrators. It contains points, streak, monthly aggregates,
  badges, and progress markers. It is not a Phase 5 export, ranking, or
  cross-member report source.
- **Public level card:** `memberStatsPublic/{uid}` is opt-in and points-free.
  It may expose only the approved level/badge fields when family visibility
  permits and the member has opted in. It does not expose points, rankings, or
  private stats.
- **Notifications:** consume inbox rows and existing notification settings
  through their repositories/providers. Derived inbox entries are virtual and
  are not persisted. Reminder/device settings are not report/export data.
- **Bazar/finance:** consume the existing bounded report and month-spend
  providers/domain outputs. Do not recompute report totals or read private
  member stats to enrich finance reports.

## Deliberately not computed or promised

- Cross-member points totals, rankings, exports, or public point histories.
- A server-side push sender or scheduled push sweep on the Spark-only setup.
- Historical stats for data outside the configured scoring/finalization window.
- A denormalized mutable fund balance or a second dashboard/report aggregation.
- User-visible localized strings as a stable storage/API contract.
- Device delivery guarantees inferred from reminder plans or emulator tests.

Any Phase 5 feature that needs data beyond these contracts must identify its
source, access policy, query bounds, offline behavior, and rules/tests before
implementation.
