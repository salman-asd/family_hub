import 'package:family_hub/features/chores/achievements/domain/badges/badge_catalog.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';

abstract final class BadgeEvaluator {
  static Set<String> evaluate(MemberStats stats, BadgeThresholds spec) {
    final earned = <String>{};
    if (stats.completedTotal > 0) earned.add(BadgeCatalog.freshStart);
    if (stats.streak.current >= spec.consistentDays) {
      earned.add(BadgeCatalog.consistent);
    }
    if (stats.monthly.values.any(
      (month) =>
          month.isFinal &&
          month.done >= spec.reliableMinDone &&
          month.done > 0 &&
          month.onTime * 100 >= spec.reliablePercent * month.done,
    )) {
      earned.add(BadgeCatalog.reliable);
    }
    if (stats.coversTotal >= spec.helperCovers) {
      earned.add(BadgeCatalog.helper);
    }
    if (stats.verifiedCleanTotal >= spec.detailCount) {
      earned.add(BadgeCatalog.detailChampion);
    }
    return Set<String>.unmodifiable(earned);
  }
}
