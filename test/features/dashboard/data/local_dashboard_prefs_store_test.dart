import 'package:family_hub/features/dashboard/data/local_dashboard_prefs_store.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('stores dashboard preferences by uid and reloads them', () async {
    final store = LocalDashboardPrefsStore(
      await SharedPreferences.getInstance(),
    );
    final first = DashboardPrefs(
      order: ['upcoming', 'chores_today'],
      hidden: {'bazar_fund'},
      shown: {'chores_week'},
    );

    expect((await store.save('one', first)).isSuccess, isTrue);
    expect(store.load('one'), first);
    expect(store.load('two'), DashboardPrefs.defaults);
  });

  test('damaged local JSON safely falls back to default preferences', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dashboard_prefs_one', '{');
    final store = LocalDashboardPrefsStore(prefs);
    expect(store.load('one'), DashboardPrefs.defaults);
  });
}
