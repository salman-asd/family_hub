# 0016 - Some inbox items are derived, never written (decision D-P4-6)

**Status:** accepted (Phase 4, P4-01). Backs CLAUDE.md rule 69.

**Context.** The inbox exists since Phase 3 (`InboxType`, `InboxItem`,
`InboxRepository`, owner-only rules). Phase 4 wants it to also show a budget
alert, pending join requests, pending contribution requests, a contribution that
is due and a count of chores awaiting verification. Each of those is a *state of
the data*, not an event. Writing a row for it would need a writer on every
change, a cleanup when the cause disappears, and one more write path for another
member's inbox.

**Decision.**
- **Stored** inbox rows stay what they are: the seven Phase 3 types plus two
  added in P4-17 (`chore_assigned`, `member_approved`), written inside the
  batches that already exist (reassignment, approval), never as a second call.
- **Virtual** items come from the pure `VirtualInbox.build(...)`. They have
  stable ids (for example `v:budget:2026-11`), are never written, vanish when the
  cause is gone, and keep their read state locally (`SharedPreferences`, per
  month).
- The unread count is stored unread + virtual unacknowledged; the dashboard bell
  and the Manage hub badge read that one provider.

**Consequences.** No new collection, rule or index for these items, and nothing
to clean up. A virtual item cannot be pushed (no server event; ADR 0015), and its
read state is per device. A derived item that is wrong is a bug in a pure
function with table tests, not corrupt data.
