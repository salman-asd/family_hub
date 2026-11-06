import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs_repository.dart';

final class SaveDashboardPrefs {
  const SaveDashboardPrefs({required this.store, required this.sync});

  final DashboardPrefsStore store;
  final DashboardPrefsSync sync;

  Future<Result<void>> call({
    required String uid,
    required DashboardPrefs prefs,
  }) async {
    final invalid = _validate(prefs);
    if (invalid != null) return Failure<void>(invalid);

    final local = await store.save(uid, prefs);
    final localFailure = local.failureOrNull;
    if (localFailure != null) return Failure<void>(localFailure);
    return sync.push(uid, prefs);
  }

  AppFailure? _validate(DashboardPrefs prefs) {
    if (prefs.order.length > DashboardPrefs.maxPreferenceIds ||
        prefs.hidden.length > DashboardPrefs.maxPreferenceIds ||
        prefs.shown.length > DashboardPrefs.maxPreferenceIds) {
      return const Validation('dashboard', 'too_many_preferences');
    }
    if (prefs.order.any((id) => id.length > DashboardPrefs.maxIdLength) ||
        prefs.hidden.any((id) => id.length > DashboardPrefs.maxIdLength) ||
        prefs.shown.any((id) => id.length > DashboardPrefs.maxIdLength)) {
      return const Validation('dashboard', 'id_too_long');
    }
    return null;
  }
}
