# 0007 - The fund balance is computed from the ledger (decision D-P2-3)

**Status:** accepted (Phase 2, P2-01)

No document stores a mutable "current balance". The balance is always

```text
balance = sum(fundTransactions with monthKey >= M0)
```

where `M0` is the month after the latest **closed** month, or
`settings/bazar.fundStartMonth` when no month has been closed yet. Closing a
month writes an `opening` row into the following month, so the window stays
bounded and every read is a normal month-range query with a `limit`.

Consequences:

* the Fund card and the dashboard can never disagree with the ledger;
* a settlement or correction is visible immediately, without a second write to
  a cached total;
* a closed month can only be changed through `ReopenMonth` (Admin or Household
  Manager, with a note).
