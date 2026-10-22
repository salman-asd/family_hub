# 0008 - Bazar offline writes and rules cost (decisions D-P2-2, D-P2-16)

**Status:** accepted (Phase 2, P2-01)

Everyday entries - expense, bazar trip, contribution, budget, custom item -
are written as ONE batch through `guardWrite` **without** a server probe, so
they queue offline and the global sync banner explains the delay.

Money-integrity operations - settle an advance, close or reopen a month,
import, undo an import, catalog backfill, Bazar settings - need fresh state;
they use a probe (`serverProbeFor`) and a transaction/batch and fail fast with
`Network` when offline.

The security rules do not cross-check every line of a trip: Firestore allows
10 access calls per single request and 20 per batch/transaction, and a long
trip would exceed that. Invariants are covered by use-case tests,
`LedgerIntegrityCheck` and the mandatory 30-line-trip emulator test instead.
Restoring a soft-deleted expense is a plain batch with no probe, so Undo works
offline. This also keeps the trust boundary honest: the rules validate shape,
types and membership; the app enforces accounting rules.
