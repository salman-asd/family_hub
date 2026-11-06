# 0019 - One resolver decides the dashboard; access is a role matrix (decisions D-P4-16, D-P4-27 to D-P4-30)

**Status:** accepted (Phase 4, P4-01). Backs CLAUDE.md rules 68, 72 and 76.

**Context.** Roles should not all see the same dashboard (R3), and every user
should be able to reorder, hide and show components (R4). If the Home screen, the
Customize screen, the matrix screen and the tests each decided visibility, they
would drift, and a stale saved layout could expose a card the user may no longer
see (F-17).

**Decision.**
- **`DashboardResolver` is the only code that decides which cards a person sees
  and in what order.** A module contributes `DashboardCardSpec`s; a card never
  opens its own listener (the Home tab has a fixed listener budget, D-P4-14).
- Access is `settings/dashboard.roles{moderator, member}{cardId: access}` with
  `access` in `hidden | on | off | required`. A missing cell falls back to the
  catalog default (Appendix A.3). **The admin always has every card available**
  and cannot be locked out; the admin customises only their own view.
- The matrix is edited by `manageDashboardLayout`: the admin, or the Household
  Manager while `moderatorManagesFinance` is true (rules helper
  `financeManager(f)`). A role cell is disabled when the role lacks the
  permission the card needs. The change is audited (`family.dashboard_policy_updated`).
- A user's own layout is `users/{uid}.preferences.dashboard {order, hidden,
  shown}`. The resolver ignores ids the user may no longer see **but keeps them
  stored**, so a role or policy change loses nothing.
- **Hiding a card is presentation only, never access control** (F-18): a member
  who may read `contributions` can still open the Fund screen by URL. Access
  stays governed by `PermissionPolicy` and the Firestore rules; the matrix screen
  says so. The rules check the shape and size of `settings/dashboard`, not its
  meaning.
- Drag and drop always has a non-drag alternative: Move up / Move down semantic
  actions for TalkBack (CLAUDE.md rule 76).

**Consequences.** The resolver is pure Dart with at least 30 table-driven tests
(each access state x each role, stale ids, a new `required` card, a role change).
Adding a card is one catalog entry and one spec. A policy that names an unknown
card or value is ignored, not an error.
