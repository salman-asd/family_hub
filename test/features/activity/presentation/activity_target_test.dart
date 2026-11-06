import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/audit/audit_ref_type.dart';
import 'package:family_hub/features/activity/domain/activity_entry.dart';
import 'package:family_hub/features/activity/presentation/activity_target.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every audit reference type has an explicit navigation decision', () {
    for (final refType in AuditRefType.all) {
      expect(ActivityTarget.hasDecisionFor(refType), isTrue, reason: refType);
    }
  });

  test('navigates only to supported records with non-empty ids', () {
    ActivityEntry entry(String refType, String refId) => ActivityEntry(
      id: 'event',
      type: 'test',
      actorId: 'actor',
      params: const {},
      refType: refType,
      refId: refId,
      createdAt: DateTime.utc(2026),
    );

    expect(
      ActivityTarget.from(entry(AuditRefType.expense, 'exp-1'))?.location,
      AppRoutes.bazarExpense('exp-1'),
    );
    expect(
      ActivityTarget.from(entry(AuditRefType.occurrence, 'occ-1'))?.location,
      AppRoutes.choresOccurrence('occ-1'),
    );
    expect(
      ActivityTarget.from(entry(AuditRefType.member, 'member-1'))?.location,
      AppRoutes.memberProfile('member-1'),
    );
    expect(ActivityTarget.from(entry(AuditRefType.family, 'fam-1')), isNull);
    expect(ActivityTarget.from(entry('unknown', 'record-1')), isNull);
    expect(ActivityTarget.from(entry(AuditRefType.expense, '  ')), isNull);
    expect(
      ActivityTarget.from(
        ActivityEntry(
          id: 'deleted',
          type: AuditEventType.bazarExpenseDeleted,
          actorId: 'actor',
          params: const {},
          refType: AuditRefType.expense,
          refId: 'expense-1',
          createdAt: DateTime.utc(2026),
        ),
      ),
      isNull,
    );
  });
}
