# Membership state machine (H4)

A user belongs to **at most one family** at a time (CLAUDE.md rule 17). The state lives in
`users/{uid}.familyId` plus `families/{f}/members/{uid}`. It is enforced in the use cases
(`ensureFreeToJoinAnyFamily`) **and** in `firebase/firestore.rules`
(`familyPointerChangeOk`, the leave / cancel / revoke rules).

| From | Action | To | Use case | Who | Fields written |
| --- | --- | --- | --- | --- | --- |
| none | join with code | pending | `JoinWithCode` | the person | member doc (pending), `users.familyId`, code `used` |
| none | create family | active admin | `CreateFamily` | the person | family, member, settings, `users.familyId` |
| pending | approve | active | `ApproveMember` | admin / moderator | `status` |
| pending | reject | rejected (`removedAt`) | `RejectMember` | admin / moderator | `removedAt` |
| pending | cancel | cancelled (`removedAt`) | `CancelJoinRequest` | the person | `removedAt` |
| active | disable | disabled | `DisableMember` | admin | `status` |
| disabled | re-enable | active | `ApproveMember` | admin / moderator | `status` |
| active | leave | left (`leftAt` + `removedAt`, status `disabled`) | `LeaveFamily` | the person | `status`, `leftAt`, `removedAt` |

* **Free to create or join again:** none, rejected, cancelled, left. `Member.isRemoved`
  is true for all three removed states, so routing sends them to `/family-choice`.
* **Blocked** (`Conflict('already_in_family')`): pending, active, and *disabled by an admin*.
  A disabled member must be re-enabled by an admin before anything else.
* **Removed is final:** rules deny any admin/moderator write to a member with
  `removedAt` or `leftAt` (no revival); the person must join again with a fresh code.
* **Last admin:** `LeaveFamily` (and role change, disable) fail with `Conflict('last_admin')`
  while the actor is the only active admin; use `TransferAdmin` first.
* **Retries:** `CreateFamily`/`JoinWithCode` accept the ids generated once per screen, so a
  repeated request after a queued or lost reply answers with the existing result.
* **Invitations:** `active -> used` (joiner) or `active -> revoked` (manager,
  `RevokeInvitation`); both copies (`inviteCodes/{code}`, `families/{f}/invitations/{code}`)
  change in one batch. Used, revoked and expired codes cannot be revoked.
* **Server only (rule 16):** every transition above needs the server and fails fast with
  `Network` when offline.

The table is walked by `test/features/family/domain/membership_lifecycle_test.dart`; the rules
side by the "H4" groups in `firebase/rules_test/firestore.rules.test.mjs`.
