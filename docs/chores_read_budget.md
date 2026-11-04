# Chores - read budget (P3-30)

**Status: NOT MEASURED.** Written without an SDK or an emulator. The table below is the count the code *should* produce, derived from the listeners in the source. Step 3 of the P3-30 script (below) replaces every "expected" with a measured number; until then do not quote these as results.

## Listeners that cost reads

| Listener | Documents read when it opens | Kept alive |
| --- | --- | --- |
| `settings/chores`, `settings/choreGeneration`, `settings/rotationPolicy` | 3 | session |
| `choreTemplates` (<= 200) | number of templates (about 16 for the family's pack) | session |
| `dutyGroups` (<= 50) | a few | session |
| `memberAvailability` (<= 200) | active records, usually 0-3 | session |
| `monthOccurrences(month)` (<= 900) | chores in that month (about 450 for 15 daily chores) | current month; others 60 s after leaving |
| `verifyQueue` (<= 50) | completed chores that need a check | while the Verify tile or card is watched |
| `swapRequests`, `notificationInbox` (<= 50 each) | open requests / inbox rows | while watched |
| `EnsureOccurrences` | one range query for ids in `(through, today+horizon]`, once per app start | - |

After the first snapshot a listener is billed only for the documents that change, so the numbers above are the cost of opening the app, not of staying in it.

## Rules the code is meant to keep (acceptance 6)

* Mine / Family, every filter and every view switch are in memory: **0 extra reads** (rule 37).
* The Home dashboard cards, Today, the rota board and the needs-cover board reuse the month listener: **0 extra listeners**.
* Swiping to another month opens one month listener (about the month's chore count in reads), and a month revisited within 60 s costs nothing.

## Spark quota

**[VERIFY]** the current Spark daily free quota in the Firebase pricing page (at the time of writing: 50,000 document reads, 20,000 writes, 20,000 deletes per day). Target: a normal family day well under 10 % of the read quota.

## How to measure (P3-30 step 3)

1. Start the emulator, open the Emulator UI, note the read counter.
2. Perform one action at a time with a fresh app start: cold open; Mine / Family toggle (expect +0); swipe 6 months (expect about 6 x chores-per-month); open Today; open one detail.
3. Record the numbers here, next to "expected", with the date and the data size (templates, chores per month).
