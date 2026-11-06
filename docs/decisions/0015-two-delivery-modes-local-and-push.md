# 0015 - Two delivery modes per notification type: Normal and Push (decisions D-P4-1, D-P4-23, D-P4-24, D-P4-25)

**Status:** accepted (Phase 4, P4-01). Backs CLAUDE.md rules 61, 62 and 73.

**Context.** Phase 3 had only local notifications in mind, because the Spark plan
cannot send push (ADR 0020). The owner asked for FCM push that is
**configurable**: the admin chooses, per notification type, whether it is Push
or Normal. If both channels could carry the same type, one event would notify
twice (F-16).

**Decision.**
- **Normal** = the in-app inbox plus an on-device local notification: scheduled
  by the pure `ReminderPlanner` for time-based types, shown immediately by the
  foreground bridge for event types while the app process is alive.
- **Push** = Firebase Cloud Messaging, sent by the Cloud Function (ADR 0020), so
  it arrives with the app closed.
- Each type has **exactly one effective mode**. `DeliveryPolicy.effective(type,
  policy, capability)` is the only place that decides it and returns `push` or
  `normal` plus a reason. The local planner skips a type whose effective mode is
  Push; the foreground bridge de-duplicates by `inboxId`.
- The admin stores the choice in `settings/notificationDelivery {pushEnabled,
  modes}`. The master `pushEnabled` defaults to **off**; the recommended per-type
  defaults (Appendix B.7 of the Phase 4 roadmap) apply the moment it is turned on.
- Types that have no server event are `pushCapable = false` (due reminders,
  overdue, nudge, morning summary, contribution due, month end, budget alert,
  achievements). They are computed on the phone, so the admin screen shows them
  locked to Normal with the reason.
- Without the backend, without Blaze, or with the master switch off, every type
  is Normal. Nothing else in Phase 4 depends on push.

**Consequences.** One tested function owns the decision, so the planner, the
bridge, the admin screen and the Cloud Function cannot disagree; the function
carries the same id table (a contract test reads it, P4-15). A later scheduled
sweeper (P4-26) could make more types push-capable without changing this model.
Push can be switched off at any time (`pushEnabled = false`) and the app
degrades to Normal.
