import 'package:family_hub/core/firebase/query_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the Phase 4 limits keep their road map values (P4-02)', () {
    expect(kMaxActivityPage, 30);
    expect(kMaxDashboardActivity, 5);
    expect(kMaxPointsPerSync, 3000);
    expect(kMaxPlannedNotifications, 60);
    expect(kMaxStatsMonths, 40);
    expect(kMaxDashboardPrefIds, 24);
    expect(kMaxPushPerHour, 30);
  });

  test('the planner cap stays under the iOS limit of about 64 pending', () {
    expect(kMaxPlannedNotifications, lessThan(64));
  });
}
