import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc } from 'firebase/firestore';
import { after, afterEach, before, beforeEach, describe, it } from 'mocha';

import {
  ALICE,
  BOB,
  CARA,
  EMULATOR,
  FAM_A,
  PROJECT_ID,
  asUser,
  dashboardPolicyDoc,
  permissionsDoc,
  seedWorld,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');
let testEnv;

const as = (uid) => asUser(testEnv, uid);
const policyPath = `families/${FAM_A}/settings/dashboard`;
const permissionsPath = `families/${FAM_A}/settings/permissions`;
const userPath = (uid) => `users/${uid}`;
const dashboardPrefs = (uid, extra = {}) => ({
  preferences: {
    dashboard: { order: ['chores_today'], hidden: [], shown: [], ...extra },
  },
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
});

describe('families/{f}/settings/dashboard', () => {
  it('allows an admin to create and incrementally update the policy', async () => {
    await assertSucceeds(
      setDoc(doc(as(ALICE), policyPath), dashboardPolicyDoc(ALICE)),
    );
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), policyPath),
        dashboardPolicyDoc(ALICE, {
          roles: { moderator: { chores_today: 'off' }, member: {} },
          version: 2,
        }),
      ),
    );
  });

  it('allows a Household Manager while moderator finance access is enabled', async () => {
    await assertSucceeds(
      setDoc(doc(as(BOB), policyPath), dashboardPolicyDoc(BOB)),
    );
  });

  it('denies a Household Manager when moderator finance access is disabled', async () => {
    await setDoc(
      doc(as(ALICE), permissionsPath),
      permissionsDoc(ALICE, { moderatorManagesFinance: false }),
    );
    await assertFails(
      setDoc(doc(as(BOB), policyPath), dashboardPolicyDoc(BOB)),
    );
  });

  it('denies a plain member from creating policy', async () => {
    await assertFails(
      setDoc(doc(as(CARA), policyPath), dashboardPolicyDoc(CARA)),
    );
  });

  it('denies a version jump or reuse on update', async () => {
    await setDoc(
      doc(as(ALICE), policyPath),
      dashboardPolicyDoc(ALICE, { version: 3 }),
    );
    await assertFails(
      setDoc(
        doc(as(ALICE), policyPath),
        dashboardPolicyDoc(ALICE, { version: 5 }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as(ALICE), policyPath),
        dashboardPolicyDoc(ALICE, { version: 3 }),
      ),
    );
  });

  it('denies an admin role cell and more than 16 cards per role', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), policyPath),
        dashboardPolicyDoc(ALICE, {
          roles: { admin: {}, member: {} },
        }),
      ),
    );
    const tooManyCards = Object.fromEntries(
      Array.from({ length: 17 }, (_, index) => [`card_${index}`, 'on']),
    );
    await assertFails(
      setDoc(
        doc(as(ALICE), policyPath),
        dashboardPolicyDoc(ALICE, {
          roles: { member: tooManyCards },
        }),
      ),
    );
  });

  it('allows active family members to read policy and denies other families', async () => {
    await setDoc(
      doc(as(ALICE), policyPath),
      dashboardPolicyDoc(ALICE),
    );
    await assertSucceeds(getDoc(doc(as(CARA), policyPath)));
    await assertFails(
      getDoc(doc(as(CARA), 'families/famB/settings/dashboard')),
    );
  });

  it('denies hard deletion', async () => {
    await setDoc(
      doc(as(ALICE), policyPath),
      dashboardPolicyDoc(ALICE),
    );
    await assertFails(deleteDoc(doc(as(ALICE), policyPath)));
  });
});

describe('users/{uid}.preferences.dashboard', () => {
  it('allows an owner to save valid dashboard preferences', async () => {
    await assertSucceeds(
      setDoc(doc(as(CARA), userPath(CARA)), dashboardPrefs(CARA)),
    );
  });

  it('denies another member from writing the owner preferences', async () => {
    await assertFails(
      setDoc(doc(as(CARA), userPath(ALICE)), dashboardPrefs(CARA)),
    );
  });

  it('denies lists above 24 or endpoint ids longer than 40 characters', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), userPath(CARA)),
        dashboardPrefs(CARA, {
          order: Array.from({ length: 25 }, (_, index) => `card_${index}`),
        }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as(CARA), userPath(CARA)),
        dashboardPrefs(CARA, { hidden: ['x'.repeat(41)] }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as(CARA), userPath(CARA)),
        dashboardPrefs(CARA, { shown: ['a', 'x'.repeat(41)] }),
      ),
    );
  });

  it('denies unknown keys and non-string list values', async () => {
    await assertFails(
      setDoc(
        doc(as(CARA), userPath(CARA)),
        dashboardPrefs(CARA, { extra: [] }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as(CARA), userPath(CARA)),
        dashboardPrefs(CARA, { order: [1] }),
      ),
    );
  });
});
