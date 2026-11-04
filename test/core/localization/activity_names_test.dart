import 'package:family_hub/core/audit/audit_event_type.dart';
import 'package:family_hub/core/localization/activity_names.dart';
import 'package:family_hub/core/localization/activity_text.dart';
import 'package:family_hub/core/localization/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? nameOf(String uid) => const {'u1': 'Rina', 'u2': 'Dave'}[uid];

  test('member uids become names, dates stay dates', () {
    final out = resolveChoreActivityNames(
      AuditEventType.choresAvailabilityAdded,
      const {'member': 'u1', 'from': '2026-11-01', 'to': '2026-11-03'},
      nameOf,
    );
    expect(out['member'], 'Rina');
    expect(out['from'], '2026-11-01');
    expect(out['to'], '2026-11-03');
  });

  test('swap events resolve from and to as people', () {
    final out = resolveChoreActivityNames(
      AuditEventType.choresSwapAccepted,
      const {'from': 'u1', 'to': 'u2', 'name': 'Sweep', 'date': '2026-11-02'},
      nameOf,
    );
    expect(out['to'], 'Dave');
    expect(
      AppLocalizationsEn().activityText(AuditEventType.choresSwapAccepted, out),
      'Dave accepted Sweep on 2026-11-02',
    );
  });

  test('an unknown uid and a non-chore type are left alone', () {
    expect(
      resolveChoreActivityNames(
        AuditEventType.choresCommentAdded,
        const {'member': 'gone'},
        nameOf,
      )['member'],
      'gone',
    );
    const other = {'member': 'u1'};
    expect(
      resolveChoreActivityNames(AuditEventType.memberLeft, other, nameOf),
      other,
    );
  });
}
