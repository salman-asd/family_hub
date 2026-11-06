# 0020 - Push is sent by a Cloud Function on the Blaze plan, and only if the owner opts in (decision D-P4-21) [OWNER]

**Status:** accepted as the default design; **deployment awaits the owner's
go/no-go** (P4-15 checklist). Until then every notification type is Normal
(ADR 0015) and nothing else in Phase 4 changes. Backs CLAUDE.md rules 74 and 75.

**Context (F-6, F-21).** Receiving FCM is free, but *sending* needs a trusted
server that holds a service account and calls the HTTP v1 API. The legacy
server-key API is shut down, so a phone cannot safely push to another phone. The
only first-party server on Firebase is Cloud Functions, which needs the **Blaze**
plan (a billing account with a payment method). Blaze has no automatic spending
cap, whereas Spark simply stops at its quota. The family currently runs on Spark
for everything.

**Alternatives considered.**
1. **No push.** Spark only; a swap request or a reassigned chore is learned when
   the app opens, as in Phase 3. Free and simple, but it is the weakest part of
   the product for time-sensitive changes. This stays the fallback for every
   family and every type.
2. **A third-party push relay** (a hosted service that stores the service account
   and exposes a send API). Needs no Blaze, but moves a credential that can
   message every device to a company outside the project, adds an account, a
   privacy review and another point of failure, and the client would still have to
   trigger it, which a member could abuse.
3. **A self-hosted sender** (a small always-on server or home machine). Avoids
   billing, but someone must run, patch and secure it, it must hold the service
   account, and a family app should not depend on a server that sleeps.
4. **Cloud Functions on Blaze (chosen).** The service account never leaves
   Google; the trigger is a Firestore write that already happens (`notificationInbox`
   create, and a pending `members` create), so the app's write path does not
   change (D-P4-22); one policy document gates every send; cost for one family is
   expected to stay inside the free tier **[VERIFY]**.

**Decision.**
- Build the client and the `functions/` code in Phase 4; **deploy only after the
  owner upgrades to Blaze and creates a low billing budget with email alerts**
  (suggested 50 / 90 / 100 %). Upgrade `familyhub-prod`, and `familyhub-dev` only
  to test live.
- The function reads `settings/notificationDelivery` on every send, sends nothing
  when the master switch is off or the type is Normal, checks that the recipient
  is an active member, honours the member's opt-out and quiet hours, caps pushes
  per recipient per hour (`pushLedger`, 30), prunes stale tokens, and writes at
  most one status field per push. `maxInstances` stays small as a second brake.
- **The client never sends push and never holds a service account** (CLAUDE.md
  rule 74). A push carries **no names, amounts or ids** of people, only a generic
  text and a `route` in `data` (rule 75); the function uses a small bn/en table
  and the `lang` stored on the device document.
- To turn it off: set `pushEnabled = false`, or `firebase functions:delete`. The
  app falls back to Normal with no update.

**Consequences.** Blaze needs a payment method and has no hard cap, so the
budget alert is a precondition, not an option. If the owner says no, skip
P4-15 and the optional P4-26 and the product is complete on Spark. The Dart
catalog and the TypeScript table list the same ids (contract test), so the two
sides cannot drift.
