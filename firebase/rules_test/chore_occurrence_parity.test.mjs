// P-03 (Wave R6): the rules half of the InMemory-vs-rules parity test.
//
// fixtures/occurrence_transitions.json is ONE table of transition sequences.
// The Dart half (occurrence_transition_parity_test.dart) runs it against the
// use cases and the in-memory backend; this file runs the SAME steps against
// the emulator, building the writes exactly as OccurrenceActionWriter does
// (patch + `lastEventId` + the event in one batch).  A step must be allowed or
// denied the same way on both sides.
//
// Written without an emulator: run `npm run test:emulator` once and, if a step
// fails, decide whether the RULE or the USE CASE is wrong, then fix that side
// (never loosen the table).

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteField,
  doc,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { after, afterEach, before, beforeEach, describe, it } from 'mocha';

import {
  ALICE,
  BOB,
  CARA,
  EMULATOR,
  FAM_A,
  PROJECT_ID,
  asUser,
  memberDoc,
  nowTs,
  occurrenceDoc,
  occurrenceEventDoc,
  permissionsDoc,
  seedWorld,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');
const GINA = 'gina'; // a plain active member who is not the assignee

const table = JSON.parse(
  readFileSync(new URL('./fixtures/occurrence_transitions.json', import.meta.url)),
);

// Table roles -> emulator users (the Dart side maps the same roles to
// alice / bob / cara / dave).
const UID = { admin: ALICE, manager: BOB, assignee: CARA, plain: GINA };

const PATH = `families/${FAM_A}/choreOccurrences/tpl_1_20261024`;
const eventPath = (eventId) => `${PATH}/events/${eventId}`;
const T0 = Timestamp.fromDate(new Date('2026-10-20T10:00:00.000Z'));

const NO_STEPS = { subtasks: [], requiredCount: 0 };

const SEEDS = {
  scheduled: { ...NO_STEPS },
  unassigned: { ...NO_STEPS, assigneeId: null },
  completed_plain: {
    ...NO_STEPS,
    status: 'completed',
    completedAt: T0,
    completedBy: CARA,
  },
  completed_verify: {
    ...NO_STEPS,
    status: 'completed',
    completedAt: T0,
    completedBy: CARA,
    verification: 'required',
  },
};

let testEnv;
const as = (uid) => asUser(testEnv, uid);

/** One write batch: the patch, its `lastEventId` and the event. */
const withEvent = (uid, eventId, patch, event) => {
  const db = as(uid);
  const batch = writeBatch(db);
  batch.update(doc(db, PATH), {
    lastEventId: eventId,
    ...patch,
    updatedAt: nowTs(),
    updatedBy: uid,
  });
  batch.set(doc(db, eventPath(eventId)), occurrenceEventDoc(uid, event));
  return batch.commit();
};

/** The write for [step]; `current` is the assignee before the step. */
const perform = (step, i, current) => {
  const uid = UID[step.actor];
  const eventId = `${step.action}_${i}`;
  switch (step.action) {
    case 'skip':
      return withEvent(
        uid,
        eventId,
        { status: 'skipped', skipReason: 'absence' },
        { type: 'skipped', reason: 'অসুস্থ' },
      );
    case 'unskip':
      return withEvent(
        uid,
        eventId,
        { status: 'scheduled', skipReason: null },
        { type: 'unskipped' },
      );
    case 'reassign': {
      const to = UID[step.to ?? 'plain'];
      return withEvent(
        uid,
        eventId,
        { assigneeId: to, assignmentSource: 'reassign' },
        {
          type: 'reassigned',
          reason: 'ছুটিতে',
          fromAssigneeId: current,
          toAssigneeId: to,
        },
      );
    }
    case 'verify':
      return withEvent(
        uid,
        eventId,
        { status: 'verified', verifiedAt: nowTs(), verifiedBy: uid },
        { type: 'verified' },
      );
    case 'uncomplete':
      return withEvent(
        uid,
        eventId,
        {
          status: 'in_progress',
          completedAt: deleteField(),
          completedBy: deleteField(),
        },
        { type: 'uncompleted' },
      );
    case 'complete':
      return updateDoc(doc(as(uid), PATH), {
        status: 'completed',
        completedAt: nowTs(),
        completedBy: uid,
        updatedAt: nowTs(),
        updatedBy: uid,
      });
    default:
      throw new Error(`unknown action ${step.action}`);
  }
};

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
    await setDoc(
      doc(ctx.firestore(), `families/${FAM_A}/members/${GINA}`),
      memberDoc(GINA, 'member', 'active'),
    );
  });
});

describe('P-03 transition table (shared with the Dart use-case test)', () => {
  for (const c of table.cases) {
    it(c.name, async () => {
      const seed = SEEDS[c.seed];
      assertTableSeed(c.seed, seed);
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), PATH), occurrenceDoc(ALICE, seed));
        if (c.seed === 'completed_verify') {
          await setDoc(
            doc(ctx.firestore(), `families/${FAM_A}/settings/permissions`),
            permissionsDoc(ALICE, { choreVerificationEnabled: true }),
          );
        }
      });

      let current = 'assigneeId' in seed ? seed.assigneeId : CARA;
      for (const [i, step] of c.steps.entries()) {
        const write = perform(step, i + 1, current);
        if (step.expect === 'allow') {
          await assertSucceeds(write);
          if (step.action === 'reassign') current = UID[step.to ?? 'plain'];
        } else {
          await assertFails(write);
        }
      }
    });
  }
});

function assertTableSeed(name, seed) {
  if (!seed) throw new Error(`the table names an unknown seed "${name}"`);
}
