// Firestore rules for the fund ledger (P2-10).
//
// The ledger is append-only and signed: the document id must match its
// reference, contributions/expenses/reimbursements have a fixed sign, and a
// closed month rejects new rows.

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
  asUser,
  closingDoc,
  fundTxDoc,
  permissionsDoc,
  seedWorld,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');

let testEnv;

const as = (uid) => asUser(testEnv, uid);
const txPath = (id = 'exp_fix1') =>
  `families/${FAM_A}/fundTransactions/${id}`;

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

describe('families/{f}/fundTransactions', () => {
  for (const [label, uid] of [
    ['member', CARA],
    ['moderator', BOB],
    ['admin', ALICE],
  ]) {
    it(`allows an active ${label} to read`, async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(
          doc(ctx.firestore(), txPath('exp_read')),
          fundTxDoc(ALICE, { refId: 'read' }),
        );
      });
      await assertSucceeds(getDoc(doc(as(uid), txPath('exp_read'))));
    });
  }

  it('denies a pending member reading', async () => {
    await assertFails(getDoc(doc(as(DAVE), txPath())));
  });

  it('denies another family reading', async () => {
    await assertFails(getDoc(doc(as(ERIN), txPath())));
  });

  it('allows a member to write a negative expense row', async () => {
    await assertSucceeds(
      setDoc(doc(as(CARA), txPath()), fundTxDoc(CARA)),
    );
  });

  it('denies a pending member writing an expense row', async () => {
    await assertFails(
      setDoc(doc(as(DAVE), txPath()), fundTxDoc(DAVE)),
    );
  });

  it('denies a forged createdBy', async () => {
    await assertFails(
      setDoc(doc(as(CARA), txPath()), fundTxDoc(ALICE)),
    );
  });

  it('denies an expense row with a positive amount', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), txPath()),
        fundTxDoc(CARA, { amountPaisa: 12000 }),
      ),
    );
  });

  it('denies an expense row whose id does not match its refId', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), txPath('exp_other')),
        fundTxDoc(CARA, { refId: 'e1' }),
      ),
    );
  });

  it('denies an unknown field', async () => {
    await assertFails(
      setDoc(doc(as(CARA), txPath()), {
        ...fundTxDoc(CARA),
        extra: 1,
      }),
    );
  });

  it('denies an expense row in a closed month', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), `families/${FAM_A}/monthClosings/2026-10`),
        closingDoc(ALICE),
      );
    });
    await assertFails(
      setDoc(doc(as(CARA), txPath()), fundTxDoc(CARA)),
    );
  });

  it('allows an admin to write a contribution row', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), txPath('con_c1')),
        fundTxDoc(ALICE, {
          type: 'contribution',
          amountPaisa: 10000,
          refType: 'contribution',
          refId: 'c1',
        }),
      ),
    );
  });

  it('allows a moderator to write a contribution while finance is on', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(BOB), txPath('con_c2')),
        fundTxDoc(BOB, {
          type: 'contribution',
          amountPaisa: 10000,
          refType: 'contribution',
          refId: 'c2',
        }),
      ),
    );
  });

  it('denies a moderator writing a contribution while finance is off', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), `families/${FAM_A}/settings/permissions`),
        permissionsDoc(ALICE, { moderatorManagesFinance: false }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as(BOB), txPath('con_c3')),
        fundTxDoc(BOB, {
          type: 'contribution',
          amountPaisa: 10000,
          refType: 'contribution',
          refId: 'c3',
        }),
      ),
    );
  });

  it('denies a plain member writing a contribution', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), txPath('con_c4')),
        fundTxDoc(CARA, {
          type: 'contribution',
          amountPaisa: 10000,
          refType: 'contribution',
          refId: 'c4',
        }),
      ),
    );
  });

  it('denies a negative contribution', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), txPath('con_c5')),
        fundTxDoc(ALICE, {
          type: 'contribution',
          amountPaisa: -10000,
          refType: 'contribution',
          refId: 'c5',
        }),
      ),
    );
  });

  it('allows an admin to write a reimbursement row', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), txPath('stl_s1')),
        fundTxDoc(ALICE, {
          type: 'reimbursement',
          amountPaisa: -3000,
          refType: 'settlement',
          refId: 's1',
        }),
      ),
    );
  });

  it('denies a member writing a reimbursement', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), txPath('stl_s2')),
        fundTxDoc(CARA, {
          type: 'reimbursement',
          amountPaisa: -3000,
          refType: 'settlement',
          refId: 's2',
        }),
      ),
    );
  });

  it('denies a positive reimbursement', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), txPath('stl_s3')),
        fundTxDoc(ALICE, {
          type: 'reimbursement',
          amountPaisa: 3000,
          refType: 'settlement',
          refId: 's3',
        }),
      ),
    );
  });

  it('allows an admin to write an opening row', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), txPath('open_2026-10')),
        fundTxDoc(ALICE, {
          type: 'opening',
          amountPaisa: 50000,
          refType: 'month',
          refId: '2026-10',
          dateKey: '2026-10-01',
          monthKey: '2026-10',
        }),
      ),
    );
  });

  it('denies a moderator writing an opening row on its own', async () => {
    await assertFails(
      setDoc(
        doc(as(BOB), txPath('open_2026-11')),
        fundTxDoc(BOB, {
          type: 'opening',
          amountPaisa: 50000,
          refType: 'month',
          refId: '2026-11',
          dateKey: '2026-11-01',
          monthKey: '2026-11',
        }),
      ),
    );
  });

  it('allows a finance moderator to carry the balance into the month it just closed', async () => {
    // P2-21: the closing document and the `open_<next>` row are ONE batch.
    await assertSucceeds(
      writeBatch(as(BOB))
        .set(
          doc(as(BOB), `families/${FAM_A}/monthClosings/2026-10`),
          closingDoc(BOB),
        )
        .set(
          doc(as(BOB), txPath('open_2026-11')),
          fundTxDoc(BOB, {
            type: 'opening',
            amountPaisa: 5000,
            refType: 'month',
            refId: '2026-11',
            dateKey: '2026-11-01',
            monthKey: '2026-11',
          }),
        )
        .commit(),
    );
  });

  it('denies a carry-forward row when the next month is not closed in the same batch', async () => {
    await assertFails(
      setDoc(
        doc(as(BOB), txPath('open_2026-11')),
        fundTxDoc(BOB, {
          type: 'opening',
          amountPaisa: 5000,
          refType: 'month',
          refId: '2026-11',
          dateKey: '2026-11-01',
          monthKey: '2026-11',
        }),
      ),
    );
  });

  it('denies a carry-forward row landing in an already closed month', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), `families/${FAM_A}/monthClosings/2026-11`),
        closingDoc(BOB, { monthKey: '2026-11' }),
      );
    });
    await assertFails(
      writeBatch(as(BOB))
        .set(
          doc(as(BOB), `families/${FAM_A}/monthClosings/2026-10`),
          closingDoc(BOB),
        )
        .set(
          doc(as(BOB), txPath('open_2026-11')),
          fundTxDoc(BOB, {
            type: 'opening',
            amountPaisa: 5000,
            refType: 'month',
            refId: '2026-11',
            dateKey: '2026-11-01',
            monthKey: '2026-11',
          }),
        )
        .commit(),
    );
  });

  it('denies a plain member carrying a balance forward', async () => {
    await assertFails(
      writeBatch(as(CARA))
        .set(
          doc(as(CARA), `families/${FAM_A}/monthClosings/2026-10`),
          closingDoc(CARA),
        )
        .set(
          doc(as(CARA), txPath('open_2026-11')),
          fundTxDoc(CARA, {
            type: 'opening',
            amountPaisa: 5000,
            refType: 'month',
            refId: '2026-11',
            dateKey: '2026-11-01',
            monthKey: '2026-11',
          }),
        )
        .commit(),
    );
  });

  it('denies a zero opening row', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), txPath('open_2026-12')),
        fundTxDoc(ALICE, {
          type: 'opening',
          amountPaisa: 0,
          refType: 'month',
          refId: '2026-12',
          dateKey: '2026-12-01',
          monthKey: '2026-12',
        }),
      ),
    );
  });

  it('allows a member to write an expense adjustment', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(CARA), txPath('adj_ev1')),
        fundTxDoc(CARA, {
          type: 'adjustment',
          amountPaisa: 1000,
          refType: 'expense',
          refId: 'e1',
        }),
      ),
    );
  });

  it('denies a member writing a contribution adjustment', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), txPath('adj_ev2')),
        fundTxDoc(CARA, {
          type: 'adjustment',
          amountPaisa: 1000,
          refType: 'contribution',
          refId: 'c1',
        }),
      ),
    );
  });

  it('denies an update', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), txPath()), fundTxDoc(CARA));
    });
    await assertFails(
      updateDoc(doc(as(ALICE), txPath()), { amountPaisa: 1 }),
    );
  });

  it('denies a hard delete', async () => {
    await assertFails(deleteDoc(doc(as(ALICE), txPath())));
  });
});
