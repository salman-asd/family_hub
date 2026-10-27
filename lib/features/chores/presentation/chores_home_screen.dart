import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/permissions/permission.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Chores tab.
///
/// P3-01 skeleton: a friendly empty state.  The calendar replaces the body in
/// P3-22; the route, the app bar and the manager-only "Manage" entry stay.
class ChoresHomeScreen extends ConsumerWidget {
  const ChoresHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canManage = ref.can(Permission.manageChoreTemplates);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navChores)),
      body: EmptyState(
        icon: Icons.checklist_rounded,
        title: l10n.choresEmptyTitle,
        message: l10n.choresEmptyMessage,
        actionLabel: canManage ? l10n.choresManageAction : null,
        onAction: canManage
            ? () => context.push(AppRoutes.choresManage)
            : null,
      ),
    );
  }
}
