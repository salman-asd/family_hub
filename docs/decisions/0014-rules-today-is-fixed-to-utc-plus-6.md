# 0014 - The occurrence rules fix "today" to UTC+6 (review item M-07)

**Status:** accepted (Phase 3, Wave R3).

**Context.** The soft-delete rule for `choreOccurrences` may only remove a FUTURE
day (`dateKey > today`). Firestore rules have no timezone database and cannot
read `settings/general.timezone` cheaply on every write (an extra `get` per
document of a 400-document generation batch breaks the access-call budget,
C-11). The family timezone defaults to `Asia/Dhaka` and the family lives there.

**Decision.** `todayKey(f)` in `firebase/firestore.rules` is
`request.time + duration.value(6, 'h')` formatted as `yyyy-MM-dd`. Asia/Dhaka is
UTC+6 all year (Bangladesh has not used DST since 2009), so the value is exact
for the default family. It is documented in CLAUDE.md rule 46.

**Consequences.** A family that changes `settings/general.timezone` to another
zone sees the guard shift by that zone's offset difference: at most a few hours
around midnight in which a manager can soft-delete "tomorrow" a little early or
is refused a little late. The guard only protects history from accidents; it is
not a security boundary (a manager could change the template instead). If the
timezone setting is ever honoured, the rules, this ADR and the rules tests
change together, for example by storing the family's offset in minutes on
`settings/general` and reading it once per batch.
