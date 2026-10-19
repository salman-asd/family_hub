// Firestore Security Rules tests (roadmap Step 10, item 4).
//
// "For every rule, one allowed and one denied case."  The four cases the
// roadmap names explicitly are marked with [roadmap].
//
//   firebase/rules_test> npm install
//   (repo root)> npx firebase emulators:exec --only firestore \
//                  --project demo-family-hub "npm --prefix firebase/rules_test test"
//
// The emulator needs a JDK (11+); `firebase emulators:exec` finds it through
// JAVA_HOME or PATH.

import { strict as assert } from 'node:assert';
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
  updateDoc,
  writeBatch,
} from 'firebase/firestore';
import { after, afterEach, before, beforeEach, describe, it } from 'mocha';

import {
  ALICE,
  BOB,
  CARA,
  CODES,
  DAVE,
  EMULATOR,
  ERIN,
  FAM_A,
  FRANK,
  PROJECT_ID,
  baseDoc,
  eventDoc,
  familyDoc,
  futureTs,
  invitationUsed,
  inviteCodeDoc,
  invitationRevoked,
  memberCancel,
  memberChange,
  memberLeave,
  memberDoc,
  nowTs,
  seedWorld,
} from './support.mjs';

const [host, port] = EMULATOR.split(':');

let testEnv;

/** Firestore as a signed-in user. */
const as = (uid) => testEnv.authenticatedContext(uid).firestore();

/** Firestore with no credentials at all. */
const anonymous = () => testEnv.unauthenticatedContext().firestore();

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

// ─────────────────────────────────────────────────────────────────────────────
// users/{uid}
// ─────────────────────────────────────────────────────────────────────────────
describe('users/{uid}', () => {
  it('allows the owner to read their own document', async () => {
    const db = as(ALICE);
    await assertSucceeds(getDoc(doc(db, `users/${ALICE}`)));
  });

  it('denies reading another user’s document', async () => {
    const db = as(ALICE);
    await assertFails(getDoc(doc(db, `users/${FRANK}`)));
  });

  it('denies an unauthenticated read', async () => {
    const db = anonymous();
    await assertFails(getDoc(doc(db, `users/${ALICE}`)));
  });

  it('allows the owner to merge preferences into their own document', async () => {
    const db = as(FRANK);
    await assertSucceeds(
      setDoc(
        doc(db, `users/${FRANK}`),
        { preferences: { themeId: 'modern', themeMode: 'system', language: 'en', banglaDigits: false } },
        { merge: true },
      ),
    );
  });

  it('allows the owner to set their own familyId', async () => {
    const db = as(FRANK);
    await assertSucceeds(
      setDoc(doc(db, `users/${FRANK}`), { familyId: FAM_A }, { merge: true }),
    );
  });

  it('denies writing another user’s document', async () => {
    const db = as(ALICE);
    await assertFails(
      setDoc(doc(db, `users/${FRANK}`), { fullName: 'Hacked' }, { merge: true }),
    );
  });

  it('denies forging the uid field of your own document', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(doc(db, `users/${FRANK}`), { uid: ALICE }, { merge: true }),
    );
  });

  it('denies forging updatedBy on your own document', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(
        doc(db, `users/${FRANK}`),
        { fullName: 'Frank', updatedBy: ALICE },
        { merge: true },
      ),
    );
  });

  it('denies a preference value outside the closed set', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(
        doc(db, `users/${FRANK}`),
        { preferences: { language: 'fr' } },
        { merge: true },
      ),
    );
  });

  it('denies deleting your own document', async () => {
    const db = as(ALICE);
    await assertFails(deleteDoc(doc(db, `users/${ALICE}`)));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// inviteCodes/{code} — exact-id get only, never list
// ─────────────────────────────────────────────────────────────────────────────
describe('inviteCodes/{code}', () => {
  it('allows a signed-in user to get a code by exact id', async () => {
    const db = as(FRANK);
    await assertSucceeds(getDoc(doc(db, `inviteCodes/${CODES.live}`)));
  });

  it('denies listing the collection', async () => {
    const db = as(FRANK);
    await assertFails(getDocs(collection(db, 'inviteCodes')));
  });

  it('denies an unauthenticated get', async () => {
    const db = anonymous();
    await assertFails(getDoc(doc(db, `inviteCodes/${CODES.live}`)));
  });

  it('allows an admin to create a code for their own family', async () => {
    const db = as(ALICE);
    await assertSucceeds(
      setDoc(doc(db, 'inviteCodes/NEWCODE1'), inviteCodeDoc(ALICE, FAM_A, 'NEWCODE1')),
    );
  });

  it('allows a moderator to create a code', async () => {
    const db = as(BOB);
    await assertSucceeds(
      setDoc(doc(db, 'inviteCodes/NEWCODE2'), inviteCodeDoc(BOB, FAM_A, 'NEWCODE2')),
    );
  });

  it('denies a plain member creating a code', async () => {
    const db = as(CARA);
    await assertFails(
      setDoc(doc(db, 'inviteCodes/NEWCODE3'), inviteCodeDoc(CARA, FAM_A, 'NEWCODE3')),
    );
  });

  it('denies a pending member creating a code', async () => {
    const db = as(DAVE);
    await assertFails(
      setDoc(doc(db, 'inviteCodes/NEWCODE4'), inviteCodeDoc(DAVE, FAM_A, 'NEWCODE4')),
    );
  });

  it('denies creating a code for a family you do not manage', async () => {
    const db = as(ERIN);
    await assertFails(
      setDoc(doc(db, 'inviteCodes/NEWCODE5'), inviteCodeDoc(ERIN, FAM_A, 'NEWCODE5')),
    );
  });

  it('denies creating a code with an elevated role', async () => {
    const db = as(ALICE);
    await assertFails(
      setDoc(
        doc(db, 'inviteCodes/NEWCODE6'),
        inviteCodeDoc(ALICE, FAM_A, 'NEWCODE6', { role: 'admin' }),
      ),
    );
  });

  it('allows a joiner to mark a live code used, as themselves', async () => {
    const db = as(FRANK);
    await assertSucceeds(
      setDoc(
        doc(db, `inviteCodes/${CODES.live}`),
        { status: 'used', usedBy: FRANK, updatedAt: nowTs(), updatedBy: FRANK },
        { merge: true },
      ),
    );
  });

  it('denies marking a code used on behalf of somebody else', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(
        doc(db, `inviteCodes/${CODES.live}`),
        { status: 'used', usedBy: ALICE, updatedAt: nowTs(), updatedBy: FRANK },
        { merge: true },
      ),
    );
  });

  it('denies marking an expired code used', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(
        doc(db, `inviteCodes/${CODES.expired}`),
        { status: 'used', usedBy: FRANK, updatedAt: nowTs(), updatedBy: FRANK },
        { merge: true },
      ),
    );
  });

  it('denies re-using a code a second time', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(
        doc(db, `inviteCodes/${CODES.used}`),
        { status: 'used', usedBy: FRANK, updatedAt: nowTs(), updatedBy: FRANK },
        { merge: true },
      ),
    );
  });

  it('denies extending a code’s lifetime', async () => {
    const db = as(ALICE);
    await assertFails(
      setDoc(
        doc(db, `inviteCodes/${CODES.live}`),
        { expiresAt: futureTs(), updatedAt: nowTs(), updatedBy: ALICE },
        { merge: true },
      ),
    );
  });

  it('denies deleting a code', async () => {
    const db = as(ALICE);
    await assertFails(deleteDoc(doc(db, `inviteCodes/${CODES.live}`)));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// families/{f}
// ─────────────────────────────────────────────────────────────────────────────
describe('families/{f}', () => {
  it('allows an active member to read the family', async () => {
    const db = as(CARA);
    await assertSucceeds(getDoc(doc(db, `families/${FAM_A}`)));
  });

  it('[roadmap] denies a pending member reading family data', async () => {
    const db = as(DAVE);
    await assertFails(getDoc(doc(db, `families/${FAM_A}`)));
  });

  it('denies a signed-in user with no membership', async () => {
    const db = as(FRANK);
    await assertFails(getDoc(doc(db, `families/${FAM_A}`)));
  });

  it('[roadmap] denies a member of another family reading this family', async () => {
    const db = as(ERIN);
    await assertFails(getDoc(doc(db, `families/${FAM_A}`)));
  });

  it('allows a signed-in user to create their own family', async () => {
    const db = as(FRANK);
    await assertSucceeds(
      setDoc(doc(db, 'families/famC'), familyDoc(FRANK, 'Frank’s family')),
    );
  });

  it('[roadmap] denies creating a family that claims another user as creator', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(doc(db, 'families/famD'), familyDoc(ALICE, 'Forged')),
    );
  });

  it('denies creating a family with an empty name', async () => {
    const db = as(FRANK);
    await assertFails(setDoc(doc(db, 'families/famE'), familyDoc(FRANK, '')));
  });

  it('allows an admin to rename the family', async () => {
    const db = as(ALICE);
    await assertSucceeds(
      updateDoc(doc(db, `families/${FAM_A}`), {
        name: 'Renamed',
        updatedAt: nowTs(),
        updatedBy: ALICE,
      }),
    );
  });

  it('denies a moderator renaming the family (editFamilySettings)', async () => {
    const db = as(BOB);
    await assertFails(
      updateDoc(doc(db, `families/${FAM_A}`), {
        name: 'Renamed',
        updatedAt: nowTs(),
        updatedBy: BOB,
      }),
    );
  });

  it('denies a member renaming the family', async () => {
    const db = as(CARA);
    await assertFails(
      updateDoc(doc(db, `families/${FAM_A}`), {
        name: 'Renamed',
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('denies deleting the family', async () => {
    const db = as(ALICE);
    await assertFails(deleteDoc(doc(db, `families/${FAM_A}`)));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// families/{f}/members/{m}
// ─────────────────────────────────────────────────────────────────────────────
describe('families/{f}/members/{m}', () => {
  it('allows an active member to read the roster', async () => {
    const db = as(CARA);
    await assertSucceeds(getDoc(doc(db, `families/${FAM_A}/members/${ALICE}`)));
  });

  it('allows a pending member to read their own document', async () => {
    const db = as(DAVE);
    await assertSucceeds(getDoc(doc(db, `families/${FAM_A}/members/${DAVE}`)));
  });

  it('denies a pending member reading somebody else’s document', async () => {
    const db = as(DAVE);
    await assertFails(getDoc(doc(db, `families/${FAM_A}/members/${ALICE}`)));
  });

  it('denies an outsider reading a member document', async () => {
    const db = as(FRANK);
    await assertFails(getDoc(doc(db, `families/${FAM_A}/members/${ALICE}`)));
  });

  it('allows the family-creation batch (family, admin member, settings, logs)', async () => {
    const db = as(FRANK);
    const batch = writeBatch(db);
    batch.set(doc(db, 'families/famF'), familyDoc(FRANK, 'New family'));
    batch.set(
      doc(db, `families/famF/members/${FRANK}`),
      memberDoc(FRANK, 'admin', 'active'),
    );
    batch.set(
      doc(db, 'families/famF/settings/general'),
      baseDoc(FRANK, { timezone: 'Asia/Dhaka', currency: 'BDT' }),
    );
    batch.set(doc(db, 'families/famF/settings/modules'), baseDoc(FRANK, { flags: { chores: true, bazar: true } }));
    batch.set(doc(db, 'families/famF/activity/evt1'), eventDoc(FRANK, { refId: 'famF' }));
    batch.set(doc(db, 'families/famF/auditLogs/evt1'), eventDoc(FRANK, { refId: 'famF' }));
    await assertSucceeds(batch.commit());
  });

  it('denies creating yourself as an admin of a family that already exists', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${FRANK}`),
        memberDoc(FRANK, 'admin', 'active'),
      ),
    );
  });

  it('allows joining as a pending member with a live code', async () => {
    const db = as(FRANK);
    await assertSucceeds(
      setDoc(
        doc(db, `families/${FAM_A}/members/${FRANK}`),
        memberDoc(FRANK, 'member', 'pending', { inviteCode: CODES.live }),
      ),
    );
  });

  it('denies joining with an expired code', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${FRANK}`),
        memberDoc(FRANK, 'member', 'pending', { inviteCode: CODES.expired }),
      ),
    );
  });

  it('denies joining with an already-used code', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${FRANK}`),
        memberDoc(FRANK, 'member', 'pending', { inviteCode: CODES.used }),
      ),
    );
  });

  it('denies joining with an invented code', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${FRANK}`),
        memberDoc(FRANK, 'member', 'pending', { inviteCode: 'ZZZZZZZZ' }),
      ),
    );
  });

  it('denies joining straight in as an active member', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${FRANK}`),
        memberDoc(FRANK, 'member', 'active', { inviteCode: CODES.live }),
      ),
    );
  });

  it('denies joining with an elevated role', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${FRANK}`),
        memberDoc(FRANK, 'moderator', 'pending', { inviteCode: CODES.live }),
      ),
    );
  });

  it('denies joining on behalf of somebody else', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${ERIN}`),
        memberDoc(ERIN, 'member', 'pending', { inviteCode: CODES.live }),
      ),
    );
  });

  it('[roadmap] denies a member promoting themselves to admin', async () => {
    const db = as(CARA);
    await assertFails(
      updateDoc(doc(db, `families/${FAM_A}/members/${CARA}`), {
        role: 'admin',
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('[roadmap] denies a pending member approving themselves', async () => {
    const db = as(DAVE);
    await assertFails(
      updateDoc(doc(db, `families/${FAM_A}/members/${DAVE}`), {
        status: 'active',
        updatedAt: nowTs(),
        updatedBy: DAVE,
      }),
    );
  });

  it('denies a moderator changing somebody else’s role', async () => {
    const db = as(BOB);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${CARA}`),
        memberChange(BOB, { role: 'moderator', status: 'active' }),
        { merge: true },
      ),
    );
  });

  it('denies a moderator disabling an active member', async () => {
    const db = as(BOB);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${CARA}`),
        memberChange(BOB, { role: 'member', status: 'disabled' }),
        { merge: true },
      ),
    );
  });

  it('allows a moderator to approve a pending request', async () => {
    const db = as(BOB);
    await assertSucceeds(
      setDoc(
        doc(db, `families/${FAM_A}/members/${DAVE}`),
        memberChange(BOB, { role: 'member', status: 'active' }),
        { merge: true },
      ),
    );
  });

  it('allows a moderator to reject a pending request', async () => {
    const db = as(BOB);
    await assertSucceeds(
      setDoc(
        doc(db, `families/${FAM_A}/members/${DAVE}`),
        memberChange(BOB, { role: 'member', status: 'pending', removedAt: nowTs() }),
        { merge: true },
      ),
    );
  });

  it('denies a moderator approving with a forged updatedBy', async () => {
    const db = as(BOB);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${DAVE}`),
        {
          role: 'member',
          status: 'active',
          removedAt: null,
          updatedAt: nowTs(),
          updatedBy: ALICE,
        },
        { merge: true },
      ),
    );
  });

  it('allows an admin to change a role', async () => {
    const db = as(ALICE);
    await assertSucceeds(
      setDoc(
        doc(db, `families/${FAM_A}/members/${CARA}`),
        memberChange(ALICE, { role: 'moderator', status: 'active' }),
        { merge: true },
      ),
    );
  });

  it('allows an admin to disable a member', async () => {
    const db = as(ALICE);
    await assertSucceeds(
      setDoc(
        doc(db, `families/${FAM_A}/members/${CARA}`),
        memberChange(ALICE, { role: 'member', status: 'disabled' }),
        { merge: true },
      ),
    );
  });

  it('denies an admin writing an unknown role', async () => {
    const db = as(ALICE);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${CARA}`),
        memberChange(ALICE, { role: 'owner', status: 'active' }),
        { merge: true },
      ),
    );
  });

  it('allows a member to edit their own profile fields', async () => {
    const db = as(CARA);
    await assertSucceeds(
      updateDoc(doc(db, `families/${FAM_A}/members/${CARA}`), {
        fullName: 'Cara Begum',
        nickname: 'Cara',
        relationship: 'daughter',
        spouseId: null,
        avatarKey: 'avatar-3',
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('denies a member editing somebody else’s profile', async () => {
    const db = as(CARA);
    await assertFails(
      updateDoc(doc(db, `families/${FAM_A}/members/${BOB}`), {
        fullName: 'Cara Begum',
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('denies a self-edit that smuggles in a role change', async () => {
    const db = as(CARA);
    await assertFails(
      updateDoc(doc(db, `families/${FAM_A}/members/${CARA}`), {
        fullName: 'Cara Begum',
        role: 'admin',
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('denies a pending member editing their own role', async () => {
    const db = as(DAVE);
    await assertFails(
      updateDoc(doc(db, `families/${FAM_A}/members/${DAVE}`), {
        fullName: 'Dave',
        role: 'moderator',
        updatedAt: nowTs(),
        updatedBy: DAVE,
      }),
    );
  });

  it('allows a rejected person to ask again with a fresh code', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(
        doc(db, `families/${FAM_A}/members/${ERIN}`),
        memberDoc(ERIN, 'member', 'pending', { removedAt: nowTs() }),
      );
    });
    const db = as(ERIN);
    await assertSucceeds(
      setDoc(
        doc(db, `families/${FAM_A}/members/${ERIN}`),
        memberDoc(ERIN, 'member', 'pending', { inviteCode: CODES.live }),
        { merge: true },
      ),
    );
  });

  it('denies a plain self-write that is not a rejoin', async () => {
    const db = as(CARA);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${CARA}`),
        memberDoc(CARA, 'member', 'pending', { inviteCode: CODES.live }),
        { merge: true },
      ),
    );
  });

  it('denies hard-deleting a member', async () => {
    const db = as(ALICE);
    await assertFails(deleteDoc(doc(db, `families/${FAM_A}/members/${CARA}`)));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// families/{f}/invitations/{i}
// ─────────────────────────────────────────────────────────────────────────────
describe('families/{f}/invitations/{i}', () => {
  it('allows a manager to read the invitations', async () => {
    const db = as(BOB);
    await assertSucceeds(
      getDoc(doc(db, `families/${FAM_A}/invitations/${CODES.live}`)),
    );
  });

  it('denies a plain member reading the invitations', async () => {
    const db = as(CARA);
    await assertFails(
      getDoc(doc(db, `families/${FAM_A}/invitations/${CODES.live}`)),
    );
  });

  it('denies a pending member reading the invitations', async () => {
    const db = as(DAVE);
    await assertFails(
      getDoc(doc(db, `families/${FAM_A}/invitations/${CODES.live}`)),
    );
  });

  it('allows a manager to create the mirror of a code', async () => {
    const db = as(ALICE);
    await assertSucceeds(
      setDoc(
        doc(db, `families/${FAM_A}/invitations/NEWCODE1`),
        inviteCodeDoc(ALICE, FAM_A, 'NEWCODE1'),
      ),
    );
  });

  it('denies a plain member creating an invitation', async () => {
    const db = as(CARA);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/invitations/NEWCODE2`),
        inviteCodeDoc(CARA, FAM_A, 'NEWCODE2'),
      ),
    );
  });

  it('allows the family-creation batch to write the mirror', async () => {
    const db = as(FRANK);
    const batch = writeBatch(db);
    batch.set(doc(db, 'families/famG'), familyDoc(FRANK, 'G'));
    batch.set(
      doc(db, `families/famG/members/${FRANK}`),
      memberDoc(FRANK, 'admin', 'active'),
    );
    batch.set(
      doc(db, 'families/famG/invitations/CODE0001'),
      inviteCodeDoc(FRANK, 'famG', 'CODE0001'),
    );
    await assertSucceeds(batch.commit());
  });

  it('allows a joiner to mark the mirror used, as themselves', async () => {
    const db = as(FRANK);
    await assertSucceeds(
      setDoc(
        doc(db, `families/${FAM_A}/invitations/${CODES.live}`),
        invitationUsed(FRANK),
        { merge: true },
      ),
    );
  });

  it('denies a joiner marking the mirror used for somebody else', async () => {
    const db = as(FRANK);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/invitations/${CODES.live}`),
        invitationUsed(ALICE),
        { merge: true },
      ),
    );
  });

  it('denies deleting an invitation', async () => {
    const db = as(ALICE);
    await assertFails(
      deleteDoc(doc(db, `families/${FAM_A}/invitations/${CODES.live}`)),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// families/{f}/settings/{s}
// ─────────────────────────────────────────────────────────────────────────────
describe('families/{f}/settings/{s}', () => {
  it('allows an active member to read the settings', async () => {
    const db = as(CARA);
    await assertSucceeds(
      getDoc(doc(db, `families/${FAM_A}/settings/general`)),
    );
  });

  it('denies a pending member reading the settings', async () => {
    const db = as(DAVE);
    await assertFails(getDoc(doc(db, `families/${FAM_A}/settings/general`)));
  });

  it('allows an admin to update the settings', async () => {
    const db = as(ALICE);
    await assertSucceeds(
      updateDoc(doc(db, `families/${FAM_A}/settings/general`), {
        timezone: 'Asia/Dhaka',
        currency: 'BDT',
        updatedAt: nowTs(),
        updatedBy: ALICE,
      }),
    );
  });

  it('denies a moderator updating the settings', async () => {
    const db = as(BOB);
    await assertFails(
      updateDoc(doc(db, `families/${FAM_A}/settings/general`), {
        currency: 'USD',
        updatedAt: nowTs(),
        updatedBy: BOB,
      }),
    );
  });

  it('denies a member updating the settings', async () => {
    const db = as(CARA);
    await assertFails(
      updateDoc(doc(db, `families/${FAM_A}/settings/general`), {
        currency: 'USD',
        updatedAt: nowTs(),
        updatedBy: CARA,
      }),
    );
  });

  it('denies deleting a settings document', async () => {
    const db = as(ALICE);
    await assertFails(
      deleteDoc(doc(db, `families/${FAM_A}/settings/general`)),
    );
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// families/{f}/activity and families/{f}/auditLogs — append-only
// ─────────────────────────────────────────────────────────────────────────────
describe('activity and auditLogs', () => {
  it('allows an active member to read activity', async () => {
    const db = as(CARA);
    await assertSucceeds(
      getDoc(doc(db, `families/${FAM_A}/activity/evt1`)),
    );
  });

  it('denies a pending member reading activity', async () => {
    const db = as(DAVE);
    await assertFails(getDoc(doc(db, `families/${FAM_A}/activity/evt1`)));
  });

  it('allows an active member to append an activity entry', async () => {
    const db = as(CARA);
    await assertSucceeds(
      setDoc(doc(db, `families/${FAM_A}/activity/evt2`), eventDoc(CARA)),
    );
  });

  it('denies appending an activity entry with a forged createdBy', async () => {
    const db = as(CARA);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/activity/evt3`),
        eventDoc(ALICE),
      ),
    );
  });

  it('denies an outsider appending an activity entry', async () => {
    const db = as(ERIN);
    await assertFails(
      setDoc(doc(db, `families/${FAM_A}/activity/evt4`), eventDoc(ERIN)),
    );
  });

  it('allows the log entries written while joining', async () => {
    const db = as(FRANK);
    const batch = writeBatch(db);
    batch.set(
      doc(db, `families/${FAM_A}/members/${FRANK}`),
      memberDoc(FRANK, 'member', 'pending', { inviteCode: CODES.live }),
    );
    batch.set(doc(db, `families/${FAM_A}/activity/evt5`), eventDoc(FRANK));
    batch.set(doc(db, `families/${FAM_A}/auditLogs/evt5`), eventDoc(FRANK));
    await assertSucceeds(batch.commit());
  });

  it('allows an admin to read audit logs', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), `families/${FAM_A}/auditLogs/evt9`),
        eventDoc(ALICE),
      );
    });
    const db = as(ALICE);
    await assertSucceeds(getDoc(doc(db, `families/${FAM_A}/auditLogs/evt9`)));
  });

  it('denies a moderator reading audit logs', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), `families/${FAM_A}/auditLogs/evt9`),
        eventDoc(ALICE),
      );
    });
    const db = as(BOB);
    await assertFails(getDoc(doc(db, `families/${FAM_A}/auditLogs/evt9`)));
  });

  it('denies updating an activity entry', async () => {
    const db = as(ALICE);
    await assertFails(
      updateDoc(doc(db, `families/${FAM_A}/activity/evt1`), {
        summary: 'Rewritten history',
      }),
    );
  });

  it('denies deleting an activity entry', async () => {
    const db = as(ALICE);
    await assertFails(deleteDoc(doc(db, `families/${FAM_A}/activity/evt1`)));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Financial and chore data: not open yet, and never hard-deleted
// ─────────────────────────────────────────────────────────────────────────────
describe('financial and chore data', () => {
  it('denies an admin reading an expense (not opened until Step 13)', async () => {
    const db = as(ALICE);
    await assertFails(getDoc(doc(db, `families/${FAM_A}/expenses/e1`)));
  });

  it('denies an admin writing a chore occurrence (not opened until Step 22)', async () => {
    const db = as(ALICE);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/choreOccurrences/occ1`),
        baseDoc(ALICE, { status: 'scheduled' }),
      ),
    );
  });

  it('denies hard-deleting a budget document', async () => {
    const db = as(ALICE);
    await assertFails(deleteDoc(doc(db, `families/${FAM_A}/budgets/2026-10`)));
  });

  it('denies reading another family’s financial data', async () => {
    const db = as(ERIN);
    await assertFails(getDoc(doc(db, `families/${FAM_A}/expenses/e1`)));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Unauthenticated access
// ─────────────────────────────────────────────────────────────────────────────
describe('unauthenticated access', () => {
  it('denies reading a family', async () => {
    const db = anonymous();
    await assertFails(getDoc(doc(db, `families/${FAM_A}`)));
  });

  it('denies writing a member document', async () => {
    const db = anonymous();
    await assertFails(
      setDoc(doc(db, `families/${FAM_A}/members/${FRANK}`), memberDoc(FRANK, 'member', 'pending')),
    );
  });

  it('denies reading activity', async () => {
    const db = anonymous();
    await assertFails(getDoc(doc(db, `families/${FAM_A}/activity/evt1`)));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// The end-to-end Phase 1 scenario, as a rules test
// ─────────────────────────────────────────────────────────────────────────────
describe('Phase 1 acceptance scenario', () => {
  it('A creates a family, invites B, B joins pending, A approves, B reads the family', async () => {
    const a = as(ALICE);

    // A creates a fresh family with its settings, logs and first member.
    const created = writeBatch(a);
    created.set(doc(a, 'families/famZ'), familyDoc(ALICE, 'Z family'));
    created.set(
      doc(a, `families/famZ/members/${ALICE}`),
      memberDoc(ALICE, 'admin', 'active'),
    );
    created.set(
      doc(a, 'families/famZ/settings/modules'),
      baseDoc(ALICE, { flags: { chores: true, bazar: true } }),
    );
    created.set(doc(a, 'families/famZ/activity/evt1'), eventDoc(ALICE, { refId: 'famZ' }));
    created.set(doc(a, 'families/famZ/auditLogs/evt1'), eventDoc(ALICE, { refId: 'famZ' }));
    await assertSucceeds(created.commit());

    // A invites B.
    const invite = writeBatch(a);
    invite.set(
      doc(a, 'inviteCodes/INVITE01'),
      inviteCodeDoc(ALICE, 'famZ', 'INVITE01'),
    );
    invite.set(
      doc(a, 'families/famZ/invitations/INVITE01'),
      inviteCodeDoc(ALICE, 'famZ', 'INVITE01'),
    );
    await assertSucceeds(invite.commit());

    // B reads the code by exact id and joins as pending, marking the code used.
    const b = as(BOB);
    const found = await assertSucceeds(getDoc(doc(b, 'inviteCodes/INVITE01')));
    assert.equal(found.data().familyId, 'famZ');

    const join = writeBatch(b);
    join.set(
      doc(b, `families/famZ/members/${BOB}`),
      memberDoc(BOB, 'member', 'pending', { inviteCode: 'INVITE01' }),
    );
    join.set(doc(b, `families/famZ/activity/evt2`), eventDoc(BOB, { refId: 'famZ' }));
    join.set(doc(b, `families/famZ/auditLogs/evt2`), eventDoc(BOB, { refId: 'famZ' }));
    join.set(
      doc(b, 'inviteCodes/INVITE01'),
      { status: 'used', usedBy: BOB, updatedAt: nowTs(), updatedBy: BOB },
      { merge: true },
    );
    join.set(
      doc(b, 'families/famZ/invitations/INVITE01'),
      { status: 'used', usedBy: BOB, updatedAt: nowTs(), updatedBy: BOB },
      { merge: true },
    );
    await assertSucceeds(join.commit());

    // B still cannot read the family while pending.
    await assertFails(getDoc(doc(b, 'families/famZ')));

    // A approves B.
    await assertSucceeds(
      setDoc(
        doc(a, `families/famZ/members/${BOB}`),
        memberChange(ALICE, { role: 'member', status: 'active' }),
        { merge: true },
      ),
    );

    // B now reads the family.
    await assertSucceeds(getDoc(doc(b, 'families/famZ')));
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Hardening H4: membership lifecycle (leave, cancel, revoke, one family)
// ─────────────────────────────────────────────────────────────────────────────
describe('H4 leave family', () => {
  it('allows an active member to leave (status disabled + leftAt/removedAt)', async () => {
    const db = as(CARA);
    await assertSucceeds(
      setDoc(
        doc(db, `families/${FAM_A}/members/${CARA}`),
        memberLeave(CARA, 'member'),
        { merge: true },
      ),
    );
  });

  it('allows the leave batch with its activity entry', async () => {
    const db = as(CARA);
    const b = writeBatch(db);
    b.set(
      doc(db, `families/${FAM_A}/members/${CARA}`),
      memberLeave(CARA, 'member'),
      { merge: true },
    );
    b.set(doc(db, `families/${FAM_A}/activity/left1`), eventDoc(CARA));
    b.set(doc(db, `families/${FAM_A}/auditLogs/left1`), eventDoc(CARA));
    await assertSucceeds(b.commit());
  });

  it('denies leaving on behalf of somebody else', async () => {
    const db = as(CARA);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${BOB}`),
        memberLeave(CARA, 'moderator'),
        { merge: true },
      ),
    );
  });

  it('denies a leave that also changes the role', async () => {
    const db = as(CARA);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${CARA}`),
        memberLeave(CARA, 'admin'),
        { merge: true },
      ),
    );
  });

  it('denies a leave without leftAt', async () => {
    const db = as(CARA);
    const { leftAt, ...noLeftAt } = memberLeave(CARA, 'member');
    await assertFails(
      setDoc(doc(db, `families/${FAM_A}/members/${CARA}`), noLeftAt, { merge: true }),
    );
  });

  it('denies a pending person using the leave path', async () => {
    const db = as(DAVE);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${DAVE}`),
        memberLeave(DAVE, 'member'),
        { merge: true },
      ),
    );
  });
});

describe('H4 cancel join request', () => {
  it('allows a pending person to cancel their own request', async () => {
    const db = as(DAVE);
    await assertSucceeds(
      setDoc(
        doc(db, `families/${FAM_A}/members/${DAVE}`),
        memberCancel(DAVE, 'member'),
        { merge: true },
      ),
    );
  });

  it('allows the cancel batch with its activity entry', async () => {
    const db = as(DAVE);
    const b = writeBatch(db);
    b.set(
      doc(db, `families/${FAM_A}/members/${DAVE}`),
      memberCancel(DAVE, 'member'),
      { merge: true },
    );
    b.set(doc(db, `families/${FAM_A}/activity/cancel1`), eventDoc(DAVE));
    b.set(doc(db, `families/${FAM_A}/auditLogs/cancel1`), eventDoc(DAVE));
    await assertSucceeds(b.commit());
  });

  it('denies cancelling somebody else’s request', async () => {
    const db = as(CARA);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${DAVE}`),
        memberCancel(CARA, 'member'),
        { merge: true },
      ),
    );
  });

  it('denies an ACTIVE member using the cancel path (status stays active)', async () => {
    const db = as(CARA);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${CARA}`),
        memberCancel(CARA, 'member', 'active'),
        { merge: true },
      ),
    );
  });

  it('denies a cancel that approves the request at the same time', async () => {
    const db = as(DAVE);
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/members/${DAVE}`),
        memberCancel(DAVE, 'member', 'active'),
        { merge: true },
      ),
    );
  });
});

describe('H4 revoke invitation', () => {
  it('allows a manager to revoke an active code (both documents)', async () => {
    const db = as(BOB);
    const b = writeBatch(db);
    b.set(doc(db, `inviteCodes/${CODES.live}`), invitationRevoked(BOB), { merge: true });
    b.set(
      doc(db, `families/${FAM_A}/invitations/${CODES.live}`),
      invitationRevoked(BOB),
      { merge: true },
    );
    b.set(doc(db, `families/${FAM_A}/activity/rev1`), eventDoc(BOB));
    b.set(doc(db, `families/${FAM_A}/auditLogs/rev1`), eventDoc(BOB));
    await assertSucceeds(b.commit());
  });

  it('denies a plain member revoking a code', async () => {
    const db = as(CARA);
    await assertFails(
      setDoc(doc(db, `inviteCodes/${CODES.live}`), invitationRevoked(CARA), { merge: true }),
    );
    await assertFails(
      setDoc(
        doc(db, `families/${FAM_A}/invitations/${CODES.live}`),
        invitationRevoked(CARA),
        { merge: true },
      ),
    );
  });

  it('denies a manager of ANOTHER family revoking this family’s code', async () => {
    const db = as(ERIN);
    await assertFails(
      setDoc(doc(db, `inviteCodes/${CODES.live}`), invitationRevoked(ERIN), { merge: true }),
    );
  });

  it('denies revoking a code that was already used', async () => {
    const db = as(ALICE);
    await assertFails(
      setDoc(doc(db, `inviteCodes/${CODES.used}`), invitationRevoked(ALICE), { merge: true }),
    );
  });

  it('denies a revoke that also extends the expiry', async () => {
    const db = as(ALICE);
    await assertFails(
      setDoc(
        doc(db, `inviteCodes/${CODES.live}`),
        { ...invitationRevoked(ALICE), expiresAt: nowTs() },
        { merge: true },
      ),
    );
  });

  it('denies a revoke with a forged updatedBy', async () => {
    const db = as(ALICE);
    await assertFails(
      setDoc(
        doc(db, `inviteCodes/${CODES.live}`),
        { ...invitationRevoked(ALICE), updatedBy: BOB },
        { merge: true },
      ),
    );
  });
});

describe('H4 one family per user (users/{uid}.familyId)', () => {
  it('allows keeping the same familyId', async () => {
    const db = as(ALICE);
    await assertSucceeds(
      setDoc(doc(db, `users/${ALICE}`), { familyId: FAM_A }, { merge: true }),
    );
  });

  it('denies pointing an ACTIVE member at another family', async () => {
    const db = as(ALICE);
    await assertFails(
      setDoc(doc(db, `users/${ALICE}`), { familyId: 'famB' }, { merge: true }),
    );
  });

  it('denies a PENDING member moving to another family', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), `users/${DAVE}`), {
        uid: DAVE,
        fullName: 'Dave',
        relationship: 'other',
        familyId: FAM_A,
        ...baseDoc(DAVE),
      });
    });
    const db = as(DAVE);
    await assertFails(
      setDoc(doc(db, `users/${DAVE}`), { familyId: 'famB' }, { merge: true }),
    );
  });

  it('denies an admin-DISABLED member moving to another family', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(
        doc(db, `families/${FAM_A}/members/${CARA}`),
        memberDoc(CARA, 'member', 'disabled'),
      );
      await setDoc(doc(db, `users/${CARA}`), {
        uid: CARA,
        fullName: 'Cara',
        relationship: 'other',
        familyId: FAM_A,
        ...baseDoc(CARA),
      });
    });
    const db = as(CARA);
    await assertFails(
      setDoc(doc(db, `users/${CARA}`), { familyId: 'famB' }, { merge: true }),
    );
  });

  it('allows moving on after LEAVING the old family', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(
        doc(db, `families/${FAM_A}/members/${CARA}`),
        memberDoc(CARA, 'member', 'disabled', { removedAt: nowTs(), leftAt: nowTs() }),
      );
      await setDoc(doc(db, `users/${CARA}`), {
        uid: CARA,
        fullName: 'Cara',
        relationship: 'other',
        familyId: FAM_A,
        ...baseDoc(CARA),
      });
    });
    const db = as(CARA);
    await assertSucceeds(
      setDoc(doc(db, `users/${CARA}`), { familyId: 'famB' }, { merge: true }),
    );
  });

  it('allows moving on after a CANCELLED / rejected request', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(
        doc(db, `families/${FAM_A}/members/${DAVE}`),
        memberDoc(DAVE, 'member', 'pending', { removedAt: nowTs() }),
      );
      await setDoc(doc(db, `users/${DAVE}`), {
        uid: DAVE,
        fullName: 'Dave',
        relationship: 'other',
        familyId: FAM_A,
        ...baseDoc(DAVE),
      });
    });
    const db = as(DAVE);
    await assertSucceeds(
      setDoc(doc(db, `users/${DAVE}`), { familyId: 'famB' }, { merge: true }),
    );
  });
});

describe('H4 removed members cannot be revived', () => {
  const seedRemoved = async (uid, status) =>
    testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), `families/${FAM_A}/members/${uid}`),
        memberDoc(uid, 'member', status, { removedAt: nowTs(), leftAt: nowTs() }),
      );
    });

  it('denies an admin re-activating a member who left', async () => {
    await seedRemoved(CARA, 'disabled');
    await assertFails(
      setDoc(
        doc(as(ALICE), `families/${FAM_A}/members/${CARA}`),
        memberChange(ALICE, { role: 'member', status: 'active', removedAt: null }),
        { merge: true },
      ),
    );
  });

  it('denies a moderator approving a rejected request', async () => {
    await seedRemoved(DAVE, 'pending');
    await assertFails(
      setDoc(
        doc(as(BOB), `families/${FAM_A}/members/${DAVE}`),
        memberChange(BOB, { role: 'member', status: 'active', removedAt: null }),
        { merge: true },
      ),
    );
  });

  it('still allows an admin to re-enable a disabled (not removed) member', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), `families/${FAM_A}/members/${CARA}`),
        memberDoc(CARA, 'member', 'disabled'),
      );
    });
    await assertSucceeds(
      setDoc(
        doc(as(ALICE), `families/${FAM_A}/members/${CARA}`),
        memberChange(ALICE, { role: 'member', status: 'active', removedAt: null }),
        { merge: true },
      ),
    );
  });
});

describe('H4 acceptance: leave and join another family', () => {
  it('Cara leaves famA, then joins famB with a live code', async () => {
    const cara = as(CARA);
    await assertSucceeds(
      setDoc(
        doc(cara, `families/${FAM_A}/members/${CARA}`),
        memberLeave(CARA, 'member'),
        { merge: true },
      ),
    );

    // A manager of famB invites; Cara joins.
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), 'inviteCodes/BBBBBBBB'),
        inviteCodeDoc(ERIN, 'famB', 'BBBBBBBB'),
      );
      await setDoc(doc(ctx.firestore(), `users/${CARA}`), {
        uid: CARA,
        fullName: 'Cara',
        relationship: 'other',
        familyId: FAM_A,
        ...baseDoc(CARA),
      });
    });

    const join = writeBatch(cara);
    join.set(
      doc(cara, `families/famB/members/${CARA}`),
      memberDoc(CARA, 'member', 'pending', { inviteCode: 'BBBBBBBB' }),
    );
    join.set(doc(cara, `users/${CARA}`), { familyId: 'famB' }, { merge: true });
    join.set(doc(cara, 'families/famB/activity/j1'), eventDoc(CARA, { refId: 'famB' }));
    join.set(doc(cara, 'families/famB/auditLogs/j1'), eventDoc(CARA, { refId: 'famB' }));
    join.set(
      doc(cara, 'inviteCodes/BBBBBBBB'),
      { status: 'used', usedBy: CARA, updatedAt: nowTs(), updatedBy: CARA },
      { merge: true },
    );
    await assertSucceeds(join.commit());
  });
});
