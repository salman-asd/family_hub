import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
} from 'firebase/firestore';
import { after, afterEach, before, beforeEach, describe, it } from 'mocha';

import {
  ALICE,
  BOB,
  EMULATOR,
  FRANK,
  PROJECT_ID,
  asUser,
  baseDoc,
  nowTs,
  seedWorld,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');
let testEnv;
const as = (uid, options) => asUser(testEnv, uid, options);
const devicesPath = (uid) => `users/${uid}/devices`;
const devicePath = (uid, deviceId) => `${devicesPath(uid)}/${deviceId}`;
const deviceDoc = (uid, extra = {}) => ({
  ...baseDoc(uid),
  token: 'fcm-registration-token',
  platform: 'android',
  lang: 'bn',
  appVersion: '0.1.0',
  flavor: 'dev',
  lastSeenAt: nowTs(),
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
});

describe('users/{uid}/devices/{deviceId}', () => {
  it('allows the verified owner to create, read, update, list and delete', async () => {
    const path = devicePath(ALICE, 'install-1');
    const original = deviceDoc(ALICE);
    await assertSucceeds(setDoc(doc(as(ALICE), path), original));
    await assertSucceeds(getDoc(doc(as(ALICE), path)));
    await assertSucceeds(
      getDocs(collection(as(ALICE), devicesPath(ALICE))),
    );
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), path),
        {
          ...original,
          token: 'refreshed-registration-token',
          lang: 'en',
          lastSeenAt: nowTs(),
          updatedAt: nowTs(),
        },
      ),
    );
    await assertSucceeds(deleteDoc(doc(as(ALICE), path)));
  });

  it('denies another user and unauthenticated access', async () => {
    const path = devicePath(ALICE, 'install-1');
    await assertFails(setDoc(doc(as(BOB), path), deviceDoc(BOB)));
    await assertFails(getDoc(doc(as(BOB), path)));
    await assertFails(
      setDoc(
        doc(testEnv.unauthenticatedContext().firestore(), path),
        deviceDoc(ALICE),
      ),
    );
  });

  it('denies writes by unverified users and malformed device records', async () => {
    await assertFails(
      setDoc(
        doc(as(FRANK, { verified: false }), devicePath(FRANK, 'install-1')),
        deviceDoc(FRANK),
      ),
    );

    const invalid = [
      { token: '' },
      { token: 't'.repeat(4097) },
      { platform: 'ios' },
      { lang: 'fr' },
      { appVersion: 'v'.repeat(33) },
      { flavor: 'staging' },
      { unexpected: true },
    ];
    for (const fields of invalid) {
      await assertFails(
        setDoc(
          doc(as(FRANK), devicePath(FRANK, 'install-1')),
          deviceDoc(FRANK, fields),
        ),
      );
    }
  });

  it('allows a verified user without a family to manage their own device', async () => {
    const path = devicePath(FRANK, 'install-1');
    await assertSucceeds(setDoc(doc(as(FRANK), path), deviceDoc(FRANK)));
    await assertSucceeds(deleteDoc(doc(as(FRANK), path)));
  });
});
