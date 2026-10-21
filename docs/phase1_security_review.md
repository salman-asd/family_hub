# Phase 1 security review (H13)

Evidence is `file:line` in `firebase/firestore.rules` as of the H13 commit, plus the rules test
that proves it (`firebase/rules_test/firestore.rules.test.mjs`, `describe` block name).
Line numbers drift: re-run the greps in the last section after any rules change.

**Method and limit.** This review was done by reading the rules and tests. The rules tests were
NOT executed by the author (no emulator). Every "Pass" below means "the rule and a test for it
exist", and becomes "verified" only when `tools/phase1_evidence.sh` reports the rules suite green.

| # | Checklist item | Result | Evidence |
| --- | --- | --- | --- |
| 1 | Every collection has `hasOnly` key sets and type checks | **Pass, one finding (F-31)** | families `:549,:561` (`familyKeys`), members `:380,:579,:610,:631,:649,:667` (`memberKeys`), invitations `:509,:519,:682,:688` (`invitationKeys`), settings `:206` (`settingsKeys`), activity/auditLogs `:251` (`eventKeys`). Tests: `H5 closed key sets`, `H5 member profile validation`. **F-31:** `users/{uid}` (`:441-487`) validates field types (`userDocOk`) but has no `hasOnly` key set, so a user can store extra junk fields on their own document. Impact is low (only the owner can read it and no rule reads other fields), fix is one `userKeys()` list mirrored by a Dart test. |
| 2 | No rule uses `get()` on a user-controlled id without an existence guard | **Pass** | `codeDoc` guards with `exists()` `:362-364`; `familyPointerChangeOk` guards with `!exists(memberPath(before, uid))` before `get(...)` `:473-480`; `adminIdsRewritten` `:347-349` runs only on member updates of an existing family (`!adminSetChanges() \|\| adminIdsRewritten(f)` at `:596,:614,:654`); `creatingFamily` uses `!exists` `:357`. Tests: `H4 one family per user`, `H6 active-admin set`. |
| 3 | Logs are append-only and actor-bound | **Pass** | `activity` `:724-729` and `auditLogs` `:731-737`: `allow update, delete: if false`; create requires `verified()` and `eventOk` (actor must be the caller, `:251`). Tests: `H5 log integrity`, `activity and auditLogs`. |
| 4 | Invites are single-use, revocable, and burned in the same batch | **Pass** | Single-use: used code cannot be reused (`:519`, `:690` allow only `status/usedBy/updatedAt/updatedBy`); burn in the same batch as joining via `joiningNow`/`existsAfter` `:412-422`. Revoke: `:534`. Tests: `inviteCodes/{code}` ("marks a live code used in the same batch", "denies joining with an already-used code", "denies marking an expired code used"), `H4 revoke invitation`. |
| 5 | One family per user | **Pass** | `familyPointerChangeOk` `:473-480` (used at `:484`). Tests: `H4 one family per user`, `H4 acceptance: leave and join another family`. |
| 6 | Verified email is required for mutating actions | **Pass** | `verified()` `:74-76` is used by 23 rules (family/invite/member/activity/audit creates, `inviteCodes` get `:498`). The owner may still write their own profile unverified (`:483-484`, deliberate: needed for sign-up flow). Tests: `H5 verified email`. |
| 7 | No hard deletes anywhere | **Pass** | `allow delete: if false` on users `:487`, inviteCodes `:538`, families `:563`, members `:672`, invitations `:706`, settings `:720`; Phase 2/3 collections are deny-all `:751-754`. Tests: `financial and chore data`, plus delete denials in each block. |
| 8 | Unauthenticated access is denied | **Pass** | Default deny `:757-759`; every `allow` requires `signedIn()`/`verified()`/membership. Tests: `unauthenticated access`, "denies an unauthenticated read/get". |
| 9 | Cross-family reads are denied | **Pass** | Reads need `isActiveMember(f)` (`:553,:711,:725`) or `isAdmin(f)` (`:732`). Tests: "[roadmap] denies a member of another family reading this family", "denies reading another family's financial data", "denies a manager of ANOTHER family revoking this family's code". |
| 10 | Roles cannot be self-promoted; last admin cannot be removed | **Pass** | `memberKeys` + role/status checks `:566-672`; `adminSetChanges`/`adminIdsRewritten` `:341-349`. Tests: `H6 active-admin set`, "member cannot make themselves admin". |
| 11 | Account deletion is a soft delete | **Pass** | `accountDeletionOk` `:458-464`, no hard delete `:487`. Tests: `H9 account soft-delete`. |

## Findings

| Id | Severity | Finding | Recommended fix |
| --- | --- | --- | --- |
| F-31 | Low | `users/{uid}` has no closed key set | Add `userKeys()` (`uid, fullName, nickname, gender, relationship, spouseId, avatarKey, familyId, preferences, createdAt, createdBy, updatedAt, updatedBy, schemaVersion, deletedAt, deletedBy`) with `hasOnly` in `userDocOk`, mirror it in `rules_key_sets_test.dart`, add an allow/deny rules test. Not done in H13 because H13 makes no feature changes and the fix cannot be verified without the emulator. |
| F-32 | Info | App Check is not enabled (Spark, no server) | Phase 6 decision (roadmap). Rules are the only server-side defense. |
| F-33 | Info | Client-side scoring and stats will be tamper-able (Spark) | Known and documented for Phase 3; rules must bound increments. |

## Re-checking line numbers

```bash
grep -n "hasOnly\|allow delete\|email_verified\|exists(/databases\|get(/databases\|getAfter" firebase/firestore.rules
```
