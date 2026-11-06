# 0017 - Stats are private, owner-only and computed on the client (decisions D-P4-8 to D-P4-11, D-P4-26)

**Status:** accepted (Phase 4, P4-01). Backs CLAUDE.md rules 64, 65 and 77.

**Context.** Points, streaks and levels are meant to encourage, never to rank.
The owner asked that stats stay private, with privacy kept as a **setting**
(default: private). Spark has no server, so the numbers are computed by each
phone and written by their owner (F-8, F-9). Firestore rules cannot recompute a
score, and a technical member could write a larger number.

**Decision.**
- `memberStats/{uid}` is readable and writable **only by its owner, always**,
  admins included. Nothing else ever reads it (F-10).
- Sharing goes only through a separate, **points-free** document
  `memberStatsPublic/{uid}` (`level`, `badgeIds`). It exists only while the admin
  sets `settings/engagement.statsVisibility` to `levels` **and** the member opts
  in (`sharing`, default off). Points, streaks and per-month numbers are never
  shared and there is no ranking (alphabetical lists only). Setting the policy
  back to `private` makes the public documents unreadable at once and the owner's
  app deletes its own.
- "This month's helpers" counts **covers given** from occurrences and never reads
  stats (D-P4-10).
- Writes are idempotent and monotonic: the current month is recomputed from the
  live listener, earlier months are read once and frozen (`final`), counting
  starts at `settings/engagement.startedOn`, and the stored value is
  `max(stored, computed)` so running the sync twice never double counts (D-P4-8).
- Scoring numbers are data in `settings/engagement` (D-P4-11); a frozen month
  keeps its `specVersion`.
- **No activity or audit entry is written for stats writes.** A stats write is
  personal bookkeeping, and an audit trail of it would itself leak the score.

**Consequences.** A member who edits their own documents can give themselves
points. That is a documented limit, bounded by the rules (monotonic, capped
steps) and harmless because nobody else can see the number. Stats are never
exported or shown to another member except the points-free card (CLAUDE.md
rule 77). Settings changes (`engagement.settings_updated`, the privacy change)
**are** audited; stats data is not.
