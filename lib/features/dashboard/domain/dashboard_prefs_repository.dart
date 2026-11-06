import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';

abstract interface class DashboardPrefsStore {
  DashboardPrefs load(String uid);

  Future<Result<void>> save(String uid, DashboardPrefs prefs);
}

abstract interface class DashboardPrefsSync {
  Future<Result<void>> push(String uid, DashboardPrefs prefs);

  Stream<DashboardPrefs?> watch(String uid);
}
