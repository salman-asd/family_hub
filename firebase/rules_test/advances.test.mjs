// Firestore rules for advances, settlements and month closings (P2-10).
//
// An advance is created once, then only its settlement progress or an
// unresolved edit/void may move; settlements and closings are manager work.

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
  permissionsDoc,
  seedWorld,
  settlementDoc,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');

let testEnv;

const as = (uid) => asUser(testEnv, uid);
const ZARA = 'zara';
const advancePath = (id = 'exp_adv1') =>
  `families/${FAM_A}/memberAdvances/${id}`;
const settlementPath = (id = 's1') => `families/${FAM_A}/settlements/${id}`;
const closingPath = (id = '2026-10') =>
  `families/${FAM_A}/monthClosings/${id}`;

const updated = (uid, extra = {}) => ({
  updatedAt: nowTs(),
  updatedBy: uid,
  ...extra,
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
    await setDoc(
      doc(db, `families/${FAM_A}/members/${ZARA}`),
      memberDoc(ZARA, 'member', 'active'),
    );
    await setDoc(
      doc(db, expensePathFor('exp_adv1')),
      expenseDoc(CARA, {
        fundingSource: 'member',
        paidByMemberId: CARA,
        reimbursable: true,
      }),
    );
    await setDoc(
      doc(db, advancePath()),
      advanceDoc(CARA, {
        expenseId: 'exp_adv1',
        memberId: CARA,
      }),
    );
    await setDoc(
      doc(db, settlementPath()),
      settlementDoc(ALICE, {
        advanceId: 'exp_adv1',
        memberId: CARA,
        fundTxId: 'stl_s1',
      }),
    );
  });
});

const expensePathFor = (id) => `families/${FAM_A}/expenses/${id}`;

describe('families/{f}/memberAdvances', () => {
  it('allows the owning member to read', async () => {
    await assertSucceeds(getDoc(doc(as(CARA), advancePath())));
  });

  it('allows a manager to read', async () => {
    await assertSucceeds(getDoc(doc(as(ALICE), advancePath())));
  });

  it('denies another member', async () => {
    await assertFails(getDoc(doc(as(ZARA), advancePath())));
  });

  it('denies a pending member', async () => {
    await assertFails(getDoc(doc(as(DAVE), advancePath())));
  });

  it('denies another family', async () => {
    await assertFails(getDoc(doc(as(ERIN), advancePath())));
  });

  it('allows a member to create an advance for a member-funded expense', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(CARA), advancePath('exp_new')),
        advanceDoc(CARA, { expenseId: 'exp_new', memberId: CARA }),
      ),
    );
  });

  it('denies a pending member creating an advance', async () => {
    await assertFails(
      setDoc(
        doc(as(DAVE), advancePath('exp_new')),
        advanceDoc(DAVE, { expenseId: 'exp_new', memberId: DAVE }),
      ),
    );
  });

  it('denies an expenseId that does not match the document id', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), advancePath('exp_new')),
        advanceDoc(CARA, { expenseId: 'other', memberId: CARA }),
      ),
    );
  });

  it('denies an already-settled advance', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), advancePath('exp_new')),
        advanceDoc(CARA, {
          expenseId: 'exp_new',
          memberId: CARA,
          settledPaisa: 100,
          status: 'partial',
        }),
      ),
    );
  });

  it('denies an unknown field', async () => {
    await assertFails(
      setDoc(doc(as(CARA), advancePath('exp_new')), {
        ...advanceDoc(CARA, { expenseId: 'exp_new', memberId: CARA }),
        extra: 1,
      }),
    );
  });

  it('denies a create in a closed month', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), closingPath()), closingDoc(ALICE));
    });
    await assertFails(
      setDoc(
        doc(as(CARA), advancePath('exp_new')),
        advanceDoc(CARA, { expenseId: 'exp_new', memberId: CARA }),
      ),
    );
  });

  it('allows a finance manager to record a partial settlement', async () => {
    await assertSucceeds(
      updateDoc(
        doc(as(ALICE), advancePath()),
        updated(ALICE, { settledPaisa: 3000, status: 'partial' }),
      ),
    );
  });

  it('denies a plain member recording a settlement', async () => {
    await assertFails(
      updateDoc(
        doc(as(CARA), advancePath()),
        updated(CARA, { settledPaisa: 3000, status: 'partial' }),
      ),
    );
  });

  it('denies a settlement that lowers the paid amount', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), advancePath()),
        advanceDoc(CARA, {
          expenseId: 'exp_adv1',
          memberId: CARA,
          settledPaisa: 3000,
          status: 'partial',
        }),
      );
    });
    await assertFails(
      updateDoc(
        doc(as(ALICE), advancePath()),
        updated(ALICE, { settledPaisa: 2000, status: 'partial' }),
      ),
    );
  });

  it('denies a settlement that moves the amount', async () => {
    await assertFails(
      updateDoc(
        doc(as(ALICE), advancePath()),
        updated(ALICE, {
          settledPaisa: 3000,
          status: 'partial',
          amountPaisa: 100,
        }),
      ),
    );
  });

  it('allows the expense owner to void an unpaid advance', async () => {
    await assertSucceeds(
      updateDoc(
        doc(as(CARA), advancePath()),
        updated(CARA, { status: 'voided' }),
      ),
    );
  });

  it('denies voiding a partly settled advance', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), advancePath()),
        advanceDoc(CARA, {
          expenseId: 'exp_adv1',
          memberId: CARA,
          settledPaisa: 3000,
          status: 'partial',
        }),
      );
    });
    await assertFails(
      updateDoc(
        doc(as(CARA), advancePath()),
        updated(CARA, { status: 'voided' }),
      ),
    );
  });

  it('denies a hard delete', async () => {
    await assertFails(deleteDoc(doc(as(ALICE), advancePath())));
  });
});

describe('families/{f}/settlements', () => {
  it('allows the owning member to read', async () => {
    await assertSucceeds(getDoc(doc(as(CARA), settlementPath())));
  });

  it('allows a manager to read', async () => {
    await assertSucceeds(getDoc(doc(as(ALICE), settlementPath())));
  });

  it('denies another member', async () => {
    await assertFails(getDoc(doc(as(ZARA), settlementPath())));
  });

  it('denies a pending member', async () => {
    await assertFails(getDoc(doc(as(DAVE), settlementPath())));
  });

  it('allows a finance manager to record a settlement', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), settlementPath('s2')),
        settlementDoc(ALICE, {
          advanceId: 'exp_adv1',
          memberId: CARA,
          fundTxId: 'stl_s2',
        }),
      ),
    );
  });

  it('denies a plain member recording a settlement', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), settlementPath('s3')),
        settlementDoc(CARA, {
          advanceId: 'exp_adv1',
          memberId: CARA,
          fundTxId: 'stl_s3',
        }),
      ),
    );
  });

  it('denies a zero amount', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), settlementPath('s4')),
        settlementDoc(ALICE, {
          advanceId: 'exp_adv1',
          memberId: CARA,
          fundTxId: 'stl_s4',
          amountPaisa: 0,
        }),
      ),
    );
  });

  it('denies a fundTxId that does not match the document id', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), settlementPath('s5')),
        settlementDoc(ALICE, {
          advanceId: 'exp_adv1',
          memberId: CARA,
          fundTxId: 'stl_other',
        }),
      ),
    );
  });

  it('denies a settlement in a closed month', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), closingPath()), closingDoc(ALICE));
    });
    await assertFails(
      setDoc(
        doc(as(ALICE), settlementPath('s6')),
        settlementDoc(ALICE, {
          advanceId: 'exp_adv1',
          memberId: CARA,
          fundTxId: 'stl_s6',
        }),
      ),
    );
  });

  it('denies an unknown field', async () => {
    await assertFails(
      setDoc(doc(as(ALICE), settlementPath('s7')), {
        ...settlementDoc(ALICE, {
          advanceId: 'exp_adv1',
          memberId: CARA,
          fundTxId: 'stl_s7',
        }),
        extra: 1,
      }),
    );
  });

  it('denies an update', async () => {
    await assertFails(
      updateDoc(doc(as(ALICE), settlementPath()), { amountPaisa: 1 }),
    );
  });

  it('denies a hard delete', async () => {
    await assertFails(deleteDoc(doc(as(ALICE), settlementPath())));
  });
});

describe('families/{f}/monthClosings', () => {
  it('allows an active member to read', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), closingPath()), closingDoc(ALICE));
    });
    await assertSucceeds(getDoc(doc(as(CARA), closingPath())));
  });

  it('denies a pending member reading', async () => {
    await assertFails(getDoc(doc(as(DAVE), closingPath())));
  });

  it('denies another family reading', async () => {
    await assertFails(getDoc(doc(as(ERIN), closingPath())));
  });

  it('allows an admin to close a month', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), closingPath('2026-11')),
        closingDoc(ALICE, { monthKey: '2026-11' }),
      ),
    );
  });

  it('allows a moderator to close a month while finance is on', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(BOB), closingPath('2026-11')),
        closingDoc(BOB, { monthKey: '2026-11' }),
      ),
    );
  });

  it('denies a moderator closing a month while finance is off', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), `families/${FAM_A}/settings/permissions`),
        permissionsDoc(ALICE, { moderatorManagesFinance: false }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as(BOB), closingPath('2026-11')),
        closingDoc(BOB, { monthKey: '2026-11' }),
      ),
    );
  });

  it('denies a plain member closing a month', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), closingPath('2026-11')),
        closingDoc(CARA, { monthKey: '2026-11' }),
      ),
    );
  });

  it('denies a monthKey that does not match the document id', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), closingPath('2026-12')),
        closingDoc(ALICE, { monthKey: '2026-11' }),
      ),
    );
  });

  it('denies an unknown field', async () => {
    await assertFails(
      setDoc(doc(as(ALICE), closingPath('2026-11')), {
        ...closingDoc(ALICE, { monthKey: '2026-11' }),
        extra: 1,
      }),
    );
  });

  it('allows an admin to reopen a closed month', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), closingPath()), closingDoc(ALICE));
    });
    await assertSucceeds(
      updateDoc(
        doc(as(ALICE), closingPath()),
        updated(ALICE, {
          status: 'open',
          reopenedAt: nowTs(),
          reopenedBy: ALICE,
          reopenCount: 1,
        }),
      ),
    );
  });

  it('denies a hard delete', async () => {
    await assertFails(deleteDoc(doc(as(ALICE), closingPath())));
  });
});
