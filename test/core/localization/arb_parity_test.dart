import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bangla is the default language, so a missing Bangla string is a bug users
/// see first. `flutter gen-l10n` fills a gap from the template, but it does
/// not fail the build, and it cannot fill a message whose placeholders differ.
/// This test closes both gaps (CLAUDE.md rule 10, road map 3.7).
/// Read inside the tests: a `test` body may call `expect`, a top-level
/// initializer may not, so reading here would crash the whole file.
Map<String, dynamic> en() => _read('lib/core/localization/arb/app_en.arb');
Map<String, dynamic> bn() => _read('lib/core/localization/arb/app_bn.arb');

Set<String> messages(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@')).toSet();

void main() {
  test('both ARB files have the same message keys', () {
    final enKeys = messages(en());
    final bnKeys = messages(bn());
    expect(enKeys, isNotEmpty);
    expect(
      enKeys.difference(bnKeys),
      isEmpty,
      reason: 'missing from app_bn.arb: ${enKeys.difference(bnKeys)}',
    );
    expect(
      bnKeys.difference(enKeys),
      isEmpty,
      reason: 'missing from app_en.arb: ${bnKeys.difference(enKeys)}',
    );
  });

  test('every message has a non-blank translation in both languages', () {
    final enArb = en();
    final bnArb = bn();
    for (final key in messages(enArb)) {
      expect(enArb[key], isA<String>(), reason: '$key (en)');
      expect(bnArb[key], isA<String>(), reason: '$key (bn)');
      expect((enArb[key] as String).trim(), isNotEmpty, reason: '$key (en)');
      expect((bnArb[key] as String).trim(), isNotEmpty, reason: '$key (bn)');
    }
  });

  test('a message and its translation use the same placeholders', () {
    final enArb = en();
    final bnArb = bn();
    final mismatched = <String>[];
    for (final key in messages(enArb)) {
      final a = _placeholders(enArb[key] as String);
      final b = _placeholders(bnArb[key] as String);
      if (a.length != b.length || !a.containsAll(b) || !b.containsAll(a)) {
        mismatched.add('$key: en $a vs bn $b');
      }
    }
    expect(mismatched, isEmpty);
  });

  test('the P3-03 vocabulary is present in both languages', () {
    const required = <String>[
      'choresModuleTitle',
      'choreStatusSkipped',
      'choreFlagNeedsCover',
      'choreFlagAwaitingVerification',
      'choreFlagNeedsAttention',
      'choreFlagPlanned',
      'permissionCompleteChoreForOthers',
      'permissionRecordOwnAvailability',
      'permissionManageAvailability',
      'permissionManageChoreOccurrences',
      'permissionModerateChoreComments',
      'choresFailure_required',
      'choresFailure_invalid_recurrence',
      'choresFailure_reason_required',
      'choresFailure_not_a_recipient',
      'choresFailure_unknown',
    ];
    final enKeys = messages(en());
    final bnKeys = messages(bn());
    for (final key in required) {
      expect(enKeys, contains(key), reason: '$key (en)');
      expect(bnKeys, contains(key), reason: '$key (bn)');
    }
  });

  test('the P4-02 vocabulary is present in both languages', () {
    const cards = <String>[
      'BudgetAlert',
      'Approvals',
      'ChoresToday',
      'ChoresOverdue',
      'ChoresVerify',
      'BazarMonth',
      'BazarFund',
      'Upcoming',
      'ChoresWeek',
      'HubLevel',
      'RecentActivity',
    ];
    const channels = <String>[
      'ChoresDue',
      'ChoresOverdue',
      'DailySummary',
      'Bazar',
      'Family',
      'PushEvents',
    ];
    const levels = <String>[
      'Seed',
      'Sprout',
      'Seedling',
      'Sapling',
      'YoungTree',
      'Flowering',
      'Fruiting',
      'GrandTree',
    ];
    // The stable failure codes of road map 3.6, by the mapper that shows them.
    const notification = <String>[
      'invalid_minutes',
      'invalid_offsets',
      'too_many_offsets',
      'invalid_quiet_hours',
      'unknown_notification_type',
      'type_not_push_capable',
      'permission_denied_by_os',
      'exact_alarm_denied',
      'scheduler_unavailable',
      'push_unavailable',
      'inboxItem',
    ];
    const engagement = <String>[
      'invalid_levels',
      'levels_not_ascending',
      'too_many_levels',
      'invalid_threshold',
      'invalid_points',
      'invalid_permille',
      'invalid_visibility',
      'stats_not_owner',
      'stats_regression',
      'engagement_disabled',
      'already_celebrated',
      'sharing_not_allowed',
      'memberStats',
    ];
    const dashboard = <String>['unknown_card', 'invalid_access'];
    final required = <String>[
      'permissionManageEngagement',
      'permissionManageDashboardLayout',
      'dashModuleCore',
      'dashModuleBazar',
      'dashModuleChores',
      'engagementVisibilityPrivate',
      'engagementVisibilityLevels',
      'activityNotificationDefaultsUpdated',
      'activityNotificationDeliveryUpdated',
      'activityDashboardPolicyUpdated',
      'activityEngagementSettingsUpdated',
      'activityEngagementPrivacyUpdated',
      for (final c in cards) 'dashCard$c',
      for (final c in channels) 'notifChannel$c',
      for (final l in levels) 'levelName$l',
      for (final c in notification) 'notificationFailure_$c',
      for (final c in engagement) 'engagementFailure_$c',
      for (final c in dashboard) 'dashboardFailure_$c',
    ];
    // 26 failure codes: 15 Validation + 9 Conflict + 2 NotFound (road map 3.6).
    expect(
      notification.length + engagement.length + dashboard.length,
      26,
    );
    final enKeys = messages(en());
    final bnKeys = messages(bn());
    for (final key in required) {
      expect(enKeys, contains(key), reason: '$key (en)');
      expect(bnKeys, contains(key), reason: '$key (bn)');
    }
  });
}

/// Reads one ARB file. Called inside the tests on purpose: `expect` may not run
/// while the file is still loading.
Map<String, dynamic> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// `{name}` style placeholders of one ICU message.
Set<String> _placeholders(String message) =>
    RegExp(r'\{([A-Za-z0-9_]+)')
        .allMatches(message)
        .map((m) => m.group(1)!)
        .toSet();
