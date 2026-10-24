// Shared fixtures for the Firestore rules tests (Step 10).
//
// Run against the emulator, never against a real project: the project id is a
// `demo-` id, which the emulator accepts without credentials.

import { Timestamp, doc, serverTimestamp, setDoc } from 'firebase/firestore';

export const PROJECT_ID = 'demo-family-hub';

/** Where the Firestore emulator listens; `emulators:exec` sets this. */
export const EMULATOR = process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8080';

/**
 * Firestore as a signed-in user (H5).
 *
 * Every mutating rule now requires a verified email, so the default context
 * carries `email_verified: true`.  Pass `{verified: false}` to model a user who
 * has not opened the verification link yet.
 */
export const asUser = (testEnv, uid, { verified = true } = {}) =>
  testEnv.authenticatedContext(uid, { email_verified: verified }).firestore();

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

export const familyDoc = (createdBy, name = 'Family A', extra = {}) =>
  baseDoc(createdBy, {
    name,
    // H6: 1..3 active-admin uids; the creator is the only admin.
    adminIds: [createdBy],
    ...extra,
  });

/** FamilyMappers.familyAdminIdsMap: rewriting the active-admin set (H6). */
export const familyAdminIds = (actorUid, adminIds) => ({
  adminIds,
  updatedAt: nowTs(),
  updatedBy: actorUid,
});

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
    type: 'member.approved',
    actorId,
    summary: 'Something happened',
    refType: 'family',
    refId: FAM_A,
    params: {},
    recordedAt: serverTimestamp(),
    ...extra,
  });

/** FamilyMappers.permissionsMap: `settings/permissions` (H7). */
export const permissionsDoc = (uid, extra = {}) =>
  baseDoc(uid, {
    moderatorManagesFinance: true,
    membersViewFamilyReports: true,
    membersViewAllContributions: false,
    membersCanInvite: false,
    choreVerificationEnabled: false,
    ...extra,
  });

/** `BazarSettingsMappers.toMap` shape (P2-07). */
export const bazarSettingsDoc = (uid, extra = {}) =>
  baseDoc(uid, {
    weekStartDay: 6,
    defaultMonthlyContributionPaisa: 0,
    contributionDueDay: 5,
    alertThresholds: [80, 100],
    fundStartMonth: '2026-01',
    ...extra,
  });

/** `CatalogMappers.categoryToMap` shape (P2-05). */
export const categoryDoc = (uid, extra = {}) =>
  baseDoc(uid, {
    nameBn: 'মুদি',
    nameEn: 'Staples',
    colorIndex: 2,
    emoji: '🌾',
    imageData: null,
    sortOrder: 0,
    active: true,
    builtIn: false,
    seedKey: null,
    ...extra,
  });

/** `CatalogMappers.itemToMap` shape; money is integer paisa (P2-05). */
export const itemDoc = (uid, extra = {}) =>
  baseDoc(uid, {
    nameBn: 'চাল',
    nameEn: 'Rice',
    categoryId: 'cat_fixStaples',
    defaultUnit: 'kg',
    aliases: ['rice'],
    emoji: '🍚',
    imageData: null,
    useCount: 0,
    lastPricePaisa: 12500,
    lastUnitPricePaisa: 6500,
    lastUsedAt: nowTs(),
    active: true,
    builtIn: false,
    seedKey: null,
    ...extra,
  });

/** `CatalogMappers.itemUsageMap` shape: only the six allowed fields. */
export const itemUsage = (
  uid,
  { useCount, lastPricePaisa = 13000, lastUnitPricePaisa = 6500, ...extra },
) => ({
  useCount,
  lastPricePaisa,
  lastUnitPricePaisa,
  lastUsedAt: nowTs(),
  updatedAt: nowTs(),
  updatedBy: uid,
  ...extra,
});

/** `ExpenseMappers.expenseToMap` shape (P2-10). */
export const expenseDoc = (uid, extra = {}) =>
  baseDoc(uid, {
    dateKey: '2026-10-18',
    monthKey: '2026-10',
    occurredAt: nowTs(),
    itemId: null,
    itemName: 'Rice',
    categoryId: 'cat_fixStaples',
    qtyMilli: 1000,
    unit: 'kg',
    unitPricePaisa: 12000,
    totalPaisa: 12000,
    fundingSource: 'fund',
    paidByMemberId: null,
    reimbursable: false,
    purchaserId: uid,
    tripId: null,
    shop: 'Bazar',
    note: null,
    source: 'manual',
    importBatchId: null,
    ...extra,
  });

/** `ExpenseMappers.revisionToMap` shape (P2-10). */
export const revisionDoc = (uid, extra = {}) =>
  baseDoc(uid, {
    before: { itemName: 'Rice' },
    changedFields: ['itemName'],
    reason: null,
    ...extra,
  });

/** `ExpenseMappers.tripToMap` shape (P2-10). */
export const tripDoc = (uid, extra = {}) =>
  baseDoc(uid, {
    dateKey: '2026-10-18',
    monthKey: '2026-10',
    shop: 'Bazar',
    fundingSource: 'fund',
    paidByMemberId: null,
    reimbursable: false,
    lineCount: 2,
    totalPaisa: 24000,
    note: null,
    ...extra,
  });

/** `FundMappers.fundTxToMap` shape (P2-10). */
export const fundTxDoc = (uid, extra = {}) =>
  baseDoc(uid, {
    type: 'expense',
    amountPaisa: -12000,
    dateKey: '2026-10-18',
    monthKey: '2026-10',
    refType: 'expense',
    refId: 'exp_fix1',
    note: null,
    ...extra,
  });

/** `AdvanceMappers.advanceToMap` shape (P2-10). */
export const advanceDoc = (uid, extra = {}) =>
  baseDoc(uid, {
    expenseId: 'exp_adv1',
    memberId: uid,
    amountPaisa: 12000,
    settledPaisa: 0,
    status: 'pending',
    dateKey: '2026-10-18',
    monthKey: '2026-10',
    ...extra,
  });

/** `AdvanceMappers.settlementToMap` shape (P2-10). */
export const settlementDoc = (uid, extra = {}) =>
  baseDoc(uid, {
    advanceId: 'exp_adv2',
    memberId: 'fixMember',
    amountPaisa: 3000,
    dateKey: '2026-10-18',
    monthKey: '2026-10',
    method: 'cash',
    note: null,
    fundTxId: 'stl_fixS1',
    ...extra,
  });

/** `MonthClosingMappers.closingToMap` shape (P2-10). */
export const closingDoc = (uid, extra = {}) =>
  baseDoc(uid, {
    monthKey: '2026-10',
    status: 'closed',
    closedAt: nowTs(),
    closedBy: uid,
    closingBalancePaisa: 5000,
    reopenedAt: null,
    reopenedBy: null,
    reopenNote: null,
    reopenCount: 0,
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
