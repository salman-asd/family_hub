import 'package:family_hub/app/routing/app_routes.dart';
import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/family/domain/member.dart';
import 'package:family_hub/features/family/domain/relationship.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/features/family/presentation/widgets/labels.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:family_hub/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// `/family/members/:uid` — read-only profile; the owner can edit their own.
class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({required this.uid, super.key});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final members = ref.watch(membersProvider).value ?? const <Member>[];
    final me = ref.watch(currentUidProvider);

    Member? member;
    for (final m in members) {
      if (m.uid == uid) member = m;
    }
    if (member == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.memberProfileTitle)),
        body: EmptyState(
          icon: Icons.person_off_outlined,
          title: l10n.notFoundTitle,
        ),
      );
    }

    String? spouseName;
    for (final m in members) {
      if (m.uid == member.spouseId) spouseName = m.displayName;
    }

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(label, style: TextStyle(color: t.textSecondary)),
              ),
              Expanded(flex: 3, child: Text(value)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.memberProfileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: AppAvatar(
              id: member.uid,
              name: member.displayName,
              avatarKey: member.avatarKey,
              size: 88,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              member.fullName,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          row(l10n.profileRelationship,
              l10n.relationshipLabel(Relationship.parse(member.relationship))),
          row(l10n.memberRoleLabel, l10n.roleLabel(member.role)),
          row(l10n.memberStatusLabel, l10n.statusLabel(member.status)),
          if (spouseName != null) row(l10n.profileSpouse, spouseName),
          if (member.uid == me) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              key: const Key('edit_my_profile'),
              onPressed: () => context.push(AppRoutes.profileEdit),
              child: Text(l10n.memberEditProfile),
            ),
          ],
        ],
      ),
    );
  }
}
