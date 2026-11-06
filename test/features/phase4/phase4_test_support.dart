import 'dart:async';

import 'package:family_hub/app/flavor.dart';
import 'package:family_hub/core/errors/app_failure.dart';
import 'package:family_hub/core/errors/result.dart';
import 'package:family_hub/core/localization/app_formatters.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/notifications/domain/push_diagnostics.dart';
import 'package:family_hub/core/notifications/domain/reminder_settings.dart';
import 'package:family_hub/core/notifications/presentation/push_providers.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/core/utils/date_key.dart';
import 'package:family_hub/features/activity/domain/activity_entry.dart';
import 'package:family_hub/features/activity/presentation/activity_feed_screen.dart';
import 'package:family_hub/features/activity/presentation/activity_providers.dart';
import 'package:family_hub/features/chores/achievements/domain/default_engagement_settings.dart';
import 'package:family_hub/features/chores/achievements/domain/member_stats.dart';
import 'package:family_hub/features/chores/achievements/domain/public_stats.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_providers.dart';
import 'package:family_hub/features/chores/achievements/presentation/engagement_ui_providers.dart';
import 'package:family_hub/features/chores/achievements/presentation/screens/achievements_screen.dart';
import 'package:family_hub/features/chores/achievements/presentation/screens/engagement_settings_screen.dart';
import 'package:family_hub/features/chores/settings/domain/chore_settings.dart';
import 'package:family_hub/features/chores/settings/presentation/chore_settings_providers.dart';
import 'package:family_hub/features/dashboard/domain/card_access.dart';
import 'package:family_hub/features/dashboard/domain/card_catalog.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_card_spec.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_policy.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_prefs_repository.dart';
import 'package:family_hub/features/dashboard/domain/dashboard_resolver.dart';
import 'package:family_hub/features/dashboard/presentation/customize_dashboard_screen.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_access_screen.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_providers.dart';
import 'package:family_hub/features/dashboard/presentation/home_screen.dart';
import 'package:family_hub/features/dashboard/presentation/resolved_dashboard_card.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/domain/module_flags.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/features/notifications/domain/inbox_item.dart';
import 'package:family_hub/features/notifications/domain/inbox_port.dart';
import 'package:family_hub/features/notifications/domain/member_notification_prefs.dart';
import 'package:family_hub/features/notifications/domain/notification_defaults.dart';
import 'package:family_hub/features/notifications/domain/notification_delivery_settings.dart';
import 'package:family_hub/features/notifications/presentation/delivery_admin_screen.dart';
import 'package:family_hub/features/notifications/presentation/inbox_providers.dart';
import 'package:family_hub/features/notifications/presentation/inbox_screen.dart';
import 'package:family_hub/features/notifications/presentation/notification_providers.dart';
import 'package:family_hub/features/notifications/presentation/notification_settings_screen.dart';
import 'package:family_hub/modules/family_module.dart';
import 'package:family_hub/modules/module_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../../support/screen_states.dart';

/// A Phase 4 screen together with the overrides that drive it into a state.
///
/// Shared by the state harness (`screen_states_phase4_test.dart`) and the
/// semantics smoke test (`a11y_phase4_test.dart`) so a screen is added to
/// Phase 4 checking in exactly one place.
final class Phase4Screen {
  const Phase4Screen(this.name, this.build, this.overrides);

  final String name;
  final Widget Function() build;
  final StateOverrides overrides;
}

const Set<ScreenState> phase4States = {
  ScreenState.loading,
  ScreenState.data,
  ScreenState.empty,
  ScreenState.error,
  ScreenState.offline,
};

final List<Phase4Screen> phase4Screens = [
  Phase4Screen(
    'HomeScreen',
    () => const HomeScreen(),
    (state) => [
      ...phase4Base(state),
      dashboardCardsProvider.overrideWithValue(switch (state) {
        ScreenState.loading =>
          const AsyncLoading<List<ResolvedDashboardCard>>(),
        ScreenState.error => const AsyncError<List<ResolvedDashboardCard>>(
          Network(),
          StackTrace.empty,
        ),
        ScreenState.empty => const AsyncData<List<ResolvedDashboardCard>>([]),
        _ => AsyncData<List<ResolvedDashboardCard>>(phase4ResolvedCards()),
      }),
    ],
  ),
  Phase4Screen(
    'CustomizeDashboardScreen',
    () => const CustomizeDashboardScreen(),
    (state) => [
      ...phase4Base(state),
      dashboardPrefsStoreProvider.overrideWithValue(DashboardPrefsStoreFake()),
      dashboardLayoutProvider.overrideWithValue(switch (state) {
        ScreenState.loading => const AsyncLoading<DashboardLayout>(),
        ScreenState.error => const AsyncError<DashboardLayout>(
          Network(),
          StackTrace.empty,
        ),
        ScreenState.empty => AsyncData<DashboardLayout>(
          DashboardLayout(
            visible: const [],
            optionalHidden: const [],
            required: const [],
          ),
        ),
        _ => AsyncData<DashboardLayout>(phase4Layout()),
      }),
    ],
  ),
  Phase4Screen(
    'DashboardAccessScreen',
    () => const DashboardAccessScreen(),
    (state) => [
      ...phase4Base(state),
      dashboardPolicyProvider.overrideWith(
        (ref, familyId) => phase4Stream(state, DashboardPolicy.defaults),
      ),
    ],
  ),
  Phase4Screen(
    'InboxScreen',
    () => const InboxScreen(),
    (state) => [
      ...phase4Base(state),
      inboxProvider.overrideWith((ref) => phase4Stream(state, phase4Inbox())),
      virtualInboxProvider.overrideWithValue(const <InboxItem>[]),
      visibleInboxItemsProvider.overrideWithValue(
        state == ScreenState.empty ? const <InboxItem>[] : phase4Inbox(),
      ),
    ],
  ),
  Phase4Screen(
    'ActivityFeedScreen',
    () => const ActivityFeedScreen(),
    (state) => [
      ...phase4Base(state),
      activityFirstPageProvider.overrideWith(
        (ref, actorId) => phase4Stream(state, phase4ActivityPage(state)),
      ),
    ],
  ),
  Phase4Screen(
    'DeliveryAdminScreen',
    () => const DeliveryAdminScreen(),
    (state) => [
      ...phase4Base(state),
      deliveryPolicyProvider.overrideWith(
        (ref, familyId) =>
            phase4Stream(state, NotificationDeliverySettings.defaults()),
      ),
      pushDiagnosticsProvider.overrideWith(
        (ref) => Stream.value(const PushDiagnostics()),
      ),
    ],
  ),
  Phase4Screen(
    'NotificationSettingsScreen',
    () => const NotificationSettingsScreen(),
    (state) => [
      ...phase4Base(state),
      reminderSettingsProvider.overrideWithValue(switch (state) {
        ScreenState.loading => const AsyncLoading<ReminderSettings>(),
        ScreenState.error => const AsyncError<ReminderSettings>(
          Network(),
          StackTrace.empty,
        ),
        _ => AsyncData<ReminderSettings>(ReminderSettings()),
      }),
      familyDefaultsProvider.overrideWith(
        (ref, familyId) => phase4Stream(state, NotificationDefaults.defaults),
      ),
    ],
  ),
  Phase4Screen(
    'AchievementsScreen',
    () => const AchievementsScreen(),
    (state) => [...phase4Base(state), ...phase4Engagement(state)],
  ),
  Phase4Screen(
    'EngagementSettingsScreen',
    () => const EngagementSettingsScreen(),
    (state) => [...phase4Base(state), ...phase4Engagement(state)],
  ),
];

/// The session-wide providers every Phase 4 screen reads through its widgets.
/// `offline` carries the same payload as `data`: the state under test is the
/// banner the harness adds, not the stream behind it.
List<Override> phase4Base(ScreenState state) => [
  flavorProvider.overrideWithValue(Flavor.dev),
  currentFamilyIdProvider.overrideWithValue('f1'),
  currentUidProvider.overrideWithValue('cara'),
  currentActorProvider.overrideWithValue(
    const PermissionActor(uid: 'cara', role: Role.admin, isActive: true),
  ),
  permissionSettingsProvider.overrideWithValue(PermissionSettings.defaults),
  moduleFlagsProvider.overrideWithValue(ModuleFlags.allOn),
  choreSettingsProvider.overrideWithValue(ChoreSettings.defaults),
  memberNotificationPrefsStoreProvider.overrideWithValue(
    MemberPrefsStoreFake(),
  ),
  appFormattersProvider.overrideWithValue(
    const AppFormatters(languageCode: 'en', useBanglaDigits: false),
  ),
  membersProvider.overrideWith(
    (ref) => Stream.value(
      state == ScreenState.empty ? const <Member>[] : phase4Members(),
    ),
  ),
];

List<Override> phase4Engagement(ScreenState state) {
  final startedOn = DateKey(2026, 11, 6);
  final settings = defaultEngagementSettings(
    startedOn: startedOn,
    graceMinutes: 0,
  );
  return [
    engagementSettingsProvider.overrideWith(
      (ref, familyId) => phase4Stream(
        state,
        state == ScreenState.empty
            ? settings.copyWith(enabled: false)
            : settings,
      ),
    ),
    memberStatsProvider.overrideWith(
      (ref, memberId) =>
          phase4Stream(state, MemberStats.empty(startedOn: startedOn)),
    ),
    familyPublicStatsProvider.overrideWith(
      (ref) => phase4Stream(state, const <String, PublicStats>{}),
    ),
  ];
}

/// Streams for the three data states; loading never emits and error throws.
Stream<T> phase4Stream<T>(ScreenState state, T payload) => switch (state) {
  ScreenState.loading => StreamController<T>().stream,
  ScreenState.error => Stream<T>.error(const Network()),
  _ => Stream.value(payload),
};

List<Member> phase4Members() => [
  for (final (uid, role) in const <(String, MemberRole)>[
    ('alice', MemberRole.admin),
    ('cara', MemberRole.member),
  ])
    Member(
      uid: uid,
      role: role,
      status: MembershipStatus.active,
      fullName: 'Person $uid',
      relationship: 'other',
    ),
];

/// Two catalog cards, drawn by a placeholder builder: the grid and the
/// customize list are what must survive here, not the cards' own data.
List<ResolvedDashboardCard> phase4ResolvedCards() {
  const ids = ['chores_overdue', 'chores_verify'];
  return [
    for (final (index, id) in ids.indexed)
      ResolvedDashboardCard(
        resolved: ResolvedCard(
          definition: CardCatalog.find(id)!,
          access: CardAccess.on,
          canHide: true,
        ),
        spec: DashboardCardSpec<DashboardCardBuilder>(
          id: id,
          builder: (_, _) =>
              SizedBox(key: ValueKey('phase4_card_$index'), height: 120),
        ),
      ),
  ];
}

DashboardLayout phase4Layout() {
  ResolvedCard resolved(String id) => ResolvedCard(
    definition: CardCatalog.find(id)!,
    access: CardAccess.on,
    canHide: true,
  );
  return DashboardLayout(
    visible: [resolved('chores_overdue'), resolved('chores_verify')],
    optionalHidden: [resolved('upcoming')],
    required: [resolved('chores_today')],
  );
}

List<InboxItem> phase4Inbox() => [
  InboxItem(
    id: 'i1',
    toMemberId: 'cara',
    type: InboxType.memberApproved,
    refType: 'member',
    refId: 'cara',
    createdAt: DateTime.utc(2026, 11, 6, 8),
  ),
  InboxItem(
    id: 'i2',
    toMemberId: 'cara',
    type: InboxType.choreAssigned,
    refType: 'occurrence',
    refId: 'o1',
    createdAt: DateTime.utc(2026, 11, 1, 8),
  ),
];

ActivityPage phase4ActivityPage(ScreenState state) => ActivityPage(
  entries: [
    ActivityEntry(
      id: 'e1',
      type: 'chores.completed',
      actorId: 'cara',
      params: const {},
      refType: 'occurrence',
      refId: 'o1',
      createdAt: DateTime.utc(2026, 11, 6),
    ),
  ],
  cursorId: state == ScreenState.empty ? null : 'cursor-1',
  hasMore: state != ScreenState.empty,
);

final class MemberPrefsStoreFake implements MemberNotificationPrefsStore {
  MemberNotificationPrefs _saved = MemberNotificationPrefs.defaults;

  @override
  MemberNotificationPrefs load(String uid) => _saved;

  @override
  Future<Result<void>> save(String uid, MemberNotificationPrefs prefs) async {
    _saved = prefs;
    return const Success<void>(null);
  }
}

final class DashboardPrefsStoreFake implements DashboardPrefsStore {
  DashboardPrefs _saved = DashboardPrefs.defaults;

  @override
  DashboardPrefs load(String uid) => _saved;

  @override
  Future<Result<void>> save(String uid, DashboardPrefs prefs) async {
    _saved = prefs;
    return const Success<void>(null);
  }
}
