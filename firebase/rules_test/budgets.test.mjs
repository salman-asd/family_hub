// Firestore rules for families/{f}/budgets/{yyyy-MM} (P2-17).
//
// A budget is a plan: every active member reads it; an admin always writes it,
// a moderator only while `settings/permissions.moderatorManagesFinance` is true,
// a plain member never.  The document id is the month key, sizes are bounded
// (40 category estimates, 150 lines, 4 thresholds), money is integer paisa and
// nothing is ever hard-deleted.

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
  asUser,
  budgetDoc,
  nowTs,
  permissionsDoc,
  seedWorld,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');

let testEnv;

const as = (uid, options) => asUser(testEnv, uid, options);
const budgetPath = (month = '2026-10') => `families/${FAM_A}/budgets/${month}`;
const permissionsPath = `families/${FAM_A}/settings/permissions`;

const seedBudget = () =>
  testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), budgetPath()), budgetDoc(ALICE));
  });

const lines = (count) =>
  Array.from({ length: count }, (_, i) => ({
    name: `Line ${i}`,
    estimatedTotalPaisa: 100,
  }));

const categories = (count) =>
  Object.fromEntries(
    Array.from({ length: count }, (_, i) => [`cat_${i}`, 100]),
  );

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

describe('families/{f}/budgets/{month} read', () => {
  it('allows every active member to read', async () => {
    await seedBudget();
    await assertSucceeds(getDoc(doc(as(ALICE), budgetPath())));
    await assertSucceeds(getDoc(doc(as(BOB), budgetPath())));
    await assertSucceeds(getDoc(doc(as(CARA), budgetPath())));
  });

  it('denies a pending member', async () => {
    await seedBudget();
    await assertFails(getDoc(doc(as(DAVE), budgetPath())));
  });

  it('denies a member of another family', async () => {
    await seedBudget();
    await assertFails(getDoc(doc(as(ERIN), budgetPath())));
  });
});

describe('families/{f}/budgets/{month} create', () => {
  it('allows an admin', async () => {
    await assertSucceeds(
      setDoc(doc(as(ALICE), budgetPath()), budgetDoc(ALICE)),
    );
  });

  it('allows a finance moderator', async () => {
    await assertSucceeds(setDoc(doc(as(BOB), budgetPath()), budgetDoc(BOB)));
  });

  it('denies a moderator while finance is switched off', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), permissionsPath),
        permissionsDoc(ALICE, { moderatorManagesFinance: false }),
      ),
    );
    await assertFails(setDoc(doc(as(BOB), budgetPath()), budgetDoc(BOB)));
  });

  it('denies a plain member', async () => {
    await assertFails(setDoc(doc(as(CARA), budgetPath()), budgetDoc(CARA)));
  });

  it('denies a pending member', async () => {
    await assertFails(setDoc(doc(as(DAVE), budgetPath()), budgetDoc(DAVE)));
  });

  it('denies an admin whose email is not verified', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE, { verified: false }), budgetPath()),
        budgetDoc(ALICE),
      ),
    );
  });

  it('denies a forged createdBy', async () => {
    await assertFails(
      setDoc(doc(as(ALICE), budgetPath()), budgetDoc(ALICE, { createdBy: BOB })),
    );
  });

  it('denies a document id that is not the month key', async () => {
    await assertFails(
      setDoc(doc(as(ALICE), budgetPath('2026-11')), budgetDoc(ALICE)),
    );
  });

  it('denies a malformed month key', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), budgetPath('2026-13')),
        budgetDoc(ALICE, { monthKey: '2026-13' }),
      ),
    );
  });

  it('denies a negative total', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), budgetPath()),
        budgetDoc(ALICE, { totalEstimatePaisa: -1 }),
      ),
    );
  });

  it('denies a total that is not an integer', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), budgetPath()),
        budgetDoc(ALICE, { totalEstimatePaisa: 100.5 }),
      ),
    );
  });

  it('allows exactly 150 lines and denies 151', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), budgetPath()),
        budgetDoc(ALICE, { lines: lines(150) }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as(ALICE), budgetPath('2026-11')),
        budgetDoc(ALICE, { monthKey: '2026-11', lines: lines(151) }),
      ),
    );
  });

  it('allows exactly 40 category estimates and denies 41', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), budgetPath()),
        budgetDoc(ALICE, { categoryEstimates: categories(40) }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as(ALICE), budgetPath('2026-11')),
        budgetDoc(ALICE, {
          monthKey: '2026-11',
          categoryEstimates: categories(41),
        }),
      ),
    );
  });

  it('denies more than four alert thresholds', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), budgetPath()),
        budgetDoc(ALICE, { alertThresholds: [50, 70, 80, 90, 100] }),
      ),
    );
  });

  it('denies lines that are not a list', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), budgetPath()),
        budgetDoc(ALICE, { lines: 'many' }),
      ),
    );
  });

  it('denies an unknown field', async () => {
    await assertFails(
      setDoc(doc(as(ALICE), budgetPath()), {
        ...budgetDoc(ALICE),
        extra: true,
      }),
    );
  });
});

describe('families/{f}/budgets/{month} update and delete', () => {
  it('allows an admin to rewrite the budget', async () => {
    await seedBudget();
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), budgetPath()),
        budgetDoc(ALICE, { totalEstimatePaisa: 900000 }),
      ),
    );
  });

  it('allows a finance moderator to rewrite the budget', async () => {
    await seedBudget();
    await assertSucceeds(
      setDoc(
        doc(as(BOB), budgetPath()),
        budgetDoc(ALICE, { totalEstimatePaisa: 900000, updatedBy: BOB }),
      ),
    );
  });

  it('denies a plain member', async () => {
    await seedBudget();
    await assertFails(
      updateDoc(doc(as(CARA), budgetPath()), {
        totalEstimatePaisa: 1,
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('denies a forged updatedBy', async () => {
    await seedBudget();
    await assertFails(
      updateDoc(doc(as(ALICE), budgetPath()), {
        totalEstimatePaisa: 1,
        updatedAt: nowTs(),
        updatedBy: BOB,
      }),
    );
  });

  it('denies an update that breaks the shape', async () => {
    await seedBudget();
    await assertFails(
      updateDoc(doc(as(ALICE), budgetPath()), {
        totalEstimatePaisa: -5,
        updatedAt: nowTs(),
        updatedBy: ALICE,
      }),
    );
  });

  it('denies a hard delete, even for an admin', async () => {
    await seedBudget();
    await assertFails(deleteDoc(doc(as(ALICE), budgetPath())));
  });
});
