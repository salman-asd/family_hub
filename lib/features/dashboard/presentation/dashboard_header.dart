import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/dashboard/domain/greeting.dart';
import 'package:family_hub/features/dashboard/presentation/dashboard_providers.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/features/notifications/presentation/inbox_providers.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:family_hub/shared/widgets/bell_button.dart';
import 'package:family_hub/shared/widgets/greeting_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final members = ref.watch(membersProvider).value ?? const [];
    final uid = ref.watch(currentUidProvider);
    final member = _memberFor(members, uid);
    final name = member?.displayName ?? l10n.greetingDefaultName;
    final greeting = switch (ref.watch(dashboardGreetingProvider)) {
      Greeting.morning => l10n.greetingMorning,
      Greeting.afternoon => l10n.greetingAfternoon,
      Greeting.evening => l10n.greetingEvening,
    };
    final count = ref.watch(unreadInboxCountProvider);
    final canManageAccess = ref.can(Permission.manageDashboardLayout);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GreetingHeader(greeting: greeting, name: name),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: l10n.memberEditProfile,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => context.push(AppRoutes.profileEdit),
          icon: AppAvatar(
            id: uid ?? 'dashboard',
            name: name,
            avatarKey: member?.avatarKey,
            size: 36,
          ),
        ),
        BellButton(
          semanticLabel: l10n.inboxBellLabel(
            ref.watch(appFormattersProvider).number(count),
          ),
          count: count,
          countText: ref.watch(appFormattersProvider).number(count),
          overflowText: l10n.dashboardBellOverflow,
          tooltip: l10n.inboxBellLabel(
            ref.watch(appFormattersProvider).number(count),
          ),
          onPressed: () => context.push(AppRoutes.inbox),
        ),
        PopupMenuButton<String>(
          tooltip: l10n.dashboardMenu,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onSelected: (value) => context.push(
            value == 'access'
                ? AppRoutes.dashboardAccess
                : AppRoutes.customizeDashboard,
          ),
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'customize',
              child: Text(l10n.dashboardCustomize),
            ),
            if (canManageAccess)
              PopupMenuItem<String>(
                value: 'access',
                child: Text(l10n.dashboardAccess),
              ),
          ],
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.more_vert_rounded),
          ),
        ),
      ],
    );
  }

  Member? _memberFor(List<Member> members, String? uid) {
    if (uid == null) return null;
    for (final member in members) {
      if (member.uid == uid) return member;
    }
    return null;
  }
}
