import 'package:family_hub/app/theme/app_tokens.dart';
import 'package:family_hub/core/localization/l10n_ext.dart';
import 'package:family_hub/features/chores/presentation/member_names.dart';
import 'package:family_hub/features/chores/rota/domain/rota_matrix.dart';
import 'package:family_hub/features/family/presentation/family_providers.dart';
import 'package:family_hub/shared/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "On duty today" (P3-28): the avatars of the people who own a chore today,
/// with the count in words so the strip reads without the avatars.
class OnDutyStrip extends ConsumerWidget {
  const OnDutyStrip({required this.matrix, super.key});

  final RotaMatrix matrix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final t = context.tokens;
    final today = ref.watch(familyDateKeysProvider).today();
    final members = ref.watch(membersProvider).value ?? const [];
    final duty = matrix.onDuty(today);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.rotaOnDuty, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (duty.isEmpty)
            Text(
              l10n.rotaOnDutyNobody,
              key: const Key('rota_nobody'),
              style: TextStyle(color: t.textSecondary),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final id in duty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppAvatar(
                        id: id,
                        name: memberNameOf(members, id),
                        size: 32,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n.rotaOnDutyCount(
                            memberNameOf(
                              members,
                              id,
                              fallback: l10n.inboxSomeone,
                            ),
                            ref
                                .watch(appFormattersProvider)
                                .number(matrix.cell(id, today).length),
                          ),
                          style: TextStyle(color: t.textPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
