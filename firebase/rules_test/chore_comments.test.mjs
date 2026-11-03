// Firestore rules for choreOccurrences/{id}/comments (P3-25) and the
// attention marker on the occurrence (rule 9).
//
// Run: npm run test:emulator (from firebase/rules_test).

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
  writeBatch,
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
  commentDoc,
  memberDoc,
  nowTs,
  occurrenceDoc,
  seedWorld,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');
let testEnv;

const GINA = 'gina'; // active plain member, NOT the assignee (CARA is)
const OCC = 'tpl_1_20261024';
const as = (uid) => asUser(testEnv, uid);
const occPath = `families/${FAM_A}/choreOccurrences/${OCC}`;
const cPath = (id = 'c1') => `${occPath}/comments/${id}`;

const seedOccurrence = (extra = {}) =>
  testEnv.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), occPath), occurrenceDoc(ALICE, extra)),
  );
const seedComment = (extra = {}, id = 'c1', author = GINA) =>
  testEnv.withSecurityRulesDisabled((ctx) =>
    setDoc(doc(ctx.firestore(), cPath(id)), commentDoc(author, extra)),
  );

const change = (uid, patch, id = 'c1') =>
  updateDoc(doc(as(uid), cPath(id)), {
    ...patch,
    updatedAt: nowTs(),
    updatedBy: uid,
  });
const occurrenceUpdate = (uid, patch) =>
  updateDoc(doc(as(uid), occPath), {
    ...patch,
    updatedAt: nowTs(),
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
  await testEnv.withSecurityRulesDisabled((ctx) =>
    setDoc(
      doc(ctx.firestore(), `families/${FAM_A}/members/${GINA}`),
      memberDoc(GINA, 'member', 'active'),
    ),
  );
  await seedOccurrence();
});

describe('comments — read and create', () => {
  it('lets an active member read a comment', async () => {
    await seedComment();
    await assertSucceeds(getDoc(doc(as(GINA), cPath())));
  });
  it('denies a pending member and another family reading', async () => {
    await seedComment();
    await assertFails(getDoc(doc(as(DAVE), cPath())));
    await assertFails(getDoc(doc(as(ERIN), cPath())));
  });

  it('lets any active member comment as themselves', async () => {
    await assertSucceeds(setDoc(doc(as(GINA), cPath()), commentDoc(GINA)));
  });
  it('lets a flag and its occurrence marker land in one batch', async () => {
    const db = as(GINA);
    const batch = writeBatch(db);
    batch.set(doc(db, cPath()), commentDoc(GINA, { needsAttention: true }));
    batch.update(doc(db, occPath), {
      needsAttention: true,
      lastCommentAt: nowTs(),
      updatedAt: nowTs(),
      updatedBy: GINA,
    });
    await assertSucceeds(batch.commit());
  });
  it('denies a forged author or createdBy', async () => {
    await assertFails(
      setDoc(doc(as(GINA), cPath()), commentDoc(GINA, { authorId: CARA })),
    );
    await assertFails(setDoc(doc(as(GINA), cPath()), commentDoc(CARA)));
  });
  it('denies a pending member and another family writing', async () => {
    await assertFails(setDoc(doc(as(DAVE), cPath()), commentDoc(DAVE)));
    await assertFails(setDoc(doc(as(ERIN), cPath()), commentDoc(ERIN)));
  });
  it('denies a created comment that is already hidden or resolved', async () => {
    await assertFails(
      setDoc(doc(as(GINA), cPath()), commentDoc(GINA, { hidden: true })),
    );
    await assertFails(
      setDoc(
        doc(as(GINA), cPath('c2')),
        commentDoc(GINA, { resolvedAt: nowTs(), resolvedBy: GINA }),
      ),
    );
  });
  it('denies an empty or over-long text and an unknown field', async () => {
    await assertFails(
      setDoc(doc(as(GINA), cPath()), commentDoc(GINA, { text: '' })),
    );
    await assertFails(
      setDoc(
        doc(as(GINA), cPath('c2')),
        commentDoc(GINA, { text: 'x'.repeat(1001) }),
      ),
    );
    await assertFails(
      setDoc(doc(as(GINA), cPath('c3')), commentDoc(GINA, { extra: 1 })),
    );
  });
  it('denies a comment on a chore that does not exist', async () => {
    await assertFails(
      setDoc(
        doc(as(GINA), `families/${FAM_A}/choreOccurrences/nope_20261024/comments/c1`),
        commentDoc(GINA),
      ),
    );
  });
});

describe('comments — resolve', () => {
  beforeEach(() => seedComment({ needsAttention: true }));

  it('lets the assignee resolve a flag', async () => {
    await assertSucceeds(change(CARA, { resolvedAt: nowTs(), resolvedBy: CARA }));
  });
  it('lets a manager resolve a flag', async () => {
    await assertSucceeds(change(BOB, { resolvedAt: nowTs(), resolvedBy: BOB }));
  });
  it('denies a plain member who may not act on the chore', async () => {
    await assertFails(change(GINA, { resolvedAt: nowTs(), resolvedBy: GINA }));
  });
  it('denies resolving in somebody else’s name', async () => {
    await assertFails(change(CARA, { resolvedAt: nowTs(), resolvedBy: BOB }));
  });
  it('denies resolving a comment that is not a flag', async () => {
    await seedComment({}, 'c2');
    await assertFails(
      change(CARA, { resolvedAt: nowTs(), resolvedBy: CARA }, 'c2'),
    );
  });
  it('denies editing the text or the author', async () => {
    await assertFails(change(GINA, { text: 'changed' }));
    await assertFails(change(CARA, { authorId: CARA }));
  });
});

describe('comments — hide and show again', () => {
  beforeEach(() => seedComment());

  it('lets a manager hide with a note', async () => {
    await assertSucceeds(
      change(BOB, { hidden: true, hiddenBy: BOB, hiddenNote: 'Not kind' }),
    );
  });
  it('denies a member hiding, and a note shorter than 3', async () => {
    await assertFails(
      change(CARA, { hidden: true, hiddenBy: CARA, hiddenNote: 'Not kind' }),
    );
    await assertFails(
      change(BOB, { hidden: true, hiddenBy: BOB, hiddenNote: 'no' }),
    );
  });
  it('denies hiding in somebody else’s name', async () => {
    await assertFails(
      change(BOB, { hidden: true, hiddenBy: ALICE, hiddenNote: 'Not kind' }),
    );
  });
  it('lets a manager show a hidden comment again, clearing the note', async () => {
    await seedComment(
      { hidden: true, hiddenBy: BOB, hiddenNote: 'Not kind' },
      'c2',
    );
    await assertSucceeds(
      change(ALICE, { hidden: false, hiddenBy: null, hiddenNote: null }, 'c2'),
    );
  });
  it('denies a member showing a hidden comment again', async () => {
    await seedComment(
      { hidden: true, hiddenBy: BOB, hiddenNote: 'Not kind' },
      'c2',
    );
    await assertFails(
      change(CARA, { hidden: false, hiddenBy: null, hiddenNote: null }, 'c2'),
    );
  });
  it('never deletes a comment', async () => {
    await assertFails(deleteDoc(doc(as(ALICE), cPath())));
  });
});

describe('choreOccurrences — attention marker (rule 9)', () => {
  it('lets any active member record a comment instant', async () => {
    await assertSucceeds(occurrenceUpdate(GINA, { lastCommentAt: nowTs() }));
  });
  it('lets any active member raise the flag', async () => {
    await assertSucceeds(
      occurrenceUpdate(GINA, { needsAttention: true, lastCommentAt: nowTs() }),
    );
  });
  it('lets the assignee or a manager clear the flag', async () => {
    await seedOccurrence({ needsAttention: true });
    await assertSucceeds(occurrenceUpdate(CARA, { needsAttention: false }));
    await seedOccurrence({ needsAttention: true });
    await assertSucceeds(occurrenceUpdate(BOB, { needsAttention: false }));
  });
  it('denies a plain member clearing the flag', async () => {
    await seedOccurrence({ needsAttention: true });
    await assertFails(occurrenceUpdate(GINA, { needsAttention: false }));
  });
  it('denies a pending member touching the marker', async () => {
    await assertFails(occurrenceUpdate(DAVE, { lastCommentAt: nowTs() }));
  });
  it('denies any other field riding along', async () => {
    await assertFails(
      occurrenceUpdate(GINA, { lastCommentAt: nowTs(), status: 'completed' }),
    );
  });
});
