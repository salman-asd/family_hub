# 0009 - Chore slots and occurrence ids (decision D-P3-3)

**Status:** accepted (Phase 3, P3-01). Amends CLAUDE.md rule 4.

**Context.** The family's own list has chores done three times a day
(sweeping, filling the water filter). One occurrence id per template per day
(`{templateId}_{yyyyMMdd}`) cannot represent them without three look-alike
templates or lost occurrences.

**Decision.** A template has 1-6 *slots* `{key, labelBn?, labelEn?, dueMinutes?}`;
the first slot key is always `main`. The occurrence id is
`{templateId}_{yyyyMMdd}` for the `main` slot and
`{templateId}_{yyyyMMdd}_{slotKey}` for every other slot (slot keys are
lowercase `[a-z0-9]{1,12}`). Ids are deterministic and never random: nothing
creates an occurrence with `add()`.

**Consequences.** Two phones generating the same day write the same document,
so a repeat is harmless. A template with one slot behaves exactly as before.
The id pattern is checked in the Firestore rules (P3-13) and by the generator
tests. Soft delete only (`deletedAt`).
