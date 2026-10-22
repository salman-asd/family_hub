// Firestore rules for settings/bazar (P2-07).
//
// The Bazar settings are finance-managed: an admin always, a moderator while
// `settings/permissions.moderatorManagesFinance` is true.  A plain member and
// a moderator without finance may not write them.

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, setDoc, updateDoc } from 'firebase/firestore';
import { after, afterEach, before, beforeEach, describe, it } from 'mocha';

import {
  ALICE,
  BOB,
  CARA,
  EMULATOR,
  FAM_A,
  PROJECT_ID,
  asUser,
  bazarSettingsDoc,
  nowTs,
  permissionsDoc,
  seedWorld,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');

let testEnv;

const as = (uid) => asUser(testEnv, uid);
const settingsPath = (id = 'bazar') => `families/${FAM_A}/settings/${id}`;
const permissionsPath = settingsPath('permissions');
const generalPath = settingsPath('general');

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

describe('families/{f}/settings/bazar', () => {
  it('allows an admin to create the settings', async () => {
    await assertSucceeds(
      setDoc(doc(as(ALICE), settingsPath()), bazarSettingsDoc(ALICE)),
    );
  });

  it('allows an admin to update the settings', async () => {
    await assertSucceeds(
      setDoc(doc(as(ALICE), settingsPath()), bazarSettingsDoc(ALICE)),
    );
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), settingsPath()),
        bazarSettingsDoc(ALICE, { weekStartDay: 7 }),
        { merge: true },
      ),
    );
  });

  it('allows a finance moderator to create and update the settings', async () => {
    await assertSucceeds(
      setDoc(doc(as(BOB), settingsPath()), bazarSettingsDoc(BOB)),
    );
    await assertSucceeds(
      setDoc(
        doc(as(BOB), settingsPath()),
        bazarSettingsDoc(BOB, { weekStartDay: 1 }),
        { merge: true },
      ),
    );
  });

  it('denies a moderator while finance is switched off', async () => {
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), permissionsPath),
        permissionsDoc(ALICE, { moderatorManagesFinance: false }),
      ),
    );
    await assertFails(
      setDoc(doc(as(BOB), settingsPath()), bazarSettingsDoc(BOB)),
    );
  });

  it('denies a plain member', async () => {
    await assertFails(
      setDoc(doc(as(CARA), settingsPath()), bazarSettingsDoc(CARA)),
    );
  });

  it('denies a moderator writing settings/general', async () => {
    await assertFails(
      updateDoc(doc(as(BOB), generalPath), {
        timezone: 'Asia/Dhaka',
        updatedAt: nowTs(),
        updatedBy: BOB,
      }),
    );
  });

  it('denies an out-of-range week start day', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), settingsPath()),
        bazarSettingsDoc(ALICE, { weekStartDay: 8 }),
      ),
    );
  });

  it('denies an out-of-range contribution due day', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), settingsPath()),
        bazarSettingsDoc(ALICE, { contributionDueDay: 29 }),
      ),
    );
  });

  it('denies more than four alert thresholds', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), settingsPath()),
        bazarSettingsDoc(ALICE, { alertThresholds: [50, 70, 80, 90, 100] }),
      ),
    );
  });

  it('denies an invalid fund start month', async () => {
    await assertFails(
      setDoc(
        doc(as(ALICE), settingsPath()),
        bazarSettingsDoc(ALICE, { fundStartMonth: '2026-13' }),
      ),
    );
  });

  it('denies an unknown field', async () => {
    await assertFails(
      setDoc(doc(as(ALICE), settingsPath()), {
        ...bazarSettingsDoc(ALICE),
        extra: true,
      }),
    );
  });

  it('denies a hard delete', async () => {
    await assertSucceeds(
      setDoc(doc(as(ALICE), settingsPath()), bazarSettingsDoc(ALICE)),
    );
    await assertFails(deleteDoc(doc(as(ALICE), settingsPath())));
  });
});
