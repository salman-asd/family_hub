import 'package:family_hub/core/firebase/base_mapper.dart';
import 'package:family_hub/core/utils/clock.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/core/utils/money.dart';
import 'package:family_hub/features/bazar/settings/data/bazar_settings_mappers.dart';
import 'package:family_hub/features/bazar/settings/domain/bazar_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 10, 18, 9);
  final meta = BaseMapper.createMetadata(uid: 'u1', clock: FakeClock(at));

  test('round-trips every field and stores money as integer paisa', () {
    final settings = BazarSettings(
      weekStartDay: 1,
      defaultMonthlyContribution: const Money.paisa(500000),
      contributionDueDay: 10,
      alertThresholds: const <int>[70, 90, 100],
      fundStartMonth: MonthKey(2026, 1),
    );

    final map = BazarSettingsMappers.toMap(settings, meta);

    expect(map['weekStartDay'], 1);
    expect(map['defaultMonthlyContributionPaisa'], 500000);
    expect(map['contributionDueDay'], 10);
    expect(map['alertThresholds'], <int>[70, 90, 100]);
    expect(map['fundStartMonth'], '2026-01');
    expect(map['createdBy'], 'u1');
    expect(BazarSettingsMappers.fromMap(map), settings);
  });

  test('an absent document becomes the defaults', () {
    expect(BazarSettingsMappers.fromMap(null), BazarSettings.defaults);
  });

  test('a toMap with no fund start month keeps the key as null', () {
    final map = BazarSettingsMappers.toMap(BazarSettings.defaults, meta);
    expect(map.containsKey('fundStartMonth'), isTrue);
    expect(map['fundStartMonth'], isNull);
    expect(BazarSettingsMappers.fromMap(map), BazarSettings.defaults);
  });

  test('damaged fields fall back without throwing', () {
    final settings = BazarSettingsMappers.fromMap(<String, dynamic>{
      'weekStartDay': 0,
      'contributionDueDay': 29,
      'defaultMonthlyContributionPaisa': -5,
      'alertThresholds': <int>[100, 80],
      'fundStartMonth': '2026-13',
    });

    expect(settings.weekStartDay, 6);
    expect(settings.contributionDueDay, 5);
    expect(settings.defaultMonthlyContribution, Money.zero);
    expect(settings.alertThresholds, <int>[80, 100]);
    expect(settings.fundStartMonth, isNull);
  });

  test('copyWith supports equality on the threshold list', () {
    final changed = BazarSettings.defaults.copyWith(
      alertThresholds: const <int>[75, 95],
      fundStartMonth: MonthKey(2026, 2),
    );

    expect(changed == BazarSettings.defaults, isFalse);
    expect(
      changed ==
          BazarSettings(
            alertThresholds: const <int>[75, 95],
            fundStartMonth: MonthKey(2026, 2),
          ),
      isTrue,
    );
    expect(changed.hashCode, isNot(BazarSettings.defaults.hashCode));
    expect(changed.copyWith(clearFundStartMonth: true).fundStartMonth, isNull);
  });
}
