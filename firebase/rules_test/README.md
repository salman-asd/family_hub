# Firestore Security Rules tests

Rules tests for `firebase/firestore.rules` (roadmap Step 10, item 4). They run
against the Firestore emulator with `@firebase/rules-unit-testing`; no real
Firebase project or credentials are involved (`demo-family-hub` is a demo id).

## Running

From the **repository root**:

```bash
npm install --prefix firebase/rules_test
npx firebase emulators:exec --only firestore --project demo-family-hub \
  "npm --prefix firebase/rules_test test"
```

Or, once `npm install` has run once, from this folder:

```bash
npm run test:emulator      # starts the emulator, runs the tests, shuts it down
```

A JDK **21 or newer** must be reachable through `JAVA_HOME` or `PATH`; the
emulator is a JVM program and firebase-tools 15 refuses older runtimes.

## What is covered

`firestore.rules.test.mjs` has an allowed and a denied case for every rule:
`users/{uid}`, `inviteCodes/{code}`, `families/{f}`, `members/{m}`,
`invitations/{i}`, `settings/{s}`, `activity`, `auditLogs`, the deny-only guard
on the not-yet-open chore collections, unauthenticated access, and the Phase 1
acceptance scenario end to end.

Phase 2 adds one file per collection group: `catalog.test.mjs` (categories and
items), `bazar_settings.test.mjs` (`settings/bazar`), `expenses.test.mjs`
(expenses, their revisions and trips), `fund.test.mjs` (the signed ledger) and
`advances.test.mjs` (advances, settlements and month closings).

The four cases the roadmap names explicitly are marked `[roadmap]`:

- a member cannot make themselves admin;
- a user cannot read another family's data;
- a pending member cannot read family data;
- `createdBy` cannot be forged.

## When you change `firestore.rules`

CLAUDE.md requires every step that adds a collection to extend the rules **and**
these tests in the same commit. Add the collection's fixtures to `support.mjs`
(`seedWorld`) and one allowed plus one denied case to the test file.
