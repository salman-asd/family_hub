// H5 contract test: the Dart ↔ rules seam.
//
// `test/contract/rules_fixtures_test.dart` builds REAL payloads with the
// FamilyMappers and writes them to `firebase/rules_test/fixtures/*.json`.  This
// test loads each one, rehydrates the Timestamps / serverTimestamp markers and
// pushes the whole batch through the emulator as the fixture's actor.  If a
// mapper writes a key the rules do not allow (or a required field is missing),
// this fails — and CI runs the Dart generator first plus
// `git diff --exit-code firebase/rules_test/fixtures`, so the two cannot drift.
//
//   firebase/rules_test> npm install
//   (repo root)> npx firebase emulators:exec --only firestore \
//                  --project demo-family-hub "npm --prefix firebase/rules_test test"

import { strict as assert } from 'node:assert';
import { readFileSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { Timestamp, doc, serverTimestamp, setDoc, writeBatch } from 'firebase/firestore';
import { after, before, describe, it } from 'mocha';

import {
  EMULATOR,
  PROJECT_ID,
  asUser,
  familyDoc,
  inviteCodeDoc,
  memberDoc,
} from './support.mjs';

const ADMIN = 'fixAdmin';
const JOINER = 'fixJoiner';
const FAMILY = 'fixFam';
const CODE = 'ABCD2345';

const [host, port] = EMULATOR.split(':');
const fixturesDir = join(dirname(fileURLToPath(import.meta.url)), 'fixtures');

/** `{"__ts": iso}` -> Timestamp, `{"__serverTime": true}` -> serverTimestamp(). */
const rehydrate = (value) => {
  if (Array.isArray(value)) return value.map(rehydrate);
  if (value && typeof value === 'object') {
    if (value.__ts !== undefined) return Timestamp.fromDate(new Date(value.__ts));
    if (value.__serverTime === true) return serverTimestamp();
    const out = {};
    for (const [k, v] of Object.entries(value)) out[k] = rehydrate(v);
    return out;
  }
  return value;
};

/** Prerequisite world for each scenario, seeded with the rules switched off. */
const seeders = {
  create_family: async () => {},
  profile: async () => {},
  join: async (db) => {
    await setDoc(doc(db, `families/${FAMILY}`), familyDoc(ADMIN));
    await setDoc(
      doc(db, `families/${FAMILY}/members/${ADMIN}`),
      memberDoc(ADMIN, 'admin', 'active'),
    );
    // A live code (expiresAt is relative to the RUN time, not the fixture).
    await setDoc(doc(db, `inviteCodes/${CODE}`), inviteCodeDoc(ADMIN, FAMILY, CODE));
    await setDoc(
      doc(db, `families/${FAMILY}/invitations/${CODE}`),
      inviteCodeDoc(ADMIN, FAMILY, CODE),
    );
  },
  approve: async (db) => {
    await seedFamilyWithAdmin(db);
    await setDoc(
      doc(db, `families/${FAMILY}/members/${JOINER}`),
      memberDoc(JOINER, 'member', 'pending'),
    );
  },
  role_change: async (db) => {
    await seedFamilyWithAdmin(db);
    await setDoc(
      doc(db, `families/${FAMILY}/members/${JOINER}`),
      memberDoc(JOINER, 'member', 'active'),
    );
  },
  create_invitation: async (db) => {
    await seedFamilyWithAdmin(db);
  },
  revoke_invitation: async (db) => {
    await seedFamilyWithAdmin(db);
    await setDoc(doc(db, `inviteCodes/${CODE}`), inviteCodeDoc(ADMIN, FAMILY, CODE));
    await setDoc(
      doc(db, `families/${FAMILY}/invitations/${CODE}`),
      inviteCodeDoc(ADMIN, FAMILY, CODE),
    );
  },
};

const seedFamilyWithAdmin = async (db) => {
  await setDoc(doc(db, `families/${FAMILY}`), familyDoc(ADMIN));
  await setDoc(
    doc(db, `families/${FAMILY}/members/${ADMIN}`),
    memberDoc(ADMIN, 'admin', 'active'),
  );
};

/** Applies the fixture's writes in one batch, exactly like the repository. */
const applyWrites = (db, writes) => {
  const batch = writeBatch(db);
  for (const write of writes) {
    const ref = doc(db, write.path);
    const data = rehydrate(write.data);
    if (write.op === 'set') batch.set(ref, data);
    else if (write.op === 'merge') batch.set(ref, data, { merge: true });
    else if (write.op === 'update') batch.update(ref, data);
    else throw new Error(`unknown write op: ${write.op}`);
  }
  return batch.commit();
};

const fixtures = readdirSync(fixturesDir)
  .filter((name) => name.endsWith('.json'))
  .sort()
  .map((name) => JSON.parse(readFileSync(join(fixturesDir, name), 'utf8')));

describe('H5 mapper ↔ rules contract', () => {
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: { host, port: Number(port) },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  assert.ok(fixtures.length > 0, 'no contract fixtures found — run flutter test');

  for (const fixture of fixtures) {
    it(`allows the real ${fixture.scenario} batch`, async () => {
      await testEnv.clearFirestore();
      const seed = seeders[fixture.scenario];
      assert.ok(seed, `no seeder for scenario ${fixture.scenario}`);
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await seed(ctx.firestore());
      });
      const db = asUser(testEnv, fixture.actor);
      await assertSucceeds(applyWrites(db, fixture.writes));
    });
  }
});
