import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, getDocs } from 'firebase/firestore';
import { after, afterEach, before, beforeEach, describe, it } from 'mocha';
import {
  ALICE,
  CARA,
  EMULATOR,
  FAM_A,
  FAM_B,
  PROJECT_ID,
  asUser,
  seedWorld,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');
let testEnv;

const as = (uid) => asUser(testEnv, uid);

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

describe('families/{familyId}/activity read access', () => {
  it('allows an active family member to list their family activity', async () => {
    await assertSucceeds(getDocs(collection(as(CARA), `families/${FAM_A}/activity`)));
  });

  it('denies a member from listing another family activity', async () => {
    await assertFails(getDocs(collection(as(ALICE), `families/${FAM_B}/activity`)));
  });
});
