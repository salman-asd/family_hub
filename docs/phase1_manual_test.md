# Phase 1 manual test matrix (H13)

Run with TWO real devices and TWO accounts (A = first admin, B = joiner), against the real **dev**
Firebase project (`flutter run --flavor dev -t lib/main_dev.dart`, no emulator define).
Repeat the whole table for each combination you need: Bangla/English, light/dark. Tick a box only
when the expected result happened; write the failure in Notes.

Combos to cover at least once each: `bn+light`, `bn+dark`, `en+light`, `en+dark`.

| # | Step | Expected | bn+light | bn+dark | en+light | en+dark | Notes |
| ---: | --- | --- | :-: | :-: | :-: | :-: | --- |
| 1 | A signs up | Verify-email screen | [ ] | [ ] | [ ] | [ ] | |
| 2 | A opens the email link, taps "I have verified" | Goes to profile setup | [ ] | [ ] | [ ] | [ ] | |
| 3 | A saves profile (name, relationship, optional spouse) | Goes to family choice | [ ] | [ ] | [ ] | [ ] | |
| 4 | A creates a family | Home; A is admin | [ ] | [ ] | [ ] | [ ] | |
| 5 | A creates an invitation | 8-character code shown | [ ] | [ ] | [ ] | [ ] | |
| 6 | B signs up, verifies, saves profile, joins with the code | B sees "pending" | [ ] | [ ] | [ ] | [ ] | |
| 7 | A approves B | B moves to Home on its own, no restart | [ ] | [ ] | [ ] | [ ] | |
| 8 | A changes B's role to moderator, then back to member | Role shown correctly on both devices | [ ] | [ ] | [ ] | [ ] | |
| 9 | A disables B, then re-enables B | B sees "disabled", then Home again | [ ] | [ ] | [ ] | [ ] | |
| 10 | A transfers admin to B | B is admin, A is not | [ ] | [ ] | [ ] | [ ] | |
| 11 | A (now member) leaves the family | A goes to family choice | [ ] | [ ] | [ ] | [ ] | |
| 12 | A requests to join again, then cancels the request | Back to family choice; no pending request remains | [ ] | [ ] | [ ] | [ ] | |
| 13 | B creates an invitation and revokes it; A tries the revoked code | A gets a localized "code invalid" error | [ ] | [ ] | [ ] | [ ] | |
| 14 | A tries to join a second family while a member of one | Refused with a localized message | [ ] | [ ] | [ ] | [ ] | |
| 15 | Edit relationships (admin): add, rename, disable a custom entry | List updates; profile picker follows | [ ] | [ ] | [ ] | [ ] | |
| 16 | Change password (wrong current, then correct) | Wrong: localized error; correct: success; old password no longer works | [ ] | [ ] | [ ] | [ ] | |
| 17 | Delete account as a plain member | Signed out; cannot sign in again; family keeps the name on history | [ ] | [ ] | [ ] | [ ] | |
| 18 | Delete account as the only admin with other members | Refused with "transfer admin first" | [ ] | [ ] | [ ] | [ ] | |
| 19 | Airplane mode: create a family | Saved locally, "waiting to sync" shown | [ ] | [ ] | [ ] | [ ] | |
| 20 | Turn the network on | Banner clears; family exists on the server (check the console) | [ ] | [ ] | [ ] | [ ] | |
| 21 | Airplane mode: cold start the app (kill, reopen) | App opens from cache, no crash, no wrong redirect | [ ] | [ ] | [ ] | [ ] | |
| 22 | Change theme and language, kill and reopen | Choices kept | [ ] | [ ] | [ ] | [ ] | |
| 23 | Sign out, sign in as the other account on the same phone | Other account's theme/language apply; no data of the first account visible | [ ] | [ ] | [ ] | [ ] | |
| 24 | Font scale 200% on Members, Invitations, Security screens | No overflow, buttons reachable | [ ] | [ ] | [ ] | [ ] | |
| 25 | TalkBack on Login, Members, Security | Every button announces a label | [ ] | [ ] | [ ] | [ ] | |

## Sign-off

- Tester: ______________  Date: ____________  Build/commit: ____________
- All rows ticked in every combination: [ ]
- Failures filed in `PROGRESS.md` > "Known limitations": [ ]
