// Firestore rules for the Phase 3 chore settings (P3-06).
//
// Three documents:
//   settings/chores            manager or admin may write (C-4)
//   settings/choreGeneration   ANY active member, forward only, <= +120 days
//   settings/rotationPolicy    manager or admin may change the absence policy
//
// Run: npm run test:emulator (from firebase/rules_test).

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { after, afterEach, before, beforeEach, describe, it } from 'mocha';

import {
  ALICE,
  BOB,
  CARA,
  DAVE,
  EMULATOR,
  ERIN,
  FAM_A,
  FAM_B,
  FRANK,
  PROJECT_ID,
  asUser,
  choreSettingsDoc,
  generationDoc,
  nowTs,
  rotationPolicyDoc,
  seedWorld,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');

let testEnv;

const as = (uid) => asUser(testEnv, uid);
const choresPath = `families/${FAM_A}/settings/chores`;
const generationPath = `families/${FAM_A}/settings/choreGeneration`;
const policyPath = `families/${FAM_A}/settings/rotationPolicy`;

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

describe('families/{f}/settings/chores', () => {
  it('allows an admin to create and update the settings', async () => {
    await assertSucceeds(
      setDoc(doc(as(ALICE), choresPath), choreSettingsDoc(ALICE)),
    );
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), choresPath),
        choreSettingsDoc(ALICE, { weekStartDay: 7 }),
        { merge: true },
      ),
    );
  });

  it('allows a Household Manager to create and update them (C-4)', async () => {
    await assertSucceeds(
      setDoc(doc(as(BOB), choresPath), choreSettingsDoc(BOB)),
    );
    await assertSucceeds(
      setDoc(
        doc(as(BOB), choresPath),
        choreSettingsDoc(BOB, { generationHorizonDays: 60 }),
        { merge: true },
      ),
    );
  });

  it('denies a plain member', async () => {
    await assertFails(
      setDoc(doc(as(CARA), choresPath), choreSettingsDoc(CARA)),
    );
  });

  it('denies a pending member', async () => {
    await assertFails(
      setDoc(doc(as(DAVE), choresPath), choreSettingsDoc(DAVE)),
    );
  });

  it('denies an admin of another family', async () => {
    await assertFails(
      setDoc(
        doc(as(ERIN), `families/${FAM_B}/settings/chores`),
        choreSettingsDoc(ERIN),
      ),
    );
  });

  it('denies a user with no family', async () => {
    await assertFails(
      setDoc(doc(as(FRANK), choresPath), choreSettingsDoc(FRANK)),
    );
  });

  it('lets any active member read them', async () => {
    await assertSucceeds(
      setDoc(doc(as(ALICE), choresPath), choreSettingsDoc(ALICE)),
    );
    await assertSucceeds(getDoc(doc(as(CARA), choresPath)));
  });

  it('denies an out-of-range week start', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), choresPath),
        choreSettingsDoc(ALICE, { weekStartDay: 8 }),
      ),
    );
  });

  it('denies a generation horizon outside 14..90', async () => {
    for (const days of [13, 91]) {
      await assertFails(
        setDoc(
          doc(as(ALICE), choresPath),
          choreSettingsDoc(ALICE, { generationHorizonDays: days }),
        ),
      );
    }
  });

  it('denies a projected-months value above 12', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), choresPath),
        choreSettingsDoc(ALICE, { projectedMonthsAhead: 13 }),
      ),
    );
  });

  it('denies an overdue grace above 240 minutes', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), choresPath),
        choreSettingsDoc(ALICE, { overdueGraceMinutes: 241 }),
      ),
    );
  });

  it('denies a swap buffer above 1440 minutes', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), choresPath),
        choreSettingsDoc(ALICE, { swapExpiryBufferMinutes: 1441 }),
      ),
    );
  });

  it('denies house rules longer than 2000 characters', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), choresPath),
        choreSettingsDoc(ALICE, { houseRules: 'x'.repeat(2001) }),
      ),
    );
  });

  it('denies an unknown calendar view', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), choresPath),
        choreSettingsDoc(ALICE, { defaultCalendarView: 'year' }),
      ),
    );
  });

  it('denies more than 30 groups', async () => {
    const groups = Array.from({ length: 31 }, (_, i) => ({
      id: `g${i}`,
      nameBn: 'গ্রুপ',
      nameEn: null,
      colorIndex: 0,
      iconKey: 'other',
      sortOrder: i,
      active: true,
      builtIn: false,
    }));
    await assertFails(
      setDoc(doc(as(ALICE), choresPath), choreSettingsDoc(ALICE, { groups })),
    );
  });

  it('denies more than 8 due-time presets', async () => {
    const dueTimePresets = Array.from({ length: 9 }, (_, i) => ({
      id: `p${i}`,
      labelBn: 'সময়',
      labelEn: null,
      minutes: 60 * i,
      active: true,
      builtIn: false,
    }));
    await assertFails(
      setDoc(
        doc(as(ALICE), choresPath),
        choreSettingsDoc(ALICE, { dueTimePresets }),
      ),
    );
  });

  it('denies more than 12 absence reasons', async () => {
    const absenceReasons = Array.from({ length: 13 }, (_, i) => ({
      id: `r${i}`,
      labelBn: 'কারণ',
      labelEn: null,
      active: true,
      builtIn: false,
    }));
    await assertFails(
      setDoc(
        doc(as(ALICE), choresPath),
        choreSettingsDoc(ALICE, { absenceReasons }),
      ),
    );
  });

  it('denies a malformed first catalog row', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), choresPath),
        choreSettingsDoc(ALICE, {
          groups: [{ id: 'NOT A VALID ID', nameBn: 'x' }],
        }),
      ),
    );
  });

  it('denies an unknown field', async () => {
    await assertFails(
      setDoc(doc(as(ALICE), choresPath), {
        ...choreSettingsDoc(ALICE),
        extra: true,
      }),
    );
  });

  it('denies a hard delete', async () => {
    await assertSucceeds(
      setDoc(doc(as(ALICE), choresPath), choreSettingsDoc(ALICE)),
    );
    await assertFails(deleteDoc(doc(as(ALICE), choresPath)));
  });
});

describe('families/{f}/settings/choreGeneration', () => {
  it('lets any active member create the marker', async () => {
    await assertSucceeds(
      setDoc(doc(as(CARA), generationPath), generationDoc(CARA, 20740)),
    );
  });

  it('lets a member advance it by up to 120 days', async () => {
    await assertSucceeds(
      setDoc(doc(as(CARA), generationPath), generationDoc(CARA, 20740)),
    );
    await assertSucceeds(
      setDoc(doc(as(CARA), generationPath), generationDoc(CARA, 20860), {
        merge: true,
      }),
    );
  });

  it('denies a decrease', async () => {
    await assertSucceeds(
      setDoc(doc(as(CARA), generationPath), generationDoc(CARA, 20740)),
    );
    await assertFails(
      setDoc(doc(as(CARA), generationPath), generationDoc(CARA, 20739), {
        merge: true,
      }),
    );
  });

  it('denies the same value again (it must advance)', async () => {
    await assertSucceeds(
      setDoc(doc(as(CARA), generationPath), generationDoc(CARA, 20740)),
    );
    await assertFails(
      setDoc(doc(as(CARA), generationPath), generationDoc(CARA, 20740), {
        merge: true,
      }),
    );
  });

  it('denies a jump of 121 days', async () => {
    await assertSucceeds(
      setDoc(doc(as(CARA), generationPath), generationDoc(CARA, 20740)),
    );
    await assertFails(
      setDoc(doc(as(CARA), generationPath), generationDoc(CARA, 20861), {
        merge: true,
      }),
    );
  });

  it('denies a pending member', async () => {
    await assertFails(
      setDoc(doc(as(DAVE), generationPath), generationDoc(DAVE, 20740)),
    );
  });

  it('denies a negative marker', async () => {
    await assertFails(
      setDoc(doc(as(CARA), generationPath), generationDoc(CARA, -1)),
    );
  });
});

describe('families/{f}/settings/rotationPolicy', () => {
  it('allows a Household Manager to change the absence policy (C-3)', async () => {
    await assertSucceeds(
      setDoc(doc(as(ALICE), policyPath), rotationPolicyDoc(ALICE)),
    );
    await assertSucceeds(
      updateDoc(doc(as(BOB), policyPath), {
        absencePolicy: 'auto_cover',
        updatedAt: nowTs(),
        updatedBy: BOB,
      }),
    );
  });

  it('denies a plain member', async () => {
    await assertSucceeds(
      setDoc(doc(as(ALICE), policyPath), rotationPolicyDoc(ALICE)),
    );
    await assertFails(
      updateDoc(doc(as(CARA), policyPath), {
        absencePolicy: 'skip',
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('denies an unknown policy value', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), policyPath),
        rotationPolicyDoc(ALICE, 'ignore_everything'),
      ),
    );
  });

  it('accepts each of the three policies', async () => {
    for (const policy of ['ask_cover', 'auto_cover', 'skip']) {
      await assertSucceeds(
        setDoc(doc(as(ALICE), policyPath), rotationPolicyDoc(ALICE, policy)),
      );
    }
  });
});
