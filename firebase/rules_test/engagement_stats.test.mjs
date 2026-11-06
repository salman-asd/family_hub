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
  writeBatch,
} from 'firebase/firestore';
import { after, afterEach, before, beforeEach, describe, it } from 'mocha';

import {
  ALICE,
  BOB,
  CARA,
  EMULATOR,
  FAM_A,
  FAM_B,
  PROJECT_ID,
  asUser,
  engagementSettingsDoc,
  memberStatsDoc,
  publicStatsDoc,
  seedWorld,
  todayDateKey,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');
let testEnv;

const as = (uid) => asUser(testEnv, uid);
const statsPath = (uid) => `families/${FAM_A}/memberStats/${uid}`;
const publicPath = (uid) => `families/${FAM_A}/memberStatsPublic/${uid}`;
const engagementPath = `families/${FAM_A}/settings/engagement`;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { host, port: Number(port) },
  });
});

after(async () => testEnv.cleanup());
afterEach(async () => testEnv.clearFirestore());
beforeEach(async () => seedWorld(testEnv));

describe('private memberStats', () => {
  it('allows an owner to create and read zero-initialized stats', async () => {
    await assertSucceeds(
      setDoc(doc(as(CARA), statsPath(CARA)), memberStatsDoc(CARA)),
    );
    await assertSucceeds(getDoc(doc(as(CARA), statsPath(CARA))));
  });

  it('denies other members and admins from reading or writing stats', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), statsPath(CARA)), memberStatsDoc(CARA));
    });
    await assertFails(getDoc(doc(as(BOB), statsPath(CARA))));
    await assertFails(getDoc(doc(as(ALICE), statsPath(CARA))));
    await assertFails(
      setDoc(doc(as(BOB), statsPath(CARA)), memberStatsDoc(BOB)),
    );
  });

  it('enforces monotonic bounded totals, retained badges and celebration dates', async () => {
    const initial = memberStatsDoc(CARA, {
      totalPoints: 100,
      completedTotal: 2,
      badges: { fresh_start: { earnedAt: todayDateKey() } },
    });
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), statsPath(CARA)), initial);
    });
    await assertFails(
      setDoc(
        doc(as(CARA), statsPath(CARA)),
        memberStatsDoc(CARA, { totalPoints: 99 }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as(CARA), statsPath(CARA)),
        memberStatsDoc(CARA, { totalPoints: 3101 }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as(CARA), statsPath(CARA)),
        memberStatsDoc(CARA, { badges: {} }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as(CARA), statsPath(CARA)),
        memberStatsDoc(CARA, {
          totalPoints: 100,
          completedTotal: 2,
          badges: { fresh_start: { earnedAt: todayDateKey() } },
          lastCelebratedDateKey: '2999-01-01',
        }),
      ),
    );
  });

  it('denies hard deletion and another-family access', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), statsPath(CARA)), memberStatsDoc(CARA));
    });
    await assertFails(deleteDoc(doc(as(CARA), statsPath(CARA))));
    await assertFails(getDoc(doc(as(ALICE), `families/${FAM_B}/memberStats/erin`)));
  });
});

describe('points-free memberStatsPublic', () => {
  it('lets active members read a card only while levels visibility is enabled', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(
        doc(db, engagementPath),
        engagementSettingsDoc(ALICE, { statsVisibility: 'levels' }),
      );
      await setDoc(
        doc(db, statsPath(CARA)),
        memberStatsDoc(CARA, { sharing: true }),
      );
    });
    await assertSucceeds(
      setDoc(doc(as(CARA), publicPath(CARA)), publicStatsDoc(CARA)),
    );
    await assertSucceeds(getDoc(doc(as(BOB), publicPath(CARA))));
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), engagementPath),
        engagementSettingsDoc(ALICE, { statsVisibility: 'private' }),
      );
    });
    await assertFails(getDoc(doc(as(BOB), publicPath(CARA))));
    await assertSucceeds(deleteDoc(doc(as(CARA), publicPath(CARA))));
    await assertFails(
      deleteDoc(
        doc(asUser(testEnv, CARA, { verified: false }), publicPath(CARA)),
      ),
    );
  });

  it('lets family members list public cards only while levels visibility is enabled', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(
        doc(db, engagementPath),
        engagementSettingsDoc(ALICE, { statsVisibility: 'levels' }),
      );
      await setDoc(doc(db, statsPath(CARA)), memberStatsDoc(CARA, { sharing: true }));
      await setDoc(doc(db, publicPath(CARA)), publicStatsDoc(CARA));
    });
    await assertSucceeds(
      getDocs(collection(as(BOB), `families/${FAM_A}/memberStatsPublic`)),
    );
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), engagementPath),
        engagementSettingsDoc(ALICE, { statsVisibility: 'private' }),
      );
    });
    await assertFails(
      getDocs(collection(as(BOB), `families/${FAM_A}/memberStatsPublic`)),
    );
  });

  it('denies points fields and writes without owner opt-in', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), engagementPath),
        engagementSettingsDoc(ALICE, { statsVisibility: 'levels' }),
      );
      await setDoc(doc(ctx.firestore(), statsPath(CARA)), memberStatsDoc(CARA));
      await setDoc(doc(ctx.firestore(), statsPath(BOB)), memberStatsDoc(BOB));
    });
    await assertFails(
      setDoc(
        doc(as(CARA), publicPath(CARA)),
        publicStatsDoc(CARA, { totalPoints: 500 }),
      ),
    );
    await assertFails(
      setDoc(doc(as(CARA), publicPath(CARA)), publicStatsDoc(CARA)),
    );
    await assertFails(deleteDoc(doc(as(BOB), publicPath(CARA))));
  });

  it('allows opt-in and public mirroring atomically', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), engagementPath),
        engagementSettingsDoc(ALICE, { statsVisibility: 'levels' }),
      );
      await setDoc(doc(ctx.firestore(), statsPath(CARA)), memberStatsDoc(CARA));
    });
    const batch = writeBatch(as(CARA));
    batch.set(
      doc(as(CARA), statsPath(CARA)),
      memberStatsDoc(CARA, { sharing: true }),
    );
    batch.set(
      doc(as(CARA), publicPath(CARA)),
      publicStatsDoc(CARA, { level: 2, badgeIds: ['fresh_start'] }),
    );
    await assertSucceeds(batch.commit());
  });
});

describe('settings/engagement', () => {
  it('allows a manager to edit scoring and an admin to change visibility', async () => {
    await assertSucceeds(
      setDoc(doc(as(ALICE), engagementPath), engagementSettingsDoc(ALICE)),
    );
    await assertSucceeds(
      setDoc(
        doc(as(BOB), engagementPath),
        engagementSettingsDoc(BOB, { latePermille: 700 }),
      ),
    );
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), engagementPath),
        engagementSettingsDoc(ALICE, { statsVisibility: 'levels' }),
      ),
    );
  });

  it('denies a manager changing visibility and rejects invalid settings', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), engagementPath),
        engagementSettingsDoc(ALICE),
      );
    });
    await assertFails(
      setDoc(
        doc(as(BOB), engagementPath),
        engagementSettingsDoc(BOB, { statsVisibility: 'levels' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(as(ALICE), engagementPath),
        engagementSettingsDoc(ALICE, { latePermille: 3000 }),
      ),
    );
  });

  it('only allows starting engagement on today and keeps its start date immutable', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), engagementPath),
        engagementSettingsDoc(ALICE, { enabled: false }),
      );
    });
    await assertFails(
      setDoc(
        doc(as(ALICE), engagementPath),
        engagementSettingsDoc(ALICE, {
          enabled: true,
          startedOn: '2000-01-01',
        }),
      ),
    );
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), engagementPath),
        engagementSettingsDoc(ALICE),
      );
    });
    await assertFails(
      setDoc(
        doc(as(ALICE), engagementPath),
        engagementSettingsDoc(ALICE, { startedOn: '2000-01-01' }),
      ),
    );
  });
});
