# 0012 - Stored status is a cache; the UI uses the effective status (decision D-P3-9)

**Status:** accepted (Phase 3, P3-01). Backs CLAUDE.md rule 36.

**Context.** Two phones can tick different subtasks of one occurrence while
offline. Each computes a status from what it sees, so the stored `status` can
end up that no single device computed (for example "in progress" with every
required box ticked).

**Decision.**
- Stored `status`: `scheduled | in_progress | completed | verified | skipped`.
  It is a cache.
- *Overdue* is derived (`isOverdue(occurrence, now, grace)`) and never stored.
- `effectiveStatus` is a pure function of `subtaskDone`, `completedAt`,
  `verifiedAt` and `skipReason`. Every read goes through it; screens use
  `ChoreItem.status`, never `occurrence.status`.
- `subtaskDone` is a map `subtaskId -> {at, by}` updated with dotted paths, so
  concurrent ticks never overwrite each other.
- When the detail screen opens and the cache disagrees, it repairs it with an
  idempotent write.

**Consequences.** Today, the calendar, the dashboard and reports cannot
disagree. A stale stored status is harmless; it is only ever corrected.
