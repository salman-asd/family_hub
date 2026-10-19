// Shared fixtures for the Firestore rules tests (Step 10).
//
// Run against the emulator, never against a real project: the project id is a
// `demo-` id, which the emulator accepts without credentials.

import { Timestamp, doc, setDoc } from 'firebase/firestore';

export const PROJECT_ID = 'demo-family-hub';

/** Where the Firestore emulator listens; `emulators:exec` sets this. */
export const EMULATOR = process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080';

// Actors used by the tests.
export const ALICE = 'alice'; // active admin of famA
export const BOB = 'bob'; // active moderator of famA
export const CARA = 'cara'; // active member of famA
export const DAVE = 'dave'; // pending member of famA
export const ERIN = 'erin'; // active admin of famB (a different family)
export const FRANK = 'frank'; // signed in, no family at all

export const FAM_A = 'famA';
export const FAM_B = 'famB';

export const CODES = {
  live: 'ABCDEFGH',
  expired: 'ABCDEFGJ',
  used: 'ABCDEFGK',
};

const DAY_MS = 24 * 60 * 60 * 1000;

export const nowTs = () => Timestamp.fromDate(new Date());
export const futureTs = () =>
  Timestamp.fromDate(new Date(Date.now() + 7 * DAY_MS));
export const pastTs = () =>
  Timestamp.fromDate(new Date(Date.now() - 7 * DAY_MS));

/** BaseMapper.metadataToMap: every document carries this. */
export const baseDoc = (uid, extra = {}) => ({
  createdAt: nowTs(),
  createdBy: uid,
  updatedAt: nowTs(),
  updatedBy: uid,
  schemaVersion: 1,
  ...extra,
});

export const familyDoc = (createdBy, name = 'Family A') =>
  baseDoc(createdBy, { name });

export const memberDoc = (uid, role, status, extra = {}) => ({
  uid,
  role,
  status,
  fullName: `Person ${uid}`,
  nickname: null,
  relationship: 'other',
  spouseId: null,
  avatarKey: null,
  inviteCode: null,
  removedAt: null,
  ...baseDoc(uid),
  ...extra,
});

/** FamilyMappers.memberChangeMap: what an approve/reject/role change writes. */
export const memberChange = (actorUid, { role, status, removedAt = null }) => ({
  role,
  status,
  removedAt,
  updatedAt: nowTs(),
  updatedBy: actorUid,
});

/** FamilyMappers.memberChangeMap for LEAVE: status disabled + leftAt/removedAt. */
export const memberLeave = (uid, role, at = nowTs()) => ({
  role,
  status: 'disabled',
  removedAt: at,
  leftAt: at,
  updatedAt: nowTs(),
  updatedBy: uid,
});

/** memberChangeMap for CANCEL: only removedAt changes. */
export const memberCancel = (uid, role, status = 'pending') => ({
  role,
  status,
  removedAt: nowTs(),
  updatedAt: nowTs(),
  updatedBy: uid,
});

/** FamilyMappers.invitationRevokedMap. */
export const invitationRevoked = (uid) => ({
  status: 'revoked',
  updatedAt: nowTs(),
  updatedBy: uid,
});

export const inviteCodeDoc = (createdBy, familyId, code, overrides = {}) => ({
  code,
  familyId,
  role: 'member',
  status: 'active',
  expiresAt: futureTs(),
  usedBy: null,
  ...baseDoc(createdBy),
  ...overrides,
});

/** FamilyMappers.invitationUsedMap: what consuming a code writes. */
export const invitationUsed = (uid) => ({
  status: 'used',
  usedBy: uid,
  updatedAt: nowTs(),
  updatedBy: uid,
});

export const eventDoc = (actorId, extra = {}) =>
  baseDoc(actorId, {
    type: 'test.event',
    actorId,
    summary: 'Something happened',
    refType: 'family',
    refId: FAM_A,
    ...extra,
  });

/** Seeds the world the tests assume, with rules switched off. */
export const seedWorld = (testEnv) =>
  testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const put = (path, data) => setDoc(doc(db, path), data);

    // Two families with different roles and statuses.
    await put(`families/${FAM_A}`, familyDoc(ALICE));
    await put(`families/${FAM_A}/members/${ALICE}`, memberDoc(ALICE, 'admin', 'active'));
    await put(`families/${FAM_A}/members/${BOB}`, memberDoc(BOB, 'moderator', 'active'));
    await put(`families/${FAM_A}/members/${CARA}`, memberDoc(CARA, 'member', 'active'));
    await put(`families/${FAM_A}/members/${DAVE}`, memberDoc(DAVE, 'member', 'pending'));

    await put(`families/${FAM_B}`, familyDoc(ERIN, 'Family B'));
    await put(`families/${FAM_B}/members/${ERIN}`, memberDoc(ERIN, 'admin', 'active'));

    // Settings and an append-only log entry.
    await put(
      `families/${FAM_A}/settings/general`,
      baseDoc(ALICE, { timezone: 'Asia/Dhaka', currency: 'BDT' }),
    );
    await put(`families/${FAM_A}/activity/${'evt1'}`, eventDoc(ALICE));

    // Users: a full profile with preferences, and a bare one.
    await put(`users/${ALICE}`, {
      uid: ALICE,
      fullName: 'Alice Rahman',
      relationship: 'mother',
      gender: 'female',
      nickname: null,
      spouseId: null,
      avatarKey: null,
      familyId: FAM_A,
      preferences: {
        themeId: 'modern',
        themeMode: 'dark',
        language: 'bn',
        banglaDigits: true,
      },
      ...baseDoc(ALICE),
    });
    await put(`users/${FRANK}`, {
      uid: FRANK,
      fullName: 'Frank Islam',
      relationship: 'other',
      ...baseDoc(FRANK),
    });

    // Invitation codes: one live, one expired, one already used.
    await put(`inviteCodes/${CODES.live}`, inviteCodeDoc(ALICE, FAM_A, CODES.live));
    await put(
      `inviteCodes/${CODES.expired}`,
      inviteCodeDoc(ALICE, FAM_A, CODES.expired, { expiresAt: pastTs() }),
    );
    await put(
      `inviteCodes/${CODES.used}`,
      inviteCodeDoc(ALICE, FAM_A, CODES.used, { status: 'used', usedBy: CARA }),
    );

    // The family-side mirror of the live code.
    await put(
      `families/${FAM_A}/invitations/${CODES.live}`,
      inviteCodeDoc(ALICE, FAM_A, CODES.live),
    );
  });
