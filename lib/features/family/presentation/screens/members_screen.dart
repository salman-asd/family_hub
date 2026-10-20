import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/core/localization/role_labels.dart';
import 'package:family_hub/core/permissions/permissions.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/membership.dart';
import 'package:family_hub/features/family/presentation/action_controller.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/permission_providers.dart';
import 'package:family_hub/features/family/presentation/widgets/labels.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:family_hub/shared/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _memberActionProvider = newActionProvider();

/// Members grouped by status; admins and moderators can approve or reject
/// requests, admins can also disable and re-enable.
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final members = ref.watch(membersProvider);
    final uid = ref.watch(currentUidProvider);
    final canApprove = ref.can(Permission.approveMembers);
    final canRemove = ref.can(Permission.removeMembers);

    ref.listen(_memberActionProvider, (_, next) {
      final f = next.failure;
      if (f != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.familyFailureMessage(f))));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.membersTitle)),
      body: members.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: l10n.errorUnknown,
          actionLabel: l10n.actionRetry,
          onAction: () => ref.invalidate(membersProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.groups_outlined,
              title: l10n.membersTitle,
            );
          }
          Iterable<Member> by(MembershipStatus s) =>
              list.where((m) => m.status == s);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final s in [
                MembershipStatus.pending,
                MembershipStatus.active,
                MembershipStatus.disabled,
              ])
                if (by(s).isNotEmpty) ...[
                  _Header(l10n.statusLabel(s)),
                  for (final m in by(s))
                    _MemberTile(
                      member: m,
                      isMe: m.uid == uid,
                      canApprove: canApprove,
                      canRemove: canRemove,
                    ),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: context.tokens.textSecondary),
        ),
      );
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.member,
    required this.isMe,
    required this.canApprove,
    required this.canRemove,
  });

  final Member member;
  final bool isMe;
  final bool canApprove;
  final bool canRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final familyId = ref.watch(currentFamilyIdProvider);
    final uid = ref.watch(currentUidProvider);
    final busy = ref.watch(_memberActionProvider).busy;

    final actions = <Widget>[];
    if (member.status == MembershipStatus.pending && canApprove) {
      actions
        ..add(
          FilledButton(
            key: Key('approve_${member.uid}'),
            onPressed: busy
                ? null
                : () => ref.read(_memberActionProvider.notifier).run(
                      () => ref.read(approveMemberProvider)(
                        actorUid: uid!,
                        familyId: familyId!,
                        targetUid: member.uid,
                      ),
                    ),
            child: Text(l10n.memberApprove),
          ),
        )
        ..add(
          OutlinedButton(
            key: Key('reject_${member.uid}'),
            onPressed: busy
                ? null
                : () => ref.read(_memberActionProvider.notifier).run(
                      () => ref.read(rejectMemberProvider)(
                        actorUid: uid!,
                        familyId: familyId!,
                        targetUid: member.uid,
                      ),
                    ),
            child: Text(l10n.memberReject),
          ),
        );
    } else if (member.status == MembershipStatus.active &&
        canRemove &&
        !isMe) {
      actions.add(
        OutlinedButton(
          key: Key('disable_${member.uid}'),
          onPressed: busy
              ? null
              : () => ref.read(_memberActionProvider.notifier).run(
                    () => ref.read(disableMemberProvider)(
                      actorUid: uid!,
                      familyId: familyId!,
                      targetUid: member.uid,
                    ),
                  ),
          child: Text(l10n.memberDisable),
        ),
      );
    } else if (member.status == MembershipStatus.disabled && canRemove) {
      actions.add(
        OutlinedButton(
          key: Key('enable_${member.uid}'),
          onPressed: busy
              ? null
              : () => ref.read(_memberActionProvider.notifier).run(
                    () => ref.read(approveMemberProvider)(
                      actorUid: uid!,
                      familyId: familyId!,
                      targetUid: member.uid,
                    ),
                  ),
          child: Text(l10n.memberReenable),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(t.radiusMd),
        onTap: () => context.push(AppRoutes.memberProfile(member.uid)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppAvatar(
                    id: member.uid,
                    name: member.displayName,
                    avatarKey: member.avatarKey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMe
                              ? '${member.displayName} (${l10n.memberYou})'
                              : member.displayName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          l10n.roleLabel(member.role),
                          style: TextStyle(color: t.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 8),
                PermissionGate(
                  allowed: canApprove || canRemove,
                  child: Wrap(spacing: 8, runSpacing: 8, children: actions),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
