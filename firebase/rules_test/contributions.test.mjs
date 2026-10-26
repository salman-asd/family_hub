// Firestore rules for contributions and contributionPlans (P2-19, D-P2-5/18).
//
// Every active member READS every contribution and plan.  A member can only
// REQUEST (pending, no ledger row) for themselves; the Household Manager
// (moderator, while moderatorManagesFinance is on) or the admin records,
// approves, rejects, changes and voids.  A closed month rejects every write.

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';
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
  baseDoc,
  nowTs,
  permissionsDoc,
  seedWorld,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');
let testEnv;
const as = (uid, options) => asUser(testEnv, uid, options);

const cPath = (id) => `families/${FAM_A}/contributions/${id}`;
const tPath = (id) => `families/${FAM_A}/fundTransactions/${id}`;
const pPath = (id) => `families/${FAM_A}/contributionPlans/${id}`;

/** ContributionMappers.toMap for a member's pending request. */
const pending = (uid, extra = {}) =>
  baseDoc(uid, {
    memberId: uid,
    monthKey: '2026-10',
    dateKey: '2026-10-05',
    amountPaisa: 100000,
    status: 'pending',
    requestedBy: uid,
    deletedAt: null,
    deletedBy: null,
    ...extra,
  });

/** An approved contribution (recorded by `by`) for `member`. */
const approved = (id, member, by, extra = {}) =>
  baseDoc(by, {
    memberId: member,
    monthKey: '2026-10',
    dateKey: '2026-10-05',
    amountPaisa: 100000,
    status: 'approved',
    requestedBy: by,
    fundTxId: `con_${id}`,
    decidedBy: by,
    decidedAt: nowTs(),
    deletedAt: null,
    deletedBy: null,
    ...extra,
  });

/** FundMappers.fundTxToMap for `con_<id>`. */
const conTx = (id, by, amountPaisa = 100000, extra = {}) =>
  baseDoc(by, {
    type: 'contribution',
    amountPaisa,
    dateKey: '2026-10-05',
    monthKey: '2026-10',
    refType: 'contribution',
    refId: id,
    note: null,
    deletedAt: null,
    deletedBy: null,
    ...extra,
  });

const seed = (path, data) =>
  testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });

const closeMonth = () =>
  seed(`families/${FAM_A}/monthClosings/2026-10`, {
    monthKey: '2026-10',
    status: 'closed',
    ...baseDoc(ALICE),
  });

/** Writes the contribution and its ledger row in ONE batch. */
const recordBatch = (db, id, contribution, tx) => {
  const batch = writeBatch(db);
  batch.set(doc(db, cPath(id)), contribution);
  if (tx) batch.set(doc(db, tPath(`con_${id}`)), tx);
  return batch.commit();
};

const approveBatch = (db, id, by, tx) => {
  const batch = writeBatch(db);
  batch.update(doc(db, cPath(id)), {
    status: 'approved',
    fundTxId: `con_${id}`,
    decidedBy: by,
    decidedAt: nowTs(),
    updatedAt: nowTs(),
    updatedBy: by,
  });
  if (tx) batch.set(doc(db, tPath(`con_${id}`)), tx);
  return batch.commit();
};

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
});

describe('contributions read (D-P2-5)', () => {
  it('lets every active member read every contribution and plan', async () => {
    await seed(cPath('c1'), pending(CARA));
    await seed(pPath(`2026-10_${CARA}`), baseDoc(ALICE, {
      monthKey: '2026-10', memberId: CARA, expectedPaisa: 100000,
    }));
    for (const uid of [ALICE, BOB, CARA]) {
      await assertSucceeds(getDoc(doc(as(uid), cPath('c1'))));
      await assertSucceeds(getDoc(doc(as(uid), pPath(`2026-10_${CARA}`))));
    }
  });

  it('denies a pending member and another family', async () => {
    await seed(cPath('c1'), pending(CARA));
    await assertFails(getDoc(doc(as(DAVE), cPath('c1'))));
    await assertFails(getDoc(doc(as(ERIN), cPath('c1'))));
  });
});

describe('contributions create', () => {
  it('lets a member request for themselves (pending, no ledger row)', async () => {
    await assertSucceeds(setDoc(doc(as(CARA), cPath('c1')), pending(CARA)));
  });

  it('denies a member requesting for another member', async () => {
    await assertFails(
      setDoc(doc(as(CARA), cPath('c1')), pending(CARA, { memberId: BOB })),
    );
  });

  it('denies a member creating an approved row or one with fundTxId', async () => {
    await assertFails(
      setDoc(doc(as(CARA), cPath('c1')), approved('c1', CARA, CARA)),
    );
    await assertFails(
      setDoc(
        doc(as(CARA), cPath('c2')),
        pending(CARA, { fundTxId: 'con_c2' }),
      ),
    );
  });

  it('denies a forged createdBy and a zero or negative amount', async () => {
    await assertFails(
      setDoc(doc(as(CARA), cPath('c1')), pending(CARA, { createdBy: BOB })),
    );
    await assertFails(
      setDoc(doc(as(CARA), cPath('c2')), pending(CARA, { amountPaisa: 0 })),
    );
  });

  it('denies an unknown field and a month that does not match the date', async () => {
    await assertFails(
      setDoc(doc(as(CARA), cPath('c1')), pending(CARA, { extra: 1 })),
    );
    await assertFails(
      setDoc(doc(as(CARA), cPath('c2')), pending(CARA, { monthKey: '2026-09' })),
    );
  });

  it('lets the admin and a moderator record with the ledger row', async () => {
    await assertSucceeds(
      recordBatch(as(ALICE), 'c1', approved('c1', CARA, ALICE), conTx('c1', ALICE)),
    );
    await assertSucceeds(
      recordBatch(as(BOB), 'c2', approved('c2', CARA, BOB), conTx('c2', BOB)),
    );
  });

  it('denies a record without its ledger row or with a different amount', async () => {
    await assertFails(
      recordBatch(as(ALICE), 'c1', approved('c1', CARA, ALICE), null),
    );
    await assertFails(
      recordBatch(
        as(ALICE),
        'c2',
        approved('c2', CARA, ALICE),
        conTx('c2', ALICE, 5),
      ),
    );
  });

  it('denies a record for a pending member', async () => {
    await assertFails(
      recordBatch(as(ALICE), 'c1', approved('c1', DAVE, ALICE), conTx('c1', ALICE)),
    );
  });

  it('denies a moderator while moderatorManagesFinance is off', async () => {
    await seed(
      `families/${FAM_A}/settings/permissions`,
      permissionsDoc(ALICE, { moderatorManagesFinance: false }),
    );
    await assertFails(
      recordBatch(as(BOB), 'c1', approved('c1', CARA, BOB), conTx('c1', BOB)),
    );
  });

  it('denies every create in a closed month', async () => {
    await closeMonth();
    await assertFails(setDoc(doc(as(CARA), cPath('c1')), pending(CARA)));
    await assertFails(
      recordBatch(as(ALICE), 'c2', approved('c2', CARA, ALICE), conTx('c2', ALICE)),
    );
  });
});

describe('contributions update: the owner', () => {
  beforeEach(async () => {
    await seed(cPath('p1'), pending(CARA));
  });

  it('edits their own pending request', async () => {
    await assertSucceeds(
      updateDoc(doc(as(CARA), cPath('p1')), {
        amountPaisa: 120000,
        note: 'bKash',
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('cannot approve their own request or change its status', async () => {
    await assertFails(approveBatch(as(CARA), 'p1', CARA, conTx('p1', CARA)));
    await assertFails(
      updateDoc(doc(as(CARA), cPath('p1')), {
        status: 'approved',
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('withdraws their pending request (soft void)', async () => {
    await assertSucceeds(
      updateDoc(doc(as(CARA), cPath('p1')), {
        voidedAt: nowTs(),
        voidedBy: CARA,
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('denies editing somebody else\'s request', async () => {
    await assertFails(
      updateDoc(doc(as(BOB), cPath('p1')), {
        amountPaisa: 1,
        updatedAt: nowTs(),
        updatedBy: BOB,
      }),
    );
  });

  it('denies an edit in a closed month', async () => {
    await closeMonth();
    await assertFails(
      updateDoc(doc(as(CARA), cPath('p1')), {
        amountPaisa: 120000,
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('sets pendingChange on their own approved row, not directly edits it', async () => {
    await seed(cPath('a1'), approved('a1', CARA, ALICE));
    await assertFails(
      updateDoc(doc(as(CARA), cPath('a1')), {
        amountPaisa: 200000,
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
    await assertSucceeds(
      updateDoc(doc(as(CARA), cPath('a1')), {
        pendingChange: {
          amountPaisa: 200000,
          dateKey: '2026-10-06',
          requestedAt: nowTs(),
        },
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('denies pendingChange on somebody else\'s approved row', async () => {
    await seed(cPath('a2'), approved('a2', BOB, ALICE));
    await assertFails(
      updateDoc(doc(as(CARA), cPath('a2')), {
        pendingChange: {
          amountPaisa: 1,
          dateKey: '2026-10-06',
          requestedAt: nowTs(),
        },
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });
});

describe('contributions update: decisions', () => {
  beforeEach(async () => {
    await seed(cPath('p1'), pending(CARA));
  });

  it('lets a moderator approve, with the con_ row in the same batch', async () => {
    await assertSucceeds(approveBatch(as(BOB), 'p1', BOB, conTx('p1', BOB)));
  });

  it('denies an approval without the ledger row', async () => {
    await assertFails(approveBatch(as(BOB), 'p1', BOB, null));
  });

  it('denies a moderator while moderatorManagesFinance is off', async () => {
    await seed(
      `families/${FAM_A}/settings/permissions`,
      permissionsDoc(ALICE, { moderatorManagesFinance: false }),
    );
    await assertFails(approveBatch(as(BOB), 'p1', BOB, conTx('p1', BOB)));
  });

  it('denies a second approval of an already approved row', async () => {
    await seed(cPath('a1'), approved('a1', CARA, ALICE));
    await assertFails(approveBatch(as(ALICE), 'a1', ALICE, conTx('a1', ALICE)));
  });

  it('rejects with a reason, never without one', async () => {
    await assertFails(
      updateDoc(doc(as(ALICE), cPath('p1')), {
        status: 'rejected',
        decidedBy: ALICE,
        decidedAt: nowTs(),
        updatedAt: nowTs(),
        updatedBy: ALICE,
      }),
    );
    await assertSucceeds(
      updateDoc(doc(as(ALICE), cPath('p1')), {
        status: 'rejected',
        rejectReason: 'Not received',
        decidedBy: ALICE,
        decidedAt: nowTs(),
        updatedAt: nowTs(),
        updatedBy: ALICE,
      }),
    );
  });

  it('denies an approval in a closed month', async () => {
    await closeMonth();
    await assertFails(approveBatch(as(ALICE), 'p1', ALICE, conTx('p1', ALICE)));
  });

  it('approves a change request (values come from pendingChange)', async () => {
    await seed(
      cPath('a1'),
      approved('a1', CARA, ALICE, {
        pendingChange: {
          amountPaisa: 150000,
          dateKey: '2026-10-07',
          requestedAt: nowTs(),
        },
      }),
    );
    await assertFails(
      updateDoc(doc(as(ALICE), cPath('a1')), {
        amountPaisa: 999,
        dateKey: '2026-10-07',
        pendingChange: deleteField(),
        updatedAt: nowTs(),
        updatedBy: ALICE,
      }),
    );
    await assertSucceeds(
      updateDoc(doc(as(ALICE), cPath('a1')), {
        amountPaisa: 150000,
        dateKey: '2026-10-07',
        pendingChange: deleteField(),
        updatedAt: nowTs(),
        updatedBy: ALICE,
      }),
    );
  });

  it('declines a change request by clearing only pendingChange', async () => {
    await seed(
      cPath('a1'),
      approved('a1', CARA, ALICE, {
        pendingChange: {
          amountPaisa: 150000,
          dateKey: '2026-10-07',
          requestedAt: nowTs(),
        },
      }),
    );
    await assertSucceeds(
      updateDoc(doc(as(ALICE), cPath('a1')), {
        pendingChange: deleteField(),
        updatedAt: nowTs(),
        updatedBy: ALICE,
      }),
    );
  });

  it('voids an approved row (manager) but not as a member', async () => {
    await seed(cPath('a1'), approved('a1', CARA, ALICE));
    const voidFields = (uid) => ({
      voidedAt: nowTs(),
      voidedBy: uid,
      updatedAt: nowTs(),
      updatedBy: uid,
    });
    await assertFails(updateDoc(doc(as(CARA), cPath('a1')), voidFields(CARA)));
    await assertSucceeds(updateDoc(doc(as(ALICE), cPath('a1')), voidFields(ALICE)));
  });

  it('denies a void in a closed month', async () => {
    await seed(cPath('a1'), approved('a1', CARA, ALICE));
    await closeMonth();
    await assertFails(
      updateDoc(doc(as(ALICE), cPath('a1')), {
        voidedAt: nowTs(),
        voidedBy: ALICE,
        updatedAt: nowTs(),
        updatedBy: ALICE,
      }),
    );
  });

  it('never hard-deletes', async () => {
    await assertFails(deleteDoc(doc(as(ALICE), cPath('p1'))));
  });
});

describe('contributionPlans', () => {
  const plan = (uid, member, extra = {}) =>
    baseDoc(uid, {
      monthKey: '2026-10',
      memberId: member,
      expectedPaisa: 166700,
      deletedAt: null,
      deletedBy: null,
      ...extra,
    });

  it('lets the admin and a moderator write, never a member', async () => {
    await assertSucceeds(
      setDoc(doc(as(ALICE), pPath(`2026-10_${CARA}`)), plan(ALICE, CARA)),
    );
    await assertSucceeds(
      setDoc(doc(as(BOB), pPath(`2026-10_${ALICE}`)), plan(BOB, ALICE)),
    );
    await assertFails(
      setDoc(doc(as(CARA), pPath(`2026-10_${CARA}`)), plan(CARA, CARA)),
    );
  });

  it('denies a wrong id, a negative amount and a delete', async () => {
    await assertFails(setDoc(doc(as(ALICE), pPath('2026-10_other')), plan(ALICE, CARA)));
    await assertFails(
      setDoc(
        doc(as(ALICE), pPath(`2026-10_${CARA}`)),
        plan(ALICE, CARA, { expectedPaisa: -1 }),
      ),
    );
    await seed(pPath(`2026-10_${CARA}`), plan(ALICE, CARA));
    await assertFails(deleteDoc(doc(as(ALICE), pPath(`2026-10_${CARA}`))));
  });

  it('lets a manager override an existing plan but not move it', async () => {
    await seed(pPath(`2026-10_${CARA}`), plan(ALICE, CARA));
    await assertSucceeds(
      updateDoc(doc(as(ALICE), pPath(`2026-10_${CARA}`)), {
        expectedPaisa: 100000,
        updatedAt: nowTs(),
        updatedBy: ALICE,
      }),
    );
  });
});
