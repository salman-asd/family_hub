import 'package:family_hub/core/errors/app_failure.dart';

typedef DashboardEnsureOccurrences = Future<AppFailure?> Function();
typedef DashboardRefreshAction = Future<void> Function();

/// Coordinates the refreshable dashboard work without owning any data source.
final class DashboardRefresh {
  const DashboardRefresh();

  Future<AppFailure?> run({
    required DashboardEnsureOccurrences ensureOccurrences,
    required void Function() invalidateOneShotProviders,
    DashboardRefreshAction? replanReminders,
    DashboardRefreshAction? syncMemberStats,
  }) async {
    final failure = await ensureOccurrences();
    invalidateOneShotProviders();
    await replanReminders?.call();
    await syncMemberStats?.call();
    return failure;
  }
}
