import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';

/// Pure functions between [BazarSettings] and `settings/bazar`.
///
/// The map is the single source of truth for the closed `settingsKeys()` list
/// and the `test/contract/*` fixture.  Money is stored as integer paisa and the
/// fund start month as `yyyy-MM`.
abstract final class BazarSettingsMappers {
  static Map<String, dynamic> toMap(
    BazarSettings settings,
    BaseDocumentMetadata meta,
  ) => <String, dynamic>{
    'weekStartDay': settings.weekStartDay,
    'defaultMonthlyContributionPaisa':
        settings.defaultMonthlyContribution.paisa,
    'contributionDueDay': settings.contributionDueDay,
    'alertThresholds': <int>[...settings.alertThresholds],
    'fundStartMonth': settings.fundStartMonth?.toString(),
    ...BaseMapper.metadataToMap(meta),
  };

  /// Tolerant read: an absent or damaged document falls back to the defaults
  /// for each field.  Old families therefore never crash on a missing document.
  static BazarSettings fromMap(Map<String, dynamic>? map) {
    if (map == null) return BazarSettings.defaults;

    final weekStart = _intFrom(map['weekStartDay']);
    final dueDay = _intFrom(map['contributionDueDay']);
    final contribution = _intFrom(map['defaultMonthlyContributionPaisa']);
    final thresholds = _thresholdsFrom(map['alertThresholds']);
    final fundStartMonth = _monthFrom(map['fundStartMonth']);

    return BazarSettings(
      weekStartDay: weekStart >= 1 && weekStart <= 7 ? weekStart : 6,
      defaultMonthlyContribution: Money.paisa(
        contribution < 0 ? 0 : contribution,
      ),
      contributionDueDay: dueDay >= 1 && dueDay <= 28 ? dueDay : 5,
      alertThresholds: thresholds.isEmpty
          ? BazarSettings.defaults.alertThresholds
          : thresholds,
      fundStartMonth: fundStartMonth,
    );
  }

  static int _intFrom(Object? value) => value is num ? value.toInt() : 0;

  static MonthKey? _monthFrom(Object? value) {
    if (value is! String) return null;
    return MonthKey.parse(value).valueOrNull;
  }

  static List<int> _thresholdsFrom(Object? value) {
    if (value is! List) return const <int>[];
    final result = <int>[];
    for (final item in value) {
      if (result.length == 4) break;
      if (item is num) {
        final threshold = item.toInt();
        if (threshold >= 1 && threshold <= 200) result.add(threshold);
      }
    }
    for (var i = 1; i < result.length; i++) {
      if (result[i] <= result[i - 1]) return const <int>[];
    }
    return result;
  }
}
