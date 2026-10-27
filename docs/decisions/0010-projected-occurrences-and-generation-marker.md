# 0010 - Projected occurrences and the generation marker (decisions D-P3-6, D-P3-10)

**Status:** accepted (Phase 3, P3-01).

**Context.** A month that nobody has generated yet (a future month, or a day
before any device opened the app) must look the same as a materialized month,
and the two must never disagree. Spark has no trusted server to run a
scheduler.

**Decision.**
1. ONE pure `OccurrenceGenerator` produces occurrence drafts. The calendar and
   Today show materialized documents plus *projected* drafts for dates that
   have no document yet, up to `projectedMonthsAhead` (default 3). A projected
   item is read-only and labelled "planned"; the first write on it (complete,
   comment, swap) materializes it in the same batch. A materialized document
   always wins by id.
2. Generation is tracked by a marker `settings/choreGeneration
   {throughEpochDay}`. On app open any active member reads it (cached),
   generates only `(through, today + horizon]` and advances it. The marker may
   only grow, by at most 120 days per write. Template and rotation edits call
   `RegenerateRange` on the manager's device. Default horizon: 30 days
   (setting, 14-90).

**Consequences.** Two devices racing write identical deterministic documents.
The marker is an optimisation, not a lock: a lost update only causes repeated,
idempotent work. Rules cannot verify rotation correctness (see ADR 0011).
