# 0006 - The fund ledger is append-only (decision D-P2-4)

**Status:** accepted (Phase 2, P2-01)

`fundTransactions`, `settlements` and `expenses/{id}/revisions` are never updated
and never deleted, not even softly. A correction is a NEW compensating row (for
example an `adj_` ledger entry) and the original row keeps its meaning.

This is the one documented exception to the project rule "soft delete only"
(CLAUDE.md rule 5): these rows are not removed at all, so there is no state in
which a `deletedAt` marker would help. The collection key sets in
`firebase/firestore.rules` therefore deny every `update` and `delete` on a
ledger or revision document, and the app treats them as immutable history.

Deterministic ids keep the ledger self-describing: `exp_<expenseId>`,
`con_<contributionId>`, `stl_<settlementId>`, `open_<yyyy-MM>`, `adj_<eventId>`.
