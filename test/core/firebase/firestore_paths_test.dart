import 'package:family_hub/core/firebase/firestore_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestorePaths', () {
    const familyId = 'fam_123';
    const uid = 'user_abc';

    test('top level paths', () {
      expect(FirestorePaths.userDoc(uid), 'users/user_abc');
      expect(
        FirestorePaths.userPreferencesDoc(uid),
        'users/user_abc/preferences/default',
      );
      expect(FirestorePaths.inviteCodeDoc('ABC12345'), 'inviteCodes/ABC12345');
      expect(FirestorePaths.familyDoc(familyId), 'families/fam_123');
    });

    test('family core subcollections', () {
      expect(FirestorePaths.members(familyId), 'families/fam_123/members');
      expect(
        FirestorePaths.memberDoc(familyId, 'mem_1'),
        'families/fam_123/members/mem_1',
      );
      expect(FirestorePaths.settings(familyId), 'families/fam_123/settings');
      expect(
        FirestorePaths.settingsDoc(familyId, 'general'),
        'families/fam_123/settings/general',
      );
      expect(
        FirestorePaths.invitations(familyId),
        'families/fam_123/invitations',
      );
      expect(
        FirestorePaths.invitationDoc(familyId, 'inv_1'),
        'families/fam_123/invitations/inv_1',
      );
    });

    test('bazar subcollections and deterministic IDs', () {
      expect(
        FirestorePaths.bazarCategories(familyId),
        'families/fam_123/bazarCategories',
      );
      expect(
        FirestorePaths.bazarCategoryDoc(familyId, 'cat_veg'),
        'families/fam_123/bazarCategories/cat_veg',
      );
      expect(
        FirestorePaths.bazarItems(familyId),
        'families/fam_123/bazarItems',
      );
      expect(
        FirestorePaths.bazarItemDoc(familyId, 'item_potato'),
        'families/fam_123/bazarItems/item_potato',
      );
      expect(FirestorePaths.expenses(familyId), 'families/fam_123/expenses');
      expect(
        FirestorePaths.expenseDoc(familyId, 'exp_1'),
        'families/fam_123/expenses/exp_1',
      );
      expect(
        FirestorePaths.budgetDoc(familyId, '2026-10'),
        'families/fam_123/budgets/2026-10',
      );
      expect(
        FirestorePaths.contributions(familyId),
        'families/fam_123/contributions',
      );
      expect(
        FirestorePaths.contributionPlanDoc(familyId, '2026-10_mem_1'),
        'families/fam_123/contributionPlans/2026-10_mem_1',
      );
      expect(
        FirestorePaths.fundTransactions(familyId),
        'families/fam_123/fundTransactions',
      );
      expect(
        FirestorePaths.memberAdvances(familyId),
        'families/fam_123/memberAdvances',
      );
      expect(
        FirestorePaths.settlements(familyId),
        'families/fam_123/settlements',
      );
      expect(
        FirestorePaths.expenseRevisions(familyId, 'exp_1'),
        'families/fam_123/expenses/exp_1/revisions',
      );
      expect(
        FirestorePaths.expenseRevisionDoc(familyId, 'exp_1', 'rev_1'),
        'families/fam_123/expenses/exp_1/revisions/rev_1',
      );
      expect(
        FirestorePaths.monthClosingDoc(familyId, '2026-10'),
        'families/fam_123/monthClosings/2026-10',
      );
      expect(
        FirestorePaths.importBatchDoc(familyId, 'imp_1'),
        'families/fam_123/importBatches/imp_1',
      );
      expect(
        FirestorePaths.bazarSettingsDoc(familyId),
        'families/fam_123/settings/bazar',
      );
    });

    test('chores subcollections and deterministic occurrences', () {
      expect(
        FirestorePaths.choreTemplates(familyId),
        'families/fam_123/choreTemplates',
      );
      expect(
        FirestorePaths.choreTemplateDoc(familyId, 'tmpl_dishes'),
        'families/fam_123/choreTemplates/tmpl_dishes',
      );
      expect(
        FirestorePaths.dutyGroups(familyId),
        'families/fam_123/dutyGroups',
      );
      expect(
        FirestorePaths.choreOccurrenceDoc(familyId, 'tmpl_dishes_20261017'),
        'families/fam_123/choreOccurrences/tmpl_dishes_20261017',
      );
      expect(
        FirestorePaths.occurrenceEventDoc(
          familyId,
          'tmpl_dishes_20261017',
          'evt_1',
        ),
        'families/fam_123/choreOccurrences/tmpl_dishes_20261017/events/evt_1',
      );
      expect(
        FirestorePaths.occurrenceCommentDoc(
          familyId,
          'tmpl_dishes_20261017',
          'cmt_1',
        ),
        'families/fam_123/choreOccurrences/tmpl_dishes_20261017/comments/cmt_1',
      );
      expect(
        FirestorePaths.memberAvailability(familyId),
        'families/fam_123/memberAvailability',
      );
      expect(
        FirestorePaths.swapRequests(familyId),
        'families/fam_123/swapRequests',
      );
    });

    test('activity, audit, inbox, stats subcollections', () {
      expect(
        FirestorePaths.notificationInbox(familyId),
        'families/fam_123/notificationInbox',
      );
      expect(FirestorePaths.activity(familyId), 'families/fam_123/activity');
      expect(FirestorePaths.auditLogs(familyId), 'families/fam_123/auditLogs');
      expect(
        FirestorePaths.memberStatsDoc(familyId, 'mem_1'),
        'families/fam_123/memberStats/mem_1',
      );
    });
  });
}
