import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/localization/activity_text.dart';
import 'package:family_hub/core/localization/generated/app_localizations_bn.dart';
import 'package:family_hub/core/localization/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final en = AppLocalizationsEn();
  final bn = AppLocalizationsBn();

  test('every audit event type has its own sentence in both languages', () {
    for (final type in AuditEventType.all) {
      for (final l in [en, bn]) {
        expect(l.activityText(type, const {'memberName': 'X', 'code': 'C', 'familyName': 'F', 'newRole': 'admin'}),
            isNot(l.activityUnknown),
            reason: type);
      }
    }
  });

  test('params are substituted and roles are localized', () {
    expect(en.activityText(AuditEventType.memberLeft, const {'memberName': 'Rina'}),
        'Rina left the family');
    expect(
      en.activityText(AuditEventType.memberRoleChanged,
          const {'memberName': 'Rina', 'newRole': 'moderator'}),
      isNot(contains('moderator')),
    );
  });

  test('unknown type and missing params never throw', () {
    expect(en.activityText('future.type', const {}), en.activityUnknown);
    expect(en.activityText(AuditEventType.memberLeft, const {}), isNotEmpty);
  });
}
