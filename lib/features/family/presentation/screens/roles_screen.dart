import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/localization/role_labels.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/member_role.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/presentation/action_controller.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:family_hub/shared/widgets/choice_wrap.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _roleActionProvider = newActionProvider();

/// Admin-only: set a member's role, or hand the admin role over.
class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final members = ref.watch(membersProvider);
    final me = ref.watch(currentUidProvider);
    final familyId = ref.watch(currentFamilyIdProvider);
    final busy = ref.watch(_roleActionProvider).busy;

    ref.listen(_roleActionProvider, (_, next) {
      final f = next.failure;
      if (f != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.familyFailureMessage(f))));
      }
    });

    Future<void> setRole(Member m, MemberRole role) async {
      if (me == null || familyId == null) return;
      await ref
          .read(_roleActionProvider.notifier)
          .run(
            () => ref.read(changeRoleProvider)(
              actorUid: me,
              familyId: familyId,
              targetUid: m.uid,
              newRole: role,
            ),
          );
    }

    Future<void> makeAdmin(Member m) async {
      if (me == null || familyId == null) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.rolesTransferTitle),
          content: Text(l10n.rolesTransferMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              key: const Key('transfer_confirm'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.actionConfirm),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await ref
          .read(_roleActionProvider.notifier)
          .run(
            () => ref.read(transferAdminProvider)(
              actorUid: me,
              familyId: familyId,
              targetUid: m.uid,
            ),
          );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rolesTitle)),
      body: members.when(
        loading: () => const LoadingView(lines: 5, showAvatar: true),
        error: (_, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: l10n.errorUnknown,
          actionLabel: l10n.actionRetry,
          onAction: () => ref.invalidate(membersProvider),
        ),
        data: (list) {
          final active = list
              .where((m) => m.status == MembershipStatus.active)
              .toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final m in active)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppAvatar(
                              id: m.uid,
                              name: m.displayName,
                              avatarKey: m.avatarKey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                m.displayName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            if (m.isActiveAdmin)
                              Chip(label: Text(l10n.roleLabel(m.role))),
                          ],
                        ),
                        if (m.uid != me && !m.isActiveAdmin) ...[
                          const SizedBox(height: 8),
                          ChoiceWrap<MemberRole>(
                            options: [
                              for (final r in assignableRoles)
                                ChoiceOption(
                                  r,
                                  l10n.roleLabel(r),
                                  key: Key('role_${r.name}_${m.uid}'),
                                ),
                            ],
                            selected: m.role,
                            onChanged: busy ? (_) {} : (r) => setRole(m, r),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            key: Key('make_admin_${m.uid}'),
                            onPressed: busy ? null : () => makeAdmin(m),
                            child: Text(
                              l10n.rolesMakeAdmin,
                              style: TextStyle(color: t.accentStrong),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
