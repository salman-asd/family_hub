// Firestore rules for memberAvailability, swapRequests and notificationInbox
// (P3-26). The swap ACCEPT that moves the chore is tested together with the
// occurrence in chore_occurrences.test.mjs.
//
// Run: npm run test:emulator (from firebase/rules_test).

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { Timestamp, deleteDoc, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { after, afterEach, before, beforeEach, describe, it } from 'mocha';

import {
  ALICE,
  BOB,
  CARA,
  DAVE,
  EMULATOR,
  ERIN,
  FAM_A,
  PROJECT_ID,
  asUser,
  availabilityDoc,
  inboxDoc,
  memberDoc,
  nowTs,
  occurrenceDoc,
  seedWorld,
  swapDoc,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');
let testEnv;
const GINA = 'gina'; // active plain member (the recipient)
const as = (uid) => asUser(testEnv, uid);
const av = (id = 'a1') => `families/${FAM_A}/memberAvailability/${id}`;
const sw = (id = 's1') => `families/${FAM_A}/swapRequests/${id}`;
const ib = (id = 'i1') => `families/${FAM_A}/notificationInbox/${id}`;
const seed = (path, data) =>
  testEnv.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), path), data));
const stamp = (uid) => ({ updatedAt: nowTs(), updatedBy: uid });
const past = () => Timestamp.fromMillis(Date.now() - 3600 * 1000);

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { host, port: Number(port) },
  });
});
after(async () => {
  await testEnv.cleanup();
});
afterEach(async () => {
  await testEnv.clearFirestore();
});
beforeEach(async () => {
  await seedWorld(testEnv);
  await seed(`families/${FAM_A}/members/${GINA}`, memberDoc(GINA, 'member', 'active'));
  await seed(
    `families/${FAM_A}/choreOccurrences/tpl_1_20261024`,
    occurrenceDoc(ALICE, { assigneeId: CARA }),
  );
});

describe('memberAvailability', () => {
  it('lets a member record their own absence', async () => {
    await assertSucceeds(setDoc(doc(as(CARA), av()), availabilityDoc(CARA)));
    await assertSucceeds(
      setDoc(doc(as(CARA), av('a2')), availabilityDoc(CARA, { status: 'pending' })),
    );
  });
  it('denies a member recording somebody else’s absence', async () => {
    await assertFails(
      setDoc(doc(as(CARA), av()), availabilityDoc(CARA, { memberId: GINA })),
    );
  });
  it('lets a manager record anybody’s absence', async () => {
    await assertSucceeds(
      setDoc(doc(as(BOB), av()), availabilityDoc(BOB, { memberId: GINA })),
    );
  });
  it('denies a forged createdBy, a decided create and a bad shape', async () => {
    await assertFails(setDoc(doc(as(CARA), av()), availabilityDoc(GINA, { memberId: CARA })));
    await assertFails(setDoc(doc(as(CARA), av()), availabilityDoc(CARA, { status: 'rejected' })));
    await assertFails(setDoc(doc(as(CARA), av()), availabilityDoc(CARA, { decidedBy: CARA })));
    await assertFails(
      setDoc(doc(as(CARA), av()), availabilityDoc(CARA, { endDateKey: '2026-10-20' })),
    );
    await assertFails(setDoc(doc(as(CARA), av()), availabilityDoc(CARA, { reason: 'x' })));
    await assertFails(setDoc(doc(as(CARA), av()), availabilityDoc(CARA, { extra: 1 })));
  });
  it('denies a pending member and another family', async () => {
    await assertFails(setDoc(doc(as(DAVE), av()), availabilityDoc(DAVE)));
    await assertFails(setDoc(doc(as(ERIN), av()), availabilityDoc(ERIN)));
  });
  it('lets the owner or a manager cancel, nobody else', async () => {
    await seed(av(), availabilityDoc(CARA));
    const cancel = { status: 'cancelled', decidedBy: null, decidedAt: null };
    await assertFails(updateDoc(doc(as(GINA), av()), { ...cancel, ...stamp(GINA) }));
    await assertSucceeds(updateDoc(doc(as(CARA), av()), { ...cancel, ...stamp(CARA) }));
    await seed(av('a2'), availabilityDoc(CARA));
    await assertSucceeds(updateDoc(doc(as(BOB), av('a2')), { ...cancel, ...stamp(BOB) }));
  });
  it('lets only a manager decide a pending absence', async () => {
    await seed(av(), availabilityDoc(CARA, { status: 'pending' }));
    const decide = { status: 'active', decidedBy: BOB, decidedAt: nowTs() };
    await assertFails(updateDoc(doc(as(CARA), av()), { ...decide, decidedBy: CARA, ...stamp(CARA) }));
    await assertSucceeds(updateDoc(doc(as(BOB), av()), { ...decide, ...stamp(BOB) }));
  });
  it('denies deciding an absence that is not pending, and deleting', async () => {
    await seed(av(), availabilityDoc(CARA));
    await assertFails(
      updateDoc(doc(as(BOB), av()), {
        status: 'rejected',
        decidedBy: BOB,
        decidedAt: nowTs(),
        ...stamp(BOB),
      }),
    );
    await assertFails(deleteDoc(doc(as(ALICE), av())));
  });
  it('lets an active member read and denies a pending member', async () => {
    await seed(av(), availabilityDoc(CARA));
    await assertSucceeds(getDoc(doc(as(GINA), av())));
    await assertFails(getDoc(doc(as(DAVE), av())));
  });
});

describe('swapRequests', () => {
  it('lets the assignee ask somebody', async () => {
    await assertSucceeds(setDoc(doc(as(CARA), sw()), swapDoc(CARA)));
  });
  it('lets a manager create a cover for an absent member', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(BOB), sw()),
        swapDoc(BOB, { kind: 'cover', fromMemberId: CARA, requestedBy: BOB }),
      ),
    );
  });
  it('denies asking in somebody else’s name', async () => {
    await assertFails(setDoc(doc(as(GINA), sw()), swapDoc(GINA, { fromMemberId: CARA })));
    await assertFails(setDoc(doc(as(CARA), sw()), swapDoc(CARA, { requestedBy: GINA })));
  });
  it('denies a request that is not pending, lapsed, or to oneself', async () => {
    await assertFails(setDoc(doc(as(CARA), sw()), swapDoc(CARA, { status: 'accepted' })));
    await assertFails(setDoc(doc(as(CARA), sw()), swapDoc(CARA, { expiresAt: past() })));
    await assertFails(setDoc(doc(as(CARA), sw()), swapDoc(CARA, { toMemberId: CARA })));
    await assertFails(setDoc(doc(as(CARA), sw()), swapDoc(CARA, { reason: 'x' })));
    await assertFails(setDoc(doc(as(CARA), sw()), swapDoc(CARA, { extra: 1 })));
  });
  it('denies a pending member and another family', async () => {
    await assertFails(setDoc(doc(as(DAVE), sw()), swapDoc(DAVE)));
    await assertFails(setDoc(doc(as(ERIN), sw()), swapDoc(ERIN)));
  });

  const answer = (uid, status, extra = {}) => ({
    status,
    respondedAt: nowTs(),
    respondedBy: uid,
    responseReason: null,
    ...stamp(uid),
    ...extra,
  });

  it('lets only the recipient decline', async () => {
    await seed(sw(), swapDoc(CARA));
    await assertFails(updateDoc(doc(as(BOB), sw()), answer(BOB, 'declined')));
    await assertSucceeds(updateDoc(doc(as(GINA), sw()), answer(GINA, 'declined')));
  });
  it('denies accepting without the paired occurrence update', async () => {
    await seed(sw(), swapDoc(CARA));
    await assertFails(updateDoc(doc(as(GINA), sw()), answer(GINA, 'accepted')));
  });
  it('lets the requester or a manager cancel, nobody else', async () => {
    await seed(sw(), swapDoc(CARA));
    await assertFails(updateDoc(doc(as(GINA), sw()), answer(GINA, 'cancelled')));
    await assertSucceeds(updateDoc(doc(as(CARA), sw()), answer(CARA, 'cancelled')));
    await seed(sw('s2'), swapDoc(CARA));
    await assertSucceeds(updateDoc(doc(as(BOB), sw('s2')), answer(BOB, 'cancelled')));
  });
  it('lets anybody expire a lapsed request, and nobody an open one', async () => {
    await seed(sw(), swapDoc(CARA, { expiresAt: past() }));
    await assertSucceeds(updateDoc(doc(as(GINA), sw()), answer(GINA, 'expired')));
    await seed(sw('s2'), swapDoc(CARA));
    await assertFails(updateDoc(doc(as(GINA), sw('s2')), answer(GINA, 'expired')));
  });
  it('denies changing a closed request, other fields, and deleting', async () => {
    await seed(sw(), swapDoc(CARA, { status: 'declined' }));
    await assertFails(updateDoc(doc(as(GINA), sw()), answer(GINA, 'declined')));
    await seed(sw('s2'), swapDoc(CARA));
    await assertFails(
      updateDoc(doc(as(GINA), sw('s2')), answer(GINA, 'declined', { reason: 'changed' })),
    );
    await assertFails(deleteDoc(doc(as(ALICE), sw())));
  });
  it('lets an active member read and denies a pending one', async () => {
    await seed(sw(), swapDoc(CARA));
    await assertSucceeds(getDoc(doc(as(GINA), sw())));
    await assertFails(getDoc(doc(as(DAVE), sw())));
  });
});

describe('notificationInbox', () => {
  it('lets an active member write a row for another member', async () => {
    await assertSucceeds(setDoc(doc(as(CARA), ib()), inboxDoc(CARA)));
  });
  it('denies a pre-read row, an unknown type, too many params, extra fields', async () => {
    await assertFails(setDoc(doc(as(CARA), ib()), inboxDoc(CARA, { readAt: nowTs() })));
    await assertFails(setDoc(doc(as(CARA), ib()), inboxDoc(CARA, { type: 'spam' })));
    const params = Object.fromEntries([1, 2, 3, 4, 5, 6, 7].map((n) => [`k${n}`, 'v']));
    await assertFails(setDoc(doc(as(CARA), ib()), inboxDoc(CARA, { params })));
    await assertFails(setDoc(doc(as(CARA), ib()), inboxDoc(CARA, { extra: 1 })));
  });
  it('denies a pending member, another family and a forged createdBy', async () => {
    await assertFails(setDoc(doc(as(DAVE), ib()), inboxDoc(DAVE)));
    await assertFails(setDoc(doc(as(ERIN), ib()), inboxDoc(ERIN)));
    await assertFails(setDoc(doc(as(CARA), ib()), inboxDoc(GINA)));
  });
  it('lets only the owner read a row', async () => {
    await seed(ib(), inboxDoc(CARA));
    await assertSucceeds(getDoc(doc(as(GINA), ib())));
    await assertFails(getDoc(doc(as(CARA), ib())));
  });
  it('lets the owner mark read and archive, nothing else', async () => {
    await seed(ib(), inboxDoc(CARA));
    await assertSucceeds(updateDoc(doc(as(GINA), ib()), { readAt: nowTs(), ...stamp(GINA) }));
    await assertSucceeds(updateDoc(doc(as(GINA), ib()), { archivedAt: nowTs(), ...stamp(GINA) }));
    await assertFails(updateDoc(doc(as(GINA), ib()), { type: 'swap_result', ...stamp(GINA) }));
    await assertFails(updateDoc(doc(as(CARA), ib()), { readAt: nowTs(), ...stamp(CARA) }));
  });
  it('never deletes a row', async () => {
    await seed(ib(), inboxDoc(CARA));
    await assertFails(deleteDoc(doc(as(GINA), ib())));
  });
});
