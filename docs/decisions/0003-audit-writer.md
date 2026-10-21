# 0003 - One audit writer, language-neutral events

**Status:** accepted (H8, H10)

Every activity/audit entry is an `AuditEvent` written ONLY by `AuditWriter` in the
same batch as the change.  Events carry a machine `type` plus small `params`, never
display text; screens localize with `AppLocalizations.activityText`.  The `summary`
field stays in the document (empty) only because the closed key set in the rules
still lists it.
