// Firestore rules for the expense collection (P2-10).
//
// One allowed and one denied case per rule: read, create, soft delete/restore,
// content edit, revisions, trips and the no-hard-delete guard.

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
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
  advanceDoc,
  asUser,
  closingDoc,
  expenseDoc,
  memberDoc,
  nowTs,
  revisionDoc,
  seedWorld,
  tripDoc,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');

let testEnv;

const as = (uid) => asUser(testEnv, uid);
const ZARA = 'zara'; // active plain member who does not own the seeded expense
const expensePath = (id = 'e1') => `families/${FAM_A}/expenses/${id}`;
const revisionPath = (id = 'r1', expenseId = 'e1') =>
  `families/${FAM_A}/expenses/${expenseId}/revisions/${id}`;
const tripPath = (id = 't1') => `families/${FAM_A}/bazarTrips/${id}`;

const softDelete = (uid) => ({
  deletedAt: nowTs(),
  deletedBy: uid,
  updatedAt: nowTs(),
  updatedBy: uid,
});

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
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, expensePath()), expenseDoc(CARA));
    await setDoc(
      doc(db, `families/${FAM_A}/members/${ZARA}`),
      memberDoc(ZARA, 'member', 'active'),
    );
  });
});

describe('families/{f}/expenses', () => {
  for (const [label, uid] of [
    ['member', CARA],
    ['moderator', BOB],
    ['admin', ALICE],
  ]) {
    it(`allows an active ${label} to read`, async () => {
      await assertSucceeds(getDoc(doc(as(uid), expensePath())));
    });
  }

  it('denies a pending member reading', async () => {
    await assertFails(getDoc(doc(as(DAVE), expensePath())));
  });

  it('denies another family reading', async () => {
    await assertFails(getDoc(doc(as(ERIN), expensePath())));
  });

  it('allows a member to create a fund expense', async () => {
    await assertSucceeds(
      setDoc(doc(as(CARA), expensePath('e2')), expenseDoc(CARA)),
    );
  });

  it('allows a member to create a member advance expense with its advance', async () => {
    const db = as(CARA);
    const batch = writeBatch(db);
    batch.set(
      doc(db, expensePath('e3')),
      expenseDoc(CARA, {
        fundingSource: 'member',
        paidByMemberId: CARA,
        reimbursable: true,
      }),
    );
    batch.set(
      doc(db, `families/${FAM_A}/memberAdvances/e3`),
      advanceDoc(CARA, { expenseId: 'e3' }),
    );
    await assertSucceeds(batch.commit());
  });

  it('denies a forged createdBy', async () => {
    await assertFails(
      setDoc(doc(as(CARA), expensePath('e2')), expenseDoc(ALICE)),
    );
  });

  it('denies an unknown field', async () => {
    await assertFails(
      setDoc(doc(as(CARA), expensePath('e2')), {
        ...expenseDoc(CARA),
        extra: 1,
      }),
    );
  });

  it('denies a zero total', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), expensePath('e2')),
        expenseDoc(CARA, { totalPaisa: 0 }),
      ),
    );
  });

  it('denies a fund row that names a payer', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), expensePath('e2')),
        expenseDoc(CARA, { paidByMemberId: CARA }),
      ),
    );
  });

  it('denies a member row without a payer', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), expensePath('e2')),
        expenseDoc(CARA, { fundingSource: 'member' }),
      ),
    );
  });

  it('denies a create in a closed month', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), `families/${FAM_A}/monthClosings/2026-10`),
        closingDoc(ALICE),
      );
    });
    await assertFails(
      setDoc(doc(as(CARA), expensePath('e2')), expenseDoc(CARA)),
    );
  });

  it('allows the owner to soft delete', async () => {
    await assertSucceeds(
      updateDoc(doc(as(CARA), expensePath()), softDelete(CARA)),
    );
  });

  it('allows a manager to soft delete someone else', async () => {
    await assertSucceeds(
      updateDoc(doc(as(ALICE), expensePath()), softDelete(ALICE)),
    );
  });

  it('denies a plain member soft deleting someone else', async () => {
    await assertFails(
      updateDoc(doc(as(ZARA), expensePath()), softDelete(ZARA)),
    );
  });

  it('denies a soft delete that also changes the total', async () => {
    await assertFails(
      updateDoc(doc(as(CARA), expensePath()), {
        ...softDelete(CARA),
        totalPaisa: 1,
      }),
    );
  });

  it('allows the owner to edit the content', async () => {
    await assertSucceeds(
      updateDoc(doc(as(CARA), expensePath()), {
        itemName: 'Chal',
        totalPaisa: 13000,
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('denies an edit that moves createdBy', async () => {
    await assertFails(
      updateDoc(doc(as(CARA), expensePath()), {
        createdBy: ALICE,
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('denies an edit that moves the source', async () => {
    await assertFails(
      updateDoc(doc(as(CARA), expensePath()), {
        source: 'import',
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('denies an edit in a closed month', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), `families/${FAM_A}/monthClosings/2026-10`),
        closingDoc(ALICE),
      );
    });
    await assertFails(
      updateDoc(doc(as(CARA), expensePath()), {
        itemName: 'Chal',
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('denies a hard delete', async () => {
    await assertFails(deleteDoc(doc(as(ALICE), expensePath())));
  });
});

describe('families/{f}/expenses/{e}/revisions', () => {
  it('allows the owner to append a revision', async () => {
    await assertSucceeds(
      setDoc(doc(as(CARA), revisionPath()), revisionDoc(CARA)),
    );
  });

  it('allows a manager to append a revision', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), revisionPath('r2')),
        revisionDoc(ALICE, {
          before: { itemName: 'Rice' },
          changedFields: ['itemName'],
        }),
      ),
    );
  });

  it('denies an unrelated member', async () => {
    await assertFails(
      setDoc(doc(as(ZARA), revisionPath('r3')), revisionDoc(ZARA)),
    );
  });

  it('denies a pending member', async () => {
    await assertFails(
      setDoc(doc(as(DAVE), revisionPath('r4')), revisionDoc(DAVE)),
    );
  });

  it('denies an unknown field', async () => {
    await assertFails(
      setDoc(doc(as(CARA), revisionPath('r5')), {
        ...revisionDoc(CARA),
        extra: 1,
      }),
    );
  });

  it('denies an update', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), revisionPath()),
        revisionDoc(CARA),
      );
    });
    await assertFails(
      updateDoc(doc(as(CARA), revisionPath()), { reason: 'changed' }),
    );
  });

  it('denies a delete', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), revisionPath()),
        revisionDoc(CARA),
      );
    });
    await assertFails(deleteDoc(doc(as(CARA), revisionPath())));
  });
});

describe('families/{f}/bazarTrips', () => {
  it('allows a member to create a trip', async () => {
    await assertSucceeds(
      setDoc(doc(as(CARA), tripPath()), tripDoc(CARA)),
    );
  });

  it('denies a member trip without a payer', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), tripPath()),
        tripDoc(CARA, { fundingSource: 'member' }),
      ),
    );
  });

  it('denies an update', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), tripPath()), tripDoc(CARA));
    });
    await assertFails(
      updateDoc(doc(as(CARA), tripPath()), { totalPaisa: 1 }),
    );
  });

  it('denies a hard delete', async () => {
    await assertFails(deleteDoc(doc(as(ALICE), tripPath())));
  });
});
