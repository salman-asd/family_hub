# 0011 - Any active member may create occurrences (decision D-P3-7)

**Status:** accepted (Phase 3, P3-01). Accepted limit.

**Context.** A plain member must be able to complete today's chore even when
no manager has opened the app since the last generation. Firestore Security
Rules cannot recompute a rotation or read several documents per created
occurrence (access-call limits: 10 per request, 20 per batch).

**Decision.** `choreOccurrences` may be created by any active member. The
rules check shape, the id pattern, `status == 'scheduled'`,
`createdBy == request.auth.uid` and a single membership lookup; they do NOT
check the template, the rotation or the assignee.

**Consequences.** On the Spark plan, with no Cloud Functions, a malicious
active member could create a wrongly assigned occurrence for a date that has
no document yet. This is accepted for one trusted family: such an occurrence
is visible to everyone, attributed through `createdBy`, and a manager can fix
it with `ReassignOccurrence` or `ReplanOccurrences`. A server-trusted
generator is a Phase 6 option (Blaze plan).
